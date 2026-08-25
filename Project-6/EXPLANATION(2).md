# Project 6 — Snowflake Schema
## Explanation

## 1. Project Overview

Project 6 converts the existing retail Star Schema into a more normalized Snowflake Schema.

The purpose is to reduce repeated descriptive attributes, separate hierarchical lookup data, improve consistency, and demonstrate how dimensions can be normalized into related tables.

The existing Project 4/5 schema was used as the source. Project 6 was implemented in a separate `RETAIL_P6` schema so that the earlier project remains available for comparison and validation.

---

## 2. Source and Target Schemas

### Source

```text
Database: RETAIL_DB_P4
Schema:   RETAIL
```

The source schema contains the original Star Schema tables:

```text
DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
FACT_SALES
```

### Target

```text
Database: RETAIL_DB_P4
Schema:   RETAIL_P6
```

Project 6 transforms the existing dimensions into a normalized Snowflake structure.

---

## 3. Star Schema Before Project 6

The original structure was approximately:

```text
                    DIM_CUSTOMER
                         |
                         |
DIM_PRODUCT ---- FACT_SALES ---- DIM_BRANCH
                         |
                         |
                     DIM_DATE
```

The dimensions contained attributes that could themselves be normalized.

Examples:

### Customer

```text
DIM_CUSTOMER
-------------------------
CUSTOMER_ID
CUSTOMER_NAME
CITY
STATE
REGION
MEMBERSHIP
```

### Product

```text
DIM_PRODUCT
-------------------------
PRODUCT_ID
PRODUCT_NAME
BRAND
CATEGORY
PRICE
```

### Date

```text
DIM_DATE
-------------------------
DATE_ID
DATE
DAY
DAY_NAME
WEEK_NO
MONTH
QUARTER
YEAR
IS_WEEKEND
```

### Branch

```text
DIM_BRANCH
-------------------------
BRANCH_ID
BRANCH_NAME
CITY
STATE
REGION
MANAGER_NAME
```

The repeated attributes were candidates for normalization.

---

# 4. Snowflake Schema Design

The final Project 6 structure contains three main hierarchies.

## 4.1 Geography Hierarchy

```text
DIM_REGION
    |
    | REGION_ID
    v
DIM_STATE
    |
    | STATE_ID
    v
DIM_CITY
    |
    | CITY_ID
    +--------------------+
    |                    |
    v                    v
DIM_CUSTOMER          DIM_BRANCH
```

### DIM_REGION

```text
REGION_ID       PK
REGION_NAME
```

### DIM_STATE

```text
STATE_ID        PK
STATE_NAME
REGION_ID       FK
```

### DIM_CITY

```text
CITY_ID         PK
CITY_NAME
STATE_ID        FK
```

This allows region and state information to be maintained centrally instead of repeatedly storing it in customer and branch records.

---

# 5. Customer Dimension

The original customer dimension contained geographic attributes directly.

The normalized version is:

```text
DIM_CUSTOMER
-------------------------
CUSTOMER_ID       PK
CUSTOMER_NAME
CITY_ID           FK
MEMBERSHIP
```

The geographic relationship becomes:

```text
CUSTOMER
   |
   | CITY_ID
   v
CITY
   |
   v
STATE
   |
   v
REGION
```

This removes repeated `CITY`, `STATE`, and `REGION` attributes from the customer table.

The source customer table was used to populate the new table.

A complete geography lookup was required because some customer cities/states were not present in the original branch-only geography data.

Therefore, the geography lookup tables were populated using the combined geography required by both branch and customer data.

---

# 6. Branch Dimension

The normalized branch dimension is:

```text
DIM_BRANCH
-------------------------
BRANCH_ID        PK
BRANCH_NAME
CITY_ID          FK
MANAGER_NAME
```

Instead of storing:

```text
CITY
STATE
REGION
```

the branch stores only:

```text
CITY_ID
```

The hierarchy is then:

```text
BRANCH
  |
  v
CITY
  |
  v
STATE
  |
  v
REGION
```

This prevents the same geographic information from being repeatedly stored in every branch row.

---

# 7. Product Hierarchy

The product hierarchy is:

```text
DIM_CATEGORY
      |
      v
DIM_BRAND
      |
      v
DIM_PRODUCT
```

## DIM_CATEGORY

```text
CATEGORY_ID      PK
CATEGORY_NAME
```

## DIM_BRAND

```text
BRAND_ID         PK
BRAND_NAME
CATEGORY_ID      FK
```

## DIM_PRODUCT

```text
PRODUCT_ID       PK
PRODUCT_NAME
BRAND_ID         FK
PRICE
```

