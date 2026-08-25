# Project 11 — Enterprise Customer Master Data Management using Hybrid SCD Strategies

## Overview

Project 11 implements an **Enterprise Customer Master Data Management** solution in **Snowflake SQL** using a unified **Hybrid Slowly Changing Dimension (SCD)** strategy.

The project demonstrates how different customer attributes can use different SCD behaviors within the same customer dimension.

### Attribute Strategies

| Attribute | Strategy |
|---|---|
| `STATE` | Type 1 / overwrite |
| `CITY` | Current value + immediate previous value |
| `SEGMENT` | Historical tracking / Type 2 |
| `MEMBERSHIP` | Current + previous + historical value |

The final dimension contains both current and historical customer versions and supports point-in-time reporting.

---

## Business Scenario

The initial customer data contains five customers:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---:|---|---|---|---|---|
| 101 | Amit Sharma | Hyderabad | Telangana | Silver | Regular |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Vijayawada | Andhra Pradesh | Silver | Regular |
| 104 | Neha Patel | Hyderabad | Telangana | Gold | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

Later, the following changes arrive:

- Customer 101: Hyderabad/Telangana → Bengaluru/Karnataka, Silver → Gold, Regular → Premium, effective `2026-04-01`.
- Customer 103: Vijayawada/Andhra Pradesh → Chennai/Tamil Nadu, Silver → Gold, Regular → Premium, effective `2026-04-05`.
- Customer 104: Gold → Platinum, effective `2026-04-10`.

---

## Technology

- Snowflake
- Snowflake SQL
- CSV
- Snowflake internal stage
- Snowflake file format
- `COPY INTO`
- Hybrid SCD dimension

---

## Project Structure

```text
Project-11/
│
├── Project_11.md
├── Project_11_Snowflake.sql
├── EXPLANATION.md
├── README.md
│
├── customers_initial.csv
└── customer_updates.csv
```

> File and folder names may differ depending on the local project organization.

---

## Architecture

```text
customers_initial.csv
customer_updates.csv
        |
        v
    RAW_STAGE
        |
        v
    CSV_FORMAT
        |
        v
   COPY INTO / SQL
        |
        v
DIM_CUSTOMER_HYBRID
        |
        +--------------------+
        |                    |
        v                    v
Current Reporting      Historical Reporting
```

---

# Implementation Tasks

## Task 1 — Create Database and Schema

Create the Snowflake warehouse, database, and schema:

```text
Warehouse: SCD_HYBRID_WH
Database:  SCD_HYBRID_DB
Schema:    SCD_HYBRID_SCHEMA
```

The warehouse is configured as an `XSMALL` warehouse with auto-resume and auto-suspend.

---

## Task 2 — Create Hybrid Dimension

The main dimension table is:

```text
DIM_CUSTOMER_HYBRID
```

### Columns

| Column | Purpose |
|---|---|
| `CUSTOMER_KEY` | Surrogate key |
| `CUSTOMER_ID` | Natural/business key |
| `CUSTOMER_NAME` | Customer name |
| `CITY` | Current city |
| `PREVIOUS_CITY` | Immediate previous city |
| `STATE` | Current state |
| `CURRENT_MEMBERSHIP` | Latest membership |
| `PREVIOUS_MEMBERSHIP` | Immediately previous membership |
| `HISTORICAL_MEMBERSHIP` | Membership for the specific row version |
| `SEGMENT` | Historical segment |
| `EFFECTIVE_DATE` | Start date of the version |
| `EXPIRY_DATE` | End date of the version |
| `IS_CURRENT` | Current-version indicator |

---

## Task 3 — File Format and Stage

Create a CSV file format:

```text
CSV_FORMAT
```

The format handles comma-separated files and skips the header row.

Create the internal stage:

```text
RAW_STAGE
```

Upload:

```text
customers_initial.csv
customer_updates.csv
```

to the stage.

---

## Task 4 — Initial Dimension Load

Load `customers_initial.csv`.

For the initial records:

```text
PREVIOUS_CITY          = NULL
CURRENT_MEMBERSHIP     = initial membership
PREVIOUS_MEMBERSHIP    = NULL
HISTORICAL_MEMBERSHIP  = initial membership
EFFECTIVE_DATE         = 2026-01-01
EXPIRY_DATE            = 9999-12-31
IS_CURRENT             = TRUE
```

Initial validation:

```text
Total Records       = 5
Current Records     = 5
Historical Records  = 0
```

---

## Task 5 — Apply Hybrid Updates

Updates are processed for Customers:

```text
101
103
104
```

### Step 1 — Expire Existing Versions

The existing current records are expired.

Example:

```text
Customer 101
2026-01-01 → 2026-03-31
IS_CURRENT = FALSE
```

### Step 2 — Insert New Versions

