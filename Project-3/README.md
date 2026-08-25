# Enterprise Incremental Sales Data Warehouse using Snowflake

A hands-on Snowflake data engineering project that demonstrates **data ingestion, incremental loading, data validation, data recovery, automation, business analytics, Views, Materialized Views, and advanced SQL concepts**.

The project simulates an enterprise sales data warehouse where historical sales are loaded initially and new or modified sales records are processed incrementally using `MERGE`. Snowflake features such as **Time Travel, Zero-Copy Cloning, Streams, and Tasks** are also demonstrated.

---

## 📌 Project Overview

The objective of this project is to build a small-scale but complete **incremental sales data warehouse using Snowflake**.

The project follows this workflow:

```text
CSV Files
    ↓
Internal Stage
    ↓
COPY INTO
    ↓
Snowflake Tables
    ↓
Incremental Sales Processing
    ↓
MERGE
    ↓
Data Validation
    ↓
Time Travel / Zero-Copy Clone
    ↓
Task Automation
    ↓
Business Analytics
    ↓
Views / Materialized Views
```

---

## 🏗️ Snowflake Architecture

```text
                    SNOWFLAKE
                        |
                ENTERPRISE_WH
                        |
                ENTERPRISE_DB
                        |
                 SALES_SCHEMA
                        |
        +---------------+---------------+
        |       |       |       |       |
        ↓       ↓       ↓       ↓       ↓
   CUSTOMERS PRODUCTS BRANCHES SALES NEW_SALES
                              ↑       |
                              |       |
                              +-- MERGE
                                  |
                                  ↓
                              SALES
                                  |
             +--------------------+-------------------+
             |                    |                   |
             ↓                    ↓                   ↓
        Analytics            Time Travel        Zero-Copy Clone
             |                                      |
             ↓                                      ↓
     Reports / Views                            SALES_TEST
```

---

# 🛠️ Technologies Used

* **Snowflake**
* **SQL**
* **CSV**
* Snowflake Internal Stage
* Snowflake Virtual Warehouse
* Snowflake Streams
* Snowflake Tasks
* Snowflake Time Travel
* Snowflake Zero-Copy Cloning
* Views
* Materialized Views
* Window Functions

---

# ⚙️ Snowflake Environment

| Object         | Name                    |
| -------------- | ----------------------- |
| Warehouse      | `ENTERPRISE_WH`         |
| Database       | `ENTERPRISE_DB`         |
| Schema         | `SALES_SCHEMA`          |
| File Format    | `ENTERPRISE_CSV_FORMAT` |
| Internal Stage | `ENTERPRISE_STAGE`      |

---

# 📂 Project Structure

A recommended repository structure is:

```text
Project-3/
│
├── README.md
├── explanation.md
├── project-3.sql
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── branches.csv
│   ├── sales_history.csv
│   └── new_sales.csv
│
└── screenshots/
    └── Project-3 Screenshots.docx
```

> File names can be adjusted according to the actual files present in the repository.

---

# 📊 Data Model

The project contains five main tables.

## 1. CUSTOMERS

Stores customer information.

```text
CUSTOMER_ID
CUSTOMER_NAME
CITY
MEMBERSHIP
```

---

## 2. PRODUCTS

Stores product information.

```text
PRODUCT_ID
PRODUCT_NAME
CATEGORY
PRICE
```

---

## 3. BRANCHES

Stores branch information.

```text
BRANCH_ID
BRANCH_NAME
STATE
```

---

## 4. SALES

The main sales transaction table.

```text
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
QUANTITY
SALE_DATE
TOTAL_AMOUNT
```

---

## 5. NEW_SALES

Contains incoming sales records that are processed incrementally.

```text
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
QUANTITY
SALE_DATE
TOTAL_AMOUNT
```

---

# 🚀 Project Implementation

## Phase 1 — Snowflake Environment

The project begins by creating the Snowflake environment.

### Warehouse

```sql
CREATE OR REPLACE WAREHOUSE ENTERPRISE_WH
WITH
WAREHOUSE_SIZE = 'X-SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;
```

The warehouse uses:

* `X-SMALL` compute size
* `AUTO_SUSPEND = 60`
* `AUTO_RESUME = TRUE`

