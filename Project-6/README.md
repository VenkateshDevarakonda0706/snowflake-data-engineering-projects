# Retail Project 6 — Snowflake Schema

## Project Overview

Project 6 converts the existing retail **Star Schema** into a more normalized **Snowflake Schema** using Snowflake SQL.

The project demonstrates:

- Dimensional modeling
- Snowflake Schema design
- Dimension normalization
- Lookup tables
- Primary and foreign keys
- Hierarchical relationships
- Data validation
- Analytical reporting
- Star Schema vs Snowflake Schema comparison

The Project 6 implementation is built separately from the earlier Project 4/5 schema so that the original Star Schema remains available for comparison.

---

## Database and Schema

### Source

```text
Database: RETAIL_DB_P4
Schema:   RETAIL
```

The source contains the original Star Schema.

### Project 6

```text
Database: RETAIL_DB_P4
Schema:   RETAIL_P6
```

All Project 6 transformations are performed in:

```text
RETAIL_DB_P4.RETAIL_P6
```

---

# Star Schema → Snowflake Schema

## Original Star Schema

The original design was centered around:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
       |
       v
   FACT_SALES
```

The dimensions contained descriptive attributes that could be normalized.

---

# Final Snowflake Schema

The final Project 6 structure is:

```text
                         DIM_REGION
                              |
                              v
                         DIM_STATE
                              |
                              v
                          DIM_CITY
                         /        \
                        v          v
                DIM_CUSTOMER   DIM_BRANCH
                       \          /
                        \        /
                         FACT_SALES


DIM_CATEGORY
      |
      v
  DIM_BRAND
      |
      v
 DIM_PRODUCT
      |
      v
 FACT_SALES


DIM_YEAR
    |
    v
DIM_QUARTER
    |
    v
 DIM_MONTH
    |
    v
  DIM_DATE
    |
    v
 FACT_SALES
```

---

# Tables

## Fact Table

### FACT_SALES

Central fact table containing sales transactions and measures.

Main columns:

```text
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
QUANTITY
TOTAL_AMOUNT
```

Relationships:

```text
FACT_SALES.CUSTOMER_ID → DIM_CUSTOMER.CUSTOMER_ID
FACT_SALES.PRODUCT_ID  → DIM_PRODUCT.PRODUCT_ID
FACT_SALES.BRANCH_ID   → DIM_BRANCH.BRANCH_ID
FACT_SALES.DATE_ID     → DIM_DATE.DATE_ID
```

---

# Geography Hierarchy

## DIM_REGION

```text
REGION_ID       PK
REGION_NAME
```

## DIM_STATE

```text
STATE_ID        PK
STATE_NAME
REGION_ID       FK
```

## DIM_CITY

```text
CITY_ID         PK
CITY_NAME
STATE_ID        FK
```

Hierarchy:

```text
REGION
  ↓
STATE
  ↓
CITY
```

Both customers and branches can reference the same city hierarchy.

---

# Customer Dimension

## DIM_CUSTOMER

```text
CUSTOMER_ID       PK
CUSTOMER_NAME
CITY_ID           FK
MEMBERSHIP
```

Relationship:

```text
DIM_CUSTOMER
      |
   CITY_ID
      ↓
 DIM_CITY
      ↓
 DIM_STATE
      ↓
 DIM_REGION
```

This removes repeated city, state and region attributes from the customer table.

---

# Branch Dimension

## DIM_BRANCH

```text
BRANCH_ID        PK
BRANCH_NAME
CITY_ID          FK
MANAGER_NAME
```

Relationship:

```text
DIM_BRANCH
     |
  CITY_ID
     ↓
 DIM_CITY
     ↓
 DIM_STATE
     ↓
 DIM_REGION
```

---

# Product Hierarchy

## DIM_CATEGORY

```text
CATEGORY_ID       PK
CATEGORY_NAME
```

## DIM_BRAND

```text
BRAND_ID          PK
BRAND_NAME
CATEGORY_ID       FK
```

## DIM_PRODUCT

```text
PRODUCT_ID        PK
PRODUCT_NAME
BRAND_ID          FK
PRICE
```

Hierarchy:

```text
CATEGORY
   ↓
BRAND
   ↓
PRODUCT
```

The product-to-brand mapping uses category context because the source data can contain the same brand under different categories.

---

# Date Hierarchy

## DIM_YEAR

```text
YEAR_ID       PK
YEAR
```

## DIM_QUARTER

```text
QUARTER_ID    PK
QUARTER
YEAR_ID       FK
```

## DIM_MONTH

```text
MONTH_ID      PK
MONTH
QUARTER_ID    FK
```

## DIM_DATE

```text
DATE_ID       PK
DATE
DAY
DAY_NAME
WEEK_NO
MONTH_ID      FK
IS_WEEKEND
```

Hierarchy:

```text
YEAR
  ↓
QUARTER
  ↓
MONTH
  ↓
DATE
```

---

# Project Workflow

The project was completed through the following stages:

## 1. Analyze Existing Star Schema

The existing Project 4/5 schema was inspected to identify:

- Fact table
- Dimension tables
- Repeated attributes
- Hierarchical relationships
- Candidate lookup tables

## 2. Identify Redundant Attributes

The following hierarchies were identified:

```text
REGION → STATE → CITY

CATEGORY → BRAND → PRODUCT

YEAR → QUARTER → MONTH → DATE
```

## 3. Create Lookup Tables

The following lookup tables were created:

```text
DIM_REGION
DIM_STATE
DIM_CITY