New active records are inserted with:

```text
IS_CURRENT = TRUE
EXPIRY_DATE = 9999-12-31
```

### Step 3 — Synchronize Global Attributes

The following attributes are synchronized across the customer's versions:

```text
CITY
PREVIOUS_CITY
STATE
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
```

The following remain version-specific:

```text
HISTORICAL_MEMBERSHIP
SEGMENT
```

---

## Understanding the Hybrid Membership Logic

For Customer 101:

### Historical version

```text
HISTORICAL_MEMBERSHIP = Silver
SEGMENT               = Regular
```

### Current version

```text
HISTORICAL_MEMBERSHIP = Gold
SEGMENT               = Premium
```

But both versions contain:

```text
CURRENT_MEMBERSHIP  = Gold
PREVIOUS_MEMBERSHIP = Silver
```

This allows the dimension to answer:

```text
What is the customer's current membership?
        -> CURRENT_MEMBERSHIP

What was the immediately previous membership?
        -> PREVIOUS_MEMBERSHIP

What membership belonged to this historical period?
        -> HISTORICAL_MEMBERSHIP
```

---

# Final Dimension State

After all updates:

```text
Customer 101 -> 2 rows
Customer 102 -> 1 row
Customer 103 -> 2 rows
Customer 104 -> 2 rows
Customer 105 -> 1 row
```

Therefore:

```text
TOTAL RECORDS       = 8
CURRENT RECORDS     = 5
HISTORICAL RECORDS  = 3
```

---

## Task 6 — Complete Dimension History

Display all records ordered by customer and effective date.

The historical versions for the updated customers are:

```text
101 -> 2026-01-01 to 2026-03-31
103 -> 2026-01-01 to 2026-04-04
104 -> 2026-01-01 to 2026-04-09
```

The current versions begin on:

```text
101 -> 2026-04-01
103 -> 2026-04-05
104 -> 2026-04-10
```

---

## Task 7 — Active Customer Report

The active report filters using:

```sql
WHERE IS_CURRENT = TRUE
```

Expected current memberships:

```text
101 -> Gold
102 -> Gold
103 -> Gold
104 -> Platinum
105 -> Bronze
```

This report represents the current state of all five customers.

---

## Task 8 — Point-in-Time Historical Query

The project asks:

> What was Customer 101's historical membership, segment, and city on March 15, 2026?

The point-in-time condition is:

```sql
EFFECTIVE_DATE <= requested_date
AND EXPIRY_DATE >= requested_date
```

Expected result:

```text
CUSTOMER_ID            = 101
CUSTOMER_NAME          = Amit Sharma
CITY                   = Bengaluru
HISTORICAL_MEMBERSHIP  = Silver
SEGMENT                = Regular
EFFECTIVE_DATE         = 2026-01-01
EXPIRY_DATE            = 2026-03-31
```

---

## Task 9 — Metric Validation

Final validation query should confirm:

```text
TOTAL RECORD COUNT       = 8
CURRENT RECORD COUNT     = 5
HISTORICAL RECORD COUNT  = 3
```

---

# Key Concepts

### Type 1 Behavior

`STATE` is overwritten when it changes.

```text
Telangana -> Karnataka
```

The old state is not maintained as a separate historical value.

### Type 3 / Prior-Value Behavior

`CITY` maintains:

```text
CITY
PREVIOUS_CITY
```

Example:

```text
CITY          = Bengaluru
PREVIOUS_CITY = Hyderabad
```

### Type 2 Behavior

`SEGMENT` is preserved by row version.

Example:

```text
Old version -> Regular
New version -> Premium
```

### Hybrid Membership Behavior

Membership combines:

```text
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
HISTORICAL_MEMBERSHIP
```

This provides current, immediate-prior, and point-in-time historical membership information.

---

# Expected Final Result

```text
+--------------------------+-------+
| Metric                   | Value |
+--------------------------+-------+
| Total Record Count       | 8     |
| Current Record Count     | 5     |
| Historical Record Count  | 3     |
+--------------------------+-------+
```

---

# Learning Outcome

After completing Project 11, you should be able to:

- Create Snowflake databases, schemas, stages, and file formats.
- Load CSV data into Snowflake.
- Design a hybrid customer dimension.
- Implement Type 1 attribute behavior.
- Implement Type 2 historical versioning.
- Maintain current and previous attribute values.
- Maintain historical membership by row version.
- Use effective and expiry dates.
- Identify current records with `IS_CURRENT`.
- Perform point-in-time historical queries.
- Validate SCD results using record counts.

---

## Project Status

**Project 11 — Completed**

```text
Tasks Completed: 1–9
Total Records: 8
Current Records: 5
Historical Records: 3
```

The project demonstrates a complete enterprise-style Hybrid SCD implementation for customer master data management in Snowflake.
