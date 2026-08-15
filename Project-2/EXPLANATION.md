PROJECT-2: What is new?

Project-2 is more advanced.

You went from:

Basic analytics

to:

Advanced analytics
Project-2 architecture
RETAIL_WH
    ↓
RETAIL_DB
    ↓
SALES_SCHEMA
    │
    ├── CUSTOMERS
    ├── PRODUCTS
    ├── BRANCHES
    ├── SALES
    │
    ├── RETAIL_STAGE
    ├── RETAIL_CSV_FORMAT
    │
    ├── SALES_REPORT
    └── TOP_CUSTOMERS
Project-2 data model

This is better to visualize as:

                 CUSTOMERS
                     │
                     │ customer_id
                     ↓
PRODUCTS ──────── SALES ──────── BRANCHES
product_id        │              branch_id
                  │
                  ↓
             sale transaction

SALES is the central transaction table.

It contains:

sale_id
customer_id
product_id
branch_id
quantity
sale_date
total_amount
Project-2 adds 4 major concepts
1. Window Functions
RANK()
ROW_NUMBER()
SUM() OVER()
AVG() OVER()

You learned:

Analyze rows while keeping the individual rows.

2. CTE
WITH customer_sales AS (...)

You learned:

Break complicated SQL into logical temporary steps.

3. View
CREATE VIEW SALES_REPORT

You learned:

Save a reusable query definition.

4. Materialized View
CREATE MATERIALIZED VIEW TOP_CUSTOMERS

You learned:

Maintain a precomputed result for eligible workloads, potentially improving performance for repeated queries.

The biggest Project-1 → Project-2 progression
PROJECT-1
────────────
SELECT
WHERE
JOIN
GROUP BY
SUM
AVG
COUNT
HAVING
VIEW

↓

PROJECT-2
────────────
Everything above
+
RANK()
ROW_NUMBER()
SUM() OVER()
AVG() OVER()
PARTITION BY
CTE
MATERIALIZED VIEW

That's why Project-2 is more important for your mentor evaluation.