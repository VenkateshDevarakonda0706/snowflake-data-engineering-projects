# Project-7: Hospital Healthcare Analytics using Snowflake Dimensional Modeling

## 1. Project Overview

This project implements a Kimball dimensional model in Snowflake for a hospital network.

The warehouse supports two business processes:

1. Patient Admissions
2. Medical Billing

The main goal is to build two fact tables that use common dimensions so management can analyze admissions and billing consistently and perform drill-across analysis.

---

## 2. Problem Statement

The hospital network maintains operational data for:

- Patients
- Doctors
- Hospitals
- Departments
- Treatments
- Patient Admissions
- Medical Billing

Management wants analytics for two major business processes.

### Business Process 1 — Patient Admissions

Management wants to analyze:

- Number of admissions
- Length of stay
- Admissions by hospital
- Admissions by department
- Admissions by doctor
- Monthly admissions

### Business Process 2 — Medical Billing

Management wants to analyze:

- Total treatment revenue
- Revenue by hospital
- Revenue by department
- Revenue by doctor
- Revenue by treatment
- Monthly revenue

Both processes should use common dimensions so that admissions and revenue can be compared using the same patient, doctor, hospital, department, and date dimensions.

---

## 3. Learning Objectives

After completing this project, the important concepts are:

- Identifying business processes
- Identifying business events
- Designing fact tables
- Designing dimension tables
- Defining fact-table grain
- Identifying additive measures
- Creating surrogate keys
- Creating fact-to-dimension relationships
- Identifying conformed dimensions
- Performing drill-across analysis
- Building and interpreting a bus matrix
- Understanding a multi-fact star-schema design

---

## 4. Source Data

The project provides dimension source data for:

- patients.csv
- doctors.csv
- hospitals.csv
- departments.csv
- treatments.csv

It also provides admission and billing source information.

The supplied project specification contains a billing-data inconsistency: the displayed `billing.csv` section repeats admission-style columns instead of providing treatment and financial fields required later by `FACT_BILLING`.

Therefore, the billing source used during implementation was constructed to match the required billing fact structure:

- billing_id
- patient_id
- doctor_id
- hospital_id
- department_id
- treatment_id
- billing_date
- quantity
- treatment_amount
- discount

---

## 5. Phase 1 — Snowflake Environment

The warehouse environment contains:

- Warehouse: `HEALTHCARE_WH`
- Database: `HEALTHCARE_DB`
- Schema: `HEALTHCARE_SCHEMA`

The warehouse uses:

- X-SMALL size
- AUTO_SUSPEND = 60
- AUTO_RESUME = TRUE

The working context is set to the healthcare warehouse, database, and schema.

---

## 6. Phase 2 — Dimension Tables

The project contains six dimensions:

1. `DIM_PATIENT`
2. `DIM_DOCTOR`
3. `DIM_HOSPITAL`
4. `DIM_DEPARTMENT`
5. `DIM_TREATMENT`
6. `DIM_DATE`

### DIM_PATIENT

Stores:

- PATIENT_KEY
- PATIENT_ID
- PATIENT_NAME
- GENDER
- CITY
- STATE

`PATIENT_KEY` is the surrogate key.

`PATIENT_ID` is the source/business identifier.

### DIM_DOCTOR

Stores:

- DOCTOR_KEY
- DOCTOR_ID
- DOCTOR_NAME
- SPECIALIZATION

### DIM_HOSPITAL

Stores:

- HOSPITAL_KEY
- HOSPITAL_ID
- HOSPITAL_NAME
- CITY
- STATE
- REGION

### Why are CITY, STATE, and REGION not separate dimensions?

They are descriptive attributes of the hospital in this project.

Keeping them in `DIM_HOSPITAL` supports the requested star-schema design.

Creating separate `DIM_CITY`, `DIM_STATE`, and `DIM_REGION` tables would normalize the dimension and introduce additional joins, moving the design toward a snowflake-style structure.

### DIM_DEPARTMENT

Stores:

- DEPARTMENT_KEY
- DEPARTMENT_ID
- DEPARTMENT_NAME

### DIM_TREATMENT

Stores:

- TREATMENT_KEY
- TREATMENT_ID
- TREATMENT_NAME
- TREATMENT_CATEGORY

