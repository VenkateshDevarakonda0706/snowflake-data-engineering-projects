# Project 5 — Retail Sales Data Warehouse Design using Star Schema

## 1. Project Overview

Project 5 focuses on designing and validating a **Retail Sales Data Warehouse using a Star Schema**.

The project is based on the retail sales warehouse implementation already completed in Project 4.

The main purpose of Project 5 is to formally understand and demonstrate:

- Star Schema architecture
- Fact tables
- Dimension tables
- Primary keys
- Foreign keys
- Measures
- Grain
- One-to-many relationships
- Dimensional modeling
- OLAP
- Business Intelligence
- Star Schema characteristics
- Star Schema advantages
- Data validation
- Analytical reporting

The project uses the following core tables:

```text
FACT_SALES

DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

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

The fact table is the center of the model, while the dimensions provide descriptive context for analyzing the sales events.

---

# 2. Relationship Between Project 4 and Project 5

Project 4 and Project 5 use the same underlying retail sales data warehouse model.

Project 4 focused more heavily on:

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

Project 5 focuses more explicitly on:

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

Therefore, the Project 4 implementation is reused as the validated foundation for Project 5 instead of unnecessarily rebuilding the same warehouse.

This avoids duplicating the same physical implementation while allowing Project 5 to focus on the Star Schema architecture.

---

# 3. Business Process

## Retail Sales Analytics

The business process being analyzed is:

> Retail Sales Analytics

The company receives sales transactions from multiple retail branches.

The business wants to analyze those sales from different perspectives such as:

- Customer
- Product
- Branch
- State
- Region
- Category
- Membership
- Date
- Month
- Quarter
- Year

The primary business measures are:

```text
Quantity
Total Amount
```

---

# 4. Business Event

A business event is something that occurs in the business and generates data.

For this project, the business event is:

> A customer purchases a product from a retail branch on a specific date.

For example:

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
Quantity = 1
    ↓
Total Amount = ₹65,000
```

This event becomes one record in the fact table at the defined grain.

---

# 5. Grain

The grain defines exactly what one row in the fact table represents.

## Grain

> One row in FACT_SALES represents one product purchased by one customer from one retail branch on one specific date.

Example:

```text
CUSTOMER_ID  = 1
PRODUCT_ID   = 101
BRANCH_ID    = 1
DATE_ID      = 1
QUANTITY     = 1
TOTAL_AMOUNT = 65000
```

This means:

> Customer 1 purchased one unit of Product 101 from Branch 1 on Date 1, generating ₹65,000 in sales.

---

# 6. Why Grain Is Important

Grain is one of the most important decisions in dimensional modeling.

Without a clearly defined grain, it would not be possible to determine exactly what a fact-table row represents.

A row could potentially represent:

- An entire customer order
- One product within an order
- A customer visit
- A transaction
- A daily sales summary

For this project, the grain is explicitly:

> One product purchased by one customer from one branch on one specific date.

Therefore:

```text
FACT_SALES
    ↓
One row = One sales event at this grain
```

The measures `QUANTITY` and `TOTAL_AMOUNT` must therefore be interpreted at this same level.

---

# 7. Dimensional Modeling

Dimensional modeling is an approach used to organize data for analytical workloads.

The basic idea is to separate:

```text
Facts
```

from:

```text
Dimensions
```

Facts contain measurable business events.

Dimensions contain descriptive information used to analyze those events.

For this project:

```text
FACT
    ↓
FACT_SALES

DIMENSIONS
    ↓
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

---

# 8. Star Schema

Project 5 uses a Star Schema.

A Star Schema contains:

```text
One central fact table
+
Multiple surrounding dimension tables
```

The central table is:

```text
FACT_SALES
```

The dimensions are:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

The structure is:

```text
                    DIM_CUSTOMER
                         |
                         |
DIM_PRODUCT ------ FACT_SALES ------ DIM_DATE
                         |
                         |
                    DIM_BRANCH
