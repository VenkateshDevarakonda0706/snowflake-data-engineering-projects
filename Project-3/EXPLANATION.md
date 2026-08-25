# Project-3: Enterprise Incremental Sales Data Warehouse using Snowflake

## 1. Project Overview

### Project Name

**Enterprise Incremental Sales Data Warehouse using Snowflake**

### Objective

The objective of this project is to build a small but complete sales data warehouse in Snowflake that demonstrates:

* Snowflake warehouse management
* Database and schema creation
* CSV file handling
* Internal stages
* File formats
* Bulk data loading using `COPY INTO`
* Historical data loading
* Incremental data processing
* `MERGE`
* Streams
* Data validation
* Time Travel
* Zero-Copy Cloning
* Scheduled Tasks
* Business analytics
* Views
* Materialized Views
* Joins
* Aggregations
* Ranking
* Window functions

The project starts with raw CSV files containing customers, products, branches, and sales information. The data is loaded into Snowflake tables, validated, incrementally updated, analyzed, and finally exposed through views and a materialized view.

---

# 2. High-Level Architecture

The basic architecture of the project is:

```text
CSV Files
   |
   v
Snowflake Internal Stage
   |
   v
COPY INTO
   |
   +------------------+
   |                  |
   v                  v
CUSTOMERS          PRODUCTS
   |                  |
   |                  |
   +--------+---------+
            |
            v
         SALES
            ^
            |
       NEW_SALES
            |
            v
         MERGE
            |
            v
    Incremental Updates
            |
            +--------------------+
            |                    |
            v                    v
       Analytics              Time Travel
            |
            +--------------------+
            |
            v
       Views / MV
```

The Snowflake hierarchy used in the project is:

```text
Warehouse
   |
   v
Database
   |
   v
Schema
   |
   v
Tables / Views / Tasks / Stage / File Format
```

The project uses:

```text
Warehouse : ENTERPRISE_WH
Database  : ENTERPRISE_DB
Schema    : SALES_SCHEMA
```

---

# 3. Snowflake Environment

The first phase creates the Snowflake environment required for the project.

## 3.1 Warehouse

```sql
CREATE OR REPLACE WAREHOUSE ENTERPRISE_WH
WITH
WAREHOUSE_SIZE = 'X-SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;
```

### What is a Warehouse?

A Snowflake **Virtual Warehouse** provides the compute resources required to execute SQL statements.

It is responsible for processing queries and performing operations such as:

* Loading data
* Running SQL queries
* Aggregations
* Joins
* MERGE operations
* Task execution

The warehouse used in this project is:

```text
ENTERPRISE_WH
```

### Why X-SMALL?

The project uses a small amount of data, so an `X-SMALL` warehouse is sufficient.

Using a larger warehouse would provide more compute power but would not be necessary for this project.

### AUTO_SUSPEND

```sql
AUTO_SUSPEND = 60
```

This means Snowflake automatically suspends the warehouse after approximately 60 seconds of inactivity.

This helps reduce unnecessary compute consumption.

### AUTO_RESUME

```sql
AUTO_RESUME = TRUE
```

When a query needs the warehouse, Snowflake automatically starts it again.

Therefore:

```text
No activity
    ↓
Warehouse suspends
    ↓
New query arrives
    ↓
Warehouse automatically resumes
```

---

# 4. Database

The project creates the database:

```sql
CREATE OR REPLACE DATABASE ENTERPRISE_DB;
```

A database is a logical container for schemas.

The project then selects it:

```sql
USE DATABASE ENTERPRISE_DB;
```

The hierarchy is now:

```text
ENTERPRISE_DB
```

---

# 5. Schema

The project creates:

```sql
CREATE OR REPLACE SCHEMA SALES_SCHEMA;
```

Then:

```sql
USE SCHEMA SALES_SCHEMA;
```

A schema is a logical container for database objects such as:

* Tables
* Views
* Stages
* Tasks
* Materialized Views

The project therefore uses:

```text
ENTERPRISE_DB
└── SALES_SCHEMA
```

---

# 6. File Format

The project creates a CSV file format:

```sql
CREATE OR REPLACE FILE FORMAT ENTERPRISE_CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('NULL', 'null');
```

## Why is a File Format required?

Snowflake needs to know how the incoming CSV files are structured.

The file format tells Snowflake:

* File type
* Column delimiter
* Whether a header exists
* How fields are enclosed
* How NULL values are represented

### Important settings

### TYPE

```sql
TYPE = 'CSV'
```

The source files are CSV files.

### FIELD_DELIMITER

```sql
FIELD_DELIMITER = ','
```

Columns are separated using commas.

Example:

```text
1,Anil,Hyderabad,Gold
```

### SKIP_HEADER

```sql
SKIP_HEADER = 1
```

The first row of the CSV contains column names, so Snowflake skips it while loading.

### FIELD_OPTIONALLY_ENCLOSED_BY

```sql
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
```

This allows values to optionally be enclosed in double quotes.

### NULL_IF

```sql
NULL_IF = ('NULL', 'null')
```

The strings `NULL` and `null` are interpreted as SQL `NULL`.

---

# 7. Internal Stage

The project creates:

```sql
CREATE OR REPLACE STAGE ENTERPRISE_STAGE
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

## What is a Stage?

A Snowflake stage is a location used to temporarily hold files before loading them into tables.

This project uses an **internal stage**.

The flow is:

```text
CSV file
   ↓
ENTERPRISE_STAGE
   ↓
COPY INTO
   ↓
Snowflake table
```

The files are checked using:

```sql
LIST @ENTERPRISE_STAGE;
```

This verifies that the required files are available in the stage.

---

# 8. Data Model

The project contains the following main tables:

```text
CUSTOMERS
PRODUCTS
BRANCHES
SALES
NEW_SALES
```

## CUSTOMERS

```text
CUSTOMER_ID
CUSTOMER_NAME
CITY
MEMBERSHIP
```

This table stores customer information.

Example customer attributes include:

* Customer ID
* Customer name
* City
* Membership type

---

# 9. PRODUCTS Table

The product table contains:

```text
PRODUCT_ID
PRODUCT_NAME
CATEGORY
PRICE
```

`PRICE` uses:

```sql
NUMBER(10,2)
```

This allows numeric values with two decimal places.

Example:

```text
60000.00
25000.00
1500.00
```

---

# 10. BRANCHES Table

The branch table contains:

```text
BRANCH_ID
BRANCH_NAME
STATE
```

It represents the different business branches.

The screenshots show branches such as:

* Bangalore Branch
* Hyderabad Branch
* Delhi Branch

---

# 11. SALES Table

The main fact table is:

```text
SALES
```

Its columns are:

```text
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
QUANTITY
SALE_DATE
TOTAL_AMOUNT
```

This table stores sales transactions.

The IDs connect the sales records with dimension/reference tables.

For example:

```text
SALES.CUSTOMER_ID
        |
        v
