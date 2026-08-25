# Project 8 — Customer Profile History Analysis using Snowflake

## 📌 Project Overview

**Project Name:** Customer Profile History Analysis using Snowflake

**Main Concept:** Slowly Changing Dimension (SCD) — The Problem

This project demonstrates the Slowly Changing Dimension problem in a Snowflake data warehouse.

An online retail company maintains customer information such as:

- City
- State
- Membership
- Customer Segment

These attributes can change over time.

The project demonstrates what happens when changed customer information simply **overwrites the existing dimension record** and how this causes **historical data loss**.

---

## 🎯 Project Objective

The main objective is to:

1. Create a customer dimension in Snowflake.
2. Load initial customer data using a Snowflake stage and `COPY INTO`.
3. Load incoming customer updates into a staging table.
4. Identify customers whose attributes have changed.
5. Identify the exact attributes that changed.
6. Overwrite the existing dimension records.
7. Demonstrate that the previous customer information is no longer available.
8. Understand the business impact of historical data loss.

> This project demonstrates the **SCD problem**. It does not implement an SCD Type 2 solution.

---

## 🏗️ Project Architecture

```text
PROJECT_8
    |
    └── SCD_SCHEMA
          |
          ├── DIM_CUSTOMER
          |
          ├── CUSTOMER_UPDATES
          |
          ├── CUSTOMER_STAGE
          |
          └── CUSTOMER_UPDATE_STAGE
```

### Data Flow

```text
customers_initial.csv
        |
        v
CUSTOMER_STAGE
        |
        v
   COPY INTO
        |
        v
 DIM_CUSTOMER
        |
        | Compare
        v
CUSTOMER_UPDATES
        ^
        |
CUSTOMER_UPDATE_STAGE
        ^
        |
customer_updates.csv
```

---

## 📂 Input Files

### 1. `customers_initial.csv`

Initial customer information:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---|---|---|---|---|---|
| 101 | Amit Sharma | Hyderabad | Telangana | Silver | Regular |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Vijayawada | Andhra Pradesh | Silver | Regular |
| 104 | Neha Patel | Hyderabad | Telangana | Gold | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

### 2. `customer_updates.csv`

Incoming customer changes:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---|---|---|---|---|---|
| 101 | Amit Sharma | Bengaluru | Karnataka | Gold | Premium |
| 103 | Rahul Verma | Chennai | Tamil Nadu | Gold | Premium |
| 104 | Neha Patel | Hyderabad | Telangana | Platinum | Premium |

---

## 🗄️ Snowflake Objects

### Database

```text
PROJECT_8
```

### Schema

```text
SCD_SCHEMA
```

### Tables

```text
DIM_CUSTOMER
CUSTOMER_UPDATES
```

### Stages

```text
CUSTOMER_STAGE
CUSTOMER_UPDATE_STAGE
```

---

## 📊 DIM_CUSTOMER

The main customer dimension contains:

| Column | Description |
|---|---|
| `CUSTOMER_KEY` | Warehouse surrogate key |
| `CUSTOMER_ID` | Source/business customer identifier |
| `CUSTOMER_NAME` | Customer name |
| `CITY` | Customer city |
| `STATE` | Customer state |
| `MEMBERSHIP` | Customer membership |
| `SEGMENT` | Customer segment |

`CUSTOMER_KEY` is generated using:

```sql
CUSTOMER_KEY NUMBER AUTOINCREMENT
```

---

# 📋 Project Tasks

## Task 1 — Create Database and Schema

Create:

```text
PROJECT_8
    └── SCD_SCHEMA
```

SQL:

```sql
CREATE OR REPLACE DATABASE PROJECT_8;

CREATE OR REPLACE SCHEMA PROJECT_8.SCD_SCHEMA;

USE DATABASE PROJECT_8;
USE SCHEMA SCD_SCHEMA;
```

---

## Task 2 — Create Initial Customer Dimension

Create `DIM_CUSTOMER`:

```sql
CREATE OR REPLACE TABLE DIM_CUSTOMER
(
    CUSTOMER_KEY NUMBER AUTOINCREMENT,
    CUSTOMER_ID NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    MEMBERSHIP VARCHAR(50),
    SEGMENT VARCHAR(50)
);
```

