# Project 12 — Enterprise Retail Analytics Data Warehouse

## 1. Project Overview

Project 12 is an end-to-end Snowflake Data Warehouse implementation for an omnichannel retail company.

The project applies Kimball dimensional modeling concepts and combines multiple Slowly Changing Dimension (SCD) techniques in a single customer dimension.

### Technology

- Snowflake SQL
- Kimball dimensional modeling
- CSV source files
- Snowflake internal stage
- Snowflake file format
- Fact and dimension tables
- SCD Type 1, Type 2, Type 3, and Type 6

### Main Business Requirement

Leadership needs daily sales and customer loyalty reporting from a centralized Snowflake Data Warehouse.

The warehouse must support:

1. One row per individual sales line item in the fact table.
2. Conformed Store and Customer dimensions.
3. Store Manager managed as SCD Type 1.
4. Customer Segment managed as SCD Type 2.
5. Customer City managed using Type 3 previous-value tracking.
6. Customer Membership managed using a hybrid Type 6 design.

---

# 2. Business Scenario

The project is divided into two phases.

## Phase 1 — Initial Load

During Q1 2026:

- 3 stores are registered.
- 4 products are added.
- 5 initial customers are loaded.
- Two sales transactions occur:
  - TXN-1001
  - TXN-1002

## Phase 2 — Master Data Updates

During Q2 2026:

- Store 201 changes its manager from Rajesh Kumar to Suresh Menon.
- Customer 101:
  - Hyderabad → Bengaluru
  - Regular → Premium
  - Silver → Gold
  - Effective date: 2026-04-01
- Customer 103:
  - Vijayawada → Chennai
  - Regular → Premium
  - Silver → Gold
  - Effective date: 2026-04-05
- Customer 104:
  - Membership changes from Gold → Platinum
  - Effective date: 2026-04-10
- A post-update sale occurs:
  - TXN-2001

---

# 3. Source Files

The project uses four CSV source datasets.

## stores.csv

Contains:

- store_id
- store_name
- city
- state
- store_manager

There are 3 stores.

## products.csv

Contains:

- product_id
- product_name
- category
- unit_price

There are 4 products.

## customers_initial.csv

Contains:

- customer_id
- customer_name
- city
- state
- membership
- segment

There are 5 initial customers.

## customer_updates.csv

Contains:

- customer_id
- customer_name
- city
- state
- membership
- segment
- effective_date

There are 3 customer updates.

---

# 4. Snowflake Architecture

The project uses the following structure:

```text
RETAIL_DW
└── SALES_ANALYTICS
    ├── DIM_STORE
    ├── DIM_PRODUCT
    ├── DIM_CUSTOMER_HYBRID
    └── FACT_SALES
```

A dedicated XSMALL warehouse is used for project compute:

```text
RETAIL_DW_WH
```

The warehouse provides compute resources. It does not store the dimension and fact data.

The database stores the project objects, while the schema organizes the tables.

---

# 5. File Format and Stage

The project uses a Snowflake CSV file format:

```sql
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE;
```

An internal stage is created:

```sql
CREATE OR REPLACE STAGE RAW_STAGE
FILE_FORMAT = CSV_FORMAT;
```

The source files are uploaded to the stage and then loaded into the warehouse using `COPY INTO`.

The important loading pattern is explicit column mapping.

For example, `DIM_STORE` contains six columns because `STORE_KEY` is a Snowflake-generated surrogate key, while the CSV contains only five source columns.

Therefore the load explicitly lists the target columns and leaves `STORE_KEY` to Snowflake.

---

# 6. Dimension Modeling

## 6.1 DIM_STORE

`DIM_STORE` is the Store conformed dimension.

Important columns:

- STORE_KEY — surrogate key
- STORE_ID — business key
- STORE_NAME
- CITY
- STATE
- STORE_MANAGER

`STORE_KEY` is an autoincrementing primary key.

The Store Manager is managed using SCD Type 1.

### Type 1 behavior

Initially:

```text
Store 201
Manager = Rajesh Kumar
```

After the update:

```text
Store 201
Manager = Suresh Menon
```

The old manager value is overwritten.

No historical Store Manager row is created.

---

# 7. DIM_PRODUCT

