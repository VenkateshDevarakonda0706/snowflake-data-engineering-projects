# Project 5 — Retail Sales Data Warehouse Using Star Schema

## 📌 Project Overview

This project focuses on designing, understanding, and validating a **Retail Sales Data Warehouse using a Star Schema** in Snowflake.

The project builds on the validated retail sales warehouse implementation from Project 4.

The main focus of Project 5 is to understand:

- Dimensional Modeling
- Star Schema
- Fact Tables
- Dimension Tables
- Grain
- Measures
- Primary Keys
- Foreign Keys
- One-to-Many Relationships
- OLAP
- Business Intelligence
- Star Schema Characteristics
- Star Schema Advantages
- Analytical Reporting
- Data Warehouse Validation

The project models retail sales data so that business users can analyze sales from different perspectives such as:

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

---

# 🎯 Project Objectives

The main objectives of this project are:

1. Understand dimensional modeling.
2. Understand the Star Schema architecture.
3. Identify the fact table and dimension tables.
4. Define the correct grain of the fact table.
5. Identify measures and foreign keys.
6. Understand relationships between facts and dimensions.
7. Validate the Star Schema implementation.
8. Understand OLTP vs OLAP.
9. Understand why Star Schema is suitable for OLAP.
10. Understand the advantages of Star Schema.
11. Demonstrate how the Star Schema supports BI and dashboards.
12. Perform analytical queries using the Star Schema.

---

# 🏢 Business Scenario

The business is a retail organization that sells products through multiple branches.

Each sales transaction records:

- Customer
- Product
- Branch
- Date
- Quantity
- Total Amount

The business wants to analyze sales performance across different dimensions.

Examples of business questions include:

- Which customers spend the most?
- Which products generate the highest revenue?
- Which branches perform best?
- Which states generate the most revenue?
- Which categories perform best?
- What is the monthly revenue?
- What is the quarterly revenue?
- Which region performs best?
- What is the customer purchase trend?
- What are the top 10 customers?
- What are the top 10 products?

---

# 🔄 Business Process

The business process is:

**Retail Sales Analytics**

The warehouse is designed around the retail sales process.

---

# 🛒 Business Event

The business event is:

> A customer purchases a product from a retail branch on a specific date.

For example:

```text
Customer
   ↓
purchases
   ↓
Product
   ↓
from Branch
   ↓
on Date
   ↓
Quantity + Revenue
```

Each business event becomes a record in the fact table at the defined grain.

---

# 📏 Grain

The grain of the fact table is:

> **One row in FACT_SALES represents one product purchased by one customer from one retail branch on one specific date.**

This is the most important fact-table design decision.

For example:

```text
CUSTOMER_ID  = 1
PRODUCT_ID   = 101
BRANCH_ID    = 1
DATE_ID      = 1
QUANTITY     = 1
TOTAL_AMOUNT = 65000
```

represents one sales event at the defined grain.

---

# ⭐ Star Schema

The project uses a Star Schema.

The architecture is:

```text
                    DIM_CUSTOMER
                         |
                         |
DIM_PRODUCT ------ FACT_SALES ------ DIM_DATE
                         |
                         |
                    DIM_BRANCH
```

The central table is:

```text
FACT_SALES
```

The surrounding dimension tables are:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

The structure resembles a star, which is why it is called a **Star Schema**.

---

# 🧩 Dimensional Model

The dimensional model separates:

```text
FACTS
```

from:

```text
DIMENSIONS
```

## Fact

The fact table stores measurable business events.

```text
FACT_SALES
```

## Dimensions

The dimension tables provide descriptive context.

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

A simple way to remember them is:

```text
Customer → WHO?
Product  → WHAT?
Branch   → WHERE?
Date     → WHEN?

Quantity      → HOW MANY?
Total Amount  → HOW MUCH?
```

---

# 📊 Schema Structure

## FACT_SALES

```text
FACT_SALES
-------------------------
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
QUANTITY
TOTAL_AMOUNT
```

### Primary Key

```text
SALE_ID
```