DIM_CATEGORY
DIM_BRAND

DIM_YEAR
DIM_QUARTER
DIM_MONTH
```

## 4. Normalize Existing Dimensions

The existing dimensions were transformed:

```text
DIM_CUSTOMER → CITY_ID
DIM_BRANCH   → CITY_ID
DIM_PRODUCT  → BRAND_ID
DIM_DATE     → MONTH_ID
```

## 5. Validate Relationships

Fact-to-dimension relationships were checked using `LEFT JOIN` validation queries.

## 6. Run Analytical Reports

The normalized Snowflake Schema was used to produce business reports.

---

# Data Validation

Final expected/validated counts:

```text
DIM_REGION       = 4
DIM_STATE        = 14
DIM_CITY         = 20

DIM_CUSTOMER     = 20
DIM_BRANCH       = 10

DIM_DATE         = 31

FACT_SALES       = 100
```

Foreign-key validation:

```text
INVALID_CUSTOMER_KEYS = 0
INVALID_PRODUCT_KEYS  = 0
INVALID_BRANCH_KEYS   = 0
INVALID_DATE_KEYS     = 0
```

This confirms that all fact records successfully resolve to their corresponding dimensions.

---

# Analytical Reports

Project 6 supports the following business reports:

### Sales and Revenue

1. Customer-wise Sales
2. Product-wise Revenue
3. Brand-wise Revenue
4. Category-wise Revenue
5. City-wise Sales
6. State-wise Revenue
7. Region-wise Revenue
8. Monthly Revenue
9. Quarterly Revenue

### Top-N Analysis

10. Top 10 Customers
11. Top 10 Products
12. Top 10 Branches

### Advanced Analysis

13. Customer Purchase Trend
14. Product Performance Dashboard
15. Regional Sales Dashboard

These queries demonstrate how the fact table can be combined with the normalized hierarchies for business analysis.

---

# Example Drill-Down Paths

## Geography

```text
FACT_SALES
    ↓
DIM_BRANCH
    ↓
DIM_CITY
    ↓
DIM_STATE
    ↓
DIM_REGION
```

This supports:

```text
City-wise Sales
State-wise Revenue
Region-wise Revenue
```

## Product

```text
FACT_SALES
    ↓
DIM_PRODUCT
    ↓
DIM_BRAND
    ↓
DIM_CATEGORY
```

This supports:

```text
Product Revenue
Brand Revenue
Category Revenue
```

## Date

```text
FACT_SALES
    ↓
DIM_DATE
    ↓
DIM_MONTH
    ↓
DIM_QUARTER
    ↓
DIM_YEAR
```

This supports:

```text
Monthly Revenue
Quarterly Revenue
Year-based Analysis
```

---

# Star Schema vs Snowflake Schema

| Feature | Star Schema | Snowflake Schema |
|---|---|---|
| Normalization | Lower | Higher |
| Redundancy | Higher | Lower |
| Number of tables | Lower | Higher |
| Number of joins | Fewer | More |
| Query complexity | Lower | Higher |
| Hierarchy representation | Often inside dimensions | Separate lookup tables |
| Maintenance | Simple | More centralized |
| BI usability | Generally simpler | More complex |
| Storage redundancy | Higher | Lower |

The main trade-off is:

```text
Star Schema
    ↓
Fewer joins + simpler queries

Snowflake Schema
    ↓
More normalization + less redundancy
```

---

# Important Lessons

## 1. Lookup Tables

A lookup table stores reusable descriptive values.

Examples:

```text
DIM_REGION
DIM_STATE
DIM_CITY

DIM_CATEGORY
DIM_BRAND

DIM_YEAR
DIM_QUARTER
DIM_MONTH
```

## 2. Foreign Keys

Foreign keys connect normalized tables.

Example:

```text
DIM_CITY.STATE_ID
        ↓
DIM_STATE.STATE_ID
```

## 3. Hierarchies

Snowflake Schema makes hierarchies explicit:

```text
REGION → STATE → CITY

CATEGORY → BRAND → PRODUCT

YEAR → QUARTER → MONTH → DATE
```

## 4. LEFT JOIN Validation

A validation query such as:

```sql
SELECT COUNT(*)
FROM FACT_SALES F
LEFT JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;
```

finds fact records that have no matching customer.

A result of:

```text
0
```

means all fact customer keys are valid.

---

# Project 6 Outcome

The final Project 6 implementation demonstrates a complete Snowflake Schema transformation:

```text
Existing Star Schema
        ↓
Analyze Redundancy
        ↓
Identify Hierarchies
        ↓
Create Lookup Tables
        ↓
Normalize Dimensions
        ↓
Validate Relationships
        ↓
Run Business Reports
        ↓
Snowflake Schema
```

The project demonstrates both the **technical SQL implementation** and the **data-modeling concepts** behind a Snowflake Schema.

---

# Files

Recommended project files:

```text
Project-6/
│
├── Project-6.sql
├── EXPLANATION.md
└── README.md
```

### Project-6.sql

Contains:

- Schema creation
- Table creation
- Lookup-table population
- Dimension transformation
- Data validation
- Analytical queries

### EXPLANATION.md

Contains the detailed explanation of:

- Star Schema
- Snowflake Schema
- Hierarchies
- Lookup tables
- PK/FK relationships
- Transformation logic
- Validation
- Analytical use cases
- Star vs Snowflake comparison

### README.md

Provides a concise project overview, architecture, tables, workflow and learning outcomes.