```

The structure resembles a star, which is why it is called a Star Schema.

---

# 9. Why This Is a Star Schema

The model qualifies as a Star Schema because:

1. `FACT_SALES` is the central fact table.
2. The dimensions directly connect to the fact table.
3. The dimensions provide descriptive context.
4. The fact table contains measures.
5. The fact table contains foreign keys to the dimensions.
6. The dimensions are designed for analytical filtering and grouping.

The key architecture is:

```text
Dimension
    ↓
Fact
    ↑
Dimension
```

rather than having long chains of dimension-to-dimension relationships.

---

# 10. Fact Table

The central fact table is:

```text
FACT_SALES
```

Its purpose is to store retail sales events at the defined grain.

Structure:

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

---

# 11. FACT_SALES Primary Key

The primary key is:

```text
SALE_ID
```

`SALE_ID` uniquely identifies a fact-table record.

The grain validation checks that the same `SALE_ID` does not occur more than once.

---

# 12. FACT_SALES Foreign Keys

The fact table contains four foreign keys:

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
```

They connect the fact to the dimensions.

The relationships are:

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

---

# 13. Measures

The fact table contains two main measures:

```text
QUANTITY
TOTAL_AMOUNT
```

Both are additive measures.

## Quantity

Represents the number of units sold.

Example:

```text
QUANTITY = 3
```

means three units were sold in that fact record.

## Total Amount

Represents the revenue generated by the sales event.

Example:

```text
TOTAL_AMOUNT = 65000
```

means the sales event generated ₹65,000.

---

# 14. Additive Measures

An additive measure can be summed across dimensions.

For example:

```text
Sale 1 → ₹65,000
Sale 2 → ₹56,000
Sale 3 → ₹135,000
```

Total revenue:

```text
₹65,000
+ ₹56,000
+ ₹135,000
----------------
₹256,000
```

Therefore:

```sql
SUM(TOTAL_AMOUNT)
```

produces meaningful total revenue.

Similarly:

```sql
SUM(QUANTITY)
```

produces total units sold.

---

# 15. Dimension Tables

The Star Schema contains four dimensions:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

Each dimension represents a different analytical perspective.

```text
Customer → WHO?

Product → WHAT?

Branch → WHERE?

Date → WHEN?
```

The fact table provides:

```text
Quantity → HOW MANY?

Total Amount → HOW MUCH?
```

---

# 16. DIM_CUSTOMER

## Purpose

`DIM_CUSTOMER` stores descriptive information about customers.

Structure:

```text
DIM_CUSTOMER
-------------------------
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
MEMBERSHIP
```

Primary Key:

```text
CUSTOMER_ID
```

Attributes:

```text
CUSTOMER_NAME
CITY
STATE
MEMBERSHIP
```

These attributes allow sales to be analyzed by customer characteristics.

---

# 17. DIM_PRODUCT

## Purpose

`DIM_PRODUCT` stores descriptive information about products.

Structure:

```text
DIM_PRODUCT
-------------------------
PRODUCT_ID
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

Primary Key:

```text
PRODUCT_ID
```

Attributes:

```text
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

---

# 18. Why PRICE Is in DIM_PRODUCT

`PRICE` is a numeric column, but that does not automatically make it a fact measure.

The important question is:

> Does the column describe the business event or describe an entity?

`PRICE` describes the product.

Therefore:

```text
PRICE
    ↓
DIM_PRODUCT
```

The sales measures are:

```text
QUANTITY
TOTAL_AMOUNT
```

and they belong in:

```text
FACT_SALES
```

This demonstrates an important dimensional-modeling principle:

> A numeric column is not automatically a measure.

---

# 19. DIM_BRANCH

## Purpose

`DIM_BRANCH` stores information about retail branches.

Structure:

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

Primary Key:

```text
BRANCH_ID
```