CUSTOMERS.CUSTOMER_ID
```

and:

```text
SALES.PRODUCT_ID
        |
        v
PRODUCTS.PRODUCT_ID
```

and:

```text
SALES.BRANCH_ID
        |
        v
BRANCHES.BRANCH_ID
```

---

# 12. NEW_SALES Table

The project also creates:

```text
NEW_SALES
```

with the same structure as `SALES`.

Its purpose is to act as the source for new or changed sales records.

Conceptually:

```text
NEW_SALES
    |
    | incremental records
    v
SALES
```

This allows the project to demonstrate incremental loading.

---

# 13. Phase 2 — Initial Data Loading

After creating the environment and tables, CSV files are loaded.

The project uses:

```sql
COPY INTO
```

For example:

```sql
COPY INTO CUSTOMERS
FROM @ENTERPRISE_STAGE/customers.csv
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

## What is COPY INTO?

`COPY INTO` is Snowflake's command for loading data from staged files into tables.

The basic flow is:

```text
CSV
 ↓
Stage
 ↓
COPY INTO
 ↓
Table
```

---

# 14. Loading Customers

The customer table is populated from:

```text
customers.csv
```

After loading:

```sql
SELECT *
FROM CUSTOMERS
ORDER BY CUSTOMER_ID;
```

This verifies that the customers were successfully loaded.

The Project-3 screenshots show the customer records successfully loaded into Snowflake.
The first screenshot section is the evidence for this step.

---

# 15. Loading Products

Products are loaded from:

```text
products.csv
```

using:

```sql
COPY INTO PRODUCTS
FROM @ENTERPRISE_STAGE/products.csv
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

The result is verified using:

```sql
SELECT *
FROM PRODUCTS
ORDER BY PRODUCT_ID;
```

The screenshots show five products loaded successfully.

---

# 16. Loading Branches

Branches are loaded from:

```text
branches.csv
```

into:

```text
BRANCHES
```

The table provides the branch information required for later business analytics.

---

# 17. Loading Historical Sales

Historical sales are loaded into:

```text
SALES
```

using:

```sql
COPY INTO SALES
FROM @ENTERPRISE_STAGE/sales_history.csv
FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
```

The initial sales data represents historical transactions.

The screenshots show the historical sales records successfully loaded.

---

# 18. Loading New Sales

The project creates `NEW_SALES` and loads:

```text
new_sales.csv
```

into it.

This table represents incoming sales data.

The screenshot output demonstrates the new sales records being captured.

The conceptual architecture is:

```text
Historical data
       ↓
     SALES

New incoming data
       ↓
   NEW_SALES
```

---

# 19. Phase 3 — Incremental Loading

The next objective is to process new or changed records without rebuilding the complete sales table.

This is called:

# Incremental Loading

Instead of doing:

```text
Delete everything
        ↓
Reload everything
```

we do:

```text
Existing SALES
       +
New/changed records
       ↓
     MERGE
       ↓
Updated SALES
```

This is much more suitable for real-world data warehouse pipelines.

---

# 20. MERGE

The project uses:

```sql
MERGE INTO SALES AS TARGET
USING NEW_SALES AS SOURCE
ON TARGET.SALE_ID = SOURCE.SALE_ID
```

The `SALE_ID` is used to determine whether the incoming record already exists.

There are two possibilities.

## Case 1 — Matching record

If:

```text
TARGET.SALE_ID = SOURCE.SALE_ID
```

then the record already exists.

The project updates:

```text
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
QUANTITY
SALE_DATE
TOTAL_AMOUNT
```

This handles updates.

---

# 21. Case 2 — New Record

If no matching `SALE_ID` exists:

```sql
WHEN NOT MATCHED THEN INSERT
```

the record is inserted into `SALES`.

Therefore, one `MERGE` handles both:

```text
UPDATE
+
INSERT
```

This is called an **upsert** operation.

---

# 22. Why MERGE is Useful

Suppose:

```text
NEW_SALES
SALE_ID = 6
TOTAL_AMOUNT = 27000
```

and `SALE_ID = 6` already exists in `SALES`.

The `MERGE` updates the existing record.

Now suppose:

```text
SALE_ID = 11
```

does not exist.

The `MERGE` inserts it.

Therefore:

```text
Existing ID → UPDATE
New ID      → INSERT
```

The project screenshots demonstrate both update and insert scenarios.

---

# 23. Streams

The project creates:

```sql
CREATE OR REPLACE STREAM SALES_STREAM
ON TABLE SALES;
```

## What is a Stream?

A Snowflake Stream is a change-tracking mechanism.

It records changes occurring on a table, such as:

* INSERT
* UPDATE
* DELETE

A stream can therefore be used to identify changed records for downstream processing.

Conceptually:

```text
SALES
  |
  v
SALES_STREAM
  |
  v
Changed records
```

---

# 24. Important Project Note About the Stream

The project creates:

```text
SALES_STREAM
```

but the supplied incremental `MERGE` uses:

```text
NEW_SALES
```

directly:

```sql
MERGE INTO SALES
USING NEW_SALES
```

Therefore, the current implementation **demonstrates creation of a Stream but does not use the Stream as the source of the MERGE**.

This is important to understand for interviews.

### If asked:

> Did you use Streams for the incremental load?

A technically accurate answer is:

> "I created a Snowflake Stream on the SALES table to demonstrate change tracking, but in the implemented pipeline I used NEW_SALES directly as the source for the MERGE. The next improvement would be to consume the Stream in the incremental pipeline."

This is better than claiming that the Stream drives the current MERGE when it does not.

---

# 25. Phase 4 — Data Validation

After loading data, the project performs data quality checks.

The main validations are:

1. Duplicate sale IDs
2. Missing customers
3. Invalid products
4. Count of new records

---

# 26. Duplicate Detection

The query:

```sql
SELECT SALE_ID,
       COUNT(*) AS DUPLICATE_COUNT