### Foreign Keys

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
```

### Measures

```text
QUANTITY
TOTAL_AMOUNT
```

---

# 👤 DIM_CUSTOMER

Stores descriptive information about customers.

```text
DIM_CUSTOMER
-------------------------
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
MEMBERSHIP
```

### Primary Key

```text
CUSTOMER_ID
```

### Attributes

```text
CUSTOMER_NAME
CITY
STATE
MEMBERSHIP
```

---

# 📦 DIM_PRODUCT

Stores descriptive information about products.

```text
DIM_PRODUCT
-------------------------
PRODUCT_ID
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

### Primary Key

```text
PRODUCT_ID
```

### Attributes

```text
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

---

# 🏪 DIM_BRANCH

Stores descriptive information about retail branches.

```text
DIM_BRANCH
-------------------------
BRANCH_ID
BRANCH_NAME
CITY
STATE
REGION
MANAGER_NAME
```

### Primary Key

```text
BRANCH_ID
```

### Attributes

```text
BRANCH_NAME
CITY
STATE
REGION
MANAGER_NAME
```

---

# 📅 DIM_DATE

Stores calendar-related information.

```text
DIM_DATE
-------------------------
DATE_ID
DATE
DAY
DAY_NAME
WEEK_NO
MONTH
QUARTER
YEAR
IS_WEEKEND
```

### Primary Key

```text
DATE_ID
```

### Attributes

```text
DATE
DAY
DAY_NAME
WEEK_NO
MONTH
QUARTER
YEAR
IS_WEEKEND
```

---

# 🔗 Relationships

The Star Schema uses the following relationships:

```text
DIM_CUSTOMER  1 : M  FACT_SALES

DIM_PRODUCT   1 : M  FACT_SALES

DIM_BRANCH    1 : M  FACT_SALES

DIM_DATE      1 : M  FACT_SALES
```

This means:

- One customer can have many sales.
- One product can appear in many sales.
- One branch can have many sales.
- One date can contain many sales.

---

# 📐 Complete Star Schema

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

# 📈 Measures

The project contains two main measures.

## QUANTITY

Represents the number of units sold.

Example:

```text
QUANTITY = 3
```

means three units were sold.

## TOTAL_AMOUNT

Represents the revenue generated by the sales event.

Example:

```text
TOTAL_AMOUNT = 65000
```

means the transaction generated ₹65,000.

Both measures are additive.

Therefore:

```sql
SUM(QUANTITY)
```

can calculate total units sold.

And:

```sql
SUM(TOTAL_AMOUNT)
```

can calculate total revenue.

---

# 🧠 Important Modeling Principle

A numeric column is not automatically a measure.

For example:

```text
PRICE
```

is numeric, but it describes a product.

Therefore:

```text
PRICE → DIM_PRODUCT
```

while:

```text
QUANTITY
TOTAL_AMOUNT
```

are sales-event measures and belong in:

```text
FACT_SALES
```

The key question is:

> Does the column describe an entity, or does it measure the business event?

---

# ⭐ Star Schema Characteristics

The main characteristics of this Star Schema are:

| Characteristic | Project Implementation |
|---|---|
| Central Table | FACT_SALES |
| Dimension Tables | 4 |
| Fact Measures | QUANTITY, TOTAL_AMOUNT |
| Dimension Design | Denormalized |
| Relationships | 1:M |
| Query Type | Analytical |
| Workload | OLAP |
| Usage | BI / Reporting / Dashboards |

---

# 🏛️ Central Fact Table

`FACT_SALES` is the center of the Star Schema.

It contains:

- Primary key
- Foreign keys
- Measures
- Sales events

The foreign keys connect each sales event to the appropriate dimensions.

---

# 🧱 Denormalized Dimensions

The dimensions keep related descriptive information together.

For example:

```text
DIM_PRODUCT

PRODUCT_ID
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

Product-related information is stored together rather than unnecessarily splitting it into multiple tables.

This makes analytical queries easier to understand.

---

# 🔗 Simple Joins

Dimensions connect directly to the fact table.

For example, category revenue can be calculated using:

```sql
SELECT
    P.CATEGORY,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY;
```

The query requires only the fact table and the relevant dimension.

---

# 🧮 Analytical Query Pattern

Most Star Schema analytical queries follow this pattern:

```text
FACT
  ↓
JOIN DIMENSION
  ↓
SELECT DIMENSION ATTRIBUTE
  ↓
AGGREGATE FACT MEASURE
  ↓
GROUP BY
  ↓
ORDER / FILTER
```

For example:

```text
FACT_SALES
    ↓
DIM_PRODUCT
    ↓
CATEGORY
    ↓
SUM(TOTAL_AMOUNT)
```

---

# 🏢 OLTP vs OLAP

## OLTP

OLTP means:

**Online Transaction Processing**

It is used for day-to-day business operations.

Examples:

- Creating an order
- Processing a payment
- Updating inventory
- Generating a receipt

Typical characteristics:

- Frequent INSERT
- Frequent UPDATE
- Frequent DELETE
- Small transaction-oriented queries
- Operational data
- Usually normalized

---

# 📊 OLAP

OLAP means:

**Online Analytical Processing**

It is used for analysis and decision-making.

Examples:

- Revenue by state
- Revenue by month
- Top customers
- Top products
- Category performance
- Regional sales

Typical operations include:

```text
SUM
COUNT
AVG
GROUP BY
FILTER
ORDER BY
```

---

# ⚖️ OLTP vs OLAP Comparison

| OLTP | OLAP |
|---|---|
| Transaction Processing | Analytical Processing |
| Runs daily operations | Supports decision-making |
| Frequent INSERT/UPDATE/DELETE | Mostly analytical SELECT |
| Small transaction queries | Large analytical queries |
| Usually normalized | Often dimensional |
| Current operational data | Historical analytical data |
| Transaction focused | Analysis focused |
| Billing system | Data Warehouse |
| Operational workload | BI / Reporting workload |

---

# 🎯 Why This Project Is OLAP

This project is designed for analytical processing.

Examples:

```sql
SUM(TOTAL_AMOUNT)
```

```sql
GROUP BY STATE
```

```sql
GROUP BY CATEGORY
```

```sql
GROUP BY YEAR, MONTH
```

These are analytical operations.

The model uses:

```text
FACT_SALES
+
DIMENSIONS
```

which is a typical data warehouse / OLAP architecture.

---

# 🔄 Project 4 vs Project 5

Project 4 and Project 5 are both OLAP-oriented.

They use the same underlying retail sales warehouse model.

## Project 4 Focus

```text
Data Warehouse Implementation
        ↓
Snowflake Setup
        ↓
Data Loading
        ↓
Data Validation
        ↓
Analytical SQL
        ↓
Business Reports
```

## Project 5 Focus

```text
Dimensional Modeling
        ↓
Star Schema
        ↓
Fact + Dimensions
        ↓
Relationships
        ↓
OLAP
        ↓
BI
        ↓
Star Schema Characteristics
        ↓
Advantages
```

Therefore:

```text
Project 4 → OLAP
Project 5 → OLAP
```

Project 5 does not represent a completely different database workload.

Instead, Project 5 formally focuses on the Star Schema architecture used for analytical processing.

---

# 🚀 Why Star Schema Is Suitable for OLAP

OLAP queries commonly require:

```text
SUM
COUNT
AVG
GROUP BY
FILTER
```

The Star Schema provides:

```text
FACT
  ↓
Measures
```

and:

```text
DIMENSIONS
  ↓
Grouping / Filtering Attributes
```

For example:

```text
Revenue by State
```

uses:

```text
DIM_BRANCH.STATE
+
FACT_SALES.TOTAL_AMOUNT
```

---

# 📊 Why Star Schema Is Suitable for BI

Business Intelligence tools need to analyze measures across different dimensions.

The Star Schema naturally supports:

```text
Dimensions
    ↓
Filters / Groups / Slicers

Facts
    ↓
Measures / KPIs
```

Example:

```text
State = Telangana
Month = July
Category = Electronics
        ↓
SUM(TOTAL_AMOUNT)
```

---

# 📈 Why Star Schema Is Suitable for Dashboards

The schema supports dashboard metrics such as:

- Total Revenue
- Units Sold
- Top Customers
- Top Products
- Top Branches
- Monthly Revenue
- Category Revenue
- Regional Revenue
- Sales Trends

These can be generated by combining the fact table with the appropriate dimensions.

---

# ✅ Advantages of Star Schema

## 1. Simple to Understand

The structure is easy to visualize:

```text
Customer
Product
Branch
Date
   ↓
Sales
```

## 2. Fewer Joins

Dimensions connect directly to the fact table.

## 3. Simple Analytical Queries

Queries generally follow:

```text
JOIN
+
GROUP BY
+
AGGREGATE
```

## 4. Suitable for OLAP

The schema is designed for analytical aggregations.

## 5. Suitable for BI

Dimensions provide filters and grouping attributes while facts provide measures.

## 6. Suitable for Dashboards

The model naturally supports KPI and dashboard reporting.

## 7. Simplifies Business Analysis

Business users can work with familiar concepts such as:

```text
Customer
Product
Branch
Date
Revenue
Quantity
```

---

# 🔍 Validation Performed

The Star Schema implementation was validated using:

- Row Count Validation
- Primary Key Validation
- Foreign Key Validation
- NULL Validation
- Grain Validation
- Measure Validation
- Revenue Calculation Validation
- Complete Star Schema Join Validation

---

# 📊 Expected Row Counts

The source dataset contains:

| Table | Expected Rows |
|---|---:|
| DIM_CUSTOMER | 20 |
| DIM_PRODUCT | 20 |
| DIM_BRANCH | 10 |
| DIM_DATE | 31 |
| FACT_SALES | 100 |

---

# 🔑 Foreign Key Validation

The following relationships were validated:

```text
FACT_SALES.CUSTOMER_ID
        ↓
DIM_CUSTOMER.CUSTOMER_ID
```

```text
FACT_SALES.PRODUCT_ID
        ↓
DIM_PRODUCT.PRODUCT_ID
```

```text
FACT_SALES.BRANCH_ID
        ↓
DIM_BRANCH.BRANCH_ID
```

```text
FACT_SALES.DATE_ID
        ↓
DIM_DATE.DATE_ID
```

Expected invalid-key count:

```text
0
```

---

# 📏 Grain Validation

`SALE_ID` was checked for duplicate records.

Expected result:

```text
No duplicate SALE_ID values
```

This helps confirm that the fact table follows its defined grain.

---

# 💰 Measure Validation

The following measures were validated:

```text
QUANTITY
TOTAL_AMOUNT
```

The validation includes:

```text
MIN
MAX
SUM
```

This verifies that the measures contain valid numerical values suitable for aggregation.

---

# 🧮 Revenue Validation

The source data allows validation of:

```text
TOTAL_AMOUNT
=
PRICE × QUANTITY
```

The fact table was joined to `DIM_PRODUCT` to identify any mismatches.

Expected result:

```text
No mismatched records
```

---

# 📋 Analytical Reports Supported

The Star Schema supports:

- Customer-wise Sales
- Product-wise Revenue
- Branch-wise Revenue
- State-wise Revenue
- Monthly Revenue
- Quarterly Revenue
- Top 10 Customers
- Top 10 Products
- Top 10 Branches
- Category-wise Revenue
- Customer Purchase Trend
- Product Performance
- Branch Performance
- Regional Sales Analysis
- Sales Trend Analysis
- Membership Analysis
- Weekend vs Weekday Revenue

---

# 🧑 Customer Analysis

Uses:

```text
DIM_CUSTOMER
+
FACT_SALES
```

Can answer:

- Who spends the most?
- How many units did each customer purchase?
- What is each customer's total spending?
- Which membership category generates the most revenue?

---

# 📦 Product Analysis

Uses:

```text
DIM_PRODUCT
+
FACT_SALES
```

Can answer:

- Which products generate the most revenue?
- Which products sell the most units?
- Which category performs best?
- Which brands perform best?

---

# 🏪 Branch Analysis

Uses:

```text
DIM_BRANCH
+
FACT_SALES
```

Can answer:

- Which branch performs best?
- Which state generates the most revenue?
- Which region performs best?
- How many units are sold by each branch?

---

# 📅 Time Analysis

Uses:

```text
DIM_DATE
+
FACT_SALES
```

Can answer:

- What is monthly revenue?
- What is quarterly revenue?
- What is the daily sales trend?
- How does weekend revenue compare with weekday revenue?

---

# 🌎 State and Regional Analysis

For sales location analysis, the branch dimension is used:

```text
DIM_BRANCH.STATE
DIM_BRANCH.REGION
```

This is important because:

```text
DIM_CUSTOMER.STATE
```

represents the customer's location, while:

```text
DIM_BRANCH.STATE
```

represents the location where the sale occurred.

The correct dimension depends on the business question.