`DIM_PRODUCT` stores product information.

Columns:

- PRODUCT_KEY
- PRODUCT_ID
- PRODUCT_NAME
- CATEGORY
- UNIT_PRICE

`PRODUCT_KEY` is the surrogate key.

`PRODUCT_ID` is the source/business key.

The project does not specify an SCD strategy for products, so this dimension is loaded as a normal product dimension.

---

# 8. DIM_CUSTOMER_HYBRID

This is the most important dimension in the project.

It is designed to support multiple SCD techniques at the same time.

Columns:

- CUSTOMER_KEY
- CUSTOMER_ID
- CUSTOMER_NAME
- CITY
- PREVIOUS_CITY
- STATE
- CURRENT_MEMBERSHIP
- PREVIOUS_MEMBERSHIP
- HISTORICAL_MEMBERSHIP
- SEGMENT
- EFFECTIVE_DATE
- EXPIRY_DATE
- IS_CURRENT

---

# 9. SCD Type 2 — Customer Segment

Customer Segment is maintained using Type 2 row versioning.

Example for Customer 101:

Initial version:

```text
CUSTOMER_ID = 101
SEGMENT = Regular
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE = 2026-03-31
IS_CURRENT = FALSE
```

New version:

```text
CUSTOMER_ID = 101
SEGMENT = Premium
EFFECTIVE_DATE = 2026-04-01
EXPIRY_DATE = 9999-12-31
IS_CURRENT = TRUE
```

A new surrogate key is generated for the new version.

This allows historical facts to continue pointing to the older customer version.

---

# 10. SCD Type 3 — Customer City

Customer City uses immediate previous-value tracking.

For Customer 101:

Before the update:

```text
CITY = Hyderabad
PREVIOUS_CITY = NULL
```

After the update:

```text
CITY = Bengaluru
PREVIOUS_CITY = Hyderabad
```

This provides the current city and the immediate previous city without maintaining an unlimited city history.

---

# 11. SCD Type 6 — Customer Membership

Membership uses the hybrid columns:

- CURRENT_MEMBERSHIP
- PREVIOUS_MEMBERSHIP
- HISTORICAL_MEMBERSHIP

For Customer 101 after the update:

```text
CURRENT_MEMBERSHIP = Gold
PREVIOUS_MEMBERSHIP = Silver
```

The historical slice is represented by `HISTORICAL_MEMBERSHIP`.

The old Type 2 row retains:

```text
HISTORICAL_MEMBERSHIP = Silver
```

The new Type 2 row contains:

```text
HISTORICAL_MEMBERSHIP = Gold
```

This allows point-in-time analysis to determine the membership associated with a transaction.

---

# 12. Why the Customer Dimension Is Hybrid

The same customer can have different requirements:

```text
Current city?
→ CITY

Previous city?
→ PREVIOUS_CITY

Current membership?
→ CURRENT_MEMBERSHIP

Previous membership?
→ PREVIOUS_MEMBERSHIP

Membership at historical point in time?
→ HISTORICAL_MEMBERSHIP

Historical segment?
→ SEGMENT on the appropriate Type 2 row
```

Therefore one SCD technique alone is not sufficient.

The hybrid dimension combines the required behaviors.

---

# 13. FACT_SALES

The fact table is:

```text
FACT_SALES
```

Columns:

- SALES_KEY
- TRANSACTION_ID
- TRANSACTION_DATE
- CUSTOMER_KEY
- STORE_KEY
- PRODUCT_KEY
- QUANTITY
- UNIT_PRICE
- TOTAL_AMOUNT

The fact table contains foreign keys to:

- DIM_CUSTOMER_HYBRID
- DIM_STORE
- DIM_PRODUCT

---

# 14. Fact Table Grain

The grain is:

> Exactly one row per individual item line in a sales transaction.

This is one of the most important design decisions in the project.

If a transaction contains three different products, the fact table should contain three rows.

For example:

```text
TXN-5001 | Product A | 1
TXN-5001 | Product B | 2
TXN-5001 | Product C | 1
```

The transaction number is repeated because the grain is the line item, not the entire transaction.

---

# 15. Surrogate Keys in the Fact Table