---

## Task 3 — Load Initial Customer Data

Create the stage:

```sql
CREATE OR REPLACE STAGE CUSTOMER_STAGE;
```

Upload:

```text
customers_initial.csv
```

Then load it:

```sql
COPY INTO DIM_CUSTOMER
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT
)
FROM @CUSTOMER_STAGE
FILE_FORMAT = (
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
);
```

Expected:

```text
Total Customers = 5
```

---

## Task 4 — Display Initial Customer Dimension

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT
FROM DIM_CUSTOMER
ORDER BY CUSTOMER_ID;
```

Initial state:

```text
101 → Hyderabad → Telangana → Silver
102 → Warangal  → Telangana → Gold
103 → Vijayawada → Andhra Pradesh → Silver
104 → Hyderabad → Telangana → Gold
105 → Nagpur → Maharashtra → Bronze
```

---

## Task 5 — Load Customer Updates

Create the update table:

```sql
CREATE OR REPLACE TABLE CUSTOMER_UPDATES
(
    CUSTOMER_ID NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    MEMBERSHIP VARCHAR(50),
    SEGMENT VARCHAR(50)
);
```

Create the stage:

```sql
CREATE OR REPLACE STAGE CUSTOMER_UPDATE_STAGE;
```

Upload:

```text
customer_updates.csv
```

Load:

```sql
COPY INTO CUSTOMER_UPDATES
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT
)
FROM @CUSTOMER_UPDATE_STAGE
FILE_FORMAT = (
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
);
```

Expected:

```text
Records Received = 3
```

---

## Task 6 — Identify Changed Customers

Compare the existing dimension with the update table:

```sql
SELECT
    d.CUSTOMER_ID,
    d.CITY AS OLD_CITY,
    u.CITY AS NEW_CITY,
    d.MEMBERSHIP AS OLD_MEMBERSHIP,
    u.MEMBERSHIP AS NEW_MEMBERSHIP
FROM DIM_CUSTOMER d
INNER JOIN CUSTOMER_UPDATES u
    ON d.CUSTOMER_ID = u.CUSTOMER_ID
WHERE
       d.CITY <> u.CITY
    OR d.STATE <> u.STATE
    OR d.MEMBERSHIP <> u.MEMBERSHIP
    OR d.SEGMENT <> u.SEGMENT
ORDER BY d.CUSTOMER_ID;
```

Expected changed customers:

```text
101 → Hyderabad → Bengaluru → Silver → Gold
103 → Vijayawada → Chennai → Silver → Gold
104 → Hyderabad → Hyderabad → Gold → Platinum
```

---

## Task 7 — Identify Attribute Changes

Produce a detailed change report showing:

```text
CUSTOMER_ID
ATTRIBUTE
OLD_VALUE
NEW_VALUE
```

Expected changes:

```text
101 → CITY       → Hyderabad       → Bengaluru
101 → STATE      → Telangana       → Karnataka
101 → MEMBERSHIP → Silver          → Gold

103 → CITY       → Vijayawada      → Chennai
103 → STATE      → Andhra Pradesh  → Tamil Nadu
103 → MEMBERSHIP → Silver          → Gold

104 → MEMBERSHIP → Gold            → Platinum
```

This demonstrates that different dimension attributes can change independently.

---

## Task 8 — Demonstrate the SCD Problem

The existing dimension records are intentionally overwritten:

```sql
UPDATE DIM_CUSTOMER d
SET
    CUSTOMER_NAME = u.CUSTOMER_NAME,
    CITY          = u.CITY,
    STATE         = u.STATE,
    MEMBERSHIP    = u.MEMBERSHIP,
    SEGMENT       = u.SEGMENT
