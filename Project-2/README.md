# Project 2 — Retail Sales Analytics using Snowflake

## Overview

This project builds a Snowflake environment for a nationwide retail chain and performs business intelligence analysis on customer, product, branch, and sales data.

The project demonstrates data loading, multi-table joins, aggregation, window functions, Common Table Expressions (CTEs), views, and materialized views.

## Technologies Used

- Snowflake
- SQL
- CSV
- Git
- GitHub

## Snowflake Environment

The following Snowflake objects were created:

- Warehouse: `RETAIL_WH`
- Database: `RETAIL_DB`
- Schema: `SALES_SCHEMA`
- File Format: `RETAIL_CSV_FORMAT`
- Internal Stage: `RETAIL_STAGE`

## Input Files

The project uses four CSV files:

- `customers.csv`
- `products.csv`
- `branches.csv`
- `sales.csv`

## Data Model

The `SALES` table acts as the central transaction table.

```text
                 CUSTOMERS
                     |
                     | customer_id
                     |
PRODUCTS -------- SALES -------- BRANCHES
product_id        |              branch_id
                  |
                  | sale_id
                  |
             Sales Transactions