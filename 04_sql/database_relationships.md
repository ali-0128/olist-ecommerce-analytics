# Olist Database - Keys & Relationships

## Primary Keys (PK)

| Table                               | Primary Key                          | Data Type     | Notes                                              |
|-------------------------------------|--------------------------------------|---------------|----------------------------------------------------|
| customers                           | customer_id                          | varchar       | Unique per order (not per actual customer)         |
| orders                              | order_id                             | varchar       |                                                    |
| order_items                         | (order_id, order_item_id)            | Composite     | No single unique column                            |
| order_payments                      | (order_id, payment_sequential)       | Composite     | Supports multiple payments per order               |
| order_reviews                       | review_id                            | varchar       |                                                    |
| products                            | product_id                           | varchar       |                                                    |
| product_category_name_translation   | product_category_name                | varchar       |                                                    |
| sellers                             | seller_id                            | varchar       |                                                    |
| zipcode_locations                   | zip_code_prefix                      | int           | Manually created aggregated table                  |

## Foreign Keys (FK) & Main Relationships

| Source Table              | Source Column                | Target Table                              | Target Column             | Relationship Type | Notes / Strength                             |
|---------------------------|------------------------------|-------------------------------------------|---------------------------|-------------------|----------------------------------------------|
| orders                    | customer_id                  | customers                                 | customer_id               | 1 : N             | One customer → many orders                   |
| order_items               | order_id                     | orders                                    | order_id                  | N : 1             |                                              |
| order_items               | product_id                   | products                                  | product_id                | N : 1             |                                              |
| order_items               | seller_id                    | sellers                                   | seller_id                 | N : 1             |                                              |
| order_payments            | order_id                     | orders                                    | order_id                  | N : 1             | Multiple payments per order possible         |
| order_reviews             | order_id                     | orders                                    | order_id                  | N : 1             | Usually one review per order                 |
| products                  | product_category_name        | product_category_name_translation         | product_category_name     | N : 1             | Category translation                         |
| customers                 | customer_zip_code_prefix     | zipcode_locations                         | zip_code_prefix           | N : 1             | Approximate geographic mapping (cleaned)     |
| sellers                   | seller_zip_code_prefix       | zipcode_locations                         | zip_code_prefix           | N : 1             | Approximate geographic mapping (cleaned)     |

## Important General Notes

- No direct relationships with the original `geolocation` table after creating `zipcode_locations`
- Relationships with `zipcode_locations` are the **only geographic relationships** currently used (clean & duplicate-free)
- All relationships are **Many-to-One** (N:1) from the "many" side to the "one" side (except orders → customers which is 1:N from customer perspective)
- No direct **N:N** relationships in the current schema (handled through junction tables like order_items)
