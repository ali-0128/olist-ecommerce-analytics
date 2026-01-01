/*--===============================================================================
OLIST E-COMMERCE PROJECT
Phase 2: Database Setup, Relational Modeling & Denormalization
===============================================================================
Description:
    This script performs the full SQL pipeline for the Olist dataset:
    1. Schema Exploration.
    2. Geographic Data Aggregation (to solve duplication issues).
    3. Referential Integrity Enforcement (PK/FK).
    4. Data Denormalization (Creating a Flat Table for Power BI).
    5. Data Imputation and Final Refinement (Gold Layer).
===============================================================================
*/


-- Create the database
CREATE DATABASE Olist_database;
GO

-- Quick inspection of all tables to verify successful import and data types
SELECT TOP 5 * FROM customers;        
SELECT TOP 5 * FROM geolocation;      
SELECT TOP 5 * FROM sellers;          
SELECT TOP 5 * FROM order_items;      
SELECT TOP 5 * FROM order_payment;  
SELECT TOP 5 * FROM order_review;     
SELECT TOP 5 * FROM orders;           
SELECT TOP 5 * FROM products;         
GO

-- Get detailed structure for key tables 
EXEC sp_help customers; 
EXEC sp_help sellers;
EXEC sp_help order_items;
EXEC sp_help order_payment;
EXEC sp_help order_review;
EXEC sp_help orders;
EXEC sp_help products;
EXEC sp_help geolocation;



-- GEOGRAPHIC OPTIMIZATION
-- Problem: Original geolocation table has >1M rows with many duplicates per zip code.
-- Solution: Create an aggregated lookup table to ensure 1:1 relationship with zip_code_prefix.

IF OBJECT_ID('zipcode_locations', 'U') IS NOT NULL DROP TABLE zipcode_locations;

CREATE TABLE zipcode_locations (
    zip_code_prefix INT PRIMARY KEY,
    avg_latitude FLOAT,
    avg_longitude FLOAT,
    city VARCHAR(100),
    state CHAR(2),
    location_count INT
);

-- Populate table with averaged coordinates and the most frequent city name
INSERT INTO zipcode_locations (zip_code_prefix, avg_latitude, avg_longitude, city, state, location_count)
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat),
    AVG(geolocation_lng),
    MAX(geolocation_city), 
    MAX(geolocation_state),
    COUNT(*)
FROM geolocation
GROUP BY geolocation_zip_code_prefix;
GO


-- REFERENTIAL INTEGRITY & MISSING DATA HANDLING
-- Find and fix 'Orphan' zip codes in Customers and Sellers that aren't in Geolocation
-- This step is CRITICAL before applying Foreign Key constraints.

-- Insert missing zip codes from Sellers
INSERT INTO zipcode_locations (zip_code_prefix)
SELECT DISTINCT s.seller_zip_code_prefix
FROM sellers s
WHERE s.seller_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM zipcode_locations)
AND s.seller_zip_code_prefix IS NOT NULL;

-- Insert missing zip codes from Customers
INSERT INTO zipcode_locations (zip_code_prefix)
SELECT DISTINCT c.customer_zip_code_prefix
FROM customers c
WHERE c.customer_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM zipcode_locations)
AND c.customer_zip_code_prefix IS NOT NULL;

SELECT * FROM sellers 
WHERE seller_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM zipcode_locations);

-- Clean up any remaining invalid sellers that break constraints (7 records found)
DELETE FROM sellers
WHERE seller_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM zipcode_locations);
GO

-- Applying Constraints (Primary and Foreign Keys)
ALTER TABLE sellers ADD CONSTRAINT FK_sellers_zipcode FOREIGN KEY (seller_zip_code_prefix) REFERENCES zipcode_locations(zip_code_prefix);
ALTER TABLE customers ADD CONSTRAINT FK_customers_zipcode FOREIGN KEY (customer_zip_code_prefix) REFERENCES zipcode_locations(zip_code_prefix);
ALTER TABLE orders ADD CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
ALTER TABLE order_items ADD CONSTRAINT FK_items_orders FOREIGN KEY (order_id) REFERENCES orders (order_id);
ALTER TABLE order_items ADD CONSTRAINT FK_items_products FOREIGN KEY (product_id) REFERENCES products (product_id);
ALTER TABLE order_items ADD CONSTRAINT FK_items_sellers FOREIGN KEY (seller_id) REFERENCES sellers (seller_id);
ALTER TABLE order_payment ADD CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES orders (order_id);
ALTER TABLE order_review ADD CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES orders (order_id);
GO


-- DATA DENORMALIZATION (BUILDING THE FLAT TABLE)
-- Purpose: Merge all relevant dimensions into one wide table for Power BI performance.
-- Use OUTER APPLY to prevent row duplication from multiple payments/reviews.

IF OBJECT_ID('olist_flat_table', 'U') IS NOT NULL DROP TABLE olist_flat_table;