This is sufficient for the small dataset used in the project while demonstrating Snowflake warehouse management.

---

# Phase 2 — Database and Schema

The project creates:

```text
ENTERPRISE_DB
└── SALES_SCHEMA
```

SQL:

```sql
CREATE OR REPLACE DATABASE ENTERPRISE_DB;

CREATE OR REPLACE SCHEMA SALES_SCHEMA;
```

---

# Phase 3 — File Format and Internal Stage

A CSV file format is created:

```sql
CREATE OR REPLACE FILE FORMAT ENTERPRISE_CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('NULL', 'null');
```

An internal stage is then created:

```sql
CREATE OR REPLACE STAGE ENTERPRISE_STAGE
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

Files can be checked using:

```sql
LIST @ENTERPRISE_STAGE;
```

---

# Phase 4 — Initial Data Loading

The project loads CSV data into Snowflake using `COPY INTO`.

The following datasets are loaded:

```text
customers.csv
products.csv
branches.csv
sales_history.csv
new_sales.csv
```

Example:

```sql
COPY INTO CUSTOMERS
FROM @ENTERPRISE_STAGE/customers.csv
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

The loaded data is verified using `SELECT` queries.

---

# 📥 Historical Sales Loading

Historical sales are loaded into the main `SALES` table:

```sql
COPY INTO SALES
FROM @ENTERPRISE_STAGE/sales_history.csv
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

This represents the initial historical data warehouse load.

---

# 📥 New Sales Loading

Incoming sales are initially loaded into:

```text
NEW_SALES
```

This table acts as the source for incremental processing.

The architecture is:

```text
Historical Sales
      ↓
    SALES

New Sales
      ↓
  NEW_SALES
```

---

# 🔄 Phase 5 — Incremental Loading

The project uses `MERGE` to process new and changed records.

```text
NEW_SALES
    ↓
   MERGE
    ↓
  SALES
```

The matching condition is:

```sql
TARGET.SALE_ID = SOURCE.SALE_ID
```

---

## UPDATE Scenario

If the `SALE_ID` already exists in `SALES`, the existing record is updated.

```text
SALE_ID exists
      ↓
    UPDATE
```

---

## INSERT Scenario

If the `SALE_ID` does not exist:

```text
SALE_ID does not exist
      ↓
     INSERT
```

Therefore, the `MERGE` implements an **upsert** pattern.

```text
Existing Record → UPDATE
New Record      → INSERT
```

---

# 🌊 Snowflake Stream

The project creates a Stream:

```sql
CREATE OR REPLACE STREAM SALES_STREAM
ON TABLE SALES;
```

A Snowflake Stream is used for tracking changes made to a table.

It can track changes such as:

* INSERT
* UPDATE
* DELETE

### Implementation Note

The project creates `SALES_STREAM` to demonstrate Snowflake change tracking.

However, the implemented `MERGE` uses `NEW_SALES` directly as its source rather than consuming `SALES_STREAM`.

Therefore, the current implementation is:

```text
NEW_SALES
    ↓
  MERGE
    ↓
  SALES
```

rather than:

```text
SALES_STREAM
    ↓
  MERGE
    ↓
  SALES
```

A future enhancement could use the Stream directly in the incremental pipeline.

---

# 🔍 Phase 6 — Data Validation

The project performs several data quality checks.

## Duplicate Sale IDs

```sql
SELECT SALE_ID,
       COUNT(*) AS DUPLICATE_COUNT
FROM SALES
GROUP BY SALE_ID
HAVING COUNT(*) > 1;
```

This identifies duplicate sales records.

---

## Missing Customer IDs

```sql
SELECT S.*
FROM SALES AS S
LEFT JOIN CUSTOMERS AS C
ON S.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;
```

This identifies sales records referencing customers that do not exist.

---

## Invalid Product IDs

```sql
SELECT S.*
FROM SALES AS S
LEFT JOIN PRODUCTS AS P
ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_ID IS NULL;
```

This identifies sales records containing invalid product references.

---

## New Record Count

```sql
SELECT COUNT(*) AS TOTAL_NEW_RECORDS
FROM NEW_SALES;
```

This verifies the number of incoming records.

---

# ⏪ Phase 7 — Time Travel

Snowflake Time Travel is demonstrated by intentionally deleting a sales record and recovering it.

The project deletes:

```sql
DELETE FROM SALES
WHERE SALE_ID = 5;
```

The record is then recovered using the historical version of the table:

```sql
SELECT *
FROM SALES
BEFORE (STATEMENT => '<DELETE_QUERY_ID>');
```

The recovered record is inserted back into the current table.

```text
Current SALES
     ↓