Attributes:

```text
BRANCH_NAME
CITY
STATE
REGION
MANAGER_NAME
```

These attributes allow analysis by:

- Branch
- City
- State
- Region
- Manager

---

# 20. DIM_DATE

## Purpose

`DIM_DATE` stores calendar information.

Structure:

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

Primary Key:

```text
DATE_ID
```

The dimension allows analysis by:

```text
Day
Week
Month
Quarter
Year
Weekend / Weekday
```

---

# 21. Why DIM_DATE Is Important

The fact table contains:

```text
DATE_ID
```

The date dimension provides the descriptive calendar attributes.

For example:

```text
FACT_SALES.DATE_ID = 1
        ↓
DIM_DATE
        ↓
DATE       = 2026-07-01
DAY        = 1
DAY_NAME   = Wednesday
WEEK_NO    = 27
MONTH      = July
QUARTER    = Q3
YEAR       = 2026
IS_WEEKEND = No
```

This allows the same sales events to be analyzed using different time perspectives.

---

# 22. Star Schema Relationships

The relationships are:

```text
DIM_CUSTOMER  1 ---- M FACT_SALES

DIM_PRODUCT   1 ---- M FACT_SALES

DIM_BRANCH    1 ---- M FACT_SALES

DIM_DATE      1 ---- M FACT_SALES
```

Why?

### Customer

One customer can make many purchases.

### Product

One product can appear in many sales transactions.

### Branch

One branch can generate many sales transactions.

### Date

One date can contain many sales transactions.

---

# 23. Complete Star Schema

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

This is the final logical Star Schema.

---

# 24. Star Schema Characteristics

The main characteristics of this Star Schema are:

| Characteristic   | Project Implementation      |
| ---------------- | --------------------------- |
| Central Table    | FACT_SALES                  |
| Dimension Tables | 4                           |
| Fact Measures    | QUANTITY, TOTAL_AMOUNT      |
| Dimension Design | Denormalized                |
| Relationships    | 1:M                         |
| Query Style      | Analytical                  |
| Workload         | OLAP                        |
| Main Usage       | BI / Reporting / Dashboards |

---

# 25. Central Fact Table

`FACT_SALES` is the center of the Star Schema.

It contains:

```text
Primary Key
Foreign Keys
Measures
```

The foreign keys connect the sales event to the dimensions.

The measures quantify the event.

---

# 26. Denormalized Dimensions

The dimensions are designed to keep related descriptive information together.

For example:

```text
DIM_PRODUCT

PRODUCT_ID
PRODUCT_NAME
CATEGORY
BRAND
PRICE
```

The product-related attributes are kept together instead of splitting them into multiple normalized tables.

Similarly:

```text
DIM_BRANCH

BRANCH_ID
BRANCH_NAME
CITY
STATE
REGION
MANAGER_NAME
```

contains branch-related descriptive information together.

This makes analytical queries easier to understand.

---

# 27. Fewer and Simpler Joins

Star Schema queries generally require straightforward joins.

For example, category revenue requires:

```text
FACT_SALES
     ↓
DIM_PRODUCT
     ↓
CATEGORY
```

Query pattern:

```sql
SELECT
    P.CATEGORY,
    SUM(F.TOTAL_AMOUNT)
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY;
```

This is simple compared with navigating through many normalized tables.

---

# 28. OLTP vs OLAP

Understanding OLTP and OLAP is an important part of Project 5.

## OLTP

OLTP stands for:

> Online Transaction Processing

It is designed for day-to-day business operations.

Examples:

```text
Customer places order
Payment is processed
Inventory is updated
Receipt is generated
```

Typical characteristics:

- Frequent inserts
- Frequent updates
- Frequent deletes
- Small transaction-oriented queries
- Current operational data
- Transaction consistency
- Usually normalized data models

---

# 29. OLAP

OLAP stands for:

> Online Analytical Processing

