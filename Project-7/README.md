# Hospital Healthcare Analytics using Snowflake Dimensional Modeling

## Project-7

A Snowflake data warehouse project that implements a **Kimball dimensional model** for hospital healthcare analytics.

The project models two major business processes:

1. **Patient Admissions**
2. **Medical Billing**

Both processes share common dimensions, allowing management to compare admissions and revenue using the same analytical dimensions.

---

## Business Problem

A hospital network maintains operational data for:

- Patients
- Doctors
- Hospitals
- Departments
- Treatments
- Patient Admissions
- Medical Billing

Management needs analytical reporting for admissions and billing.

### Patient Admissions Analytics

- Number of admissions
- Length of stay
- Admissions by hospital
- Admissions by department
- Admissions by doctor
- Monthly admissions

### Medical Billing Analytics

- Total treatment revenue
- Revenue by hospital
- Revenue by department
- Revenue by doctor
- Revenue by treatment
- Monthly revenue

---

## Learning Objectives

This project demonstrates:

- Business process identification
- Business event identification
- Fact-table design
- Dimension-table design
- Fact-table grain
- Additive measures
- Surrogate keys
- Fact-to-dimension relationships
- Conformed dimensions
- Drill-across analysis
- Bus matrix
- Multi-fact dimensional modeling

---

## Architecture

The project contains six dimensions and two fact tables.

### Dimensions

```text
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_TREATMENT
DIM_DATE
```

### Fact Tables

```text
FACT_ADMISSION
FACT_BILLING
```

### Admission Star

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

### Billing Star

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

---

## Conformed Dimensions

The following dimensions are shared by both fact tables:

| Dimension | FACT_ADMISSION | FACT_BILLING |
|---|:---:|:---:|
| DIM_PATIENT | ✓ | ✓ |
| DIM_DOCTOR | ✓ | ✓ |
| DIM_HOSPITAL | ✓ | ✓ |
| DIM_DEPARTMENT | ✓ | ✓ |
| DIM_DATE | ✓ | ✓ |
| DIM_TREATMENT | — | ✓ |

The shared dimensions are called **conformed dimensions**.

`DIM_TREATMENT` is used only by `FACT_BILLING`.

---

## Snowflake Environment

```text
Warehouse : HEALTHCARE_WH
Database  : HEALTHCARE_DB
Schema    : HEALTHCARE_SCHEMA
Stage     : HEALTHCARE_STAGE
```

Warehouse configuration:

```text
WAREHOUSE_SIZE = X-SMALL
AUTO_SUSPEND   = 60
AUTO_RESUME    = TRUE
```

---

## Dimension Tables

### DIM_PATIENT

Stores:

```text
PATIENT_KEY
PATIENT_ID
PATIENT_NAME
GENDER
CITY
STATE
```

### DIM_DOCTOR

Stores:

```text
DOCTOR_KEY
DOCTOR_ID
DOCTOR_NAME
SPECIALIZATION
```

### DIM_HOSPITAL

Stores:

```text
HOSPITAL_KEY
HOSPITAL_ID
HOSPITAL_NAME
CITY
STATE
REGION
```

### DIM_DEPARTMENT

Stores:

```text
DEPARTMENT_KEY
DEPARTMENT_ID
DEPARTMENT_NAME
```

### DIM_TREATMENT

Stores:

```text
TREATMENT_KEY
TREATMENT_ID
TREATMENT_NAME
TREATMENT_CATEGORY
```

### DIM_DATE

Stores:

```text
DATE_KEY
FULL_DATE
DAY
DAY_NAME
WEEK_NO
MONTH
MONTH_NAME
QUARTER
YEAR
```

The date dimension covers:

```text
2026-01-01
through
2026-03-31
```

for a total of 90 dates.

---

## Fact Tables

### FACT_ADMISSION

Columns:

```text
ADMISSION_KEY
PATIENT_KEY
DOCTOR_KEY
HOSPITAL_KEY
DEPARTMENT_KEY
DATE_KEY
ADMISSION_COUNT
LENGTH_OF_STAY
```

### FACT_ADMISSION Grain

> One record represents one patient admission to one hospital, under one doctor and department, on one admission date.

### Measures

```text
ADMISSION_COUNT
LENGTH_OF_STAY
```

`ADMISSION_COUNT` is set to `1` for each admission.

`LENGTH_OF_STAY` is calculated as:

```text
DISCHARGE_DATE - ADMISSION_DATE
```

---

### FACT_BILLING

Columns:

```text
BILLING_KEY
PATIENT_KEY
DOCTOR_KEY
HOSPITAL_KEY
DEPARTMENT_KEY
TREATMENT_KEY
DATE_KEY
QUANTITY
TREATMENT_AMOUNT
DISCOUNT
NET_AMOUNT
```

### FACT_BILLING Grain

> One record represents one treatment/service billed to one patient by one doctor at one hospital on one billing date.

### Measures

```text
QUANTITY
TREATMENT_AMOUNT
DISCOUNT
NET_AMOUNT
```

Calculation:

```text
NET_AMOUNT = TREATMENT_AMOUNT - DISCOUNT
```

---

## Source Data Loading

Dimension data is loaded using a Snowflake internal stage and `COPY INTO`.

The general process is:

```text
CSV Files
   ↓
HEALTHCARE_STAGE
   ↓
COPY INTO
   ↓
Dimension Tables
```

Dimension source files:

```text
patients.csv
doctors.csv
hospitals.csv
departments.csv
treatments.csv
```

Expected dimension row counts:

```text
DIM_PATIENT       6
DIM_DOCTOR        4
DIM_HOSPITAL      3
DIM_DEPARTMENT    4
DIM_TREATMENT     6
```

---

## Surrogate Keys

Dimension tables use warehouse-generated surrogate keys.

Example:

```text
PATIENT_KEY   PATIENT_ID
-----------   ----------
1             P101
2             P102
3             P103
```

The fact tables use these surrogate keys as foreign keys.

This separates warehouse identifiers from source-system business identifiers.

---

## Analytics

The project performs:

### Hospital Admissions

Expected:

```text
KMIT Hospital          5
City Care Hospital     3
Apollo Care            2
```

### Hospital Revenue

Expected:

```text
City Care Hospital     9900
KMIT Hospital          7400
Apollo Care            5400
```

### Monthly Revenue

Expected:

```text
2026-01    12250
2026-02     7000
2026-03     3450
```

### Doctor Revenue

Doctor-wise revenue is calculated from:

```text
SUM(NET_AMOUNT)
```

The project specification lists doctor totals, but those figures contain an internal inconsistency: they sum to `22,050`, while the specified hospital and monthly totals sum to `22,700`.

The implementation therefore preserves consistent warehouse calculations instead of artificially changing the data to force incompatible totals.

---

## Drill-Across Analysis

The project compares measures from the two fact tables:

```text
FACT_ADMISSION
    ↓
Total Admissions

FACT_BILLING
    ↓
Total Revenue
```

using the shared:

```text
DIM_HOSPITAL
```

The recommended approach is to aggregate each fact separately by `HOSPITAL_KEY` and then combine the results through the conformed hospital dimension.

This avoids accidental many-to-many multiplication that can occur when fact tables are directly joined.

---

## Bus Matrix

```text
| Dimension      | FACT_ADMISSION | FACT_BILLING |
|----------------|----------------|--------------|
| DIM_PATIENT    | ✓              | ✓            |
| DIM_DOCTOR     | ✓              | ✓            |
| DIM_HOSPITAL   | ✓              | ✓            |
| DIM_DEPARTMENT | ✓              | ✓            |
| DIM_DATE       | ✓              | ✓            |
| DIM_TREATMENT  | —              | ✓            |
```

---

## Key Concepts

### Business Process

A business activity that generates measurable events.

Examples:

```text
Patient Admissions
Medical Billing
```

### Fact Table

Stores measurable business events.

```text
FACT_ADMISSION
FACT_BILLING
```

### Dimension Table

Stores descriptive attributes used to analyze facts.

```text
DIM_PATIENT
DIM_DOCTOR
DIM_HOSPITAL
DIM_DEPARTMENT
DIM_TREATMENT
DIM_DATE
```

### Grain

Defines exactly what one row in a fact table represents.

### Surrogate Key

A warehouse-generated key used to identify dimension or fact rows.

### Additive Measure

A measure that can be summed across relevant dimensions.

### Conformed Dimension

A dimension shared consistently by multiple fact tables.

### Drill-Across

Comparing measures from different fact tables through common dimensions.

### Bus Matrix

Shows which dimensions are associated with each business process/fact table.

---

## Project Workflow

```text
1. Create Snowflake Environment
2. Create Dimension Tables
3. Create File Format and Stage
4. Load Dimension Data
5. Create DIM_DATE
6. Identify Business Processes
7. Create FACT_ADMISSION
8. Define Admission Grain
9. Load FACT_ADMISSION
10. Create FACT_BILLING
11. Define Billing Grain
12. Load FACT_BILLING
13. Identify Measures
14. Identify Conformed Dimensions
15. Build Star Schema
16. Run Admission Analytics
17. Run Revenue Analytics
18. Perform Drill-Across Analysis
19. Prepare Bus Matrix
```

---

## Project Files

```text
Project-7.sql
EXPLANATION.md
README.md
```

- `Project-7.sql` — complete Snowflake SQL implementation
- `EXPLANATION.md` — detailed concepts and phase-by-phase explanation
- `README.md` — project overview, architecture, workflow, and key concepts

---

## Final Outcome

The completed project demonstrates a Kimball dimensional model with:

- Two business processes
- Two fact tables
- Six dimensions
- Surrogate keys
- Additive measures
- Date dimension
- Conformed dimensions
- Star-schema design
- Hospital, monthly, and doctor analytics
- Drill-across reporting
- Bus matrix

The central concept of Project-7 is that **different business processes can have separate fact tables while sharing common conformed dimensions for consistent enterprise-wide analysis**.