---

## 7. Surrogate Keys

Surrogate keys are warehouse-generated keys used to identify dimension rows.

Example:

```text
PATIENT_KEY   PATIENT_ID
-----------   ----------
1             P101
2             P102
3             P103
```

Here:

- `PATIENT_ID` comes from the source system.
- `PATIENT_KEY` is the warehouse surrogate key.

The fact tables store surrogate keys rather than descriptive business IDs.

---

## 8. Primary Keys and Foreign Keys

The dimension surrogate keys are defined as primary keys in the implementation.

The fact tables contain foreign-key columns pointing to the corresponding dimensions.

Example:

```text
FACT_ADMISSION.PATIENT_KEY
        |
        v
DIM_PATIENT.PATIENT_KEY
```

The same pattern is used for doctor, hospital, department, treatment, and date relationships.

In Snowflake, primary-key and foreign-key constraints are metadata constraints and are not enforced in the same manner as traditional OLTP databases. Therefore, data-quality validation queries are still useful.

---

## 9. Phase 3 — File Format and Stage

A CSV file format is created:

```text
CSV_FORMAT
```

with:

- TYPE = CSV
- FIELD_OPTIONALLY_ENCLOSED_BY = '"'
- SKIP_HEADER = 1

An internal Snowflake stage is created:

```text
HEALTHCARE_STAGE
```

The general loading flow is:

```text
CSV Files
   |
   v
HEALTHCARE_STAGE
   |
   v
COPY INTO
   |
   v
Dimension Tables
```

The dimension files loaded are:

- patients.csv
- doctors.csv
- hospitals.csv
- departments.csv
- treatments.csv

---

## 10. Dimension Loading Results

Expected and verified dimension counts:

```text
DIM_PATIENT       6
DIM_DOCTOR        4
DIM_HOSPITAL      3
DIM_DEPARTMENT    4
DIM_TREATMENT     6
```

---

## 11. Phase 4 — DIM_DATE

A date dimension is created for:

```text
2026-01-01
through
2026-03-31
```

This gives 90 dates.

The columns are:

- DATE_KEY
- FULL_DATE
- DAY
- DAY_NAME
- WEEK_NO
- MONTH
- MONTH_NAME
- QUARTER
- YEAR

### Why use DATE_KEY?

The date key is generated in `YYYYMMDD` form.

Examples:

```text
2026-01-01 -> 20260101
2026-01-02 -> 20260102
2026-01-05 -> 20260105
```

This makes the date dimension easy to use for reporting.

Both fact tables use this same `DIM_DATE`.

---

## 12. Phase 5 — Business Processes

The two business processes are:

### 1. Patient Admissions

A patient admission creates an admission business event.

This event is represented in:

```text
FACT_ADMISSION
```

### 2. Medical Billing

A treatment/service billing transaction creates a billing business event.

This event is represented in:

```text
FACT_BILLING
```

---

## 13. Phase 6 — FACT_ADMISSION

The admission fact table contains:

- ADMISSION_KEY
- PATIENT_KEY
- DOCTOR_KEY
- HOSPITAL_KEY
- DEPARTMENT_KEY
- DATE_KEY
- ADMISSION_COUNT
- LENGTH_OF_STAY

`ADMISSION_KEY` is the fact-table surrogate key.

---

## 14. FACT_ADMISSION Grain

Grain means:

> What exactly does one row in the fact table represent?

The grain of `FACT_ADMISSION` is:

> One record represents one patient admission to one hospital, under one doctor and department, on one admission date.

The supplied admission data contains 10 admissions, so the final fact contains 10 admission rows.

---

## 15. FACT_ADMISSION Measures

### ADMISSION_COUNT

Every admission row represents one admission.

Therefore:

```text
ADMISSION_COUNT = 1
```

for every fact row.

Then:

```sql
SUM(ADMISSION_COUNT)
```

returns the total number of admissions.

### LENGTH_OF_STAY

Calculated using:

```text
Discharge Date - Admission Date
```

For example:

```text
2026-01-05 to 2026-01-08 = 3 days
```

The supplied admission data produces:

```text
Total Admissions = 10
Total Length of Stay = 41 days
```

---