It is designed for analysis and decision-making.

Examples:

```text
Which state generated the highest revenue?

Which products performed best?

What was monthly revenue?

Which customers spent the most?
```

Typical characteristics:

- Large analytical queries
- Aggregations
- Historical data analysis
- GROUP BY operations
- SUM / COUNT / AVG
- Business reporting
- BI dashboards
- Data warehouse environments

---

# 30. OLTP vs OLAP Comparison

| OLTP                          | OLAP                             |
| ----------------------------- | -------------------------------- |
| Transaction Processing        | Analytical Processing            |
| Runs day-to-day operations    | Supports decision-making         |
| Frequent INSERT/UPDATE/DELETE | Mostly analytical SELECT queries |
| Small transaction queries     | Large analytical queries         |
| Usually normalized            | Often dimensional                |
| Current operational data      | Historical analytical data       |
| Transaction focused           | Analysis focused                 |
| Example: Billing system       | Example: Data Warehouse          |
| Operational reporting         | BI / Dashboards                  |

---

# 31. Why This Project Is OLAP

Project 5 is an OLAP-oriented project because the warehouse is designed to answer analytical questions.

For example:

```text
SUM(TOTAL_AMOUNT)
GROUP BY STATE
```

or:

```text
SUM(TOTAL_AMOUNT)
GROUP BY MONTH
```

or:

```text
SUM(TOTAL_AMOUNT)
GROUP BY CATEGORY
```

These are analytical operations.

The data is organized around:

```text
FACT_SALES
+
DIMENSIONS
```

which is typical of a data warehouse and OLAP environment.

---

# 32. Project 4 and Project 5 Are Both OLAP

Project 4 is also an OLAP/data warehouse project.

The difference is the focus.

## Project 4

Focused more on:

```text
Warehouse Implementation
Data Ingestion
Validation
Analytical SQL
Business Reports
```

## Project 5

Focuses more explicitly on:

```text
Star Schema
Fact and Dimensions
Relationships
Star Schema Characteristics
OLAP
BI
Advantages
```

Therefore:

```text
Project 4 → OLAP
Project 5 → OLAP
```

Project 5 is not a conversion from OLTP to OLAP.

It is a more explicit study and validation of the Star Schema architecture used for OLAP.

---

# 33. Why Star Schema Is Suitable for OLAP

OLAP queries commonly require:

```text
SUM
COUNT
AVG
GROUP BY
FILTER
ORDER BY
```

The Star Schema provides:

```text
FACT_SALES
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

becomes:

```text
DIM_BRANCH.STATE
+
FACT_SALES.TOTAL_AMOUNT
```

---

# 34. Why Star Schema Is Suitable for BI

Business Intelligence tools need to analyze measures across different dimensions.

The Star Schema provides a natural structure:

```text
DIMENSIONS
    ↓
Filters / Groups / Slicers

FACT
    ↓
Measures / KPIs
```

For example:

```text
State = Telangana
Month = July
Category = Electronics
        ↓
SUM(TOTAL_AMOUNT)
```

This can be used as a dashboard KPI.

---

# 35. Why Star Schema Is Suitable for Dashboards

Dashboards commonly need metrics such as:

```text
Total Revenue
Units Sold
Top Customers
Top Products
Top Branches
Monthly Revenue
Category Revenue
Regional Revenue
```

These metrics can be generated by combining:

```text
FACT_SALES
```

with:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

Therefore the Star Schema provides a simple analytical foundation for dashboards.

---

# 36. Advantages of Star Schema

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

Business analysts can understand the model without needing to understand complex database relationships.

---

## 2. Fewer Joins

Dimensions connect directly to the fact table.

For example:

```text
FACT_SALES
      ↓
