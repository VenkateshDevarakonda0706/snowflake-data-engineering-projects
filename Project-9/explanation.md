# Project 9 — Customer History Management using SCD Type 1 and Type 2

## 1. Project Overview

Project 9 demonstrates how an online retail company can manage changing customer information in a Snowflake Data Warehouse using two Slowly Changing Dimension strategies:

- **SCD Type 1** — overwrite changed values and do not preserve the old value.
- **SCD Type 2** — preserve the complete history by expiring the old record and inserting a new version.

The project uses customer attributes such as city, state, membership, and segment.

## 2. Business Scenario

Initial customers:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---:|---|---|---|---|---|
| 101 | Amit Sharma | Hyderabad | Telangana | Silver | Regular |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Vijayawada | Andhra Pradesh | Silver | Regular |
| 104 | Neha Patel | Hyderabad | Telangana | Gold | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

Later changes:

| Customer ID | Change |
|---:|---|
| 101 | Hyderabad → Bengaluru, Silver → Gold |
| 103 | Vijayawada → Chennai, Silver → Gold |
| 104 | Gold → Platinum |

## 3. Input Files

### customers_initial.csv

Contains the original five customer records.

Columns:

```text
customer_id
customer_name
city
state
membership
segment
```

### customer_updates.csv

Contains the changed customer records.

Columns:

```text
customer_id
customer_name
city
state
membership
segment
effective_date
```

## 4. Snowflake Objects

Database and schema:

```text
PROJECT_9_DB
└── CUSTOMER_HISTORY
```

Main tables:

```text
DIM_CUSTOMER_TYPE1
DIM_CUSTOMER_TYPE2
CUSTOMER_UPDATES
```

A CSV file format and internal stage are used for loading the input files.

## 5. Task 1 — Create Database and Schema

```sql
CREATE OR REPLACE DATABASE PROJECT_9_DB;

CREATE OR REPLACE SCHEMA PROJECT_9_DB.CUSTOMER_HISTORY;

USE DATABASE PROJECT_9_DB;

USE SCHEMA CUSTOMER_HISTORY;
```

## 6. Task 2 — Create SCD Type 1 Table

Columns:

| Column | Purpose |
|---|---|
| CUSTOMER_KEY | Surrogate key |
| CUSTOMER_ID | Natural/business key |
| CUSTOMER_NAME | Customer name |
| CITY | Current city |
| STATE | Current state |
| MEMBERSHIP | Current membership |
| SEGMENT | Current segment |

```sql
CREATE OR REPLACE TABLE DIM_CUSTOMER_TYPE1
(
    CUSTOMER_KEY  NUMBER AUTOINCREMENT,
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(50),
    STATE         VARCHAR(50),
    MEMBERSHIP    VARCHAR(30),
    SEGMENT       VARCHAR(30)
);
```

## 7. Task 3 — Load Initial Type 1 Data

The initial CSV was loaded through the Snowflake file-loading workflow:

```text
customers_initial.csv
        ↓
File Format
        ↓
Internal Stage
        ↓
COPY INTO
        ↓
DIM_CUSTOMER_TYPE1
```

The initial table contained five records.

## 8. Task 4 — Apply SCD Type 1 Updates

The update data was loaded into:

```sql
CREATE OR REPLACE TABLE CUSTOMER_UPDATES
(
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    CITY           VARCHAR(50),
    STATE          VARCHAR(50),
    MEMBERSHIP     VARCHAR(30),
    SEGMENT        VARCHAR(30),
    EFFECTIVE_DATE DATE
);
```

Type 1 update:

```sql
UPDATE DIM_CUSTOMER_TYPE1 AS TARGET
SET
    CUSTOMER_NAME = SOURCE.CUSTOMER_NAME,
    CITY          = SOURCE.CITY,
    STATE         = SOURCE.STATE,
    MEMBERSHIP    = SOURCE.MEMBERSHIP,
    SEGMENT       = SOURCE.SEGMENT
FROM CUSTOMER_UPDATES AS SOURCE
WHERE TARGET.CUSTOMER_ID = SOURCE.CUSTOMER_ID;
```

The existing row is overwritten. No new version row is created.

## 9. Task 5 — Display Type 1 Result

Final Type 1 result:

| CUSTOMER_ID | CUSTOMER_NAME | CITY | STATE | MEMBERSHIP | SEGMENT |
|---:|---|---|---|---|---|
| 101 | Amit Sharma | Bengaluru | Karnataka | Gold | Premium |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Chennai | Tamil Nadu | Gold | Premium |
| 104 | Neha Patel | Hyderabad | Telangana | Platinum | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

