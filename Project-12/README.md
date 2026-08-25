# Project 12 — Enterprise Retail Analytics Data Warehouse

## Overview

Project 12 is an end-to-end **Snowflake SQL Data Warehouse** project for an omnichannel retail company.

The project implements a Kimball-style dimensional model and demonstrates:

- Facts and Dimensions
- Fact table grain
- Conformed dimensions
- Snowflake staging and CSV loading
- Surrogate keys
- SCD Type 1
- SCD Type 2
- SCD Type 3
- SCD Type 6 / Hybrid SCD
- Point-in-time analytics
- Warehouse auditing and validation

---

## Business Scenario

The retail company sells products through physical stores and online channels and needs centralized sales and customer loyalty reporting.

The warehouse must support:

| Requirement | Implementation |
|---|---|
| Sales line-item grain | `FACT_SALES` |
| Conformed Store dimension | `DIM_STORE` |
| Conformed Customer dimension | `DIM_CUSTOMER_HYBRID` |
| Store Manager history | SCD Type 1 |
| Customer Segment history | SCD Type 2 |
| Customer City previous value | SCD Type 3 |
| Customer Membership hybrid history | SCD Type 6 |

---

## Technology

- **Database:** Snowflake
- **Language:** Snowflake SQL
- **Model:** Kimball dimensional model / Star Schema
- **Source format:** CSV
- **Staging:** Snowflake Internal Stage
- **File format:** CSV File Format

---

## Project Structure

```text
RETAIL_DW
└── SALES_ANALYTICS
    ├── DIM_STORE
    ├── DIM_PRODUCT
    ├── DIM_CUSTOMER_HYBRID
    └── FACT_SALES
```

### Architecture

```text
                         DIM_STORE
                             |
                             |
DIM_PRODUCT ---------- FACT_SALES ---------- DIM_CUSTOMER_HYBRID
```

The fact table stores surrogate keys that reference the dimensions.

---

## Source Files

The project uses four source CSV files:

```text
stores.csv
products.csv
customers_initial.csv
customer_updates.csv
```

### stores.csv

Contains:

```text
store_id
store_name
city
state
store_manager
```

Initial records: **3**

### products.csv

Contains:

```text
product_id
product_name
category
unit_price
```

Initial records: **4**

### customers_initial.csv

Contains:

```text
customer_id
customer_name
city
state
membership
segment
```

Initial records: **5**

### customer_updates.csv

Contains:

```text
customer_id
customer_name
city
state
membership
segment
effective_date
```

Updated customers: **101, 103, 104**

---

# Snowflake Objects

## Warehouse

The project uses:

```text
RETAIL_DW_WH
```

with an XSMALL warehouse configuration.

## Database

```text
RETAIL_DW
```

## Schema

```text
SALES_ANALYTICS
```

## File Format

```text
CSV_FORMAT
```

## Stage

```text
RAW_STAGE
```

---

# Dimension Tables

## 1. DIM_STORE

Stores retail store information.

| Column | Purpose |
|---|---|
| `STORE_KEY` | Autoincrement surrogate key |
| `STORE_ID` | Business key |
| `STORE_NAME` | Store name |
| `CITY` | Store city |
| `STATE` | Store state |
| `STORE_MANAGER` | Store manager |

### SCD Strategy

`STORE_MANAGER` uses **SCD Type 1**.

Example:

```text
Rajesh Kumar
      ↓
Suresh Menon
```

The old value is overwritten rather than creating a historical row.

---

## 2. DIM_PRODUCT

Stores product information.

| Column | Purpose |
|---|---|
| `PRODUCT_KEY` | Autoincrement surrogate key |
| `PRODUCT_ID` | Business key |
| `PRODUCT_NAME` | Product name |
| `CATEGORY` | Product category |
| `UNIT_PRICE` | Product price |

Initial records: **4**

No SCD strategy is required for products in this project.

---

## 3. DIM_CUSTOMER_HYBRID

This is the main SCD dimension.

| Column | Purpose |
|---|---|
| `CUSTOMER_KEY` | Autoincrement surrogate key |
| `CUSTOMER_ID` | Business key |
| `CUSTOMER_NAME` | Customer name |
| `CITY` | Current city |
| `PREVIOUS_CITY` | Immediate previous city |
| `STATE` | Current state |
| `CURRENT_MEMBERSHIP` | Current membership |
| `PREVIOUS_MEMBERSHIP` | Previous membership |
| `HISTORICAL_MEMBERSHIP` | Historical membership slice |
| `SEGMENT` | Type 2 segment |
| `EFFECTIVE_DATE` | Version start date |
| `EXPIRY_DATE` | Version end date |
| `IS_CURRENT` | Current-row indicator |

---

# SCD Implementation

## SCD Type 1 — Store Manager

Used for:

```text
DIM_STORE.STORE_MANAGER
```

When Store 201 changes:

```text
Before:
Rajesh Kumar

After:
Suresh Menon
```

The existing row is updated.

---

## SCD Type 2 — Customer Segment

Used for:

```text
DIM_CUSTOMER_HYBRID.SEGMENT
```

When a customer segment changes, a new dimension row is created.

Example:

```text
Customer 101

Old:
Regular
2026-01-01 → 2026-03-31
IS_CURRENT = FALSE

New:
Premium
2026-04-01 → 9999-12-31
IS_CURRENT = TRUE
```