FROM SALES
GROUP BY SALE_ID
HAVING COUNT(*) > 1;
```

groups records by `SALE_ID`.

If a sale ID occurs more than once:

```text
COUNT(*) > 1
```

the record is reported.

This helps detect duplicate transactions.

The project screenshot shows that the duplicate check produced no rows.

That means no duplicate `SALE_ID` was found at that point.

---

# 27. Missing Customer Validation

The project uses:

```sql
LEFT JOIN
```

between `SALES` and `CUSTOMERS`.

```sql
SELECT S.*
FROM SALES AS S
LEFT JOIN CUSTOMERS AS C
ON S.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;
```

## Why LEFT JOIN?

We want to keep every sales record.

If a sales record has no corresponding customer:

```text
SALES.CUSTOMER_ID
       ↓
No match in CUSTOMERS
       ↓
C.CUSTOMER_ID = NULL
```

Therefore it is identified as an invalid/missing customer reference.

The screenshot shows no records returned.

---

# 28. Invalid Product Validation

The same principle is applied to products:

```sql
SELECT S.*
FROM SALES AS S
LEFT JOIN PRODUCTS AS P
ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_ID IS NULL;
```

This identifies sales records referencing products that do not exist in the `PRODUCTS` table.

The screenshot shows no invalid product records.

---

# 29. Count of New Records

The project checks:

```sql
SELECT COUNT(*) AS TOTAL_NEW_RECORDS
FROM NEW_SALES;
```

This provides a simple validation of how many incoming records are present.

---

# 30. Phase 5 — Time Travel

One of Snowflake's important features demonstrated in the project is:

# Time Travel

Time Travel allows historical versions of table data to be accessed within the retention period.

This is useful when data is accidentally:

* Deleted
* Updated
* Changed

Instead of immediately losing access to the previous version, Snowflake can query historical data.

---

# 31. Delete a Sales Record

The project intentionally deletes:

```sql
DELETE FROM SALES
WHERE SALE_ID = 5;
```

Then it verifies:

```sql
SELECT *
FROM SALES
WHERE SALE_ID = 5;
```

The record is no longer present in the current table.

---

# 32. Recover Using Time Travel

The historical version is queried using:

```sql
SELECT *
FROM SALES
BEFORE (STATEMENT => '<DELETE_QUERY_ID>');
```

The important concept is:

```text
Current SALES
     ↓
Historical version
     ↓
Time Travel
```

The query ID of the DELETE statement is used to identify the correct historical state.

---

# 33. Restoring the Deleted Record

After finding the historical record, it is inserted back:

```sql
INSERT INTO SALES
SELECT *
FROM SALES BEFORE (STATEMENT => '<DELETE_QUERY_ID>')
WHERE SALE_ID = 5;
```

Then:

```sql
SELECT *
FROM SALES
WHERE SALE_ID = 5;
```

confirms that the record has been recovered.

---

# 34. Why Time Travel is Important

Time Travel is useful for:

* Accidental deletes
* Data recovery
* Debugging
* Auditing
* Comparing historical states
* Recovering from incorrect transformations

It provides an important safety mechanism in a data warehouse.

---

# 35. Phase 6 — Zero-Copy Clone

The project creates:

```sql
CREATE OR REPLACE TABLE SALES_TEST
CLONE SALES;
```

This demonstrates:

# Zero-Copy Cloning

Snowflake can create a clone without immediately creating a completely separate physical copy of all the data.

The clone initially references the same underlying data.

Conceptually:

```text
             SALES
               |
        +------+------+
        |             |
        v             v
   Original       SALES_TEST
```

---

# 36. Why Zero-Copy Clone is Useful

Zero-Copy Cloning is useful for:

* Testing
* Development
* Experimentation
* QA
* Temporary environments
* Data validation

For example, developers can clone production-like data and test changes without modifying the original table.

---

# 37. Modifying the Clone

The project inserts:

```text
SALE_ID = 999
```

into:

```text
SALES_TEST
```

Then it checks the clone.

The clone contains the new record.

But the original:

```text
SALES
```

does not contain the new record.

This proves that modifications to the clone do not modify the original table.

The screenshots specifically demonstrate that the original sales table remains unchanged after modifying the clone.

---

# 38. Zero-Copy Clone vs Normal Copy

Normal copy:

```text
Original
   ↓
Physical copy of data
```

Zero-Copy Clone:

```text
Original
   ↓
Metadata-based clone
```

Initially, the clone shares the underlying data.

When changes are made, Snowflake uses its copy-on-write architecture to maintain independence.

---

# 39. Phase 7 — Task Automation

The project then automates incremental processing using a Snowflake Task.

The Task is:

```text
DAILY_SALES_INCREMENTAL_TASK
```

---

# 40. What is a Snowflake Task?

A Task allows SQL statements to be executed automatically according to a schedule or dependency.

It can be used for:

* ETL
* ELT
* Incremental loading
* Data transformations
* Scheduled maintenance
* Data pipeline automation

The project uses the Task to automate the `MERGE`.

---

# 41. Creating the Task

The original schedule is:

```sql
SCHEDULE = 'USING CRON 0 0 * * * UTC'
```

This represents a scheduled execution based on UTC.

The Task uses:

```text
ENTERPRISE_WH
```

and executes the incremental `MERGE`.

Conceptually:

```text
NEW_SALES
    |
    v
Scheduled Task
    |
    v
MERGE
    |
    v
SALES
```

---

# 42. Resuming the Task

A newly created task must be resumed:

```sql
ALTER TASK DAILY_SALES_INCREMENTAL_TASK RESUME;
```

Once resumed, Snowflake can execute it according to its schedule.

The project checks the task using:

```sql
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
```

---

# 43. Manual Task Execution

For testing, the project executes:

```sql
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
```

This is useful because waiting for the scheduled execution is unnecessary during development.

The flow becomes:

```text
Change source data
      ↓