Therefore:

```text
PRODUCT
   |
   v
BRAND
   |
   v
CATEGORY
```

This separates product classification from individual products.

An important modeling consideration is that a brand can occur under different categories in the source data. Therefore, product-to-brand resolution was performed using both brand and category context rather than matching on brand name alone.

---

# 8. Date Hierarchy

The date hierarchy is:

```text
DIM_YEAR
    |
    v
DIM_QUARTER
    |
    v
DIM_MONTH
    |
    v
DIM_DATE
```

## DIM_YEAR

```text
YEAR_ID         PK
YEAR
```

## DIM_QUARTER

```text
QUARTER_ID      PK
QUARTER
YEAR_ID         FK
```

## DIM_MONTH

```text
MONTH_ID        PK
MONTH
QUARTER_ID      FK
```

## DIM_DATE

```text
DATE_ID         PK
DATE
DAY
DAY_NAME
WEEK_NO
MONTH_ID        FK
IS_WEEKEND
```

The final relationship is:

```text
YEAR
  |
  v
QUARTER
  |
  v
MONTH
  |
  v
DATE
```

The date hierarchy allows analytical queries to drill from year to quarter to month and finally to individual dates.

---

# 9. Why Year, Quarter and Month Were Normalized

The project could have kept:

```text
YEAR
QUARTER
MONTH
```

directly inside `DIM_DATE`.

However, Project 6 is specifically demonstrating a Snowflake Schema. Therefore, the date hierarchy was separated into related lookup dimensions.

The final `DIM_DATE` stores `MONTH_ID` instead of repeating the month, quarter and year attributes.

The complete hierarchy can still be reconstructed through joins.

---

# 10. Fact Table

`FACT_SALES` remains the central transactional/measure table.

Its important foreign keys are:

```text
FACT_SALES
-------------------------
SALE_ID
CUSTOMER_ID
PRODUCT_ID
BRANCH_ID
DATE_ID
QUANTITY
TOTAL_AMOUNT
```

The fact table connects to the main dimensions:

```text
FACT_SALES
    |
    +---- CUSTOMER_ID ---> DIM_CUSTOMER
    |
    +---- PRODUCT_ID ----> DIM_PRODUCT
    |
    +---- BRANCH_ID -----> DIM_BRANCH
    |
    +---- DATE_ID -------> DIM_DATE
```

The fact table was not unnecessarily rebuilt because its existing business keys continue to identify the corresponding dimension records.

---

# 11. Final Snowflake Schema

The final logical structure is:

```text
                         DIM_REGION
                              |
                           REGION_ID
                              |
                              v
                         DIM_STATE
                              |
                           STATE_ID
                              |
                              v
                          DIM_CITY
                         /        \
                        /          \
                       v            v
                DIM_CUSTOMER     DIM_BRANCH
                       |             |
                       |             |
                       +------+-+----+
                              |
                              v
                          FACT_SALES
                              ^
                              |
                       DIM_PRODUCT
                              ^
                              |
                         DIM_BRAND
                              ^
                              |
                       DIM_CATEGORY


                         DIM_DATE
                            ^
                            |
                       DIM_MONTH
                            ^
                            |
                       DIM_QUARTER
                            ^
                            |
                         DIM_YEAR
```

A more relationship-focused representation is:

```text
DIM_REGION
    |
    +--> DIM_STATE
            |
            +--> DIM_CITY
                    |
                    +--> DIM_CUSTOMER
                    |
                    +--> DIM_BRANCH

DIM_CATEGORY
    |
    +--> DIM_BRAND
            |
            +--> DIM_PRODUCT

DIM_YEAR
    |
    +--> DIM_QUARTER
            |
            +--> DIM_MONTH
                    |
                    +--> DIM_DATE

DIM_CUSTOMER
DIM_PRODUCT
DIM_BRANCH
DIM_DATE
       |
       v
FACT_SALES
```

---

# 12. Primary Keys and Foreign Keys

## Geography

```text
DIM_REGION.REGION_ID
        ↑
DIM_STATE.REGION_ID

DIM_STATE.STATE_ID
        ↑
DIM_CITY.STATE_ID

DIM_CITY.CITY_ID
        ↑
DIM_CUSTOMER.CITY_ID

DIM_CITY.CITY_ID
        ↑
DIM_BRANCH.CITY_ID
```

## Product

```text
DIM_CATEGORY.CATEGORY_ID
        ↑
DIM_BRAND.CATEGORY_ID

DIM_BRAND.BRAND_ID
        ↑
DIM_PRODUCT.BRAND_ID
```

