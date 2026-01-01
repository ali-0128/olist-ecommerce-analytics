# Data Exploration & Preprocessing (Python Phase)

## Overview
Initial exploration and preparation of 8 raw CSV files from Kaggle's Olist Brazilian E-Commerce dataset. This phase focused on **data quality assessment** and **datetime type corrections** to prepare for SQL modeling.

---

## What Was Done

### 1. Automated Data Quality Audit
Built an **EDA loop** that profiled all 8 tables systematically:
- Checked shape, duplicates, data types, and missing values
- Generated descriptive statistics for all columns
- Inspected head/tail samples for anomalies

### 2. Key Findings

**Critical Issues Identified:**
- **Geolocation**: 1M+ rows with severe duplication (same zip code, multiple coordinates)
- **Orders**: ~3% missing delivery dates, affecting time calculations
- **Products**: ~610 missing categories, ~2 missing dimensions
- **Reviews**: 87% missing titles, 59% missing comments

**Data Integrity Validated:**
- All primary keys are unique (no duplicates in order_id, product_id, seller_id, etc.)
- Text-based IDs are clean with no missing values

### 3. Data Type Corrections
Converted **8 timestamp columns** from string (object) to datetime format:
- `orders`: 5 columns (purchase, approval, delivery timestamps)
- `order_items`: 1 column (shipping_limit_date)
- `order_reviews`: 2 columns (creation, answer timestamps)

```python
# Used error handling to convert invalid dates to NaT
for col in date_cols:
    orders[col] = pd.to_datetime(orders[col], errors='coerce')
```

### 4. Strategic Decisions

**Geolocation Aggregation → Deferred to SQL**
- Reason: SQL handles GROUP BY on 1M+ rows more efficiently
- Benefit: Allows Foreign Key constraints after creating clean lookup table

**Missing Values → Preserved (No Imputation)**
- Reason: SQL better suited for global mean/median calculations
- Benefit: Flexibility for different imputation strategies in SQL/Power BI

**Customer Identity Insight:**
- `customer_id` = Order-level identifier (one per order)
- `customer_unique_id` = Person-level identifier (tracks same customer across orders)
- **Impact**: Critical distinction for retention and RFM analysis

---

## Deliverables
✅ **8 cleaned CSV files** exported with:
- Corrected datetime formats
- Preserved null values (for SQL-stage handling)
- UTF-8 encoding for Portuguese text
- No index columns

---

## Tools Used
- **Python (Pandas, NumPy)**: Data manipulation and type conversion
- **IPython Display**: Structured profiling output

---

## Why Python for This Phase?
- **Fast profiling**: Automated loop audited 9 tables in seconds
- **Type flexibility**: Pandas handles multiple datetime formats automatically
- **Interactive exploration**: Quick `.describe()`, `.isnull()` for quality checks

## Why NOT Python for Everything?
- **Aggregation**: SQL GROUP BY is faster for 1M+ rows
- **Integrity**: Foreign Keys are native to SQL
- **Imputation**: SQL subqueries more efficient at scale

---

## Next Phase: SQL Data Modeling
The cleaned CSVs will be imported into SQL Server for:
1. Geolocation aggregation (create `zipcode_locations` table)
2. Primary/Foreign Key constraints enforcement
3. Flat table creation using OUTER APPLY
4. Missing value imputation with COALESCE
5. Gold layer with flags and calculated columns

---

*This phase established a clean foundation for robust SQL transformations and Power BI visualization.*