DIM_PRODUCT
```

is enough to analyze category revenue.

---

## 3. Easy Analytical Queries

Queries generally follow a simple pattern:

```text
JOIN
+
GROUP BY
+
AGGREGATE
```

Example:

```sql
SUM(F.TOTAL_AMOUNT)
GROUP BY P.CATEGORY
```

---

## 4. Suitable for OLAP

The structure is designed for analytical operations such as:

```text
SUM
COUNT
AVG
GROUP BY
```

---

## 5. Suitable for BI

Dimensions provide:

```text
Filters
Groups
Categories
Hierarchies
```

Facts provide:

```text
Measures
KPIs
```

---

## 6. Suitable for Dashboards

The model can support:

- Revenue dashboards
- Product dashboards
- Branch dashboards
- Customer dashboards
- Sales trend dashboards

---

## 7. Simplifies Business Analysis

Business users can think in business terms:

```text
Customer
Product
Branch
Date
Revenue
Quantity
```

rather than thinking about complex operational database structures.

---

# 37. Data Validation

The existing Star Schema implementation was validated before being reused for Project 5.

Validation included:

```text
Row Count Validation
Primary Key Uniqueness
Foreign Key Validation
NULL Validation
Grain Validation
Measure Validation
Revenue Calculation Validation
Complete Star Schema Join Validation
```

---

# 38. Row Count Validation

The expected source counts are:

```text
DIM_CUSTOMER → 20
DIM_PRODUCT  → 20
DIM_BRANCH   → 10
DIM_DATE     → 31
FACT_SALES   → 100
```

The implemented warehouse was validated against these expected counts.

---

# 39. Primary Key Validation

Each dimension primary key was checked for duplicates:

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
```

The fact primary key was also checked:

```text
SALE_ID
```

No duplicate primary-key records should exist.

---

# 40. Foreign Key Validation

Each fact foreign key was checked against its dimension.

For example:

```text
FACT_SALES.CUSTOMER_ID
        ↓
DIM_CUSTOMER.CUSTOMER_ID
```

The same validation was performed for:

```text
PRODUCT_ID
BRANCH_ID
DATE_ID
```

The expected result is:

```text
INVALID KEYS = 0
```

This verifies that fact records successfully connect to the dimensions.

---

# 41. Grain Validation

The fact table was checked to ensure that:

```text
SALE_ID
```

does not occur more than once.

This helps confirm that each fact row represents one event at the defined grain.

---

# 42. Measure Validation

The fact table measures were validated using:

```sql
MIN(QUANTITY)
MAX(QUANTITY)
SUM(QUANTITY)
MIN(TOTAL_AMOUNT)
MAX(TOTAL_AMOUNT)
SUM(TOTAL_AMOUNT)
```

This provides a basic sanity check of the numerical measures.

---

# 43. Revenue Calculation Validation

The source data provides:

```text
PRICE
QUANTITY
TOTAL_AMOUNT
```

Therefore the following relationship can be validated:

```text
TOTAL_AMOUNT
=
PRICE × QUANTITY
```

The fact table was joined to `DIM_PRODUCT` and records were checked for mismatches.

Expected result:

```text
No mismatched records
```

---

# 44. Complete Star Schema Validation

A final validation joins:

```text
FACT_SALES
    ↓
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

If the resulting row count equals the number of fact rows:

```text
FACT_SALES = 100
```

then all fact rows successfully connect to the four dimensions.

This validates the practical Star Schema relationships.

---

# 45. Analytical Reports Supported

The Star Schema supports:

```text
Customer-wise Sales Report
Product-wise Revenue Report
Branch-wise Revenue Report
State-wise Revenue Report
Monthly Revenue Report
Quarterly Revenue Report
Top 10 Customers
Top 10 Products
Top 10 Performing Branches
Category-wise Revenue
Customer Purchase Trend
Product Performance Dashboard
Branch Performance Dashboard
Regional Sales Analysis
Sales Trend Analysis
```

---

# 46. Customer Analysis

Customer analysis uses:

```text
DIM_CUSTOMER
+
FACT_SALES
```

Example business questions:

```text
Who are the highest-spending customers?