SELECT 
    -- Order & Customer Core Info
    o.order_id, o.order_status, o.order_purchase_timestamp, o.order_approved_at,
    o.order_delivered_carrier_date, o.order_delivered_customer_date, o.order_estimated_delivery_date,
    c.customer_unique_id, c.customer_zip_code_prefix AS customer_zip_prefix,
    zl_c.city AS customer_city, zl_c.state AS customer_state,
    zl_c.avg_latitude AS customer_avg_lat, zl_c.avg_longitude AS customer_avg_lng,
    
    -- Item & Product Details
    oi.order_item_id, oi.price, oi.freight_value, oi.shipping_limit_date,
    p.product_id, p.product_category_name, p.product_weight_g,
    p.product_length_cm, p.product_height_cm, p.product_width_cm,
    
    -- Seller Details
    s.seller_id, s.seller_zip_code_prefix AS seller_zip_prefix,
    zl_s.city AS seller_city, zl_s.state AS seller_state,
    zl_s.avg_latitude AS seller_avg_lat, zl_s.avg_longitude AS seller_avg_lng,
    
    -- Payment & Review Details (Ensuring 1:1 mapping using OUTER APPLY)
    pay.payment_type, pay.payment_installments, pay.payment_value,
    rev.review_score, rev.review_creation_date,

    -- Pre-calculated Metrics (Feature Engineering)
    oi.price + oi.freight_value AS total_order_item_value,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days_actual,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) AS delivery_days_estimated

INTO olist_flat_table
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
LEFT JOIN zipcode_locations zl_c ON c.customer_zip_code_prefix = zl_c.zip_code_prefix
LEFT JOIN zipcode_locations zl_s ON s.seller_zip_code_prefix = zl_s.zip_code_prefix
OUTER APPLY (SELECT TOP 1 payment_type, payment_installments, payment_value FROM order_payment op WHERE op.order_id = o.order_id ORDER BY op.payment_sequential) pay
OUTER APPLY (SELECT TOP 1 review_score, review_creation_date FROM order_review r WHERE r.order_id = o.order_id ORDER BY r.review_creation_date) rev;
GO


-- DATA QUALITY AUDIT
-- Checking for remaining NULL values in the newly created Flat Table
WITH total AS (SELECT COUNT(*) AS total_rows FROM olist_flat_table),
missing_counts AS (
    SELECT COLUMN_NAME, SUM(CASE WHEN t.[value] IS NULL THEN 1 ELSE 0 END) AS null_count
    FROM olist_flat_table
    CROSS APPLY (VALUES 
        ('order_id', CAST(order_id AS SQL_VARIANT)), ('order_status', CAST(order_status AS SQL_VARIANT)),
        ('order_delivered_customer_date', CAST(order_delivered_customer_date AS SQL_VARIANT)),
        ('customer_city', CAST(customer_city AS SQL_VARIANT)), ('product_category_name', CAST(product_category_name AS SQL_VARIANT)),
        ('price', CAST(price AS SQL_VARIANT)), ('payment_type', CAST(payment_type AS SQL_VARIANT))
        -- You can add more columns here as per your original script
    ) t (COLUMN_NAME, [value])
    GROUP BY COLUMN_NAME
)
SELECT mc.*, ROUND(100.0 * mc.null_count / t.total_rows, 4) AS null_percentage
FROM missing_counts mc CROSS JOIN total t
WHERE mc.null_count > 0 ORDER BY mc.null_count DESC;
GO


-- FINAL REFINEMENT - THE GOLD LAYER
-- Handling NULLs, adding logical Flags, and final Imputation for BI readiness.

IF OBJECT_ID('olist_clean_for_powerbi', 'U') IS NOT NULL DROP TABLE olist_clean_for_powerbi;

SELECT 
    order_id, order_status, order_purchase_timestamp,
    COALESCE(order_approved_at, order_purchase_timestamp) AS order_approved_at,
    order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date,

    -- Status Flags for easier filtering in Power BI
    CASE WHEN order_delivered_customer_date IS NULL THEN 0 ELSE 1 END AS is_delivered,
    CASE WHEN review_score IS NULL THEN 0 ELSE 1 END AS has_review,

    customer_unique_id,
    COALESCE(customer_city, 'Unknown') AS customer_city,
    COALESCE(customer_state, 'Unknown') AS customer_state,
    customer_avg_lat, customer_avg_lng,

    order_item_id,
    COALESCE(price, 0) AS price,
    COALESCE(freight_value, 0) AS freight_value,
    total_order_item_value,

    -- Product Imputation using global averages for missing dimensions
    COALESCE(product_category_name, 'Unknown') AS product_category_name,
    COALESCE(product_weight_g, (SELECT AVG(product_weight_g) FROM olist_flat_table)) AS product_weight_g,
    COALESCE(product_length_cm, (SELECT AVG(product_length_cm) FROM olist_flat_table)) AS product_length_cm,

    -- Seller & Payment Info
    seller_id,
    COALESCE(seller_city, 'Unknown') AS seller_city,
    COALESCE(payment_type, 'unknown') AS payment_type,
    COALESCE(payment_value, 0) AS payment_value,

    review_score,
    delivery_days_actual, delivery_days_estimated
INTO olist_clean_for_powerbi
FROM olist_flat_table;

-- Final View
SELECT TOP 100 * FROM olist_clean_for_powerbi;
GO