## 16. Loading FACT_ADMISSION

The source contains business IDs:

- patient_id
- doctor_id
- hospital_id
- department_id
- admission_date

These are matched to dimension tables to retrieve surrogate keys.

Conceptually:

```text
P101
 |
 v
DIM_PATIENT
 |
 v
PATIENT_KEY
```

The same process is used for doctor, hospital, department, and date.

Those surrogate keys are then inserted into the fact table.

---

## 17. Phase 8 — FACT_BILLING

The billing fact contains:

- BILLING_KEY
- PATIENT_KEY
- DOCTOR_KEY
- HOSPITAL_KEY
- DEPARTMENT_KEY
- TREATMENT_KEY
- DATE_KEY
- QUANTITY
- TREATMENT_AMOUNT
- DISCOUNT
- NET_AMOUNT

`BILLING_KEY` is the fact-table surrogate key.

---

## 18. FACT_BILLING Grain

The grain is:

> One record represents one treatment/service billed to one patient by one doctor at one hospital on one billing date.

Treatment is part of the billing process because billing records represent treatment/service transactions.

---

## 19. FACT_BILLING Measures

### QUANTITY

Represents the quantity of the billed treatment/service.

### TREATMENT_AMOUNT

Represents the amount before discount.

### DISCOUNT

Represents the discount applied to the treatment amount.

### NET_AMOUNT

Calculated as:

```text
NET_AMOUNT = TREATMENT_AMOUNT - DISCOUNT
```

All four measures are additive according to the project specification.

---

## 20. Conformed Dimensions

The dimensions shared by both fact tables are:

```text
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_DATE
```

These are called **conformed dimensions**.

`DIM_TREATMENT` is used only by `FACT_BILLING`.

The key idea is that both business processes use the same definitions for these common dimensions.

---

## 21. Star Schema

The admission star is:

```text
                    DIM_PATIENT
                         |
                         |
DIM_DOCTOR ------ FACT_ADMISSION ------ DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT
```

The billing star is:

```text
                    DIM_PATIENT
                         |
                         |
DIM_DOCTOR ------- FACT_BILLING ------- DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT
                         |
                   DIM_TREATMENT
```

The overall design contains two fact tables with shared dimensions.

---

## 22. Admission Analytics

Hospital-wise admissions are calculated by joining:

```text
FACT_ADMISSION
      |
      v
DIM_HOSPITAL
```

and summing:

```text
ADMISSION_COUNT
```

Expected result:

```text
KMIT Hospital          5
City Care Hospital     3
Apollo Care            2
```

---

## 23. Hospital Revenue Analytics

Hospital revenue is calculated using:

```text
SUM(NET_AMOUNT)
```

grouped by hospital.

Expected project output:

```text
City Care Hospital     9900
KMIT Hospital          7400
Apollo Care            5400
```

---

## 24. Monthly Revenue

Monthly revenue uses the shared `DIM_DATE`.

The relationship is:

```text
FACT_BILLING
     |
     | DATE_KEY
     v
DIM_DATE
```

The project expects:

```text
2026-01    12250
2026-02     7000
2026-03     3450
```

Using `DIM_DATE` makes it possible to group billing by month without storing month attributes repeatedly in the fact table.

---

## 25. Doctor-wise Revenue

Doctor-wise revenue is calculated by joining:

```text
FACT_BILLING
      |
      v
DIM_DOCTOR
```

and summing `NET_AMOUNT`.

The project specification lists:

```text
Dr. Rao       3700
Dr. Mehta     9900
Dr. Kumar     5400
Dr. Sharma    3050
```

However, these specified doctor totals add up to:

```text
22050
```

while the specified hospital totals and monthly totals each add up to:

```text
22700
```

Therefore, the supplied specification contains an internal inconsistency of:

```text
22700 - 22050 = 650
```

This should be treated as a source-data/specification inconsistency rather than changing the warehouse logic to force incompatible results.

---

## 26. Drill-Across Analysis

Drill-across means comparing measures from different fact tables using shared/conformed dimensions.

Here we compare:

```text
FACT_ADMISSION
    |
    v
Total Admissions

FACT_BILLING
    |
    v
Total Revenue
```

using:

```text
DIM_HOSPITAL
```