FROM CUSTOMER_UPDATES u
WHERE d.CUSTOMER_ID = u.CUSTOMER_ID;
```

Three customer records are updated:

```text
101
103
104
```

The old values are replaced by the new values.

---

## Task 9 — Display Updated Dimension

After the overwrite, the dimension contains:

```text
101 → Bengaluru → Karnataka → Gold
102 → Warangal  → Telangana → Gold
103 → Chennai   → Tamil Nadu → Gold
104 → Hyderabad → Telangana → Platinum
105 → Nagpur    → Maharashtra → Bronze
```

The table now represents the latest customer information.

---

## Task 10 — Demonstrate Historical Data Loss

Query Customer 101:

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP
FROM DIM_CUSTOMER
WHERE CUSTOMER_ID = 101;
```

Current result:

```text
101 → Amit Sharma → Bengaluru → Karnataka → Gold
```

Original values were:

```text
City       → Hyderabad
State      → Telangana
Membership → Silver
```

The original values are no longer available in the current dimension row.

Therefore, the current `DIM_CUSTOMER` cannot tell us where Customer 101 lived before the update.

---

## Task 11 — Business Impact Analysis

### Customer 101

**Original:**

```text
City       → Hyderabad
State      → Telangana
Membership → Silver
```

**Current:**

```text
City       → Bengaluru
State      → Karnataka
Membership → Gold
```

### Historical information lost

```text
Historical City       → LOST
Historical State      → LOST
Historical Membership → LOST
```

This means the company cannot perform historical customer analysis using the current dimension alone.

---

# 🧠 Key Concepts Learned

## 1. Slowly Changing Dimension

Customer dimension attributes can change over time.

Examples:

```text
Hyderabad → Bengaluru
Silver → Gold
Gold → Platinum
```

These changes need to be handled appropriately when historical analysis is required.

## 2. Business Key

`CUSTOMER_ID` represents the source/business identifier.

Example:

```text
CUSTOMER_ID = 101
```

It continues to identify the same customer even after the customer's attributes change.

## 3. Surrogate Key

`CUSTOMER_KEY` is the warehouse-generated key.

```sql
CUSTOMER_KEY NUMBER AUTOINCREMENT
```

It is different from the source `CUSTOMER_ID`.

## 4. Overwrite Problem

If an existing dimension record is simply updated:

```text
OLD VALUE
    ↓
UPDATE
    ↓
NEW VALUE
```

the old value is no longer available in the current dimension.

## 5. Historical Data Loss

The project demonstrates that overwriting customer attributes causes historical information to disappear.

For Customer 101:

```text
Hyderabad → Bengaluru
Telangana → Karnataka
Silver → Gold
```

Only the latest values remain.

---

# 🔍 Before vs After

## Before Update

```text
101 → Hyderabad → Telangana → Silver
103 → Vijayawada → Andhra Pradesh → Silver
104 → Hyderabad → Telangana → Gold
```

## After Update

```text
101 → Bengaluru → Karnataka → Gold
103 → Chennai → Tamil Nadu → Gold
104 → Hyderabad → Telangana → Platinum
```

## Problem

```text
Previous versions are no longer stored.
```

---

# 📈 Project Learning Flow

```text
Create Database & Schema
          ↓
Create Customer Dimension
          ↓
Load Initial Customer Data
          ↓
Load Customer Updates
          ↓
Compare Existing vs New Data
          ↓
Identify Changed Customers
          ↓
Identify Attribute Changes
          ↓
Overwrite Existing Dimension
          ↓
Historical Data Gets Lost
          ↓
Understand the SCD Problem
```

---

# 🏁 Final Conclusion

Project 8 demonstrates the fundamental problem of managing changing dimension attributes.

The current design stores one row per customer. When a customer changes, the existing row is overwritten.

For example:

```text
Customer 101

OLD
Hyderabad | Telangana | Silver

        ↓ UPDATE

NEW
Bengaluru | Karnataka | Gold
```

After the update, the current dimension contains only the new values.

Therefore:

```text
Historical City       → LOST
Historical State      → LOST
Historical Membership → LOST
```

This demonstrates why a data warehouse needs an appropriate **Slowly Changing Dimension strategy** when historical customer information must be preserved.

---

# 📁 Documentation

Detailed task-by-task explanations and SQL are available in:

```text
explanation.md
```

---

# ✅ Project Status

```text
Project 8 — COMPLETED
```

All 11 tasks from the supplied project requirements have been completed.
