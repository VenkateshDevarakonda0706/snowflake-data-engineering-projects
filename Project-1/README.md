# Project 1 — Customer Sales Analytics using Snowflake

## Overview

This project demonstrates how to build a basic data warehouse environment in Snowflake, load CSV files into Snowflake tables, and perform SQL-based business analytics.

The project uses customer, food item, and order data to generate customer sales, food sales, category revenue, and other business reports.

## Technologies Used

- Snowflake
- SQL
- CSV
- Git
- GitHub

## Snowflake Environment

The following Snowflake objects were created:

- Warehouse: `SALES_WH`
- Database: `CUSTOMER_SALES_DB`
- Schema: `SALES_SCHEMA`
- File Format: `SALES_CSV_FORMAT`
- Internal Stage: `SALES_STAGE`

## Input Files

The project uses:

- `customers.csv`
- `fooditems.csv`
- `orders.csv`

## Tables

### CUSTOMERS

Stores customer information.

Columns:

- `customer_id`
- `first_name`
- `last_name`
- `email`
- `phone`
- `address`

### FOODITEMS

Stores food/product information.

Columns:

- `food_id`
- `name`
- `price`
- `category`
- `availability`

### ORDERS

Stores order transactions.

Columns:

- `order_id`
- `customer_id`
- `food_id`
- `quantity`
- `order_date`
- `status`
- `total_amount`

## Data Loading Process

The data loading workflow was:

```text
CSV Files
    ↓
Internal Snowflake Stage
    ↓
COPY INTO
    ↓
Snowflake Tables
    ↓
SQL Analytics
```