Accidental DELETE
     ↓
Time Travel
     ↓
Historical Record
     ↓
INSERT
     ↓
Recovered SALES
```

### Purpose

Time Travel can be useful for:

* Accidental deletion recovery
* Debugging
* Auditing
* Historical analysis
* Data restoration

---

# 🧪 Phase 8 — Zero-Copy Clone

The project creates a clone of the `SALES` table:

```sql
CREATE OR REPLACE TABLE SALES_TEST
CLONE SALES;
```

This demonstrates Snowflake **Zero-Copy Cloning**.

The clone can be modified independently.

For example:

```text
SALES
  |
  +----> SALES_TEST
```

A new record is inserted into `SALES_TEST`.

The original `SALES` table remains unchanged.

This demonstrates why Zero-Copy Cloning is useful for:

* Development
* Testing
* QA
* Experimentation
* Safe data modifications

---

# ⏰ Phase 9 — Task Automation

The project creates a Snowflake Task:

```text
DAILY_SALES_INCREMENTAL_TASK
```

The Task executes the incremental `MERGE` automatically.

The original schedule is:

```text
USING CRON 0 0 * * * UTC
```

The Task is resumed using:

```sql
ALTER TASK DAILY_SALES_INCREMENTAL_TASK RESUME;
```

---

# ▶️ Manual Task Testing

The Task can also be executed manually:

```sql
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
```

This was used to test the incremental pipeline without waiting for the scheduled execution.

---

# 🔄 Task UPDATE Test

The project modifies an existing record:

```text
SALE_ID = 6
```

The `TOTAL_AMOUNT` is changed to:

```text
27000
```

The Task is executed.

The corresponding record in `SALES` is then verified.

This demonstrates:

```text
NEW_SALES
    ↓
Task
    ↓
MERGE
    ↓
UPDATE SALES
```

---

# ➕ Task INSERT Test

A new record is inserted:

```text
SALE_ID = 11
```

into `NEW_SALES`.

The Task processes it.

Because the record does not already exist in `SALES`, it is inserted.

This demonstrates:

```text
NEW_SALES
    ↓
Task
    ↓
MERGE
    ↓