## Date

```text
DIM_YEAR.YEAR_ID
        ↑
DIM_QUARTER.YEAR_ID

DIM_QUARTER.QUARTER_ID
        ↑
DIM_MONTH.QUARTER_ID

DIM_MONTH.MONTH_ID
        ↑
DIM_DATE.MONTH_ID
```

## Fact

```text
DIM_CUSTOMER.CUSTOMER_ID
        ↑
FACT_SALES.CUSTOMER_ID

DIM_PRODUCT.PRODUCT_ID
        ↑
FACT_SALES.PRODUCT_ID

DIM_BRANCH.BRANCH_ID
        ↑
FACT_SALES.BRANCH_ID

DIM_DATE.DATE_ID
        ↑
FACT_SALES.DATE_ID
```

---

# 13. Data Validation

After transforming the schema, the data relationships were validated.

The important validation checks were:

### Customer count

```text
DIM_CUSTOMER = 20 rows
```

### Branch count

```text
DIM_BRANCH = 10 rows
```

### Geography

```text
DIM_REGION = 4 rows
DIM_STATE  = 14 rows
DIM_CITY   = 20 rows
```

### Date

```text
DIM_DATE = 31 rows
```

### Fact table

```text
FACT_SALES = 100 rows
```

Foreign-key validation confirmed that all fact records successfully matched the corresponding:

```text
CUSTOMER
PRODUCT
BRANCH
DATE
```

dimensions.

The final validation result was:

```text
TOTAL_FACT_ROWS = 100
VALID_CUSTOMERS = 100
VALID_PRODUCTS  = 100
VALID_BRANCHES  = 100
VALID_DATES     = 100
```

This demonstrates that the normalization did not break the existing fact-to-dimension relationships.

---

# 14. Why LEFT JOIN Was Used for FK Validation

A validation query such as:

```sql
SELECT COUNT(*) AS INVALID_CUSTOMER_KEYS
FROM FACT_SALES F
LEFT JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;
```

means:

1. Start with every fact row.
2. Try to find its matching customer.
3. Keep unmatched fact rows because it is a `LEFT JOIN`.
4. `C.CUSTOMER_ID IS NULL` identifies rows where no customer was found.

Therefore:

```text
INVALID_CUSTOMER_KEYS = 0
```

means every fact customer key successfully found a matching customer.

The same logic was applied to product, branch and date.

---

# 15. Analytical Queries

The normalized Snowflake Schema supports the required business reports.

The Project 6 analytical work includes:

1. Customer-wise Sales
2. Product-wise Revenue
3. Brand-wise Revenue
4. Category-wise Revenue
5. City-wise Sales
6. State-wise Revenue
7. Region-wise Revenue
8. Monthly Revenue
9. Quarterly Revenue
10. Top 10 Customers
11. Top 10 Products
12. Top 10 Branches
13. Customer Purchase Trend
14. Product Performance Dashboard
15. Regional Sales Dashboard

These reports demonstrate that normalization does not prevent analytical reporting.

Instead, analytical queries traverse the appropriate hierarchy.

---

# 16. Example: Region-wise Revenue

To calculate regional revenue:

```text
FACT_SALES
    |
    v
DIM_BRANCH
    |
    v
DIM_CITY
    |
    v
DIM_STATE
    |
    v
DIM_REGION
```

The query follows the hierarchy until it reaches `REGION_NAME`, then aggregates `TOTAL_AMOUNT`.

Conceptually:

```text
Branch
  ↓
City
  ↓
State
  ↓
Region
  ↓
Revenue
```

---

# 17. Example: Category Revenue

For category revenue:

```text
FACT_SALES
    |
    v
DIM_PRODUCT
    |
    v
DIM_BRAND
    |
    v
DIM_CATEGORY
```

The product hierarchy is traversed until the category is reached.

```text
Product
   ↓
Brand
   ↓
Category
   ↓
Revenue
```

---

# 18. Example: Monthly Revenue

For monthly revenue:

```text
FACT_SALES
    |
    v
DIM_DATE
    |
    v
DIM_MONTH
    |
    v
DIM_QUARTER
    |
    v
DIM_YEAR
```

The date hierarchy provides the context required for time-based aggregation.

---

# 19. Star Schema vs Snowflake Schema

## Star Schema

The Star Schema keeps dimensions relatively denormalized.

```text
                 DIM_CUSTOMER
                      |
DIM_PRODUCT --- FACT_SALES --- DIM_BRANCH
                      |
                  DIM_DATE
```

Advantages:

- Fewer joins
- Simpler queries
- Easy for BI/reporting
- Generally easier to understand