---

# 🆚 Star Schema vs Snowflake Schema

## Star Schema

```text
              DIMENSION
                   |
DIMENSION ---- FACT ---- DIMENSION
                   |
               DIMENSION
```

Dimensions directly connect to the fact.

## Snowflake Schema

Dimensions may be further normalized:

```text
FACT
 ↓
DIM_PRODUCT
 ↓
DIM_CATEGORY
```

The current project uses a Star Schema because the dimensions directly connect to `FACT_SALES`.

---

# 🗂️ Project Structure

```text
Project-5/
│
├── project-5.sql
├── explanation.md
├── README.md
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── branches.csv
│   ├── calendar.csv
│   └── sales.csv
│
└── screenshots/
    └── Snowflake query/output screenshots
```

---

# 🛠️ Technologies Used

- Snowflake
- SQL
- Data Warehouse
- Dimensional Modeling
- Star Schema
- OLAP
- Business Intelligence

---

# ▶️ How to Run

## Step 1 — Open Snowflake

Open Snowflake Snowsight.

## Step 2 — Select the appropriate warehouse

```sql
USE WAREHOUSE RETAIL_WH;
```

## Step 3 — Select the database

```sql
USE DATABASE RETAIL_DB_P4;
```

## Step 4 — Select the schema

```sql
USE SCHEMA RETAIL;
```

## Step 5 — Run the Project 5 SQL

Execute:

```text
project-5.sql
```

The SQL validates the existing Star Schema and executes the analytical queries.

---

# 📌 Important Note About Project 4

Project 5 builds on the validated implementation from Project 4.

Therefore, the following components do not need to be unnecessarily recreated:

```text
Warehouse
Database
Schema
Stage
File Format
CSV Loading
Fact Table
Dimension Tables
```

Project 5 reuses the validated warehouse and focuses on:

```text
Star Schema
Dimensional Modeling
OLAP
BI
Star Schema Characteristics
Advantages
Validation
Analytical Queries
```

This avoids unnecessary duplication while demonstrating the additional concepts introduced by Project 5.

---

# 🎓 Key Concepts Learned

### Fact

A table that stores measurable business events.

```text
FACT_SALES
```

### Dimension

A table that provides descriptive context.

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

### Grain

Defines what one fact-table row represents.

```text
One product
+
One customer
+
One branch
+
One date
```

### Measure

A numerical value that can be analyzed.

```text
QUANTITY
TOTAL_AMOUNT
```

### Star Schema

A central fact table directly connected to surrounding dimension tables.

### OLAP

Analytical processing used for business analysis and decision-making.

### BI

Business Intelligence that uses data to create reports, KPIs, dashboards, and insights.

---

# 🧠 Core Mental Model

The most important concept to remember is:

```text
Business Requirement
        ↓
Business Process
        ↓
Business Event
        ↓
Grain
        ↓
Fact
        ↓
Measures
        ↓
Dimensions
        ↓
Relationships
        ↓
Star Schema
        ↓
OLAP
        ↓
BI / Dashboards
        ↓
Business Decisions
```

Another simple way to remember the model:

```text
                    WHO?
                 CUSTOMER
                     |
                     |
WHAT? ----------- SALES ----------- WHEN?
PRODUCT                         DATE
                     |
                     |
                   WHERE?
                   BRANCH
```

And the measures are:

```text
HOW MANY?  → QUANTITY
HOW MUCH?  → TOTAL_AMOUNT
```

---

# 🏁 Final Conclusion

Project 5 demonstrates a Retail Sales Data Warehouse using a Star Schema.

The central fact table is:

```text
FACT_SALES
```

and the surrounding dimensions are:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

The fact table stores measurable sales events while the dimensions provide the descriptive context required for analysis.

The project demonstrates:

```text
Dimensional Modeling
        ↓
Star Schema
        ↓
Fact + Dimensions
        ↓
Measures
        ↓
Relationships
        ↓
OLAP
        ↓
BI
        ↓
Dashboards
        ↓
Business Analysis
```

The validated Project 4 warehouse serves as the implementation foundation, while Project 5 focuses on formally understanding and documenting the Star Schema architecture, its characteristics, its OLAP purpose, and its advantages.

The final result is a simple, analytical, and BI-friendly data warehouse model suitable for retail sales analysis.
