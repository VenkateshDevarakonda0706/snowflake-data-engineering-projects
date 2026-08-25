# Project 4 — Retail Sales Data Warehouse

A complete **Retail Sales Analytics Data Warehouse** built using **Snowflake** and a **Star Schema** dimensional model.

The project demonstrates an end-to-end data warehousing workflow:

```text
Business Requirement
        ↓
Business Process
        ↓
Business Event
        ↓
Grain Definition
        ↓
Dimensional Modeling
        ↓
Snowflake Implementation
        ↓
CSV Ingestion
        ↓
Data Validation
        ↓
Analytical SQL
        ↓
Business Reporting
```

---

## 📌 Project Overview

The objective of this project is to build a structured analytical warehouse for retail sales data.

The warehouse allows the business to analyze sales from different perspectives:

- Customers
- Products
- Branches
- States
- Regions
- Categories
- Memberships
- Dates
- Months
- Quarters
- Years
- Weekends / Weekdays

The main business measures are:

- Quantity
- Total Amount / Revenue

---

# 🏢 Business Process

## Retail Sales Analytics

The business process analyzed in this project is:

> **Retail Sales Analytics**

The business wants to understand and analyze retail sales transactions generated when customers purchase products from different branches.

---

# 🎯 Business Event

The business event is:

> **A customer purchases a product from a branch on a specific date.**

Example:

```text
Customer 1
    ↓
purchases
    ↓
Product 101
    ↓
from Branch 1
    ↓
on Date 1
    ↓
for ₹65,000
```

---

# 📏 Grain

The grain defines exactly what one row in the fact table represents.

> **One row in FACT_SALES represents one product purchased by one customer from one branch on one specific date.**

Example:

```text
CUSTOMER_ID  = 1
PRODUCT_ID   = 101
BRANCH_ID    = 1
DATE_ID      = 1
QUANTITY     = 1
TOTAL_AMOUNT = 65000
```

This represents one retail sales event at the defined grain.

---

# ⭐ Why Star Schema?

This project uses a **Star Schema** because the workload is analytical.

The fact table stores the measurable business events, while dimension tables provide descriptive context.

```text
                    DIM_CUSTOMER
                         |
                         |
DIM_PRODUCT ------ FACT_SALES ------ DIM_DATE
                         |
                         |
                    DIM_BRANCH
```

The model makes questions such as these easy to answer:

```text
Who?
→ Customer

What?
→ Product

Where?
→ Branch

When?
→ Date

How many?
→ Quantity

How much?
→ Total Amount
```

---

# 🏗️ Snowflake Architecture

The project is implemented using Snowflake.

### Warehouse

```text
RETAIL_WH
```

Used as the compute resource for executing SQL statements.

### Database

```text
RETAIL_DB_P4
```

Dedicated database for Project 4.

### Schema

```text
RETAIL
```

The schema contains the project's tables, stage, and file format.

---

# 📂 Project Objects

```text
RETAIL_DB_P4
│
└── RETAIL
    │
    ├── DIM_CUSTOMER
    ├── DIM_PRODUCT
    ├── DIM_BRANCH
    ├── DIM_DATE
    ├── FACT_SALES
    │
    ├── RETAIL_STAGE
    └── RETAIL_CSV_FORMAT
```

---

# 📄 Source Data

The project uses five CSV files:

```text
customers.csv
products.csv
branches.csv
calendar.csv
sales.csv
```

Source data contains:

```text
20 customers
20 products
10 branches
31 calendar dates
100 sales records
```

---

# 🔄 Source-to-Warehouse Mapping

```text
customers.csv
      ↓
DIM_CUSTOMER

products.csv
      ↓
DIM_PRODUCT

branches.csv
      ↓
DIM_BRANCH

calendar.csv
      ↓
DIM_DATE

sales.csv
      ↓
FACT_SALES
```

---

# 🧩 Dimension Tables

The project contains four dimension tables.

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

Dimensions provide descriptive context for the sales events.

---

## 👤 DIM_CUSTOMER

Stores customer information.

| Column | Description |
|---|---|
| CUSTOMER_ID | Unique customer identifier |
| CUSTOMER_NAME | Customer name |
| CITY | Customer city |
| STATE | Customer state |
| MEMBERSHIP | Customer membership type |

Primary Key:

```text
CUSTOMER_ID
```

---

## 📦 DIM_PRODUCT

Stores product information.

| Column | Description |
|---|---|
| PRODUCT_ID | Unique product identifier |
| PRODUCT_NAME | Product name |
| CATEGORY | Product category |
| BRAND | Product brand |
| PRICE | Product price |

Primary Key:

```text
PRODUCT_ID
```

### Why is PRICE in the dimension?

Although `PRICE` is numeric, being numeric does not automatically make a column a measure.

`PRICE` describes the product, so it belongs to:

```text
DIM_PRODUCT
```

The sales measures are:

```text
QUANTITY
TOTAL_AMOUNT
```

which belong to:

```text
FACT_SALES
```

---

## 🏪 DIM_BRANCH

Stores branch information.

| Column | Description |
|---|---|
| BRANCH_ID | Unique branch identifier |
| BRANCH_NAME | Branch name |
| CITY | Branch city |
| STATE | Branch state |
| REGION | Branch region |
| MANAGER_NAME | Branch manager |

Primary Key:

```text
BRANCH_ID
```

---

## 📅 DIM_DATE

Stores calendar information.

| Column | Description |
|---|---|
| DATE_ID | Unique date identifier |
| DATE | Actual date |
| DAY | Day number |
| DAY_NAME | Day name |
| WEEK_NO | Week number |
| MONTH | Month |
| QUARTER | Quarter |
| YEAR | Year |
| IS_WEEKEND | Weekend indicator |

Primary Key:

```text
DATE_ID
```

The date dimension allows analysis by:

- Day
- Week
- Month
- Quarter
- Year
- Weekend / Weekday

---

# 📊 Fact Table

## FACT_SALES

`FACT_SALES` is the central fact table.

It stores the retail sales business events at the defined grain.

### Structure

| Column | Type / Role |
|---|---|
| SALE_ID | Primary Key |
| CUSTOMER_ID | Foreign Key |
| PRODUCT_ID | Foreign Key |
| BRANCH_ID | Foreign Key |
| DATE_ID | Foreign Key |
| QUANTITY | Additive Measure |
| TOTAL_AMOUNT | Additive Measure |

---

# 📐 Measures

The project contains two main measures.

| Measure | Type |
|---|---|
| QUANTITY | Additive |
| TOTAL_AMOUNT | Additive |

### QUANTITY

Represents the number of units sold.

### TOTAL_AMOUNT

Represents the revenue generated by the sales event.

Both measures can be summed across the relevant dimensions.

---

# 🔗 Relationships

The Star Schema relationships are:

```text
DIM_CUSTOMER  1 ---- * FACT_SALES

DIM_PRODUCT   1 ---- * FACT_SALES

DIM_BRANCH    1 ---- * FACT_SALES

DIM_DATE      1 ---- * FACT_SALES
```

Meaning:

- One customer can have many sales.
- One product can appear in many sales.
- One branch can have many sales.
- One date can contain many sales.

---

# 🔑 Primary and Foreign Keys

## Primary Keys

```text
DIM_CUSTOMER → CUSTOMER_ID
DIM_PRODUCT  → PRODUCT_ID
DIM_BRANCH   → BRANCH_ID
DIM_DATE     → DATE_ID
FACT_SALES   → SALE_ID
```

## Foreign Keys

FACT_SALES contains:

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
```

These connect the fact table to the dimension tables.

---

# 🗺️ Dimensional Model

```text
                         DIM_CUSTOMER
                         PK: CUSTOMER_ID
                              |
                              | 1:M
                              |
                              ↓
DIM_PRODUCT ─────────── FACT_SALES ─────────── DIM_DATE
PK: PRODUCT_ID          PK: SALE_ID            PK: DATE_ID
                        FK: CUSTOMER_ID
                        FK: PRODUCT_ID
                        FK: BRANCH_ID
                        FK: DATE_ID
                              ↑
                              |
                              | M:1
                              |
                         DIM_BRANCH
                         PK: BRANCH_ID
```

---

# 📥 Data Ingestion

The project uses a Snowflake internal stage and CSV file format.

## File Format

```text
RETAIL_CSV_FORMAT
```

The file format tells Snowflake how to read the CSV files.

Typical configuration:

```sql
TYPE = CSV
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
EMPTY_FIELD_AS_NULL = TRUE
```

---

# 📦 Stage

The project uses:

```text
RETAIL_STAGE
```

The stage provides a controlled location for the source CSV files before loading them into Snowflake tables.

Data flow:

```text
CSV Files
    ↓
RETAIL_STAGE
    ↓
COPY INTO
    ↓
Snowflake Tables
```

---

# 🚚 Data Loading

Snowflake's `COPY INTO` command is used to load the CSV data.

Example:

```sql
COPY INTO DIM_CUSTOMER
FROM @RETAIL_STAGE/customers.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';
```

The same approach is used for the remaining source files.

---

# 🔢 Loading Order

Dimension tables are loaded before the fact table.

```text
customers.csv
      ↓
DIM_CUSTOMER

products.csv
      ↓
DIM_PRODUCT

branches.csv
      ↓
DIM_BRANCH

calendar.csv
      ↓
DIM_DATE

sales.csv
      ↓