The fact table stores dimension surrogate keys:

```text
CUSTOMER_KEY
STORE_KEY
PRODUCT_KEY
```

It does not depend on the business IDs for dimensional relationships.

The surrogate key is looked up dynamically during fact loading.

For example:

```text
CUSTOMER_ID = 101
        ↓
DIM_CUSTOMER_HYBRID
        ↓
CUSTOMER_KEY
        ↓
FACT_SALES
```

This is particularly important for SCD Type 2 because the same business customer can have multiple surrogate-key versions.

---

# 16. Q1 Sales

Two initial transactions were loaded.

## TXN-1001

```text
Date: 2026-02-15
Customer: 101
Store: 201
Product: 501
Quantity: 1
Unit Price: 75000.00
Total: 75000.00
```

## TXN-1002

```text
Date: 2026-03-10
Customer: 103
Store: 203
Product: 502
Quantity: 2
Unit Price: 1500.00
Total: 3000.00
```

The dimension surrogate keys were obtained through joins rather than manually hard-coded.

---

# 17. Store SCD Type 1 Update

Store 201's manager changes:

```text
Rajesh Kumar
        ↓
Suresh Menon
```

The update is:

```sql
UPDATE DIM_STORE
SET STORE_MANAGER = 'Suresh Menon'
WHERE STORE_ID = 201;
```

The dimension retains one Store 201 row.

The previous manager is not preserved.

---

# 18. Customer SCD Processing

The customer update process consists of three logical stages.

## Stage 1 — Expire the old active rows

For each changed customer:

```text
EXPIRY_DATE = effective_date - 1 day
IS_CURRENT = FALSE
```

Therefore:

```text
101 → 2026-03-31
103 → 2026-04-04
104 → 2026-04-09
```

## Stage 2 — Insert new active versions

New rows are inserted with:

```text
IS_CURRENT = TRUE
EXPIRY_DATE = 9999-12-31
```

New surrogate keys are automatically generated.

## Stage 3 — Synchronize current profile attributes

The current profile values are synchronized across affected historical rows for:

- CITY
- PREVIOUS_CITY
- STATE
- CURRENT_MEMBERSHIP
- PREVIOUS_MEMBERSHIP

The historical values needed for Type 2/Type 6 analysis remain preserved in:

- HISTORICAL_MEMBERSHIP
- SEGMENT
- EFFECTIVE_DATE
- EXPIRY_DATE
- IS_CURRENT

---

# 19. Q2 Sales and SCD Type 2

`TXN-2001` occurs on:

```text
2026-04-15
```

Customer 101 has already changed from:

```text
Regular / Silver
```

to:

```text
Premium / Gold
```

Therefore the fact must use Customer 101's **new active CUSTOMER_KEY**.

The transaction is:

```text
TXN-2001
Customer = 101
Store = 201
Product = 503
Quantity = 1
Unit Price = 12000.00
Total = 12000.00
```

This demonstrates why the fact table stores the SCD surrogate key.

---

# 20. Historical Fact Behavior

After the customer update, the two Customer 101 transactions point to different customer dimension versions.

Conceptually:

```text
TXN-1001
2026-02-15
        ↓
OLD CUSTOMER_KEY
        ↓
Silver / Regular
```

and:

```text
TXN-2001
2026-04-15
        ↓
NEW CUSTOMER_KEY
        ↓
Gold / Premium
```

The old fact is not updated.

This preserves the customer's state associated with the historical transaction.

---

# 21. Point-in-Time Analytics

The project uses a join between:

- FACT_SALES
- DIM_CUSTOMER_HYBRID
- DIM_STORE
- DIM_PRODUCT

For Customer 101, the final analytical result demonstrates:

```text
TXN-1001
2026-02-15
Current City = Bengaluru
Membership at Purchase = Silver
Segment at Purchase = Regular
Product = Laptop Pro
Total = 75000.00
```

and:

```text
TXN-2001
2026-04-15
Current City = Bengaluru
Membership at Purchase = Gold
Segment at Purchase = Premium
Product = Ergonomic Chair
Total = 12000.00
```

The city is current because the hybrid dimension synchronizes the current profile.

Membership and segment are historical because the fact points to the appropriate customer dimension version.

