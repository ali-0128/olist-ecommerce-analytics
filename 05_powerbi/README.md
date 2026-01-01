# Data Visualization & Business Intelligence (Power BI Phase)

## Overview
Transformed the SQL flat table into an **interactive executive dashboard** with advanced DAX measures and strategic insights. Focus: actionable business intelligence for decision-makers.

---

## What Was Done

### 1. Data Import & Validation
- Connected to SQL Server (`olist_clean_for_powerbi` table)
- Validated data types and row counts in Power Query
- Confirmed zero data quality issues from SQL stage

### 2. Data Modeling (Advanced Features)

**Date Table:**
- Built comprehensive calendar table with DAX
- Added Year, Month, Quarter, Week columns
- Enabled time intelligence functions

**RFM Segmentation Table:**
Created customer segments based on purchase behavior:
- **Champions** (28%): High recency, frequency, monetary value
- **Loyal Customers** (20%): Consistent purchasers
- **At Risk** (16%): Declining engagement - retention priority
- **Lost** (15%): Churned customers
- **Potential** (20%): Growth opportunity

**Relationships:**
- `Date` table linked to orders via purchase timestamp
- `RFM` table linked via `customer_unique_id`
- Single-direction relationships for optimal performance

---

### 3. DAX Measures (Key Highlights)

**Core KPIs:**
```dax
Total Revenue = SUM(olist_clean[total_order_item_value])
Active Customers = DISTINCTCOUNT(olist_clean[customer_unique_id])
Avg Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
Delivery Rate = DIVIDE(CALCULATE([Total Orders], is_delivered = 1), [Total Orders], 0)
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

**Time Intelligence:**
- Revenue MTD, QTD, YTD using TOTALMTD/TOTALQTD/TOTALYTD functions

---

### 4. Dashboard Design

#### **Page 1: Executive Summary**
**Purpose:** High-level KPIs for C-level executives

**Key Components:**
- **KPI Cards**: Revenue (15.79M), Orders (113K), Customers (96K), AOV ($202.59), Review Score (4.02)
- **Growth Indicators**: YOY badges showing 207% revenue growth, 208% orders growth
- **Order Status Donut**: 97.21% delivered (green), 1.04% shipped (yellow), 0.60% canceled (red)
- **RFM Segmentation Donut**: Visual breakdown of customer loyalty segments
- **Top 5 Categories Bar Chart**: Revenue leaders (Health & Beauty: $1.4M at top)
- **Revenue Trend Line**: Monthly performance showing 207% YOY growth with seasonal patterns

**Interactivity:**
- Date and State slicers for filtering
- Cross-filtering across all visuals

---

#### **Page 2: Strategic Business Insights**
**Purpose:** Translate data into actionable recommendations

**4 Key Areas:**
1. **Revenue Performance**: 207% growth analysis with seasonal considerations
2. **Customer Loyalty**: Champions/Loyal drive profit, At Risk needs retention campaigns
3. **Operational Excellence**: 97.15% delivery rate, but regional variations affect 4.02 review score
4. **Order Value**: $202.59 AOV indicates healthy basket size with growth potential

---

### 5. Design Principles

**Color Strategy:**
- **Green**: Positive metrics (growth, delivered)
- **Yellow**: Neutral/warning (shipped, potential customers)
- **Red**: Negative (canceled, at risk)
- **Gray**: Professional neutral background

**Layout:**
- F-pattern reading flow (top-left to bottom-right)
- KPIs at top for immediate scanning
- White space to prevent clutter
- Grid-based alignment for consistency

**Performance Optimization:**
- Import mode (not DirectQuery) for speed
- Measures over calculated columns
- 7-8 visuals per page maximum
- Result: <3 second load time

---

## Most Professional Aspects

### **1. RFM Segmentation**
**Why it's advanced:**
- Goes beyond basic metrics to **behavioral segmentation**
- Enables targeted retention strategies (e.g., save At Risk = $1M+ revenue)
- Industry-standard approach used by Amazon, Netflix, etc.

### **2. Year-over-Year Growth Calculations**
**Why it's professional:**
- Uses DAX time intelligence (not manual year filtering)
- Automatically adapts to date range changes
- Shows 207% growth = 3x revenue increase (impressive for portfolio)

### **3. Strategic Insights Page**
**Why it stands out:**
- Combines quantitative (Page 1) with qualitative analysis (Page 2)
- Answers "So what?" - not just "What happened?"
- Executive-level storytelling with clear recommendations

### **4. Data Model Architecture**
**Why it's advanced:**
- Separate Date and RFM tables (not just flat import)
- Proper star schema design (fact table + dimension tables)
- Optimized relationships for query performance

---

## Key Insights Delivered

**Business Impact:**
- **15.79M revenue** (207% YOY growth) - successful expansion
- **16% At Risk customers** = $1M+ retention opportunity
- **97.21% delivery rate** = operational excellence
- **159.59 AOV** = room for 10-15% growth via bundling

---

## Tools Used
- **Power BI Desktop**: Dashboard development
- **DAX**: Advanced calculations (time intelligence, segmentation)
- **Power Query**: Data validation
- **SQL Server**: Data source

---

## Why Power BI?
**Time Intelligence**: Built-in DATEADD, TOTALYTD functions  
**Interactivity**: Slicers and cross-filtering out-of-the-box  
**Performance**: Handles millions of rows (our 113K is trivial)  
**Professional UI**: Modern visuals suitable for executive presentations

---

## Deliverables
2-page interactive dashboard (.pbix)  
Strategic insights with quantified recommendations  
Documented DAX measure library  
Optimized data model (star schema)

---

## Summary
This phase completes the **end-to-end analytics pipeline**:
- **Python**: Data cleaning & type corrections
- **SQL**: Aggregation, modeling, flat table creation
- **Power BI**: Visualization & strategic storytelling

**Result:** A portfolio-ready project demonstrating full-stack data analytics skills from raw data to executive insights.