EXECUTE TASK
      ↓
MERGE
      ↓
Verify SALES
```

---

# 44. Testing UPDATE Through the Task

The project changes:

```text
SALE_ID = 6
```

in `NEW_SALES`.

The amount is changed to:

```text
27000
```

Then the Task is executed.

After execution:

```sql
SELECT *
FROM SALES
WHERE SALE_ID = 6;
```

is used to verify the update.

This proves that the Task can automate the MERGE logic.

---

# 45. Testing INSERT Through the Task

The project inserts:

```text
SALE_ID = 11
```

into `NEW_SALES`.

Then:

```sql
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
```

is executed.

Because `SALE_ID = 11` does not already exist in `SALES`, the MERGE inserts it.

This demonstrates:

```text
New source record
       ↓
Task
       ↓
MERGE
       ↓
INSERT into SALES
```

---

# 46. Testing Another UPDATE

The project then changes the amount for:

```text
SALE_ID = 11
```

from:

```text
15000
```

to:

```text
18000
```

The Task is executed again.

Because `SALE_ID = 11` now exists in `SALES`, the MERGE updates the existing record.

This demonstrates both sides of incremental processing:

```text
New SALE_ID → INSERT
Existing SALE_ID → UPDATE
```

---

# 47. Changing the Task Schedule

For testing, the project changes the Task schedule to:

```sql
ALTER TASK DAILY_SALES_INCREMENTAL_TASK
SET SCHEDULE = '5 MINUTE';
```

The Task is suspended before modifying the schedule and resumed afterward.

The sequence is:

```sql
ALTER TASK ... SUSPEND;

ALTER TASK ...
SET SCHEDULE = '5 MINUTE';

ALTER TASK ... RESUME;
```

This allows the Task to run automatically every five minutes during testing.

---

# 48. Automatic Task Test

The project inserts:

```text
SALE_ID = 12
```

into `NEW_SALES`.

The Task then automatically processes the record.

After the Task runs:

```sql
SELECT *
FROM SALES
WHERE SALE_ID = 12;
```

is used to verify the insertion.

The source record is then updated from:

```text
30000
```

to:

```text
35000
```

The Task runs again and updates the corresponding record in `SALES`.

This demonstrates actual scheduled automation.

---

# 49. Task History

The project checks Task execution history using:

```sql
INFORMATION_SCHEMA.TASK_HISTORY
```

The query retrieves information such as:

```text
NAME
STATE
SCHEDULED_TIME
COMPLETED_TIME
ERROR_MESSAGE
```

This is useful for monitoring whether scheduled data pipelines succeeded or failed.

For a production pipeline, Task History is important for troubleshooting.

---

# 50. Suspending the Task

After testing:

```sql
ALTER TASK DAILY_SALES_INCREMENTAL_TASK SUSPEND;
```

is used.

This prevents the Task from continuing to execute automatically after the demonstration is complete.

---

# 51. Phase 8 — Business Analytics

After completing the data pipeline, the project performs business analysis.

This is where the warehouse becomes useful to the business.

The project calculates:

* Customer revenue
* Branch revenue
* Product revenue
* Monthly revenue
* Highest-revenue customer
* Highest-revenue branch
* Top five products
* Customer purchase frequency
* Running revenue
* Customer ranking

---

# 52. Customer Revenue

The query joins:

```text
SALES
+
CUSTOMERS
```

using:

```sql
S.CUSTOMER_ID = C.CUSTOMER_ID
```

Then:

```sql
SUM(S.TOTAL_AMOUNT)
```

calculates total revenue for each customer.

The result is grouped by:

```text
CUSTOMER_ID
CUSTOMER_NAME
```

and ordered from highest to lowest revenue.

The screenshot shows the customer revenue report.

---

# 53. Why JOIN is Required

The `SALES` table contains:

```text
CUSTOMER_ID
```

but not necessarily the customer's name.

The `CUSTOMERS` table contains:

```text
CUSTOMER_ID
CUSTOMER_NAME
```

Therefore:

```text
SALES
   |
   | CUSTOMER_ID
   v
CUSTOMERS
```

allows us to display meaningful customer information.

---

# 54. Branch Revenue

The project joins:

```text
SALES
+
BRANCHES
```

and calculates:

```sql
SUM(S.TOTAL_AMOUNT)
```

for each branch.

The result identifies the revenue generated by each branch.

The screenshots show three branches and their corresponding revenue.

---

# 55. Product Revenue

The project joins:

```text
SALES
+
PRODUCTS
```

and calculates total revenue for each product.

The output identifies the highest-revenue products.

The screenshots show the product revenue ranking, including products such as laptops, mobiles, keyboards, and monitors.

---

# 56. Monthly Revenue

The project uses:

```sql
DATE_TRUNC('MONTH', SALE_DATE)
```

to group sales by month.

Then:

```sql
SUM(TOTAL_AMOUNT)
```

calculates monthly revenue.

The concept is:

```text
Individual sales
       ↓
Extract month
       ↓
GROUP BY month
       ↓
SUM revenue
```

This is useful for monthly business reporting.

---

# 57. Highest Revenue Customer

The project sorts customer revenue:

```sql
ORDER BY TOTAL_REVENUE DESC
```

and selects:

```sql
LIMIT 1
```

Therefore, only the highest-revenue customer is returned.

---

# 58. Highest Revenue Branch

The same concept is applied to branches.

The query:

```text
GROUP BY branch
        ↓
SUM revenue
        ↓
ORDER BY revenue DESC
        ↓
