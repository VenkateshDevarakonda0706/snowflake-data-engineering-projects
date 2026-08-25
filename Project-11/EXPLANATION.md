# Project 11 — Enterprise Customer Master Data Management using Hybrid SCD Strategies

## 1. Project Overview

Project 11 implements an Enterprise Customer Master Data Management solution in Snowflake using a unified Hybrid Slowly Changing Dimension (SCD) strategy.

The project demonstrates how different customer attributes can require different change-tracking behaviors within the same dimension:

- **STATE** — operational attribute; overwritten with the latest value.
- **SEGMENT** — historically tracked attribute; previous versions are preserved.
- **CITY** — prior-value attribute; current and immediate previous city are maintained.
- **MEMBERSHIP** — hybrid attribute; current membership, immediate previous membership, and historical membership for each row version are maintained.

The implementation uses Snowflake SQL, an internal stage, CSV file format, and a hybrid customer dimension.

## 2. Business Scenario

Initial customers:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---:|---|---|---|---|---|
| 101 | Amit Sharma | Hyderabad | Telangana | Silver | Regular |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Vijayawada | Andhra Pradesh | Silver | Regular |
| 104 | Neha Patel | Hyderabad | Telangana | Gold | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

Updates:

- Customer 101: Hyderabad/Telangana → Bengaluru/Karnataka, Silver → Gold, Regular → Premium, effective 2026-04-01.
- Customer 103: Vijayawada/Andhra Pradesh → Chennai/Tamil Nadu, Silver → Gold, Regular → Premium, effective 2026-04-05.
- Customer 104: Gold → Platinum, effective 2026-04-10.

## 3. Technology

- Snowflake
- Snowflake SQL
- CSV input files
- Snowflake internal stage
- Snowflake CSV file format

## 4. Source Files

### customers_initial.csv

```text
customer_id,customer_name,city,state,membership,segment
101,Amit Sharma,Hyderabad,Telangana,Silver,Regular
102,Priya Reddy,Warangal,Telangana,Gold,Premium
103,Rahul Verma,Vijayawada,Andhra Pradesh,Silver,Regular
104,Neha Patel,Hyderabad,Telangana,Gold,Premium
105,Arjun Gupta,Nagpur,Maharashtra,Bronze,Regular
```

### customer_updates.csv

```text
customer_id,customer_name,city,state,membership,segment,effective_date
101,Amit Sharma,Bengaluru,Karnataka,Gold,Premium,2026-04-01
103,Rahul Verma,Chennai,Tamil Nadu,Gold,Premium,2026-04-05
104,Neha Patel,Hyderabad,Telangana,Platinum,Premium,2026-04-10
```

## 5. Database, Schema, File Format and Stage

The project creates:

```text
Warehouse: SCD_HYBRID_WH
Database:  SCD_HYBRID_DB
Schema:    SCD_HYBRID_SCHEMA
Stage:     RAW_STAGE
```

The CSV file format is configured for comma-separated files and skips the header row.

Loading architecture:

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
Snowflake SQL
   |
   v
DIM_CUSTOMER_HYBRID
```

## 6. Hybrid Dimension Table

The main table is:

```text
DIM_CUSTOMER_HYBRID
```

| Column | Purpose |
|---|---|
| CUSTOMER_KEY | Surrogate key generated using AUTOINCREMENT |
| CUSTOMER_ID | Business/natural customer key |
| CUSTOMER_NAME | Customer name |
| CITY | Current city |
| PREVIOUS_CITY | Immediate prior city |
| STATE | Current state |
| CURRENT_MEMBERSHIP | Latest active membership |
| PREVIOUS_MEMBERSHIP | Immediate previous membership |
| HISTORICAL_MEMBERSHIP | Membership associated with the specific row version |
| SEGMENT | Historical customer segment |
| EFFECTIVE_DATE | Beginning date of row version |
| EXPIRY_DATE | Ending date of row version |
| IS_CURRENT | Active-version indicator |

## 7. Attribute Strategy

```text
STATE
  -> overwrite current value

CITY
  -> current city + immediate previous city

SEGMENT
  -> historical row versions

MEMBERSHIP
  -> current membership
  -> previous membership
  -> historical membership per row version