Disadvantages:

- More repeated descriptive data
- Higher redundancy
- Changes to shared attributes may require updates in more places

---

## Snowflake Schema

The Snowflake Schema normalizes dimensions.

```text
DIM_REGION
    |
DIM_STATE
    |
DIM_CITY
    |
DIM_BRANCH

DIM_CATEGORY
    |
DIM_BRAND
    |
DIM_PRODUCT

DIM_YEAR
    |
DIM_QUARTER
    |
DIM_MONTH
    |
DIM_DATE
```

Advantages:

- Lower redundancy
- Better separation of hierarchical attributes
- Centralized maintenance of lookup information
- Clear representation of hierarchies

Disadvantages:

- More joins
- More complex SQL
- More tables
- BI queries can be more complicated

---

# 20. Why More Joins Are Required

In the Star Schema, a region may already be directly available in `DIM_BRANCH`.

In the Snowflake Schema, the query must traverse:

```text
BRANCH
  ↓
CITY
  ↓
STATE
  ↓
REGION
```

Therefore the Snowflake Schema normally requires more joins.

This is not a mistake.

It is a direct consequence of normalization.

---

# 21. Important Modeling Lesson

A lookup table should represent a reusable piece of descriptive information.

Examples:

```text
REGION
STATE
CITY

CATEGORY
BRAND

YEAR
QUARTER
MONTH
```

These tables allow multiple dimensions or levels of a hierarchy to reference the same standardized information.

For example:

```text
DIM_CUSTOMER ──┐
               ├──> DIM_CITY
DIM_BRANCH ────┘
```

Both customers and branches can use the same city definition.

This creates a more consistent geography hierarchy.

---

# 22. Important Data-Quality Lesson

While building the geography hierarchy, the initial lookup tables were created from branch data only.

This caused some customer records to fail the lookup because certain customer states/cities did not exist in the branch-derived lookup.

The problem was diagnosed using `LEFT JOIN` validation queries.

The solution was to create geography lookup coverage for both customer and branch data.

This resulted in:

```text
4 regions
14 states
20 cities
20 customers
10 branches
```

and ultimately:

```text
0 invalid customer keys
0 invalid product keys
0 invalid branch keys
0 invalid date keys
```

This is an important real-world ETL/data-modeling lesson:

> A lookup table must contain every valid business value that its referencing tables need.

---

# 23. Important Product-Modeling Lesson

The source data contains brands that can appear in multiple categories.

Therefore, matching a product to a brand using only:

```text
BRAND_NAME
```

can be ambiguous.

The safer resolution is:

```text
BRAND + CATEGORY
```

which identifies the correct `DIM_BRAND` record.

This is why the final product transformation uses both brand and category context.

---

# 24. Why Project 5 Was Not Rebuilt

Project 6 was created separately under:

```text
RETAIL_DB_P4.RETAIL_P6
```

The original schema:

```text
RETAIL_DB_P4.RETAIL
```

was retained as the source/reference.

This provides two benefits:

1. Project 5 remains unchanged.
2. Project 6 can be compared directly with the original Star Schema.

This is safer than modifying the original project tables in place.

---

# 25. Final Project Outcome

Project 6 successfully transforms the retail Star Schema into a normalized Snowflake Schema.

The final design contains:

```text
GEOGRAPHY
DIM_REGION
DIM_STATE
DIM_CITY

CUSTOMER
DIM_CUSTOMER

PRODUCT
DIM_CATEGORY
DIM_BRAND
DIM_PRODUCT

DATE
DIM_YEAR
DIM_QUARTER
DIM_MONTH
DIM_DATE

BRANCH
DIM_BRANCH

FACT
FACT_SALES
```

The schema supports:

- Geographic drill-down
- Product/category/brand analysis
- Time-based analysis
- Customer analysis
- Branch analysis
- Revenue analysis
- Top-N analysis
- Dashboard-style reporting

The transformation was validated using row counts, relationship checks and foreign-key consistency checks.

---

# 26. Key Takeaways

### Star Schema

```text
Simple
Fewer joins
More denormalized
```

### Snowflake Schema

```text
More normalized
More lookup tables
More joins
Less redundancy
Clearer hierarchies
```

### Project 6 Core Learning

The most important concept is not simply creating more tables.

It is understanding:

```text
Repeated attributes
       ↓
Identify hierarchy
       ↓
Create lookup tables
       ↓
Create PK/FK relationships
       ↓
Replace repeated attributes with keys
       ↓
Validate relationships
       ↓
Query through the hierarchy
```

That is the core Snowflake Schema transformation demonstrated by this project.