FACT_SALES
```

This follows the logical dependency of the fact table on the dimensions.

---

# ✅ Data Validation

After loading, the warehouse was validated.

## Row Count Validation

Expected counts:

```text
DIM_CUSTOMER → 20
DIM_PRODUCT  → 20
DIM_BRANCH   → 10
DIM_DATE     → 31
FACT_SALES   → 100
```

## NULL Validation

Important fact columns were checked:

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
QUANTITY
TOTAL_AMOUNT
```

## Foreign-Key Validation

Fact-table keys were checked against:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

to identify orphan records.

## Measure Validation

Measures were checked using:

```text
MIN()
MAX()
SUM()
```

for:

```text
QUANTITY
TOTAL_AMOUNT
```

---

# 📈 Analytics and Reports

The warehouse supports multiple analytical reports.

## 1. Customer Revenue Report

Answers:

> How much revenue did each customer generate?

Uses:

```text
FACT_SALES
+
DIM_CUSTOMER
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY CUSTOMER
```

---

## 2. Product Revenue Report

Answers:

> Which products generate the most revenue?

Uses:

```text
FACT_SALES
+
DIM_PRODUCT
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY PRODUCT
```

---

## 3. Branch Performance Report

Answers:

> Which branches generate the most sales?

Uses:

```text
FACT_SALES
+
DIM_BRANCH
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY BRANCH
```

---

## 4. Monthly Revenue Report

Answers:

> How much revenue was generated by month?

Uses:

```text
FACT_SALES
+
DIM_DATE
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY YEAR, MONTH
```

---

## 5. State-wise Sales Report

Answers:

> Which states generate the most revenue?

Uses:

```text
DIM_BRANCH.STATE
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY STATE
```

---

## 6. Category-wise Revenue Report

Answers:

> Which product categories generate the most revenue?

Uses:

```text
DIM_PRODUCT.CATEGORY
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY CATEGORY
```

---

## 7. Top Customers

Identifies the customers with the highest revenue.

```sql
ORDER BY TOTAL_SALES DESC
LIMIT 10
```

---

## 8. Top Products

Identifies the products with the highest revenue.

```sql
ORDER BY TOTAL_REVENUE DESC
LIMIT 10
```

---

## 9. Top Branches

Identifies the branches with the highest revenue.

```sql
ORDER BY TOTAL_SALES DESC
LIMIT 10
```

---

## 10. Sales Trend Analysis

Analyzes how revenue changes over time.

The main components are:

```text
Time
+
Sales Measure
```

For this project:

```text
Time
→ DIM_DATE.DATE

Measure
→ FACT_SALES.TOTAL_AMOUNT
```

The dataset contains dates for July 2026, so daily sales trend analysis is appropriate.

---

## 11. Regional Sales Analysis

Answers:

> Which regions generate the most revenue?

Uses:

```text
DIM_BRANCH.REGION
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY REGION
```

---

## 12. Quarterly Revenue

Answers:

> How much revenue was generated in each quarter?

Uses:

```text
DIM_DATE.QUARTER
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY YEAR, QUARTER
```

---

## 13. Customer Purchase Analysis

Provides:

- Purchase count
- Total units purchased
- Total spending

Uses:

```text
COUNT(SALE_ID)
SUM(QUANTITY)
SUM(TOTAL_AMOUNT)
```

---

## 14. Product Performance

Provides:

- Units sold
- Revenue
- Product category

This allows products to be compared using both volume and revenue.

---

## 15. Revenue by Membership

Analyzes revenue across customer membership categories.

Uses:

```text
DIM_CUSTOMER.MEMBERSHIP
```

and:

```sql
SUM(TOTAL_AMOUNT)
GROUP BY MEMBERSHIP
```

---

## 16. Revenue Contribution by Category

Calculates:

```text
Category Revenue
----------------- × 100
Total Revenue
```

This identifies each category's contribution to overall revenue.

---

## 17. Weekend vs Weekday Revenue

Uses:

```text
DIM_DATE.IS_WEEKEND
```

to compare revenue generated during:

```text
Weekdays
vs
Weekends
```

---

# 🧠 Analytical Query Pattern

Most analytical queries follow the same pattern:

```text
FACT_SALES
    ↓
JOIN DIMENSION
    ↓
SELECT DIMENSION ATTRIBUTE
    ↓
AGGREGATE MEASURE
    ↓
GROUP BY ATTRIBUTE
    ↓
ORDER / FILTER
```

Examples:

```text
Revenue by Customer
FACT → CUSTOMER → GROUP BY CUSTOMER → SUM(AMOUNT)

Revenue by Product
FACT → PRODUCT → GROUP BY PRODUCT → SUM(AMOUNT)

Revenue by Branch
FACT → BRANCH → GROUP BY BRANCH → SUM(AMOUNT)

Revenue by Month
FACT → DATE → GROUP BY MONTH → SUM(AMOUNT)

Revenue by Category
FACT → PRODUCT → GROUP BY CATEGORY → SUM(AMOUNT)

Revenue by Region
FACT → BRANCH → GROUP BY REGION → SUM(AMOUNT)
```