How many units did each customer purchase?

How much revenue did each customer generate?

Which membership category generates the most revenue?
```

---

# 47. Product Analysis

Product analysis uses:

```text
DIM_PRODUCT
+
FACT_SALES
```

It can answer:

```text
Which products generate the most revenue?

Which products sell the most units?

Which categories perform best?

Which brands generate the most revenue?
```

---

# 48. Branch Analysis

Branch analysis uses:

```text
DIM_BRANCH
+
FACT_SALES
```

It can answer:

```text
Which branches perform best?

Which states generate the most revenue?

Which regions generate the most revenue?

How many units does each branch sell?
```

---

# 49. Time Analysis

Time analysis uses:

```text
DIM_DATE
+
FACT_SALES
```

It can answer:

```text
What is monthly revenue?

What is quarterly revenue?

What is daily sales trend?

How does weekend revenue compare with weekday revenue?
```

---

# 50. Category Analysis

Category analysis uses:

```text
DIM_PRODUCT.CATEGORY
+
FACT_SALES.TOTAL_AMOUNT
```

The general pattern is:

```text
CATEGORY
    ↓
GROUP BY
    ↓
SUM(TOTAL_AMOUNT)
```

This identifies the highest-revenue product categories.

---

# 51. Regional Analysis

Regional analysis uses:

```text
DIM_BRANCH.REGION
+
FACT_SALES.TOTAL_AMOUNT
```

This allows management to compare revenue across:

```text
South
West
North
East
```

---

# 52. Main Star Schema Query Pattern

Most reports follow the same structure:

```text
FACT_SALES
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
Revenue by Customer
FACT → CUSTOMER → GROUP BY CUSTOMER → SUM(REVENUE)

Revenue by Product
FACT → PRODUCT → GROUP BY PRODUCT → SUM(REVENUE)

Revenue by Branch
FACT → BRANCH → GROUP BY BRANCH → SUM(REVENUE)

Revenue by Month
FACT → DATE → GROUP BY MONTH → SUM(REVENUE)

Revenue by Category
FACT → PRODUCT → GROUP BY CATEGORY → SUM(REVENUE)

Revenue by Region
FACT → BRANCH → GROUP BY REGION → SUM(REVENUE)
```

This pattern is one of the most important concepts demonstrated by the project.

---

# 53. Fact vs Dimension

A simple rule for remembering the difference is:

> **Facts are what we measure. Dimensions are how we describe or analyze those measurements.**

For this project:

```text
FACT_SALES
    ↓
QUANTITY
TOTAL_AMOUNT
```

Dimensions:

```text
DIM_CUSTOMER → WHO
DIM_PRODUCT  → WHAT
DIM_BRANCH   → WHERE
DIM_DATE     → WHEN
```

---

# 54. Example: Revenue by Product Category

Suppose management asks:

> Which product category generated the highest revenue?

Break the question down:

```text
WHAT ARE WE MEASURING?
        ↓
TOTAL_AMOUNT

BY WHAT?
        ↓
CATEGORY
```

Find the locations:

```text
TOTAL_AMOUNT
    ↓
FACT_SALES

CATEGORY
    ↓
DIM_PRODUCT
```

Therefore:

```text
FACT_SALES
      ↓
JOIN DIM_PRODUCT
      ↓
GROUP BY CATEGORY
      ↓
SUM(TOTAL_AMOUNT)
```

This is dimensional thinking.

---

# 55. Example: Monthly Revenue

Business question:

> How much revenue did we generate each month?

Breakdown:

```text
Measure:
TOTAL_AMOUNT
        ↓
FACT_SALES

Grouping:
MONTH
        ↓
DIM_DATE
```

Query logic:

```text
FACT_SALES
      ↓
DIM_DATE
      ↓
GROUP BY YEAR, MONTH
      ↓