This preserves historical segment information.

---

## SCD Type 3 — Customer City

Used for:

```text
CITY
PREVIOUS_CITY
```

Example:

```text
CITY = Bengaluru
PREVIOUS_CITY = Hyderabad
```

This maintains the current city and immediate previous city.

---

## SCD Type 6 — Customer Membership

The membership implementation uses:

```text
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
HISTORICAL_MEMBERSHIP
```

Example for Customer 101:

```text
Current membership    = Gold
Previous membership   = Silver
Historical membership = Silver on old version
Historical membership = Gold on new version
```

This combines current-value tracking with Type 2 historical row versions.

---

# Fact Table

## FACT_SALES

The fact table records sales transactions.

| Column | Purpose |
|---|---|
| `SALES_KEY` | Autoincrement fact surrogate key |
| `TRANSACTION_ID` | Business transaction number |
| `TRANSACTION_DATE` | Sale date |
| `CUSTOMER_KEY` | Customer dimension surrogate key |
| `STORE_KEY` | Store dimension surrogate key |
| `PRODUCT_KEY` | Product dimension surrogate key |
| `QUANTITY` | Quantity sold |
| `UNIT_PRICE` | Price at sale |
| `TOTAL_AMOUNT` | Quantity × Unit Price |

---

# Fact Table Grain

The grain is:

> **One row per individual item line in a sales transaction.**

For example, if one transaction contains three different products, the fact table contains three rows.

This grain must be defined before designing the fact table because it determines what one row represents.

---

# Sales Transactions

## Q1 Transactions

### TXN-1001

```text
Date     : 2026-02-15
Customer : 101
Store    : 201
Product  : 501
Quantity : 1
Amount   : 75000.00
```

### TXN-1002

```text
Date     : 2026-03-10
Customer : 103
Store    : 203
Product  : 502
Quantity : 2
Amount   : 3000.00
```

## Q2 Transaction

### TXN-2001

```text
Date     : 2026-04-15
Customer : 101
Store    : 201
Product  : 503
Quantity : 1
Amount   : 12000.00
```

TXN-2001 uses Customer 101's **new active surrogate key** because the customer update occurred on 2026-04-01.

---

# Point-in-Time Analytics

The project demonstrates that historical facts remain connected to the appropriate customer dimension version.

For Customer 101:

```text
TXN-1001
2026-02-15
Membership = Silver
Segment    = Regular
```

while:

```text
TXN-2001
2026-04-15
Membership = Gold
Segment    = Premium
```

Both transactions show the customer's current city:

```text
CURRENT_CITY = Bengaluru
```

This demonstrates the difference between current profile attributes and historical point-in-time attributes.

---

# Data Loading Flow

```text
CSV Files
    |
    v
RAW_STAGE
    |
    v
CSV_FORMAT
    |
    v
COPY INTO
    |
    +------------------+
    |                  |
    v                  v
Dimensions          Fact Table
```

Explicit column mapping is used when loading CSV files so that Snowflake-generated surrogate-key columns are not incorrectly mapped from source columns.

---

# Project Tasks

The project was completed through 14 tasks:

1. Create warehouse, database, and schema context
2. Create `DIM_STORE`
3. Create `DIM_PRODUCT`
4. Create `DIM_CUSTOMER_HYBRID`
5. Create file format/stage and load Store/Product data
6. Load initial Customer data
7. Create `FACT_SALES`
8. Load Q1 sales
9. Apply Store Manager SCD Type 1 update
10. Apply Customer SCD Type 2/3/6 updates
11. Load Q2 sales
12. Display complete customer history
13. Run point-in-time POS analytics
14. Run final warehouse audit

---

# Final Expected Counts

After completing the project:

```text
Store Dimension Records           = 3
Product Dimension Records         = 4
Customer Dimension Records        = 8
Current Customer Records          = 5
Historical Customer Records       = 3
Fact Sales Records                = 3
```

The customer dimension contains:

```text
5 initial customer rows
+ 3 new Type 2 versions
= 8 total rows
```

There are still only five current customers because each business customer has one active version.

---

# Key Learning Outcomes

By completing Project 12, the following concepts are demonstrated:

- Snowflake database and schema organization
- Snowflake warehouse usage
- Internal stages
- CSV file formats
- `COPY INTO`
- Explicit source-to-target column mapping
- Dimension table design
- Fact table design
- Star schema
- Conformed dimensions
- Business keys
- Surrogate keys
- Fact table grain
- Measures
- Foreign-key relationships
- SCD Type 1
- SCD Type 2
- SCD Type 3
- SCD Type 6 / Hybrid SCD
- Historical versioning
- Current-state tracking
- Point-in-time reporting
- Data auditing

---

# Final Takeaway

Project 12 combines the major dimensional-modeling concepts into one end-to-end Snowflake Data Warehouse.

The most important design idea is that different attributes can require different SCD strategies:

```text
Store Manager
    → SCD Type 1
    → Overwrite

Customer Segment
    → SCD Type 2
    → Historical row versions

Customer City
    → SCD Type 3
    → Current + previous value

Customer Membership
    → SCD Type 6
    → Current + previous + historical slice
```

Together with a clearly defined fact grain and surrogate-key-based fact loading, this design supports both current reporting and historical point-in-time analytics.
