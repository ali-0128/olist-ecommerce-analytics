# Project Documentation: Olist E-Commerce Insight Hub

## 1. Project Overview

**Olist Insight Hub** is an end-to-end data analytics project demonstrating professional Business Intelligence capabilities. The project analyzes **100,000+ orders** from Olist (Brazil's largest e-commerce marketplace, 2016-2018) across logistics, customer behavior, and product performance to deliver actionable insights for strategic growth.

**Real-World Simulation:**
This project replicates a professional BI environment where data flows from raw sources → cleaned datasets → relational database → executive dashboards.

---

## 2. Project Objectives

**Data Quality Assurance**: Profile and validate 8 raw datasets, correcting critical data type issues (8+ timestamp columns)

**Relational Modeling**: Build optimized SQL schema with referential integrity (PK/FK constraints) and aggregated geolocation lookup table

**Customer Intelligence**: Implement RFM segmentation model to identify high-value customers and churn risks

**Operational Insights**: Track 97.21% delivery success rate and analyze impact on customer satisfaction (4.02/5 avg review)

**Growth Analysis**: Measure 207% Year-over-Year revenue increase with seasonal trend identification

---

## 3. Scope of Work

The project addresses four analytical domains:

### **Executive Analysis**
- Revenue performance: R$15.79M total, 207% YoY growth
- Order volume: 113K orders (208% YoY increase)
- Customer base: 96K active customers
- Average Order Value: R$159.59

### **Customer Segmentation (RFM)**
- **Champions (28%)**: High recency, frequency, monetary - primary profit drivers
- **Loyal Customers (20%)**: Consistent repeat purchasers
- **At Risk (16%)**: Declining engagement - R$1M+ revenue exposure
- **Lost (15%)**: Churned customers - R$2.4M+ lost potential
- **Potential (20%)**: Growth opportunity segment
- **New (<1%)**: Recent first-time buyers

### **Operational Excellence**
- Delivery success: 97.21% (industry-leading)
- Cancellation rate: 0.60% (minimal failures)
- Avg review score: 4.02/5 (solid performance)
- Gap analysis: High delivery rate vs. moderate satisfaction

### **Product Performance**
- Top category: Health & Beauty (R$1.4M, 9% of revenue)
- Category concentration: Top 5 = 43% of total revenue
- AOV optimization: Bundling strategies to increase from R$159.59 → R$225

---

## 4. Tools & Technologies

| Tool | Phase | Purpose |
|------|-------|---------|
| **Python** | Data Preparation | Profiling, datetime conversion, quality assessment |
| **Pandas/NumPy** | Data Preparation | CSV processing, type corrections |
| **SQL Server** | Data Engineering | Aggregation, modeling, flat table creation |
| **T-SQL** | Data Engineering | GROUP BY, OUTER APPLY, CTEs, constraints |
| **Power BI** | Visualization | Interactive dashboards, DAX measures |
| **DAX** | Analytics | Time intelligence, RFM scoring, KPI calculations |
| **Power Query** | Data Validation | Pre-visualization data checks |
| **dbdiagram.io** | Documentation | ERD schema visualization |

---

## 5. Database Design & Schema

### **Architecture: Modified Star Schema**

**Fact Table:**
- `olist_clean_for_powerbi` (113K rows): Denormalized order transactions

**Dimension Tables:**
- `Date` table: Time intelligence hierarchy (Year → Quarter → Month → Week)
- `RFM_Segmentation` table: Customer behavioral segments

**Key Design Decisions:**
1. **Geolocation Aggregation**: 
   - Problem: 1M+ rows with duplicate zip codes
   - Solution: Created `zipcode_locations` (20K unique zips with averaged coordinates)

2. **Denormalization Strategy**: 
   - Used **OUTER APPLY** to prevent row multiplication from multiple payments/reviews
   - Result: Single row per order item (no inflated revenue)

3. **Missing Value Handling**:
   - SQL COALESCE with global means for product dimensions
   - Status flags (is_delivered, has_review) for easy filtering

### **Schema Diagram:**
[View Interactive ERD](https://dbdiagram.io/d/Olist_Database_Schema-694a881edbf05578e65ff0d1)

---

## 6. Data Analysis & Dashboard Development

### **Phase 1: Python Exploration (Week 1-2)**

**Automated EDA Loop:**
- Profiled 9 datasets for shape, duplicates, data types, nulls
- Generated descriptive statistics and sample inspections

**Critical Findings:**
- Geolocation: 1M rows → 20K unique zips (50x duplication)
- Orders: 3% missing delivery dates
- Products: 610 missing categories
- Reviews: 87% missing titles, 59% missing messages

**Deliverable:** 8 cleaned CSV files with corrected datetime formats

---

### **Phase 2: SQL Engineering (Week 2-3)**

**Key Transformations:**

1. **Zipcode Aggregation:**
```sql
CREATE TABLE zipcode_locations (
    zip_code_prefix INT PRIMARY KEY,
    avg_latitude FLOAT,
    avg_longitude FLOAT,
    city VARCHAR(100),
    state CHAR(2),
    location_count INT
);
```

2. **Flat Table Creation:**
```sql
-- Used OUTER APPLY to handle multiple payments/reviews per order
SELECT o.*, pay.payment_type, rev.review_score, ...
FROM orders o
OUTER APPLY (
    SELECT TOP 1 * FROM order_payment 
    WHERE order_id = o.order_id 
    ORDER BY payment_sequential
) pay
```

3. **Gold Layer (Power BI Ready):**
- Imputed missing categories: `COALESCE(product_category_name, 'Unknown')`
- Added flags: `is_delivered`, `has_review`
- Calculated metrics: `delivery_days_actual`, `total_order_item_value`

**Deliverable:** `olist_clean_for_powerbi` table (113K rows, 40+ columns)

---

### **Phase 3: Power BI Analytics (Week 4-5)**

**DAX Measures Library:**

**Core KPIs:**
```dax
Total Revenue = SUM(olist_clean[total_order_item_value])
Total Orders = DISTINCTCOUNT(olist_clean[order_id])
Active Customers = DISTINCTCOUNT(olist_clean[customer_unique_id])
Avg Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
Delivery Rate = DIVIDE(
    CALCULATE([Total Orders], olist_clean[is_delivered] = 1),
    [Total Orders], 0
)
```

**Year-over-Year Growth:**
```dax
YOY Revenue Growth % = 
DIVIDE(
    [Total Revenue] - CALCULATE([Total Revenue], DATEADD('Date'[Date], -1, YEAR)),
    CALCULATE([Total Revenue], DATEADD('Date'[Date], -1, YEAR)),
    0
)
```

**RFM Segmentation:**
```dax
RFM_Table = 
VAR CurrentDate = MAX(DateTable[Date])  

VAR CustomerSummary =
    SUMMARIZE(
        olist_flat_table,
        olist_flat_table[customer_unique_id],
        "LastPurchaseDate", MAX(olist_flat_table[order_purchase_timestamp]),
        "OrderCount", COUNTROWS(olist_flat_table),
        "TotalSpent", SUM(olist_flat_table[total_order_item_value])
    )

VAR RFMCalc =
    ADDCOLUMNS(
        CustomerSummary,
        "Recency", DATEDIFF([LastPurchaseDate], CurrentDate, DAY),
        "Frequency", [OrderCount],
        "Monetary", [TotalSpent]
    )

VAR RFMWithRanks =
    ADDCOLUMNS(
        RFMCalc,
        "R_Score", 
            VAR RankR = RANKX(RFMCalc, [Recency], , ASC, Dense)
            RETURN
                SWITCH(
                    TRUE(),
                    RankR <= PERCENTILEX.INC(RFMCalc, [Recency], 0.2), 5,
                    RankR <= PERCENTILEX.INC(RFMCalc, [Recency], 0.4), 4,
                    RankR <= PERCENTILEX.INC(RFMCalc, [Recency], 0.6), 3,
                    RankR <= PERCENTILEX.INC(RFMCalc, [Recency], 0.8), 2,
                    1
                ),
        "F_Score", 
            VAR RankF = RANKX(RFMCalc, [Frequency], , DESC, Dense)
            RETURN
                SWITCH(
                    TRUE(),
                    RankF <= PERCENTILEX.INC(RFMCalc, [Frequency], 0.2), 5,
                    RankF <= PERCENTILEX.INC(RFMCalc, [Frequency], 0.4), 4,
                    RankF <= PERCENTILEX.INC(RFMCalc, [Frequency], 0.6), 3,
                    RankF <= PERCENTILEX.INC(RFMCalc, [Frequency], 0.8), 2,
                    1
                ),
        "M_Score", 
            VAR RankM = RANKX(RFMCalc, [Monetary], , DESC, Dense)
            RETURN
                SWITCH(
                    TRUE(),
                    RankM <= PERCENTILEX.INC(RFMCalc, [Monetary], 0.2), 5,
                    RankM <= PERCENTILEX.INC(RFMCalc, [Monetary], 0.4), 4,
                    RankM <= PERCENTILEX.INC(RFMCalc, [Monetary], 0.6), 3,
                    RankM <= PERCENTILEX.INC(RFMCalc, [Monetary], 0.8), 2,
                    1
                )
    )

RETURN
    ADDCOLUMNS(
        RFMWithRanks,
        "RFM_Score", [R_Score] & [F_Score] & [M_Score],
        "Customer_Segment",
            SWITCH(
                TRUE(),
                [R_Score] >= 4 && [F_Score] >= 4 && [M_Score] >= 4, "Champions",
                [R_Score] >= 3 && [F_Score] >= 3 && [M_Score] >= 3, "Loyal Customers",
                [R_Score] >= 4 && [F_Score] >= 2, "Potential Loyalists",
                [R_Score] >= 4 && [M_Score] >= 4, "New Customers",
                [R_Score] <= 2 && [F_Score] >= 4, "At Risk",
                [R_Score] <= 2 && [F_Score] <= 2, "Lost",
                "Others"
            )
    )

Customer Segment = 
SWITCH( TRUE(),
    [RFM_Score] >= 444, "Champions",
    [RFM_Score] >= 333, "Loyal Customers",
    [RFM_Score] >= 222, "Potential Loyalists",
    [RFM_Score] <= 111, "Lost Customers",
    "At Risk" 
)
```

---

### **Dashboard Design Principles:**

**Page 1: Executive Summary**
- **Layout**: F-pattern (KPIs → Status → Trends → Details)
- **Color Coding**: Green (positive), Yellow (neutral), Red (negative)
- **Interactivity**: Date and State slicers with cross-filtering

**Page 2: Strategic Insights**
- **Revenue Analysis**: 207% growth with seasonal drop investigation
- **Customer Strategy**: At Risk retention = R$1M+ opportunity
- **Operations**: Delivery excellence vs. satisfaction gap
- **AOV Optimization**: Bundling recommendations

**Performance:** <3 second load time via Import mode and measure optimization

---

## 7. Key Analytical Questions Answered

**What is the Year-over-Year growth in revenue?**
- Answer: **207% growth** (R$5.1M → R$15.79M), driven by 208% increase in orders

**Which customer segments drive the most value?**
- Answer: **Champions (28%)** and **Loyal (20%)** = 48% of customer base, disproportionate revenue contribution

**What is the delivery performance?**
- Answer: **97.21% success rate**, but moderate 4.02/5 review score suggests quality/speed gaps

**Where are the revenue opportunities?**
- Answer: **At Risk segment** (16%) = R$1M+ retention potential; **AOV growth** to R$225 = R$2.5M+ annual increase

**What products drive revenue?**
- Answer: **Health & Beauty** (R$1.4M) leads; Top 5 categories = 43% of revenue (concentration risk)

---

## 8. UI/UX Dashboard Design

### **Design Philosophy:**
1. **Executive-First**: Simple, scannable layout for C-level audience
2. **Color Psychology**: Semantic colors (green = good, red = alert)
3. **Progressive Disclosure**: High-level summary → detailed insights
4. **Performance**: Optimized for speed (<3s load)

### **Visual Hierarchy:**
- **Top**: KPI cards with YoY badges (immediate impact)
- **Middle**: Status donuts and category bars (operational view)
- **Bottom**: Trend line (historical context)

### **Typography:**
- Headers: Bold, 18-20pt
- Metrics: Large, 32-36pt
- Labels: Regular, 10-12pt

---

## 9. Final Deliverables

| Deliverable | Description | Status |
|-------------|-------------|--------|
| **Cleaned CSV Files** | 8 processed datasets with datetime corrections | Complete |
| **SQL Schema** | Database with zipcode_locations + flat table | Complete |
| **ERD Diagram** | Interactive schema visualization | [Link](https://dbdiagram.io/d/Olist_Database_Schema-694a881edbf05578e65ff0d1) |
| **Power BI Dashboard** | 2-page executive report (.pbix) | Complete |
| **DAX Library** | Documented measures with comments | Complete |
| **Strategic Insights** | Business recommendations with ROI | Complete |
| **Project Documentation** | This comprehensive guide (PDF) | Complete |

---

## 10. Business Impact Summary

### **Key Findings:**
- **Revenue Growth**: 207% YoY increase demonstrates successful expansion
- **Churn Risk**: 16% At Risk + 15% Lost = 31% of customers need intervention
- **Operations**: 97.21% delivery rate = logistics strength
- **Opportunity**: R$3.5M+ revenue potential (retention + AOV growth)

### **Strategic Recommendations:**

**1. Customer Retention Campaign (Priority 1)**
- **Target**: At Risk segment (16% = ~15,360 customers)
- **Action**: Personalized discount codes, abandoned cart recovery
- **Expected ROI**: Save 50% from churn = **R$1M+ revenue**

**2. AOV Optimization (Priority 2)**
- **Target**: All customers, focus on Top 5 categories
- **Action**: Product bundling, free shipping threshold at $250
- **Expected ROI**: 10% AOV increase = **R$2.5M+ annual revenue**

**3. Regional Delivery Analysis (Priority 3)**
- **Target**: States with low satisfaction scores
- **Action**: Partner with additional carriers, add fulfillment centers
- **Expected ROI**: Improve review score 4.02 → 4.3 = higher conversion

---

## 11. Skills Demonstrated

This project showcases professional-level competencies across the full analytics stack:

**Data Engineering**: Aggregation, denormalization, referential integrity  
**SQL Mastery**: OUTER APPLY, CTEs, window functions, constraints  
**Python Proficiency**: Pandas profiling, datetime handling, CSV processing  
**BI Development**: DAX measures, time intelligence, RFM modeling  
**Data Visualization**: Color theory, layout design, interactive dashboards  
**Business Analysis**: Customer segmentation, YoY growth, strategic recommendations  
**Documentation**: Professional README structure, ERD diagrams, technical writing  

---

## 12. Lessons Learned

### **Technical:**
- **OUTER APPLY > JOINs** for preventing row duplication in denormalization
- **Import mode > DirectQuery** for dashboard performance (<3s load)
- **Aggregation in SQL > Python** for large datasets (1M+ rows)

### **Analytical:**
- **customer_unique_id ≠ customer_id**: Critical for retention metrics
- **RFM segments** provide more value than simple demographic cuts
- **Delivery rate** and **satisfaction** are not perfectly correlated

### **Design:**
- **Less is more**: 7-8 visuals per page max for clarity
- **Color semantics** improve comprehension (green = positive)
- **Strategic insights** page adds immense value vs. just charts

---

*This documentation was created as part of a professional portfolio project to demonstrate end-to-end analytics capabilities. For questions or collaboration inquiries, please contact [alirabie0128@gmail.com].*

*Last Updated: December 2025*
