# **SQL Data Modeling & Flat Table Engineering**

## **Overview**
This phase marks the transition from raw data cleaning to Relational Modeling. The objective was to build a robust SQL database that enforces data integrity and provides a high-performance "Flat Table" for Power BI visualization.

## **Logic & Workflow**
Exploration & Profiling: Used sp_help and SELECT audits to understand the grain of each table.

Geospatial Aggregation: Created a dedicated zipcode_locations table. This resolved the issue of multiple coordinates for the same zip code, ensuring a clean 1:N relationship with customers and sellers.

Integrity Shield: * Resolved Foreign Key violations by inserting missing zip codes from transactional tables into the master lookup table.

Removed orphan records to ensure the database schema is perfectly linked.

Advanced Denormalization: * Built the olist_flat_table using OUTER APPLY. This logic ensures that if an order has multiple payments or reviews, the core order metrics are not duplicated (avoiding inflated revenue numbers).

## **Data Imputation (Gold Layer):**

Used COALESCE to handle missing product categories.

Applied Mean Imputation for missing product weights and dimensions using SQL subqueries.

Added Boolean Flags (e.g., is_delivered) to simplify DAX calculations in Power BI.

Key SQL Features Used
Window Logic / Apply: OUTER APPLY for grain control.

Data Quality CTEs: Dynamic NULL checking using CROSS APPLY (VALUES...).

DDL/DML: ALTER TABLE constraints and INSERT/SELECT flows.