```

This is the core Hybrid SCD behavior.

## 8. Initial Load

The five records from `customers_initial.csv` are loaded with:

- `PREVIOUS_CITY = NULL`
- `CURRENT_MEMBERSHIP = initial membership`
- `PREVIOUS_MEMBERSHIP = NULL`
- `HISTORICAL_MEMBERSHIP = initial membership`
- `EFFECTIVE_DATE = 2026-01-01`
- `EXPIRY_DATE = 9999-12-31`
- `IS_CURRENT = TRUE`

Initial metrics:

```text
Total records       = 5
Current records     = 5
Historical records  = 0
```

## 9. Hybrid Update Process

Updates are applied in three steps.

### Step 1 — Expire Existing Versions

The active version of each updated customer is changed to historical:

```text
IS_CURRENT = FALSE
```

and the expiry date becomes one day before the new effective date.

```text
Customer 101 -> 2026-03-31
Customer 103 -> 2026-04-04
Customer 104 -> 2026-04-09
```

### Step 2 — Insert New Versions

A new active row is inserted for each updated customer.

```text
IS_CURRENT = TRUE
EXPIRY_DATE = 9999-12-31
```

The new row captures the new values and the relevant prior values.

### Step 3 — Synchronize Global Attributes

The globally current/prior attributes are synchronized across versions:

- CITY
- PREVIOUS_CITY
- STATE
- CURRENT_MEMBERSHIP
- PREVIOUS_MEMBERSHIP

The version-specific attributes remain tied to the historical version:

- HISTORICAL_MEMBERSHIP
- SEGMENT

## 10. Understanding Historical Membership

`HISTORICAL_MEMBERSHIP` is not the same as `CURRENT_MEMBERSHIP`.

For Customer 101:

```text
2026-01-01 to 2026-03-31 -> Silver
2026-04-01 onward        -> Gold
```

Therefore:

```text
Historical version:
HISTORICAL_MEMBERSHIP = Silver

Current version:
HISTORICAL_MEMBERSHIP = Gold
```

At the same time:

```text
CURRENT_MEMBERSHIP  = Gold
PREVIOUS_MEMBERSHIP = Silver
```

The historical column preserves the membership belonging to that specific time slice, while the current column represents the latest membership.

## 11. Customer 101 Example

### Historical version

```text
CUSTOMER_ID            101
CITY                   Bengaluru
PREVIOUS_CITY          Hyderabad
STATE                  Karnataka
CURRENT_MEMBERSHIP     Gold
PREVIOUS_MEMBERSHIP    Silver
HISTORICAL_MEMBERSHIP  Silver
SEGMENT                Regular
EFFECTIVE_DATE         2026-01-01
EXPIRY_DATE            2026-03-31
IS_CURRENT             FALSE
```

### Current version

```text
CUSTOMER_ID            101
CITY                   Bengaluru
PREVIOUS_CITY          Hyderabad
STATE                  Karnataka
CURRENT_MEMBERSHIP     Gold
PREVIOUS_MEMBERSHIP    Silver
HISTORICAL_MEMBERSHIP  Gold
SEGMENT                Premium
EFFECTIVE_DATE         2026-04-01
EXPIRY_DATE            9999-12-31
IS_CURRENT             TRUE
```

This allows the same dimension to answer both current-state and historical questions.

## 12. Complete History

After updates:

```text
Customer 101 -> 2 rows
Customer 102 -> 1 row
Customer 103 -> 2 rows
Customer 104 -> 2 rows
Customer 105 -> 1 row
```

Therefore:

```text
Total rows       = 8
Current rows     = 5
Historical rows  = 3
```

## 13. Active Customer Report

The active report uses:

```sql
WHERE IS_CURRENT = TRUE
```

This returns one active version for every customer.

Current memberships:

```text
101 -> Gold
102 -> Gold
103 -> Gold
104 -> Platinum
105 -> Bronze
```

## 14. Point-in-Time Historical Query

To find the version valid on a particular date:

```sql
EFFECTIVE_DATE <= requested_date
AND EXPIRY_DATE >= requested_date
```

For Customer 101 on March 15, 2026, the valid version is:

```text
2026-01-01 to 2026-03-31
```

The historical membership is:

```text
Silver
```

and the historical segment is:

```text
Regular
```

## 15. Final Validation

Expected final metrics:

| Metric | Value |
|---|---:|
| TOTAL RECORD COUNT | 8 |
| CURRENT RECORD COUNT | 5 |
| HISTORICAL RECORD COUNT | 3 |

## 16. Key Concepts Learned

1. Surrogate keys with AUTOINCREMENT.
2. Natural/business keys.
3. Snowflake internal stages.
4. CSV file formats.
5. COPY INTO loading.
6. Type 1-style overwrite behavior.
7. Type 2 historical row versioning.
8. Prior-value tracking.
9. Hybrid SCD design.
10. Effective and expiry dates.
11. Current-row indicators.
12. Point-in-time reporting.
13. Current-state reporting.
14. Record-count validation.

## 17. Final Outcome

Project 11 successfully implements a unified Hybrid SCD customer dimension in Snowflake.

Final state:

```text
TOTAL RECORDS       = 8
CURRENT RECORDS     = 5
HISTORICAL RECORDS  = 3
```

The dimension supports both current customer reporting and historical point-in-time reporting while applying different tracking strategies to different customer attributes.