SUM(TOTAL_AMOUNT)
```

---

# 56. Example: State-wise Revenue

Business question:

> Which state generated the highest revenue?

The relevant state is the branch's state because the analysis concerns the location where the sale occurred.

Therefore:

```text
DIM_BRANCH.STATE
```

is used rather than:

```text
DIM_CUSTOMER.STATE
```

The query logic is:

```text
FACT_SALES
      ↓
DIM_BRANCH
      ↓
STATE
      ↓
SUM(TOTAL_AMOUNT)
```

This demonstrates the importance of selecting the dimension attribute with the correct business meaning.

---

# 57. Important Modeling Observation

Both customer and branch dimensions contain geographic information.

```text
DIM_CUSTOMER
    ↓
Customer's city/state

DIM_BRANCH
    ↓
Branch's city/state
```

These represent different business meanings.

Customer state answers:

> Where does the customer live?

Branch state answers:

> Where did the sale occur?

Therefore the correct dimension depends on the business question.

For:

```text
State-wise Branch Sales
```

the branch dimension is used.

---

# 58. Star Schema vs Operational Database

| Operational Database      | Star Schema                     |
| ------------------------- | ------------------------------- |
| OLTP                      | OLAP                            |
| Day-to-day operations     | Analytical reporting            |
| Transaction focused       | Analysis focused                |
| Usually normalized        | Denormalized dimensions         |
| Frequent updates          | Read/analysis optimized         |
| Many operational entities | Fact + dimensions               |
| Current transactions      | Historical analysis             |
| Complex relationships     | Simple analytical relationships |

The Project 5 model belongs to the Star Schema / OLAP side.

---

# 59. Star Schema vs Snowflake Schema

A Star Schema has:

```text
Fact
 ↓
Directly connected dimensions
```

Example:

```text
FACT_SALES
   |
   ├── DIM_CUSTOMER
   ├── DIM_PRODUCT
   ├── DIM_BRANCH
   └── DIM_DATE
```

A Snowflake Schema further normalizes dimensions.

For example:

```text
FACT
 ↓
DIM_PRODUCT
 ↓
DIM_CATEGORY
```

The current Project 5 model is a Star Schema because the dimensions directly connect to the fact table.

---

# 60. Project Architecture

The complete architecture can be summarized as:

```text
                         SNOWFLAKE
                            |
                     RETAIL_WH
                            |
                            ↓
                    RETAIL_DB_P4
                            |
                            ↓
                         RETAIL
                            |
          +-----------------+-----------------+
          |                 |                 |
          ↓                 ↓                 ↓
    DIM_CUSTOMER      DIM_PRODUCT       DIM_BRANCH
          |                 |                 |
          +-----------------+-----------------+
                            |
                            ↓
                       FACT_SALES
                            ↑
                            |
                       DIM_DATE
                            |
                            ↓
                     OLAP / BI Queries
                            |
                            ↓
                   Business Reports