---

# 🔄 Complete Project Workflow

```text
Business Requirement
        ↓
Business Process
        ↓
Business Event
        ↓
Grain
        ↓
Fact Identification
        ↓
Dimension Identification
        ↓
Measure Identification
        ↓
Star Schema Design
        ↓
Snowflake Database
        ↓
Schema
        ↓
File Format
        ↓
Stage
        ↓
Dimension Tables
        ↓
Fact Table
        ↓
CSV Upload
        ↓
COPY INTO
        ↓
Data Validation
        ↓
Analytical SQL
        ↓
Business Reports
```

---

# 📊 Expected Project Outputs

### Business Process

```text
Retail Sales Analytics
```

### Fact Table

```text
FACT_SALES
```

### Measures

```text
QUANTITY
TOTAL_AMOUNT
```

Both are additive measures.

### Dimension Tables

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

### Fact Table Structure

```text
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
QUANTITY
TOTAL_AMOUNT
```

### Customer Dimension

```text
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
MEMBERSHIP
```

### Product Dimension

```text
PRODUCT_ID
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

### Branch Dimension

```text
BRANCH_ID
BRANCH_NAME
CITY
STATE
```

The implemented table additionally contains:

```text
REGION
MANAGER_NAME
```

### Date Dimension

```text
DATE_ID
DATE
MONTH
QUARTER
YEAR
```

The implemented table additionally contains:

```text
DAY
DAY_NAME
WEEK_NO
IS_WEEKEND
```

### Grain

```text
One row in FACT_SALES represents one product purchased
by one customer from one branch on one specific date.
```

### Relationships

```text
DIM_CUSTOMER  1 ---- * FACT_SALES
DIM_PRODUCT   1 ---- * FACT_SALES
DIM_BRANCH    1 ---- * FACT_SALES
DIM_DATE      1 ---- * FACT_SALES
```

---

# 🛠️ Technologies Used

- Snowflake
- SQL
- Snowflake Virtual Warehouse
- Snowflake Database
- Snowflake Schema
- Snowflake Internal Stage
- Snowflake CSV File Format
- Star Schema
- Dimensional Modeling
- `COPY INTO`

---

# 📚 Data Warehousing Concepts Demonstrated

This project demonstrates:

- Business Process
- Business Event
- Grain
- Fact Tables
- Dimension Tables
- Measures
- Additive Measures
- Primary Keys
- Foreign Keys
- One-to-Many Relationships
- Star Schema
- Dimensional Modeling
- Snowflake Architecture
- Virtual Warehouses
- Stages
- File Formats
- Data Ingestion
- `COPY INTO`
- Data Validation
- Referential Integrity
- Aggregation
- `SUM()`
- `COUNT()`
- `GROUP BY`
- `ORDER BY`
- Top-N Analysis
- Time-Series Analysis
- Customer Analysis
- Product Analysis
- Branch Analysis
- Geographic Analysis
- Category Analysis

---

# 📁 Recommended Repository Structure

```text
Project-4/
│
├── README.md
├── explanation.md
├── Project-4.sql
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── branches.csv
│   ├── calendar.csv
│   └── sales.csv
│
└── screenshots/
    ├── database.png
    ├── schema.png
    ├── tables.png
    ├── stage.png
    ├── loading.png
    └── analytics.png
```

---

# 🎓 What This Project Demonstrates

This project demonstrates the complete lifecycle of a small analytical data warehouse.

The most important modeling decision is the grain:

> One row in FACT_SALES represents one product purchased by one customer from one branch on one specific date.

From this grain, the following were derived:

```text
Fact Table
Dimensions
Measures
Primary Keys
Foreign Keys
Relationships
Star Schema
```

The project then implements the model in Snowflake:

```text
CSV
 ↓
Stage
 ↓
COPY INTO
 ↓
Dimension / Fact Tables
 ↓
Validation
 ↓
Analytics
```

The final warehouse provides a clean foundation for retail sales analytics.

---

# 🏁 Final Result

The completed project provides a Snowflake-based Retail Sales Data Warehouse capable of answering business questions across:

```text
Customer
Product
Branch
State
Region
Category
Membership
Date
Month
Quarter
Year
Weekend / Weekday
```

using the core measures:

```text
Quantity
Total Amount
```

The project demonstrates an end-to-end understanding of:

```text
Business Requirement
        ↓
Dimensional Modeling
        ↓
Snowflake Implementation
        ↓
Data Ingestion
        ↓
Data Validation
        ↓
Business Analytics
```

This forms the complete Project 4 Retail Sales Analytics Data Warehouse.