## 10. Task 6 — Demonstrate Type 1 History Loss

Customer 101 now contains:

```text
101 | Bengaluru | Karnataka | Gold
```

The original Hyderabad/Telangana/Silver values are no longer available in the Type 1 table.

Therefore:

```text
SCD Type 1
-----------
Old value  → Overwritten
History    → Not preserved
New row    → No
```

## 11. Task 7 — Create SCD Type 2 Table

```sql
CREATE OR REPLACE TABLE DIM_CUSTOMER_TYPE2
(
    CUSTOMER_KEY   NUMBER AUTOINCREMENT,
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    CITY           VARCHAR(50),
    STATE          VARCHAR(50),
    MEMBERSHIP     VARCHAR(30),
    SEGMENT        VARCHAR(30),
    EFFECTIVE_DATE DATE,
    EXPIRY_DATE    DATE,
    IS_CURRENT     BOOLEAN
);
```

## 12. Task 8 — Verify Type 2 Structure

The table structure was verified with:

```sql
DESC TABLE DIM_CUSTOMER_TYPE2;
```

At this stage the table contained zero records.

## 13. Task 9 — Load Initial Type 2 Records

The initial Type 2 load was taken from the **original `customers_initial.csv` in the stage**, not from the already-updated Type 1 table.

Initial version values:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

Initial totals:

```text
Total records   = 5
Current records = 5
```

This is important because the Type 1 table had already overwritten historical values.

## 14. Task 10 — Apply SCD Type 2 Changes

Type 2 uses two logical operations:

1. Expire the old record.
2. Insert the new version.

Expire old versions:

```sql
UPDATE DIM_CUSTOMER_TYPE2 AS TARGET
SET
    EXPIRY_DATE = DATEADD(DAY, -1, SOURCE.EFFECTIVE_DATE),
    IS_CURRENT  = FALSE
FROM CUSTOMER_UPDATES AS SOURCE
WHERE TARGET.CUSTOMER_ID = SOURCE.CUSTOMER_ID
  AND TARGET.IS_CURRENT = TRUE;
```

Insert new versions:

```sql
INSERT INTO DIM_CUSTOMER_TYPE2
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT,
    EFFECTIVE_DATE,
    EXPIRY_DATE,
    IS_CURRENT
)
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT,
    EFFECTIVE_DATE,
    '9999-12-31'::DATE,
    TRUE
FROM CUSTOMER_UPDATES;
```

A `MERGE` was not required for this project because the FRD explicitly describes the Type 2 process as expire-then-insert.

## 15. Task 11 — Customer 101 Type 2 Change

| CUSTOMER_ID | CITY | MEMBERSHIP | EFFECTIVE_DATE | EXPIRY_DATE | IS_CURRENT |
|---:|---|---|---|---|---|
| 101 | Hyderabad | Silver | 2026-01-01 | 2026-03-31 | FALSE |
| 101 | Bengaluru | Gold | 2026-04-01 | 9999-12-31 | TRUE |

The old version is preserved and the new version is current.

## 16. Task 12 — Customer 103 Type 2 Change

| CUSTOMER_ID | CITY | MEMBERSHIP | EFFECTIVE_DATE | EXPIRY_DATE | IS_CURRENT |
|---:|---|---|---|---|---|
| 103 | Vijayawada | Silver | 2026-01-01 | 2026-04-04 | FALSE |
| 103 | Chennai | Gold | 2026-04-05 | 9999-12-31 | TRUE |

## 17. Task 13 — Customer 104 Type 2 Change

| CUSTOMER_ID | CITY | MEMBERSHIP | EFFECTIVE_DATE | EXPIRY_DATE | IS_CURRENT |
|---:|---|---|---|---|---|
| 104 | Hyderabad | Gold | 2026-01-01 | 2026-04-09 | FALSE |
| 104 | Hyderabad | Platinum | 2026-04-10 | 9999-12-31 | TRUE |

## 18. Task 14 — Display Complete Type 2 History

The complete Type 2 table contains:

```text
101 → 2 versions
102 → 1 version
103 → 2 versions
104 → 2 versions
105 → 1 version
----------------
Total = 8
```

Historical records:

```text
101 old version
103 old version
104 old version
```

Current records:

```text
101
102
103
104
105
```

## 19. Task 15 — Display Current Customer Records

Current records are selected using:

```sql
WHERE IS_CURRENT = TRUE
```

Final current data:

| CUSTOMER_ID | CUSTOMER_NAME | CITY | STATE | MEMBERSHIP | SEGMENT |
|---:|---|---|---|---|---|
| 101 | Amit Sharma | Bengaluru | Karnataka | Gold | Premium |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Chennai | Tamil Nadu | Gold | Premium |
| 104 | Neha Patel | Hyderabad | Telangana | Platinum | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

