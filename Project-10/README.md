# Project 10 — Customer Membership History using SCD Type 3 and Type 6

## 📌 Project Overview

This project demonstrates how to implement **Slowly Changing Dimensions (SCD)** in **Snowflake SQL** using:

- **SCD Type 3**
- **SCD Type 6**

The project uses an online retail customer scenario where customer membership and other customer attributes can change over time.

The main objective is to understand the difference between:

- Maintaining the **current and previous value** using SCD Type 3.
- Maintaining **current, previous, and complete historical versions** using SCD Type 6.

---

## 🎯 Business Scenario

The initial customers are:

| Customer ID | Customer Name | City | State | Membership | Segment |
|---|---|---|---|---|---|
| 101 | Amit Sharma | Hyderabad | Telangana | Silver | Regular |
| 102 | Priya Reddy | Warangal | Telangana | Gold | Premium |
| 103 | Rahul Verma | Vijayawada | Andhra Pradesh | Silver | Regular |
| 104 | Neha Patel | Hyderabad | Telangana | Gold | Premium |
| 105 | Arjun Gupta | Nagpur | Maharashtra | Bronze | Regular |

Later, the following membership changes occur:

| Customer | Change | Effective Date |
|---|---|---|
| 101 | Silver → Gold | 2026-04-01 |
| 103 | Silver → Gold | 2026-04-05 |
| 104 | Gold → Platinum | 2026-04-10 |

Customer location and segment changes are also included in the update file.

---

## 🛠️ Technology Used

- **Snowflake**
- **Snowflake SQL**
- CSV source files
- Snowflake internal stage
- Snowflake CSV file format

---

## 📂 Source Files

The project uses two CSV files:

### `customers_initial.csv`

Contains the initial customer records.

### `customers_updates.csv`

Contains the customer changes along with their effective dates.

---

## 🏗️ Snowflake Project Structure

```text
PROJECT_10
└── SCD
    ├── DIM_CUSTOMER_TYPE3
    └── DIM_CUSTOMER_TYPE6
```

Supporting Snowflake objects:

```text
CUSTOMER_CSV_FORMAT
CUSTOMER_STAGE
```

---

# 🔹 SCD Type 3

## What is SCD Type 3?

SCD Type 3 stores the **current value** and **previous value** in the same record.

Example:

```text
Before:

CURRENT_MEMBERSHIP  = Silver
PREVIOUS_MEMBERSHIP = NULL
```

After the customer changes to Gold:

```text
CURRENT_MEMBERSHIP  = Gold
PREVIOUS_MEMBERSHIP = Silver
```

No new row is created.

Therefore, Type 3 maintains only a limited amount of historical information.

---

## Type 3 Table

The table is:

```text
DIM_CUSTOMER_TYPE3
```

Columns:

```text
CUSTOMER_KEY
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
SEGMENT
```

### Type 3 behavior

```text
Old Current Value
       ↓
Previous Value

New Value
       ↓
Current Value
```

For Customer 101:

```text
Silver → Gold
```

becomes:

```text
CURRENT_MEMBERSHIP  = Gold
PREVIOUS_MEMBERSHIP = Silver
```

There is still only one row for Customer 101.

---

# 🔹 SCD Type 6

## What is SCD Type 6?

SCD Type 6 provides a more complete historical solution.

It maintains:

- Current membership
- Previous membership
- Historical membership
- Effective date
- Expiry date
- Current-record indicator

Unlike Type 3, Type 6 creates a **new row/version when a change occurs**.

---

## Type 6 Table

The table is:

```text
DIM_CUSTOMER_TYPE6
```

Columns:

```text
CUSTOMER_KEY
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
CURRENT_MEMBERSHIP
PREVIOUS_MEMBERSHIP
HISTORICAL_MEMBERSHIP
SEGMENT
EFFECTIVE_DATE
EXPIRY_DATE
IS_CURRENT
```

---

## Type 6 Change Process

When a customer changes:

```text
1. Expire the old record
2. Set IS_CURRENT = FALSE
3. Set EXPIRY_DATE to the day before the new effective date
4. Insert a new version
5. Set IS_CURRENT = TRUE
6. Set EXPIRY_DATE = 9999-12-31
```

Example for Customer 101:

```text
OLD VERSION

Membership     = Silver
Effective Date = 2026-01-01
Expiry Date    = 2026-03-31
IS_CURRENT     = FALSE
```

```text
NEW VERSION

Membership     = Gold
Previous       = Silver
Effective Date = 2026-04-01
Expiry Date    = 9999-12-31
IS_CURRENT     = TRUE
```

---

# 📋 Project Tasks

The project was completed through the following tasks:

### Task 1 — Create Database and Schema

Created:

```text
PROJECT_10
└── SCD
```

### Task 2 — Create Type 3 Dimension

Created:

```text
DIM_CUSTOMER_TYPE3
```

### Task 3 — Load Initial Type 3 Data

Loaded the five initial customers.

### Task 4 — Display Initial Type 3 Data

Verified the initial customer records.

### Task 5 — Apply SCD Type 3 Changes

Applied membership changes for:

```text
101 → Silver to Gold
103 → Silver to Gold
104 → Gold to Platinum
```

### Task 6 — Update Type 3 Dimension

Verified the updated current and previous membership values.

### Task 7 — Type 3 Final Report

Generated the final Type 3 customer report.

### Task 8 — Demonstrate Type 3

Verified Customer 101:

```text
Current  = Gold
Previous = Silver
```

### Task 9 — Create Type 6 Dimension

Created:

```text
DIM_CUSTOMER_TYPE6
```

### Task 10 — Load Initial Type 6 Records

Loaded five initial versions.

Initial values:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

### Task 11 — Apply Type 6 Change for Customer 101

Applied:

```text
Silver → Gold
Effective Date = 2026-04-01
```

### Task 12 — Apply Remaining Changes

Applied changes for Customers 103 and 104.

### Task 13 — Display Complete Type 6 History

Verified all historical and current versions.

### Task 14 — Current Customer Report

Filtered current records using:

```sql
WHERE IS_CURRENT = TRUE
```

### Task 15 — Point-in-Time Historical Query

Verified Customer 101's membership on:

```text
2026-03-15
```

Result:

```text
Silver
```

### Task 16 — Type 3 vs Type 6

Compared the capabilities of both SCD approaches.

### Task 17 — Record Count Validation

Validated the final record counts.

---

# 📊 Final Results

## SCD Type 3

```text
Total Records = 5
```

There is one row per customer.

Even though three customers changed, no additional historical rows were created.

---

## SCD Type 6

```text
Total Records       = 8
Current Records     = 5
Historical Records  = 3
```

Calculation:

```text
Initial records                 = 5
Customer 101 new version       = 1
Customer 103 new version       = 1
Customer 104 new version       = 1
                                ---
Total                           = 8
```

---

# 🔍 Final Type 3 Report

```text
CUSTOMER_ID  CUSTOMER_NAME   CITY         CURRENT_MEMBERSHIP  PREVIOUS_MEMBERSHIP
---------------------------------------------------------------------------------
101          Amit Sharma     Bengaluru    Gold                Silver
102          Priya Reddy     Warangal     Gold                NULL
103          Rahul Verma     Chennai      Gold                Silver
104          Neha Patel      Hyderabad    Platinum            Gold
105          Arjun Gupta     Nagpur       Bronze               NULL
```

---

# 🔍 Final Type 6 History

```text
CUSTOMER_ID  MEMBERSHIP  EFFECTIVE_DATE  EXPIRY_DATE  IS_CURRENT
---------------------------------------------------------------
101          Silver      2026-01-01      2026-03-31   FALSE
101          Gold        2026-04-01      9999-12-31   TRUE

102          Gold        2026-01-01      9999-12-31   TRUE

103          Silver      2026-01-01      2026-04-04   FALSE
103          Gold        2026-04-05      9999-12-31   TRUE

104          Gold        2026-01-01      2026-04-09   FALSE
104          Platinum    2026-04-10      9999-12-31   TRUE

105          Bronze      2026-01-01      9999-12-31   TRUE
```

---

# ⚖️ SCD Type 3 vs SCD Type 6

| Feature | SCD Type 3 | SCD Type 6 |
|---|---|---|
| Current Value | ✅ | ✅ |
| Previous Value | ✅ | ✅ |
| Historical Rows | ❌ | ✅ |
| Effective Date | ❌ | ✅ |
| Expiry Date | ❌ | ✅ |
| IS_CURRENT | ❌ | ✅ |
| Point-in-Time Analysis | Limited | ✅ |
| Number of Rows | One per customer | Multiple versions |

### Simple way to remember

```text
SCD TYPE 3
-----------
Same row
Current + Previous
Limited history


SCD TYPE 6
-----------
New row for each change
Current + Previous + Historical
Effective + Expiry dates
Current flag
Complete history
```

---

# 🧪 Validation

The final validation produced:

```text
SCD TYPE 3 RECORD COUNT
5

SCD TYPE 6 RECORD COUNT
8

SCD TYPE 6 CURRENT RECORD COUNT
5

SCD TYPE 6 HISTORICAL RECORD COUNT
3
```

These values match the project requirements.

---

# 💡 Key Learning Outcomes

By completing Project 10, the following concepts were practiced:

- Slowly Changing Dimensions
- SCD Type 3
- SCD Type 6
- Current vs previous values
- Historical versions
- Effective dates
- Expiry dates
- Current-record indicators
- Surrogate keys
- Business keys
- Snowflake tables
- Snowflake stages
- Snowflake CSV file formats
- Loading CSV data into Snowflake
- Updating dimension records
- Creating historical versions
- Point-in-time historical queries
- Record-count validation

---

# ✅ Project Status

```text
PROJECT 10
Customer Membership History using SCD Type 3 and Type 6

STATUS: COMPLETED ✅
```

Final validation:

```text
Type 3 Records              = 5
Type 6 Records              = 8
Type 6 Current Records      = 5
Type 6 Historical Records   = 3
```

The project successfully demonstrates both **limited-history SCD Type 3** and **complete historical SCD Type 6** implementations in Snowflake.