INSERT into SALES
```

---

# 🔁 Task Automatic Execution Test

For testing purposes, the Task schedule was changed to:

```sql
ALTER TASK DAILY_SALES_INCREMENTAL_TASK
SET SCHEDULE = '5 MINUTE';
```

A new record:

```text
SALE_ID = 12
```

was inserted into `NEW_SALES`.

The Task automatically processed the record.

The source record was then updated, allowing the automatic UPDATE behavior to be tested as well.

---

# 📜 Task History

Task execution history is checked using:

```sql
SELECT NAME,
       STATE,
       SCHEDULED_TIME,
       COMPLETED_TIME,
       ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'DAILY_SALES_INCREMENTAL_TASK',
        RESULT_LIMIT => 10
    )
)
ORDER BY SCHEDULED_TIME DESC;
```

This helps monitor:

* Task execution
* Success/failure state
* Scheduled time
* Completion time
* Error messages

---

# 📈 Phase 10 — Business Analytics

After completing the data pipeline, the project performs business analysis on the `SALES` data.

The project generates:

* Customer Revenue Report
* Branch Revenue Report
* Product Revenue Report
* Monthly Revenue Report
* Highest Revenue Customer
* Highest Revenue Branch
* Top Five Products
* Customer Purchase Frequency
* Running Revenue
* Customer Ranking

---

# 👤 Customer Revenue

Customer revenue is calculated by joining:

```text
SALES
+
CUSTOMERS
```

and calculating:

```sql
SUM(TOTAL_AMOUNT)
```

for each customer.

Output:

```text
CUSTOMER_ID
CUSTOMER_NAME
TOTAL_REVENUE
```

---

# 🏢 Branch Revenue

Branch revenue is calculated by joining:

```text
SALES
+
BRANCHES
```

and aggregating sales by branch.

Output:

```text
BRANCH_ID
BRANCH_NAME
TOTAL_REVENUE
```

---

# 📦 Product Revenue

Product revenue is calculated by joining:

```text
SALES
+
PRODUCTS
```

and aggregating revenue for each product.

Output:

```text
PRODUCT_ID
PRODUCT_NAME
TOTAL_REVENUE
```

---

# 📅 Monthly Revenue

Monthly revenue is calculated using:

```sql
DATE_TRUNC('MONTH', SALE_DATE)
```

and:

```sql
SUM(TOTAL_AMOUNT)
```

This produces:

```text
MONTH
MONTHLY_REVENUE
```

---

# 🏆 Highest Revenue Customer

The highest revenue customer is identified using:

```text
ORDER BY TOTAL_REVENUE DESC
LIMIT 1
```

---

# 🏢 Highest Revenue Branch

The highest revenue branch is identified using:

```text
ORDER BY TOTAL_REVENUE DESC
LIMIT 1
```

---

# 🥇 Top Five Products

The five highest-revenue products are identified using:

```sql
ORDER BY TOTAL_REVENUE DESC
LIMIT 5;
```

---

# 🛍️ Customer Purchase Frequency

Purchase frequency is calculated using:

```sql
COUNT(SALE_ID)
```

for each customer.

This measures the number of transactions made by each customer.

---

# 📊 Running Revenue

The project uses a window function:

```sql
SUM(TOTAL_AMOUNT) OVER (
    ORDER BY SALE_DATE, SALE_ID
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

to calculate cumulative revenue.

Example:

```text
Sale 1 → ₹60,000
Sale 2 → ₹50,000
Sale 3 → ₹30,000

Running Revenue:

₹60,000
₹1,10,000
₹1,40,000
```

---

# 🏅 Customer Ranking

Customers are ranked according to their total revenue using:

```sql
RANK() OVER (
    ORDER BY SUM(TOTAL_AMOUNT) DESC
)
```

Output:

```text
CUSTOMER_ID
CUSTOMER_NAME
TOTAL_REVENUE
CUSTOMER_RANK
```

---

# 👁️ Phase 11 — View

The project creates:

```text
CUSTOMER_REVENUE
```

as a View.

It contains:

```text
CUSTOMER_ID
CUSTOMER_NAME
TOTAL_REVENUE
```

The View allows the customer revenue calculation to be reused without repeatedly writing the complete aggregation query.

Example:

```sql
SELECT *
FROM CUSTOMER_REVENUE
ORDER BY TOTAL_REVENUE DESC;
```

---

# ⚡ Phase 12 — Materialized View

The project creates:

```text
BRANCH_REVENUE
```

as a Materialized View.

```sql
CREATE OR REPLACE MATERIALIZED VIEW BRANCH_REVENUE AS
SELECT
    BRANCH_ID,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES
GROUP BY BRANCH_ID;
```

The Materialized View stores the branch-level revenue aggregation.

The branch name is then obtained by joining it with `BRANCHES`.

```text
SALES
  ↓
BRANCH_REVENUE
  ↓
BRANCHES
  ↓
BRANCH_NAME
```

---

# 📊 Project Outputs

The project successfully demonstrates the following outputs:

| Output                  | Description                         |
| ----------------------- | ----------------------------------- |
| Customers Loaded        | Customer data successfully loaded   |
| Products Loaded         | Product data successfully loaded    |
| Historical Sales Loaded | Historical transactions loaded      |
| New Sales Captured      | Incoming sales captured             |
| Incremental Load        | Sales incrementally processed       |
| Duplicate Report        | Duplicate sale IDs checked          |
| Missing Customer Report | Invalid customer references checked |
| Invalid Product Report  | Invalid product references checked  |
| Time Travel Recovery    | Deleted sales record recovered      |
| Zero-Copy Clone         | Test clone created                  |
| Clone Isolation         | Original table verified unchanged   |
| Task Automation         | Incremental Task created            |
| Task Testing            | INSERT and UPDATE scenarios tested  |
| Task History            | Task execution monitored            |
| Customer Revenue        | Revenue by customer                 |
| Branch Revenue          | Revenue by branch                   |
| Monthly Revenue         | Revenue by month                    |
| Top Five Customers      | Highest-value customers             |
| Top Five Products       | Highest-revenue products            |
| Customer Ranking        | Customers ranked by revenue         |
| Running Revenue         | Cumulative revenue                  |
| Materialized View       | Branch revenue aggregation          |

---

# 📸 Screenshots / Evidence

The project execution was verified through Snowflake worksheets and result screenshots.

The screenshots demonstrate:

* Successful data loading
* Historical sales
* Stream creation
* Incremental processing
* Validation queries
* Time Travel recovery
* Zero-Copy Clone
* Task creation and execution
* Task history
* Business analytics
* Customer revenue
* Branch revenue
* Monthly revenue
* Product revenue
* Customer ranking
* Running revenue
* Materialized View

---

# 🧠 Key Snowflake Concepts Demonstrated

```text
Virtual Warehouse
Database
Schema
File Format
Internal Stage
COPY INTO
MERGE
Streams
Tasks
Time Travel
Zero-Copy Clone
Views
Materialized Views
```

---

# 🧠 Key SQL Concepts Demonstrated

```text
SELECT
WHERE
JOIN
LEFT JOIN
GROUP BY
HAVING
ORDER BY
LIMIT
SUM()
COUNT()
DATE_TRUNC()
MERGE
Window Functions
RANK()
```

---

# 🔑 Important Concepts

## COPY INTO

Used to load CSV files from the Snowflake stage into tables.

```text
Stage → Table
```

---

## MERGE

Used for incremental processing.

```text
Existing Record → UPDATE
New Record      → INSERT
```

---

## Stream

Used to track changes made to a table.

> In this implementation, the Stream is created for demonstration, while `NEW_SALES` is directly used as the source of the MERGE.

---

## Task

Used to automate the incremental data processing.

```text
Schedule
   ↓
Task
   ↓
MERGE
   ↓
SALES
```

---

## Time Travel

Used to access historical versions of table data and recover deleted records.

---

## Zero-Copy Clone

Used to create an independent test environment without immediately creating a complete physical copy of the data.

---

## View

Used to provide reusable query logic.

---

## Materialized View

Used to maintain an aggregated result for eligible queries and improve repeated analytical access.

---

# 🎯 Business Value

This project demonstrates how a business can build a basic incremental data warehouse pipeline.

For example:

```text
Sales System
     ↓
New Sales
     ↓
Incremental Processing
     ↓
Snowflake
     ↓
Data Validation
     ↓
Business Analytics
     ↓
Reports
```

The resulting warehouse can answer questions such as:

* Who are the highest-value customers?
* Which branch generates the most revenue?
* Which products generate the most revenue?
* What is the monthly revenue?
* How frequently do customers purchase?
* What is the cumulative revenue?
* How are customers ranked by revenue?

---

# ⚠️ Current Implementation Notes

Two concepts are listed in the project scope but are not fully used in the final SQL implementation.

### Stream

`SALES_STREAM` is created, but the current incremental `MERGE` uses `NEW_SALES` directly.

### CTE

CTE was included in the planned concepts, but the supplied final SQL does not contain a `WITH ... AS (...)` implementation.

These can be added as future enhancements.

---

# 🚀 Future Enhancements

The project can be extended with:

* Stream-driven incremental processing
* CTE-based transformations
* Raw / Staging / Curated data layers
* Automated data quality checks
* Error logging
* Failed-record handling
* Pipeline monitoring
* Alerts for Task failures
* More complex dimensional modeling
* Fact and Dimension tables
* Snowflake Dynamic Tables
* Snowpipe for continuous ingestion
* Dashboard integration with BI tools

A more advanced architecture could be:

```text
Source Files
     ↓
Snowflake Stage
     ↓
Raw Layer
     ↓
Staging Layer
     ↓
Stream
     ↓
Task
     ↓
MERGE
     ↓
Curated Layer
     ↓
Views / Materialized Views
     ↓
BI Dashboard
```

---

# ▶️ How to Run the Project

## 1. Create Snowflake Warehouse

Run the warehouse creation section from:

```text
project-3.sql
```

---

## 2. Create Database and Schema

Create:

```text
ENTERPRISE_DB
SALES_SCHEMA
```

---

## 3. Create File Format

Create:

```text
ENTERPRISE_CSV_FORMAT
```

---

## 4. Create Internal Stage

Create:

```text
ENTERPRISE_STAGE
```

---

## 5. Upload CSV Files

Upload:

```text
customers.csv
products.csv
branches.csv
sales_history.csv
new_sales.csv
```

to:

```text
@ENTERPRISE_STAGE
```

---

## 6. Create Tables

Create:

```text
CUSTOMERS
PRODUCTS
BRANCHES
SALES
NEW_SALES
```

---

## 7. Load the Data

Run the corresponding:

```sql
COPY INTO
```

commands.

---

## 8. Run Incremental Processing

Execute the:

```sql
MERGE
```

statement.

---

## 9. Run Validation

Execute the duplicate, customer, and product validation queries.

---

## 10. Test Time Travel

Delete a test record and recover it using Snowflake Time Travel.

---

## 11. Test Zero-Copy Clone

Create:

```text
SALES_TEST
```

and modify the clone to verify isolation.

---

## 12. Create and Test Task

Create:

```text
DAILY_SALES_INCREMENTAL_TASK
```

Resume it and test using:

```sql
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
```

---

## 13. Run Business Analytics

Execute the customer, branch, product, monthly revenue, ranking, and running revenue queries.

---

## 14. Create Views

Create:

```text
CUSTOMER_REVENUE
BRANCH_REVENUE
```

where the second object is a Materialized View.

---

# 📚 Documentation

Detailed explanations of every phase, SQL concept, implementation decision, interview question, and project workflow are available in:

```text
explanation.md
```

---

# 🏆 Skills Demonstrated

Through this project, the following skills were practiced:

* Snowflake
* SQL
* Data Warehousing
* Data Ingestion
* Incremental Data Loading
* ETL / ELT Concepts
* Data Validation
* Data Recovery
* Data Pipeline Automation
* SQL Aggregations
* Joins
* Window Functions
* Ranking
* Analytical SQL
* Snowflake Administration
* Data Engineering Concepts

---

# 📝 Project Summary

This project demonstrates an end-to-end incremental sales data warehouse using Snowflake.

The implementation covers:

```text
1. Snowflake Environment
2. Database & Schema
3. File Format
4. Internal Stage
5. Data Loading
6. Incremental Loading
7. MERGE
8. Stream
9. Data Validation
10. Time Travel
11. Zero-Copy Clone
12. Task Automation
13. Business Analytics
14. Views
15. Materialized Views
16. Final Verification
```

The main data engineering workflow is:

```text
             CSV DATA
                 ↓
        INTERNAL STAGE
                 ↓
             COPY INTO
                 ↓
          SNOWFLAKE TABLES
                 ↓
          NEW_SALES SOURCE
                 ↓
               MERGE
                 ↓
             SALES TABLE
                 ↓
       +---------+---------+
       |         |         |
       ↓         ↓         ↓
 Validation  Recovery  Automation
       |         |         |
       +---------+---------+
                 |
                 ↓
          BUSINESS ANALYTICS
                 |
       +---------+---------+
       |         |         |
       ↓         ↓         ↓
      VIEW       MV     SQL REPORTS
```

---

# 👨‍💻 Author

**Venkatesh**

B.Tech — Computer Science & Engineering (AI/ML)

---

# 📌 Project Status

**Completed**

The project has been implemented and tested in Snowflake, with execution results verified through Snowflake worksheet outputs.

---

## ⭐ Key Takeaway

> **This project demonstrates how Snowflake can be used to build an incremental data warehouse that loads data, processes new and changed records, validates data quality, provides recovery and testing capabilities, automates processing, and generates business analytics.**
