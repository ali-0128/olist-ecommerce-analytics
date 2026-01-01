# Olist E-Commerce Data Dictionary

Comprehensive description of all tables and columns in the Olist Brazilian E-Commerce dataset.

## Dataset Overview

**Source:** Kaggle - Brazilian E-Commerce Public Dataset by Olist
**Time Period:** September 2016 - August 2018 (24 months)
**Total Orders:** ~100,000 orders
**Geographic Coverage:** All Brazilian states
**Number of Tables:** 8 original tables + 1 aggregated table (zipcode_locations)
> **Note:** This dictionary includes the aggregated `zipcode_locations` table created during preprocessing to optimize geolocation queries.

### Business Context:
Olist is a Brazilian e-commerce marketplace that connects small businesses to major sales channels. Sellers can advertise their products through Olist Store and ship directly to customers using Olist's logistics partners.

## customers

| Column                        | Data Type | Description                                          | Notes                                      |
|-------------------------------|-----------|------------------------------------------------------|--------------------------------------------|
| customer_id                   | varchar   | Unique identifier for each customer record in this Data                     | Primary Key                                |
customer_unique_id | varchar | Real unique customer identifier across all their orders | One customer_unique_id can have multiple customer_id values (one per order)| customer_zip_code_prefix      | int       | First 5 digits of the postal code                    | Used for geographic mapping                |
| customer_city                 | varchar   | City name                                            |                                            |
| customer_state                | varchar   | Two-letter state code (SP, RJ, MG...)                |                                            |

## orders

| Column                            | Data Type  | Description                                          |
|-----------------------------------|------------|------------------------------------------------------|
| order_id                          | varchar    | Unique identifier of the order                       |
| customer_id                       | varchar    | Foreign Key → customers                              |
| order_status                      | varchar    | Order status (delivered, shipped, canceled...)       |
| order_purchase_timestamp          | timestamp  | When customer placed the order                       |
| order_approved_at                 | timestamp  | When payment was approved (can be NULL if not approved)|
| order_delivered_carrier_date      | timestamp  | When order was handed over to logistics partner      |
| order_delivered_customer_date     | timestamp  | When order was actually delivered to customer's address|
| order_estimated_delivery_date     | timestamp  | Expected delivery date shown to customer at purchase time|

## order_items

| Column                    | Data Type | Description                                          |
|---------------------------|-----------|------------------------------------------------------|
| order_id                  | varchar   | Foreign Key → orders                                 |
| order_item_id             | int       | Item sequence within the order (1,2,3...)            |
| product_id                | varchar   | Foreign Key → products                               |
| seller_id                 | varchar   | Foreign Key → sellers                                |
| shipping_limit_date       | timestamp | Seller's limit date to hand over product to carrier  |
| price                     | float     | Product price                                        |
| freight_value             | float     | Freight/shipping cost                                |

## order_payments

| Column                  | Data Type | Description                                          |
|-------------------------|-----------|------------------------------------------------------|
| order_id                | varchar   | Foreign Key → orders                                 |
| payment_sequential      | int       | Payment sequence (1,2,3...) when multiple payments   |
| payment_type            | varchar   | Payment method (credit_card, boleto, voucher...)     |
| payment_installments    | int       | Number of installments                               |
| payment_value           | float     | Payment amount                                       |

## order_reviews

| Column                      | Data Type | Description                                          |
|-----------------------------|-----------|------------------------------------------------------|
| review_id                   | varchar   | Unique review identifier                             |
| order_id                    | varchar   | Foreign Key → orders                                 |
| review_score                | int       | Review score (1 to 5)                                |
| review_comment_title        | varchar   | Review title (very high null rate)                   |
| review_comment_message      | text      | Review comment text (high null rate)                 |
| review_creation_date        | timestamp | Review creation timestamp                            |
| review_answer_timestamp     | timestamp | Timestamp when seller/support replied (if any)       |

## products

| Column                        | Data Type | Description                                          |
|-------------------------------|-----------|------------------------------------------------------|
| product_id                    | varchar   | Unique product identifier                            |
| product_category_name         | varchar   | Product category name (in Portuguese)                |
| product_name_lenght           | float     | Number of characters in product name                 |
| product_description_lenght    | float     | Number of characters in product description          |
| product_photos_qty            | float     | Number of product photos                             |
| product_weight_g              | float     | Product weight in grams                              |
| product_length_cm             | float     | Product length in cm                                 |
| product_height_cm             | float     | Product height in cm                                 |
| product_width_cm              | float     | Product width in cm                                  |

## sellers

| Column                      | Data Type | Description                                          |
|-----------------------------|-----------|------------------------------------------------------|
| seller_id                   | varchar   | Unique seller identifier                             |
| seller_zip_code_prefix      | int       | First 5 digits of seller's postal code               |
| seller_city                 | varchar   | Seller's city                                        |
| seller_state                | varchar   | Seller's state (two-letter code)                     |

## zipcode_locations (manually created/aggregated table)

| Column              | Data Type | Description                                                  |
|---------------------|-----------|--------------------------------------------------------------|
| zip_code_prefix     | int       | Postal code prefix (Primary Key)                             |
| avg_latitude        | float     | Average latitude for this zip code prefix                    |
| avg_longitude       | float     | Average longitude for this zip code prefix                   |
| city                | varchar   | Most common city name for this prefix                        |
| state               | varchar   | State (two-letter code)                                      |
| location_count      | int       | Number of original rows in geolocation table for this prefix |