LIMIT 1
```

returns the branch generating the highest revenue.

---

# 59. Top Five Products

The project uses:

```sql
ORDER BY TOTAL_REVENUE DESC
LIMIT 5;
```

This returns the five products with the highest revenue.

The screenshot demonstrates the top-five product report.

---

# 60. Customer Purchase Frequency

The project calculates:

```sql
COUNT(S.SALE_ID)
```

for each customer.

This answers:

> How many sales transactions has each customer made?

The result is ordered by purchase frequency.

This is different from revenue.

For example:

```text
Customer A
Revenue = ₹100,000
Purchases = 2
```

and:

```text
Customer B
Revenue = ₹90,000
Purchases = 10
```

would mean Customer A has higher revenue but Customer B purchases more frequently.

---

# 61. Running Revenue

The project uses a window function:

```sql
SUM(TOTAL_AMOUNT) OVER (
    ORDER BY SALE_DATE, SALE_ID
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

This calculates cumulative revenue.

Example:

```text
Sale 1 → 60,000
Sale 2 → 50,000
Sale 3 → 30,000
```

Running revenue becomes:

```text
60,000
110,000
140,000
```

The important idea is:

```text
Current revenue
+
All previous revenue
=
Running revenue
```

---

# 62. Why a Window Function is Used

A normal `GROUP BY` would collapse multiple sales into one row.

A window function allows us to calculate an aggregate while keeping individual rows.

Therefore:

```text
GROUP BY
```

reduces rows.

Whereas:

```text
WINDOW FUNCTION
```

can calculate across rows while preserving the individual records.

---

# 63. Customer Ranking

The project uses:

```sql
RANK() OVER (
    ORDER BY SUM(S.TOTAL_AMOUNT) DESC
)
```

to rank customers according to revenue.

The result contains:

```text
CUSTOMER_ID
CUSTOMER_NAME
TOTAL_REVENUE
CUSTOMER_RANK
```

Example:

```text
Customer A → ₹100,000 → Rank 1
Customer B → ₹90,000  → Rank 2
Customer C → ₹80,000  → Rank 3
```

---

# 64. RANK vs ROW_NUMBER

An important interview concept:

### RANK()

If two customers have the same revenue:

```text
100000 → Rank 1
100000 → Rank 1
90000  → Rank 3
```

There is a gap.

### ROW_NUMBER()

Would assign unique sequential numbers:

```text
100000 → 1
100000 → 2
90000  → 3
```

Therefore `RANK()` is appropriate when tied positions should share the same rank.

---

# 65. Phase 9 — Views

The project creates a view:

```text
CUSTOMER_REVENUE
```

using:

```sql
CREATE OR REPLACE VIEW CUSTOMER_REVENUE AS
...
```

---

# 66. What is a View?

A View is a logical/virtual representation of a query.

Instead of repeatedly writing:

```sql
JOIN
GROUP BY
SUM
```

we can store the query as a View.

Then users can simply query:

```sql
SELECT *
FROM CUSTOMER_REVENUE;
```

---

# 67. Customer Revenue View

The View contains:

```text
CUSTOMER_ID
CUSTOMER_NAME
TOTAL_REVENUE
```

It calculates total revenue for each customer.

The benefit is that analysts can query the View instead of rewriting the underlying business logic every time.

---

# 68. View vs Table

A table stores data.

A normal view stores a query definition.

Conceptually:

```text
Table
→ stores data

View
→ stores query logic
```

A View normally does not store a separate physical copy of the result data.

---

# 69. Materialized View

The project creates:

```text
BRANCH_REVENUE
```

as a Materialized View.

The definition is:

```sql
CREATE OR REPLACE MATERIALIZED VIEW BRANCH_REVENUE AS
SELECT BRANCH_ID,
       SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES
GROUP BY BRANCH_ID;
```

---

# 70. What is a Materialized View?

A Materialized View stores the result of a query in a maintained form so that certain repeated queries can be faster.

It is useful when:

* A query is expensive
* Aggregations are repeated
* The same result is requested frequently

In this project, the materialized view pre-aggregates:

```text
BRANCH_ID
TOTAL_REVENUE
```

---

# 71. Why Doesn't the Materialized View Directly Use BRANCHES?

The project notes an important Snowflake restriction around Materialized Views.

Therefore, the Materialized View uses only:

```text
SALES
```

and stores:

```text
BRANCH_ID
TOTAL_REVENUE
```

Then the final query joins the Materialized View with `BRANCHES` to obtain the branch name.

The architecture is:

```text
SALES
  |
  v
BRANCH_REVENUE Materialized View
  |
  | BRANCH_ID
  v
BRANCHES
  |
  v
BRANCH_NAME
```

This is what is demonstrated in the final screenshots.

---

# 72. Final Verification

The project performs final verification using:

```sql
SELECT COUNT(*) AS TOTAL_SALES
FROM SALES;
```

This checks the final number of sales records.

Then:

```sql
SELECT *
FROM SALES
ORDER BY SALE_ID;
```

displays the final sales dataset.

Finally:

```sql
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
```

checks the Task configuration.

---

# 73. Complete Project Flow

The entire project can be summarized as:

```text
                  CSV FILES
                      |
                      v
             INTERNAL STAGE
                      |
                      v
              FILE FORMAT
                      |
                      v
                 COPY INTO
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
      CUSTOMERS   PRODUCTS    BRANCHES
                      |
                      |
                      v
                HISTORICAL SALES
                      |
                      v
                    SALES
                      ^
                      |
                 NEW_SALES
                      |
                      v
                   MERGE
                      |
                      v
              INCREMENTAL LOAD
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
    VALIDATION   TIME TRAVEL   CLONING
                                  |
                                  v
                              SALES_TEST

                    SALES
                      |
                      v
                 TASK AUTOMATION
                      |
                      v
                Scheduled MERGE

                    SALES
                      |
          +-----------+------------+
          |           |            |
          v           v            v
      ANALYTICS      VIEW       MATERIALIZED
                                  VIEW
```

---

# 74. Concepts Demonstrated in the Project

## Snowflake Warehouse

Provides compute resources.

```text
ENTERPRISE_WH
```

---

## Database

Logical container for schemas.

```text
ENTERPRISE_DB
```

---

## Schema

Logical container for project objects.

```text
SALES_SCHEMA
```

---

## File Format

Defines how Snowflake interprets CSV files.

```text
ENTERPRISE_CSV_FORMAT
```

---

## Internal Stage

Temporary Snowflake-managed location for files.

```text
ENTERPRISE_STAGE
```

---

## COPY INTO

Loads staged files into Snowflake tables.

---

## MERGE

Performs conditional:

```text
UPDATE
+
INSERT
```

operations.

---

## Stream

Tracks changes made to a Snowflake table.

In this project, a Stream was created but the implemented MERGE uses `NEW_SALES` directly.

---

## Task

Automates SQL execution according to a schedule.

---

## Time Travel

Allows access to historical table states.

---

## Zero-Copy Clone

Creates a clone without immediately duplicating all underlying data.

---

## JOIN

Combines related information from different tables.

---

## GROUP BY

Groups rows for aggregation.

---

## SUM

Calculates total revenue.

---

## COUNT

Calculates transaction/purchase frequency.

---

## Window Function

Performs calculations across rows while preserving row-level information.

---

## RANK

Ranks customers based on revenue.

---

## View

Stores reusable query logic.

---

## Materialized View

Stores a maintained/precomputed form of query results for eligible queries.

---

# 75. Important SQL Concepts Used

## SELECT

Retrieves data.

```sql
SELECT *
FROM SALES;
```

---

## WHERE

Filters rows.

```sql
WHERE SALE_ID = 5;
```

---

## GROUP BY

Groups records.

```sql
GROUP BY CUSTOMER_ID;
```

---

## HAVING

Filters aggregated groups.

```sql
HAVING COUNT(*) > 1;
```

Important difference:

```text
WHERE
→ filters rows before aggregation

HAVING
→ filters groups after aggregation
```

---

## ORDER BY

Sorts results.

```sql
ORDER BY TOTAL_REVENUE DESC;
```

---

## LIMIT

Restricts the number of returned rows.

```sql
LIMIT 5;
```

---

## LEFT JOIN

Keeps all records from the left table and matches data from the right table when available.

Used in this project for data validation.

---

# 76. CTE — Important Note

The project documentation lists:

```text
CTE
```

as one of the main concepts.

However, the supplied Project-3 SQL does **not actually contain a `WITH ... AS (...)` CTE implementation**.

A CTE normally looks like:

```sql
WITH customer_revenue AS (
    SELECT
        CUSTOMER_ID,
        SUM(TOTAL_AMOUNT) AS REVENUE
    FROM SALES
    GROUP BY CUSTOMER_ID
)
SELECT *
FROM customer_revenue;
```

Therefore, if asked:

> Did you use a CTE in Project-3?

The accurate answer is:

> "CTEs were included in the planned concepts for the project, but the final submitted SQL mainly used direct queries, joins, aggregations, and window functions rather than a CTE."

---

# 77. Difference Between Historical and Incremental Loading

This project demonstrates both.

## Historical Load

Loads existing historical data.

```text
sales_history.csv
       ↓
SALES
```

Usually performed initially.

---

## Incremental Load

Processes new or changed records.

```text
NEW_SALES
     ↓
MERGE
     ↓
SALES
```

This avoids reloading the entire historical dataset every time.

---

# 78. Why Incremental Loading is Important

Imagine a company has:

```text
500 million sales records
```

and only:

```text
10,000 new records
```

arrive today.

Reloading all 500 million records would be inefficient.

Instead:

```text
Existing 500M
+
New 10K
   ↓
Incremental processing
```

is much more practical.

This is the main idea behind the project's incremental data warehouse design.

---

# 79. Why MERGE is Better Than Only INSERT

Suppose a record arrives with:

```text
SALE_ID = 6
TOTAL_AMOUNT = 27000
```

but `SALE_ID = 6` already exists.

If we only use:

```sql
INSERT
```

we could create a duplicate.

With:

```sql
MERGE
```

we can determine:

```text
Exists?
   |
   +-- YES → UPDATE
   |
   +-- NO  → INSERT
```

This is why MERGE is useful for incremental pipelines.

---

# 80. Data Quality Layer

The validation phase effectively creates a basic data quality layer.

The project checks:

```text
Duplicate sale IDs
        +
Missing customers
        +
Invalid products
        +
New record count
```

This prevents obvious data integrity problems from going unnoticed.

---

# 81. Recovery and Testing Layer

The project also demonstrates operational safety.

### Time Travel

Protects against accidental data deletion.

### Zero-Copy Clone

Allows safe experimentation.

### Task History

Allows monitoring of automated processing.

Therefore, the project is not only about querying data.

It also demonstrates basic warehouse administration and operational capabilities.

---

# 82. Business Intelligence Layer

The final analytics layer transforms raw transaction data into business information.

```text
Raw sales
   ↓
Aggregations
   ↓
Business metrics
```

Examples:

```text
Customer Revenue
Branch Revenue
Product Revenue
Monthly Revenue
Top Customers
Top Products
Purchase Frequency
Running Revenue
Customer Ranking
```

This is the part that allows business users to make decisions from the warehouse.

---

# 83. Example Business Questions Answered

The project can answer questions such as:

### Which customer generated the most revenue?

Use customer revenue aggregation and ordering.

### Which branch generated the most revenue?

Aggregate sales by branch.

### Which products are the top five?

Aggregate revenue by product and use:

```sql
LIMIT 5
```

### How much revenue was generated each month?

Use:

```sql
DATE_TRUNC('MONTH', SALE_DATE)
```

### How frequently does each customer purchase?

Use:

```sql
COUNT(SALE_ID)
```

### What is the cumulative revenue over time?

Use:

```sql
SUM(...) OVER (...)
```

### What is each customer's revenue rank?

Use:

```sql
RANK() OVER (...)
```

---

# 84. What I Actually Built in This Project

A good interview explanation is:

> "I built an enterprise-style incremental sales data warehouse in Snowflake. I started by creating a virtual warehouse, database, schema, CSV file format, and internal stage. I loaded customer, product, branch, and historical sales data using COPY INTO. I then created a NEW_SALES source for incoming records and used MERGE to perform incremental inserts and updates into the main SALES table. I added data validation checks for duplicates and invalid customer and product references. I demonstrated Snowflake Time Travel by deleting and recovering a sales record, and Zero-Copy Cloning by creating a SALES_TEST clone and modifying it without affecting the original table. I automated incremental processing with a Snowflake Task and tested both insert and update scenarios. Finally, I built business analytics for customer, branch, product, and monthly revenue, along with running revenue and customer ranking. I also created a customer revenue View and a branch revenue Materialized View."

This is the short version to memorize.

---

# 85. Two-Minute Interview Explanation

If the interviewer says:

> "Explain your Snowflake project."

You can say:

> "My project was an Enterprise Incremental Sales Data Warehouse built using Snowflake. The goal was to load historical sales data and continuously process new sales records while also demonstrating Snowflake's data engineering capabilities.
>
> I first created an X-Small virtual warehouse with auto-suspend and auto-resume, followed by a database and sales schema. I created a CSV file format and an internal stage, uploaded the source files, and loaded customers, products, branches, historical sales, and new sales using COPY INTO.
>
> For incremental processing, I used NEW_SALES as the source and MERGE as the target operation. If the SALE_ID already existed, the record was updated; otherwise, it was inserted. I also created a Stream on SALES to demonstrate change tracking, although the implemented MERGE uses NEW_SALES directly.
>
> I then performed data validation to detect duplicate sale IDs, missing customers, and invalid products. I demonstrated Time Travel by deleting a record and recovering it from a previous table state. I also created a Zero-Copy Clone called SALES_TEST and verified that modifying the clone did not affect the original SALES table.
>
> For automation, I created a Snowflake Task that executes the incremental MERGE on a schedule. I tested both INSERT and UPDATE scenarios and checked Task History.
>
> Finally, I created business reports for customer, branch, product, and monthly revenue. I also implemented top-five products, customer purchase frequency, running revenue using window functions, and customer ranking using RANK. I created a customer revenue View and a branch revenue Materialized View.
>
> So overall, the project demonstrates the complete flow from data ingestion to incremental processing, validation, recovery, automation, and business analytics in Snowflake."

---

# 86. Interview Questions You Should Be Able to Answer

## Snowflake Basics

### 1. What is Snowflake?

A cloud-based data platform designed for scalable data storage, processing, analytics, and data engineering.

### 2. What is a Snowflake warehouse?

A compute resource used to execute SQL operations.

### 3. What is a database?

A logical container for schemas.

### 4. What is a schema?

A logical container for database objects.

### 5. What is a stage?

A location used to store files before loading them into Snowflake.

---

# 87. Data Loading Questions

### 6. Why did you use a File Format?

To tell Snowflake how to interpret the CSV files.

### 7. Why did you use `SKIP_HEADER = 1`?

Because the first row contains CSV column names.

### 8. What is COPY INTO?

Snowflake command used to load data from a stage into a table.

### 9. What is the difference between a stage and a table?

A stage holds files; a table stores structured data in Snowflake.

---

# 88. Incremental Loading Questions

### 10. What is incremental loading?

Loading only new or changed records instead of reloading the entire dataset.

### 11. Why did you use MERGE?

To handle both updates and inserts.

### 12. What determines whether a record is updated or inserted?

The matching condition:

```sql
TARGET.SALE_ID = SOURCE.SALE_ID
```

### 13. What is an upsert?

An operation that performs:

```text
UPDATE if exists
INSERT if not exists
```

---

# 89. Stream Questions

### 14. What is a Stream?

A Snowflake change-tracking object that records table changes.

### 15. Did your final MERGE consume the Stream?

No.

The project created:

```text
SALES_STREAM
```

but the implemented MERGE uses:

```text
NEW_SALES
```

directly.

### 16. How could you improve it?

A more production-oriented pipeline could use the Stream as the source of changed records and consume those changes through a Task.

---

# 90. Time Travel Questions

### 17. What is Time Travel?

A Snowflake capability that allows historical data to be queried within the retention period.

### 18. Why did you use it?

To demonstrate recovery from accidental deletion.

### 19. How did you recover the deleted record?

By querying the historical version using:

```sql
BEFORE (STATEMENT => ...)
```

and inserting the required record back into `SALES`.

---

# 91. Clone Questions

### 20. What is Zero-Copy Cloning?

Creating a clone without immediately making a full physical copy of the data.

### 21. Why use it?

For testing and development without modifying the original table.

### 22. Did changing the clone change the original?

No.

The project specifically verifies that `SALES` remains unchanged after modifying `SALES_TEST`.

---

# 92. Task Questions

### 23. What is a Task?

A Snowflake object that automatically executes SQL according to a schedule or dependency.

### 24. How did you test the Task?

Using:

```sql
EXECUTE TASK
```

and by changing the schedule to:

```text
5 MINUTE
```

for automatic testing.

### 25. How did you monitor the Task?

Using:

```sql
INFORMATION_SCHEMA.TASK_HISTORY
```

---

# 93. Analytics Questions

### 26. How did you calculate customer revenue?

Using:

```text
JOIN
+
GROUP BY
+
SUM
```

### 27. How did you calculate monthly revenue?

Using:

```sql
DATE_TRUNC('MONTH', SALE_DATE)
```

and:

```sql
SUM(TOTAL_AMOUNT)
```

### 28. How did you calculate running revenue?

Using a window function:

```sql
SUM(TOTAL_AMOUNT) OVER (...)
```

### 29. How did you rank customers?

Using:

```sql
RANK() OVER (...)
```

### 30. How did you find the top five products?

Using:

```sql
ORDER BY TOTAL_REVENUE DESC
LIMIT 5
```

---

# 94. View Questions

### 31. What is a View?

A reusable query definition that provides a logical representation of data.

### 32. Why create a View?

To simplify repeated business logic and make it easier for analysts to query prepared data.

### 33. What View did you create?

```text
CUSTOMER_REVENUE
```

---

# 95. Materialized View Questions

### 34. What is a Materialized View?

A maintained/precomputed representation of an eligible query result that can improve performance for repeated queries.

### 35. What Materialized View did you create?

```text
BRANCH_REVENUE
```

It pre-aggregates:

```text
BRANCH_ID
TOTAL_REVENUE
```

from `SALES`.

---

# 96. Important Difference: View vs Materialized View

```text
VIEW
 |
 +-- Stores query definition
 |
 +-- Calculates when queried


MATERIALIZED VIEW
 |
 +-- Maintains/precomputes eligible results
 |
 +-- Can improve repeated query performance
```

---

# 97. Project Strengths

This project demonstrates several important data engineering skills:

```text
1. Data ingestion
2. Data modeling
3. Incremental loading
4. Data validation
5. Data recovery
6. Testing isolation
7. Pipeline automation
8. SQL analytics
9. Window functions
10. Reusable reporting objects
```

It therefore goes beyond simple SQL querying.

---

# 98. What Could Be Improved

There are a few areas that could be improved in a future version.

## 1. Actually consume the Stream

Currently:

```text
SALES_STREAM
```

is created, but:

```text
NEW_SALES
```

is used directly by the MERGE.

A stronger implementation would use the Stream in the incremental pipeline.

---

## 2. Use a CTE

The project lists CTE as a concept but does not currently demonstrate a `WITH` query.

A future version could use CTEs for more complex transformations.

---

## 3. Separate Raw and Curated Layers

A larger production architecture could use:

```text
RAW
 ↓
STAGING
 ↓
CURATED
 ↓
ANALYTICS
```

instead of keeping the project relatively simple.

---

## 4. Add Error Handling

A production pipeline could include:

* Failed record handling
* Load error tables
* Data quality thresholds
* Monitoring alerts
* Pipeline status logging

---

## 5. Use Stream + Task Together

A more advanced architecture would be:

```text
Source
   ↓
Staging
   ↓
Stream
   ↓
Task
   ↓
MERGE
   ↓
Target
```

This would make the project a more realistic Snowflake incremental pipeline.

---

# 99. Final Project Architecture to Remember

The most important architecture to remember is:

```text
                    SNOWFLAKE
                        |
              +---------+---------+
              |                   |
          COMPUTE              STORAGE
              |                   |
      ENTERPRISE_WH        ENTERPRISE_DB
                                  |
                            SALES_SCHEMA
                                  |
              +-------------------+-------------------+
              |         |         |        |          |
              v         v         v        v          v
          CUSTOMERS  PRODUCTS  BRANCHES  SALES    NEW_SALES
                                             |
                                             |
                                           MERGE
                                             |
                                             v
                                      Updated SALES
                                             |
             +---------------+---------------+---------------+
             |               |               |               |
             v               v               v               v
        Analytics       Time Travel     Zero-Copy Clone    Task
             |                               |
             v                               v
       Reports/Views                    SALES_TEST
```

---

# 100. One-Line Explanation of Every Major Feature

| Feature           | Simple Explanation                     |
| ----------------- | -------------------------------------- |
| Warehouse         | Provides compute power                 |
| Database          | Contains schemas                       |
| Schema            | Contains database objects              |
| File Format       | Defines how files are read             |
| Stage             | Stores files before loading            |
| COPY INTO         | Loads files into tables                |
| SALES             | Main sales table                       |
| NEW_SALES         | Incoming sales source                  |
| Stream            | Tracks table changes                   |
| MERGE             | Handles update + insert                |
| Validation        | Checks data quality                    |
| Time Travel       | Recovers historical data               |
| Zero-Copy Clone   | Creates a testable clone               |
| Task              | Automates SQL execution                |
| JOIN              | Combines related tables                |
| GROUP BY          | Groups records                         |
| SUM               | Calculates revenue                     |
| COUNT             | Counts transactions                    |
| Window Function   | Calculates across rows                 |
| RANK              | Assigns business rankings              |
| View              | Reusable query                         |
| Materialized View | Maintained/precomputed eligible result |

---

# 101. Final Summary

Project-3 demonstrates a complete small-scale Snowflake data warehouse workflow.

The project starts with:

```text
CSV Files
```

and moves through:

```text
Stage
 ↓
Data Loading
 ↓
Historical Data
 ↓
Incremental Data
 ↓
MERGE
 ↓
Validation
 ↓
Recovery
 ↓
Testing
 ↓
Automation
 ↓
Analytics
 ↓
Views
 ↓
Materialized View
```

The most important concepts to remember are:

```text
COPY INTO
MERGE
STREAM
TASK
TIME TRAVEL
ZERO-COPY CLONE
VIEW
MATERIALIZED VIEW
WINDOW FUNCTIONS
RANK
```

The core data engineering idea behind the project is:

> **Load historical data once, process new or changed data incrementally, validate the data, automate the pipeline, provide recovery and testing capabilities, and finally transform the warehouse data into business insights.**

---

# 102. Final Interview Cheat Sheet

If you have very little time before an interview, remember this:

```text
PROJECT:
Enterprise Incremental Sales Data Warehouse

PLATFORM:
Snowflake

WAREHOUSE:
ENTERPRISE_WH

DATABASE:
ENTERPRISE_DB

SCHEMA:
SALES_SCHEMA

SOURCE:
CSV files

STAGE:
ENTERPRISE_STAGE

TABLES:
CUSTOMERS
PRODUCTS
BRANCHES
SALES
NEW_SALES

LOADING:
COPY INTO

INCREMENTAL:
MERGE

STREAM:
SALES_STREAM created for change tracking,
but current MERGE uses NEW_SALES directly

RECOVERY:
TIME TRAVEL

TESTING:
ZERO-COPY CLONE

AUTOMATION:
DAILY_SALES_INCREMENTAL_TASK

ANALYTICS:
Customer Revenue
Branch Revenue
Product Revenue
Monthly Revenue
Top Customers
Top Products
Purchase Frequency
Running Revenue
Customer Ranking

VIEW:
CUSTOMER_REVENUE

MATERIALIZED VIEW:
BRANCH_REVENUE

SQL CONCEPTS:
JOIN
GROUP BY
HAVING
SUM
COUNT
DATE_TRUNC
WINDOW FUNCTIONS
RANK
ORDER BY
LIMIT
```

## Final 30-Second Answer

> "I built an incremental sales data warehouse in Snowflake. I created the warehouse, database, schema, CSV file format, and internal stage, then loaded customers, products, branches, and historical sales using COPY INTO. For incoming sales, I used a NEW_SALES table and MERGE to handle both inserts and updates. I performed data quality checks, demonstrated Time Travel recovery and Zero-Copy Cloning, and automated the incremental MERGE using a Snowflake Task. Finally, I built customer, branch, product, and monthly revenue analytics, including running revenue and customer ranking, and created a View and Materialized View for reusable reporting."

---

# End of Project-3 Explanation

**Project:** Enterprise Incremental Sales Data Warehouse using Snowflake
**Warehouse:** `ENTERPRISE_WH`
**Database:** `ENTERPRISE_DB`
**Schema:** `SALES_SCHEMA`
