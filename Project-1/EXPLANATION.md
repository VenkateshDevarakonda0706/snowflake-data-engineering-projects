PROJECT-1: What you actually learned

Your Project-1 was the simpler foundation.

Project-1 architecture
SALES_WH
   ↓
CUSTOMER_SALES_DB
   ↓
SALES_SCHEMA
   ├── CUSTOMERS
   ├── FOODITEMS
   ├── ORDERS
   ├── SALES_STAGE
   ├── SALES_CSV_FORMAT
   ├── CUSTOMER_ORDER_DETAILS
   └── CUSTOMER_SALES_REPORT
Project-1 data model
CUSTOMERS
    │
    │ customer_id
    ↓
ORDERS
    ↑
    │ food_id
    │
FOODITEMS

The main purpose was:

Load raw transactional data and perform basic analytical reporting.

Project-1 main SQL concepts

You used:

DDL
CREATE WAREHOUSE
CREATE DATABASE
CREATE SCHEMA
CREATE TABLE
CREATE STAGE
CREATE FILE FORMAT
CREATE VIEW

DDL = Data Definition Language

Used to create/change database objects.

Data loading
COPY INTO
Querying
SELECT
WHERE
ORDER BY
Aggregation
SUM()
AVG()
COUNT()

with:

GROUP BY
Filtering groups
HAVING
Combining tables
JOIN
Reusable query
VIEW
Project-1 mentor questions

You should be ready for:

Q: Why did you create a warehouse?

To provide compute resources for executing SQL queries and loading data.

Q: Why did you create a stage?

To temporarily store the incoming CSV files before loading them into Snowflake tables.

Q: Why create a file format?

To tell Snowflake how to interpret the CSV, such as delimiter and header handling.

Q: Why COPY INTO?

To load staged files into target Snowflake tables.

Q: Why JOIN?

Customer and product information are stored separately from orders, so JOIN allows us to combine them for reporting.

Q: Why GROUP BY?

To aggregate measures such as revenue by customer, product, category, or status.

Q: Why HAVING?

WHERE filters rows before aggregation, while HAVING filters groups after aggregation.

Q: Why create a view?

To save a reusable query so users don't have to repeatedly write the same joins and transformations.