## 20. Task 16 — Historical Customer Analysis

Question:

> What was Customer 101's membership on March 15, 2026?

Query:

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    MEMBERSHIP,
    CITY,
    EFFECTIVE_DATE,
    EXPIRY_DATE
FROM DIM_CUSTOMER_TYPE2
WHERE CUSTOMER_ID = 101
  AND '2026-03-15'::DATE BETWEEN EFFECTIVE_DATE AND EXPIRY_DATE;
```

Result:

```text
CUSTOMER_ID  CUSTOMER_NAME  MEMBERSHIP  CITY        EFFECTIVE_DATE  EXPIRY_DATE
--------------------------------------------------------------------------------
101          Amit Sharma    Silver      Hyderabad   2026-01-01      2026-03-31
```

Therefore, on March 15, 2026, Customer 101's membership was **Silver**.

This demonstrates the value of Type 2 for historical analysis.

## 21. Task 17 — Compare Type 1 vs Type 2

| Feature | Type 1 | Type 2 |
|---|---|---|
| Old value preserved? | No | Yes |
| New row created? | No | Yes |
| Historical analysis? | No | Yes |
| Effective Date | No | Yes |
| Expiry Date | No | Yes |
| IS_CURRENT | No | Yes |
| Storage required | Lower | Higher |

### Type 1

```text
Old Value      → Overwritten
History        → Not Preserved
New Row        → No
```

### Type 2

```text
Old Value      → Preserved
History        → Preserved
New Row        → Yes
Effective Date → Yes
Expiry Date    → Yes
IS_CURRENT     → Yes
```

## 22. Task 18 — Final Validation

Final counts:

```text
SCD TYPE 1 RECORD COUNT
5
```

```text
SCD TYPE 2 RECORD COUNT
8
```

```text
SCD TYPE 2 CURRENT RECORD COUNT
5
```

```text
SCD TYPE 2 HISTORICAL RECORD COUNT
3
```

Calculation:

```text
Initial Type 2 records = 5
Changed customers      = 3
Additional versions    = 3

5 + 3 = 8
```

## 23. Important SCD Type 2 Concepts

### Natural Key vs Surrogate Key

`CUSTOMER_ID` is the natural/business key.

`CUSTOMER_KEY` is the surrogate key.

A single customer can therefore have multiple dimension records representing different versions.

The surrogate key is not required to be gap-free or sequential.

### Effective Date

Defines when a version becomes valid.

### Expiry Date

Defines when a version stops being valid.

### IS_CURRENT

```text
TRUE  → Current version
FALSE → Historical version
```

### Historical Date Lookup

To find the version valid on a particular date:

```sql
requested_date BETWEEN EFFECTIVE_DATE AND EXPIRY_DATE
```

## 24. Final Project Architecture

```text
customers_initial.csv
        ↓
   Snowflake Stage
        ↓
   ┌────┴─────┐
   ↓          ↓
Type 1      Type 2
Table       Table
   ↓          ↓
Overwrite   Expire old row
values      + Insert new row
   ↓          ↓
Current     Complete
only        history
```

The update file follows:

```text
customer_updates.csv
        ↓
CUSTOMER_UPDATES
        ↓
Type 1 → UPDATE existing rows
Type 2 → UPDATE old version + INSERT new version
```

## 25. Final Outcome

Project 9 successfully demonstrates both SCD strategies.

### Type 1

```text
5 records
Old values overwritten
Historical values not preserved
```

### Type 2

```text
8 records
5 current records
3 historical records
Old versions preserved
Historical analysis supported
```

## 26. Key Interview Takeaways

**What is SCD Type 1?**

SCD Type 1 overwrites the existing dimension attribute. The previous value is not preserved.

**What is SCD Type 2?**

SCD Type 2 preserves historical versions by expiring the old record and inserting a new record.

**Why use a surrogate key?**

The same natural customer can have multiple dimension versions, so each version needs its own unique dimension key.

**What does IS_CURRENT do?**

It identifies the latest active version.

**Why use effective and expiry dates?**

They allow the warehouse to determine which version was valid on a historical date.

**How do you find the current version?**

```sql
WHERE IS_CURRENT = TRUE
```

**How do you perform historical analysis?**

```sql
requested_date BETWEEN EFFECTIVE_DATE AND EXPIRY_DATE
```

# Project 9 Status

**COMPLETED**

Final validation:

```text
Type 1 Records             = 5
Type 2 Records             = 8
Type 2 Current Records     = 5
Type 2 Historical Records  = 3
```