Conceptually:

```text
             DIM_HOSPITAL
              /                     /                      v            v
FACT_ADMISSION       FACT_BILLING
```

The safest approach is to aggregate each fact separately by `HOSPITAL_KEY` and then combine the results through the hospital dimension.

This avoids accidental row multiplication.

---

## 27. Why Not Directly Join the Two Fact Tables?

Suppose one hospital has:

```text
5 admission rows
4 billing rows
```

A direct fact-to-fact join can potentially produce:

```text
5 x 4 = 20 rows
```

This can inflate measures.

Instead:

```text
FACT_ADMISSION
     |
     v
GROUP BY HOSPITAL_KEY
     |
     v
Admissions total

FACT_BILLING
     |
     v
GROUP BY HOSPITAL_KEY
     |
     v
Revenue total

        |
        v
DIM_HOSPITAL
        |
        v
Final comparison
```

This is the correct drill-across approach.

---

## 28. Bus Matrix

The bus matrix shows which dimensions are used by each fact table.

| Dimension | FACT_ADMISSION | FACT_BILLING |
|---|:---:|:---:|
| DIM_PATIENT | ✓ | ✓ |
| DIM_DOCTOR | ✓ | ✓ |
| DIM_HOSPITAL | ✓ | ✓ |
| DIM_DEPARTMENT | ✓ | ✓ |
| DIM_DATE | ✓ | ✓ |
| DIM_TREATMENT | — | ✓ |

This makes the conformed-dimension design easy to understand.

---

## 29. Complete Project Flow

```text
Create Warehouse
       |
       v
Create Database
       |
       v
Create Schema
       |
       v
Create Dimensions
       |
       v
Create File Format
       |
       v
Create Stage
       |
       v
Upload CSV Files
       |
       v
COPY INTO Dimensions
       |
       v
Create DIM_DATE
       |
       v
Identify Business Processes
       |
       v
Create FACT_ADMISSION
       |
       v
Define Admission Grain
       |
       v
Load FACT_ADMISSION
       |
       v
Create FACT_BILLING
       |
       v
Define Billing Grain
       |
       v
Load FACT_BILLING
       |
       v
Identify Measures
       |
       v
Identify Conformed Dimensions
       |
       v
Perform Analytics
       |
       v
Perform Drill-Across
       |
       v
Create Bus Matrix
```

---

## 30. Key Concepts to Remember

### Business Process

A business activity that generates measurable events.

Examples:

```text
Patient Admission
Medical Billing
```

### Fact Table

Stores measurable business events.

Examples:

```text
FACT_ADMISSION
FACT_BILLING
```

### Dimension Table

Stores descriptive information used to analyze facts.

Examples:

```text
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DATE
```

### Grain

Defines exactly what one fact row represents.

### Surrogate Key

Warehouse-generated key used to identify dimension/fact rows.

### Measure

Numeric value stored in a fact table for analysis.

### Additive Measure

A measure that can be summed across the relevant dimensions.

### Conformed Dimension

A shared dimension used consistently by multiple fact tables.

### Drill-Across

Comparing measures from different fact tables using common/conformed dimensions.

### Bus Matrix

A matrix showing the relationship between business processes/facts and dimensions.

---

## 31. Final Project Architecture

```text
                         DIM_PATIENT
                              |
                              |
DIM_DOCTOR -------- FACT_ADMISSION -------- DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT


                         DIM_PATIENT
                              |
                              |
DIM_DOCTOR --------- FACT_BILLING --------- DIM_DATE
                         |
                    DIM_HOSPITAL
                         |
                   DIM_DEPARTMENT
                         |
                    DIM_TREATMENT
```

### Conformed Dimensions

```text
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_DATE
```

### Admission Fact

```text
FACT_ADMISSION
```

### Billing Fact

```text
FACT_BILLING
```

### Billing-only Dimension

```text
DIM_TREATMENT
```

---

## 32. Project Completion

The project demonstrates a Kimball dimensional model containing two business processes, two fact tables, shared conformed dimensions, surrogate keys, additive measures, date analysis, and drill-across reporting.

The major learning outcome is understanding how **multiple business processes can share common dimensions while retaining separate fact tables with their own grains and measures**.