---

# 22. Final Audit

The final `UNION ALL` audit checks:

```text
STORE DIMENSION RECORDS
PRODUCT DIMENSION RECORDS
TOTAL CUSTOMER DIMENSION RECORDS
CURRENT CUSTOMER RECORDS
HISTORICAL CUSTOMER RECORDS
FACT SALES TRANSACTIONS
```

Expected final counts:

```text
STORE DIMENSION RECORDS           3
PRODUCT DIMENSION RECORDS         4
TOTAL CUSTOMER DIMENSION RECORDS  8
CURRENT CUSTOMER RECORDS          5
HISTORICAL CUSTOMER RECORDS       3
FACT SALES TRANSACTIONS           3
```

The customer count is:

```text
5 initial customer rows
+ 3 new Type 2 versions
= 8 total customer dimension rows
```

There are still only five current customers because each business customer has exactly one active row.

---

# 23. Final Data Warehouse Structure

```text
                         RETAIL_DW
                             |
                     SALES_ANALYTICS
                             |
        +--------------------+--------------------+
        |                    |                    |
        v                    v                    v
   DIM_STORE          DIM_PRODUCT       DIM_CUSTOMER_HYBRID
    3 rows               4 rows                8 rows
        |                    |                    |
        |                    |                    |
        +--------------------+--------------------+
                             |
                             v
                        FACT_SALES
                          3 rows
```

The fact table connects to the dimensions using surrogate keys.

---

# 24. What Was Learned in Project 12

## Kimball Dimensional Modeling

The project demonstrates the basic star-schema pattern:

```text
Dimensions
    ↓
Fact Table
```

Dimensions provide descriptive context, while the fact table stores measurable business events.

## Fact Grain

The fact grain must be explicitly defined before designing the fact table.

Here:

```text
One row = One individual sales line item
```

## Conformed Dimensions

`DIM_STORE` and `DIM_CUSTOMER_HYBRID` are reusable dimensions that can support multiple business subjects.

## Surrogate Keys

Surrogate keys provide stable warehouse identifiers and allow multiple historical versions of the same business entity.

## SCD Type 1

Overwrites the old attribute.

Used for:

```text
Store Manager
```

## SCD Type 2

Creates a new row version and tracks:

- Effective date
- Expiry date
- Current indicator

Used for:

```text
Customer Segment
```

## SCD Type 3

Stores the current value and immediate previous value.

Used for:

```text
Customer City
```

## SCD Type 6

Combines Type 1, Type 2, and Type 3-style behavior.

Used for:

```text
Customer Membership
```

through:

```text
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
HISTORICAL_MEMBERSHIP
```

---

# 25. Project 12 Completion Checklist

- [x] Created project warehouse
- [x] Created `RETAIL_DW`
- [x] Created `SALES_ANALYTICS`
- [x] Created CSV file format
- [x] Created internal stage
- [x] Created `DIM_STORE`
- [x] Created `DIM_PRODUCT`
- [x] Created `DIM_CUSTOMER_HYBRID`
- [x] Loaded initial stores
- [x] Loaded initial products
- [x] Loaded initial customers
- [x] Created `FACT_SALES`
- [x] Established line-item grain
- [x] Loaded Q1 transactions
- [x] Applied Store SCD Type 1
- [x] Applied Customer SCD Type 2
- [x] Applied Customer SCD Type 3
- [x] Applied Customer SCD Type 6
- [x] Loaded Q2 transaction
- [x] Verified historical customer versions
- [x] Performed point-in-time analytics
- [x] Performed final record-count audit

---

# 26. Final Takeaway

Project 12 brings together the concepts from the earlier projects into one complete Snowflake Data Warehouse.

The central idea is that **different business attributes can require different historical-management strategies**.

```text
Store Manager
    → Type 1
    → overwrite

Customer Segment
    → Type 2
    → create historical row versions

Customer City
    → Type 3
    → current + previous value

Customer Membership
    → Type 6
    → current + previous + historical slice
```

The combination of these strategies inside `DIM_CUSTOMER_HYBRID`, together with surrogate-key-based fact loading and a clearly defined fact grain, allows the warehouse to answer both current-state and historical point-in-time reporting requirements.