```

---

# 61. Project 5 SQL

The Project 5 SQL file focuses on the validated Star Schema and its analytical capabilities.

The SQL includes:

```text
Table Structure Validation
Row Count Validation
Primary Key Validation
Foreign Key Validation
NULL Validation
Grain Validation
Measure Validation
Revenue Validation
Star Schema Join Validation
Customer Analysis
Product Analysis
Branch Analysis
State Analysis
Monthly Analysis
Quarterly Analysis
Top-N Analysis
Category Analysis
Customer Trend
Product Performance
Branch Performance
Regional Analysis
Sales Trend
Membership Analysis
Weekend / Weekday Analysis
```

The physical warehouse creation and ingestion work were already completed and validated as part of Project 4.

---

# 62. Why the Project 5 SQL Does Not Recreate Everything

Project 4 already contains the physical implementation of:

```text
Warehouse
Database
Schema
Stage
File Format
Dimensions
Fact Table
Data Loading
```

Recreating the exact same objects only for Project 5 would introduce unnecessary duplication.

Therefore Project 5 reuses the validated implementation and focuses on:

```text
Star Schema Validation
+
OLAP Analysis
+
Architecture Demonstration
```

This is appropriate because the purpose of Project 5 is to demonstrate understanding of the Star Schema rather than create an unrelated retail dataset.

---

# 63. Project Validation Summary

The Star Schema implementation satisfies the following requirements:

```text
Business Process                    ✓
Business Event                      ✓
Grain                               ✓
Fact Table                          ✓
Fact Primary Key                    ✓
Fact Foreign Keys                   ✓
Measures                            ✓
Customer Dimension                  ✓
Product Dimension                   ✓
Branch Dimension                    ✓
Date Dimension                      ✓
One-to-Many Relationships            ✓
Star Schema Architecture            ✓
Data Validation                     ✓
OLAP Analytical Queries             ✓
BI Reporting Support                ✓
Dashboard Support                   ✓
```

---

# 64. Final Project Status

Project 5 is built on the validated Project 4 retail sales warehouse.

The implementation already contains:

```text
FACT_SALES
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

The additional focus of Project 5 is the understanding and formal documentation of:

```text
Star Schema
Dimensional Modeling
OLAP
BI
Star Schema Characteristics
Star Schema Advantages
Fact vs Dimension
Analytical Relationships
```

---

# 65. Key Lessons Learned

The most important lessons from this project are:

### Lesson 1 — Start with the business process

The warehouse is designed around:

```text
Retail Sales Analytics
```

### Lesson 2 — Define the grain first

The grain determines what each fact row means.

```text
One product
+
One customer
+
One branch
+
One date
```

### Lesson 3 — Facts contain measurable events

```text
FACT_SALES
```

contains:

```text
QUANTITY
TOTAL_AMOUNT
```

### Lesson 4 — Dimensions provide context

```text
Customer → Who
Product → What
Branch → Where
Date → When
```

### Lesson 5 — Numeric does not automatically mean measure

`PRICE` is numeric but describes a product, so it belongs to:

```text
DIM_PRODUCT
```

### Lesson 6 — Star Schema simplifies analytical queries

The fact table connects directly to the dimensions.

### Lesson 7 — Star Schema is designed for OLAP

It is optimized for:

```text
Aggregation
Analysis
Reporting
BI
Dashboards
```

### Lesson 8 — Validation is essential

A successful data load alone does not prove that the warehouse is correct.

Keys, row counts, measures, grain, and relationships must be validated.

---

# 66. Final Conclusion

Project 5 demonstrates the design and validation of a Retail Sales Data Warehouse using a Star Schema.

The central fact table:

```text
FACT_SALES
```

stores retail sales events and measures.

The surrounding dimensions:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
```

provide the descriptive context required for analytical reporting.

The grain is:

> One product purchased by one customer from one branch on one specific date.

The measures are:

```text
QUANTITY
TOTAL_AMOUNT
```

The relationships are:

```text
DIM_CUSTOMER  1:M FACT_SALES
DIM_PRODUCT   1:M FACT_SALES
DIM_BRANCH    1:M FACT_SALES
DIM_DATE      1:M FACT_SALES
```

The model is designed for:

```text
OLAP
Business Intelligence
Dashboards
Analytical Reporting
```

The Star Schema provides a simple and understandable analytical structure because the fact table is centrally connected to the dimensions.

The project therefore demonstrates the complete reasoning behind a Star Schema:

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
Dimensions
        ↓
Measures
        ↓
Relationships
        ↓
Star Schema
        ↓
OLAP
        ↓
BI / Dashboards
        ↓
Business Analysis
```

The validated Project 4 warehouse therefore serves as the implementation foundation, while Project 5 formalizes the Star Schema architecture, its characteristics, its OLAP purpose, and its advantages.
