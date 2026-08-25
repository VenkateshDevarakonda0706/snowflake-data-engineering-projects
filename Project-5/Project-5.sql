# Project-5 — Retail Sales Data Warehouse Design using Star Schema
```sql
/* ============================================================
   PROJECT-5
   Retail Sales Data Warehouse Design using Star Schema

   Topic: 4.1B - Star Schema

   Project-5 builds on the validated retail sales warehouse
   implemented in Project-4.

   Main focus:
   1. Star Schema architecture
   2. Fact and Dimension relationships
   3. Schema validation
   4. OLAP / BI analytical queries
   5. Star Schema characteristics
   ============================================================ */


/* ============================================================
   1. PROJECT CONTEXT
   ============================================================

   Business Process:
   Retail Sales Analytics

   Business Event:
   A customer purchases a product from a retail branch
   on a specific date.

   Grain:
   One row in FACT_SALES represents one product purchased
   by one customer from one retail branch on one specific date.

   Fact:
   FACT_SALES

   Dimensions:
   DIM_CUSTOMER
   DIM_PRODUCT
   DIM_BRANCH
   DIM_DATE

   Measures:
   QUANTITY
   TOTAL_AMOUNT
   ============================================================ */


/* ============================================================
   2. SELECT PROJECT DATABASE AND SCHEMA
   ============================================================ */

USE DATABASE RETAIL_DB_P4;
USE SCHEMA RETAIL;


/* ============================================================
   3. VERIFY STAR SCHEMA TABLES
   ============================================================ */

SHOW TABLES;


/* Expected core tables:

   DIM_CUSTOMER
   DIM_PRODUCT
   DIM_BRANCH
   DIM_DATE
   FACT_SALES
*/


/* ============================================================
   4. VERIFY DIMENSION STRUCTURES
   ============================================================ */

DESC TABLE DIM_CUSTOMER;

DESC TABLE DIM_PRODUCT;

DESC TABLE DIM_BRANCH;

DESC TABLE DIM_DATE;


/* ============================================================
   5. VERIFY FACT TABLE STRUCTURE
   ============================================================ */

DESC TABLE FACT_SALES;


/* ============================================================
   6. STAR SCHEMA RELATIONSHIP OVERVIEW
   ============================================================

   DIM_CUSTOMER  1 -------- M FACT_SALES
   DIM_PRODUCT   1 -------- M FACT_SALES
   DIM_BRANCH    1 -------- M FACT_SALES
   DIM_DATE      1 -------- M FACT_SALES

   FACT_SALES is the central fact table.
   ============================================================ */


/* ============================================================
   7. ROW COUNT VALIDATION
   ============================================================ */

SELECT
    'DIM_CUSTOMER' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT
FROM DIM_CUSTOMER

UNION ALL

SELECT
    'DIM_PRODUCT',
    COUNT(*)
FROM DIM_PRODUCT

UNION ALL

SELECT
    'DIM_BRANCH',
    COUNT(*)
FROM DIM_BRANCH

UNION ALL

SELECT
    'DIM_DATE',
    COUNT(*)
FROM DIM_DATE

UNION ALL

SELECT
    'FACT_SALES',
    COUNT(*)
FROM FACT_SALES;


/* Expected:

   DIM_CUSTOMER → 20
   DIM_PRODUCT  → 20
   DIM_BRANCH   → 10
   DIM_DATE     → 31
   FACT_SALES   → 100
*/


/* ============================================================
   8. PRIMARY KEY UNIQUENESS VALIDATION
   ============================================================ */

/* Customer */

SELECT
    CUSTOMER_ID,
    COUNT(*) AS CNT
FROM DIM_CUSTOMER
GROUP BY CUSTOMER_ID
HAVING COUNT(*) > 1;


/* Product */

SELECT
    PRODUCT_ID,
    COUNT(*) AS CNT
FROM DIM_PRODUCT
GROUP BY PRODUCT_ID
HAVING COUNT(*) > 1;


/* Branch */

SELECT
    BRANCH_ID,
    COUNT(*) AS CNT
FROM DIM_BRANCH
GROUP BY BRANCH_ID
HAVING COUNT(*) > 1;


/* Date */

SELECT
    DATE_ID,
    COUNT(*) AS CNT
FROM DIM_DATE
GROUP BY DATE_ID
HAVING COUNT(*) > 1;


/* Fact */

SELECT
    SALE_ID,
    COUNT(*) AS CNT
FROM FACT_SALES
GROUP BY SALE_ID
HAVING COUNT(*) > 1;


/* Expected:
   No rows from all five queries.
*/


/* ============================================================
   9. CUSTOMER FOREIGN KEY VALIDATION
   ============================================================ */

SELECT
    COUNT(*) AS INVALID_CUSTOMER_KEYS
FROM FACT_SALES F
LEFT JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;


/* Expected: 0 */


/* ============================================================
   10. PRODUCT FOREIGN KEY VALIDATION
   ============================================================ */

SELECT
    COUNT(*) AS INVALID_PRODUCT_KEYS
FROM FACT_SALES F
LEFT JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_ID IS NULL;


/* Expected: 0 */


/* ============================================================
   11. BRANCH FOREIGN KEY VALIDATION
   ============================================================ */

SELECT
    COUNT(*) AS INVALID_BRANCH_KEYS
FROM FACT_SALES F
LEFT JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
WHERE B.BRANCH_ID IS NULL;


/* Expected: 0 */


/* ============================================================
   12. DATE FOREIGN KEY VALIDATION
   ============================================================ */

SELECT
    COUNT(*) AS INVALID_DATE_KEYS
FROM FACT_SALES F
LEFT JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
WHERE D.DATE_ID IS NULL;


/* Expected: 0 */


/* ============================================================
   13. FACT NULL VALIDATION
   ============================================================ */

SELECT *
FROM FACT_SALES
WHERE CUSTOMER_ID IS NULL
   OR PRODUCT_ID IS NULL
   OR BRANCH_ID IS NULL
   OR DATE_ID IS NULL
   OR QUANTITY IS NULL
   OR TOTAL_AMOUNT IS NULL;


/* Expected: No rows */


/* ============================================================
   14. MEASURE VALIDATION
   ============================================================ */

SELECT
    MIN(QUANTITY) AS MIN_QUANTITY,
    MAX(QUANTITY) AS MAX_QUANTITY,
    SUM(QUANTITY) AS TOTAL_QUANTITY,
    MIN(TOTAL_AMOUNT) AS MIN_AMOUNT,
    MAX(TOTAL_AMOUNT) AS MAX_AMOUNT,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES;


/* ============================================================
   15. POSITIVE MEASURE VALIDATION
   ============================================================ */

SELECT *
FROM FACT_SALES
WHERE QUANTITY <= 0
   OR TOTAL_AMOUNT <= 0;


/* Expected: No rows */


/* ============================================================
   16. GRAIN VALIDATION
   ============================================================

   The grain is:

   One product purchased by one customer from one branch
   on one specific date.

   SALE_ID must identify one fact row.
   ============================================================ */

SELECT
    SALE_ID,
    COUNT(*) AS ROW_COUNT
FROM FACT_SALES
GROUP BY SALE_ID
HAVING COUNT(*) > 1;


/* Expected: No rows */


/* ============================================================
   17. FACT + ALL DIMENSIONS VALIDATION
   ============================================================

   Reconstruct the complete business event by joining the
   fact table with all four dimensions.
   ============================================================ */

SELECT
    F.SALE_ID,

    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.CITY AS CUSTOMER_CITY,
    C.STATE AS CUSTOMER_STATE,
    C.MEMBERSHIP,

    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    P.BRAND,
    P.PRICE,

    B.BRANCH_ID,
    B.BRANCH_NAME,
    B.CITY AS BRANCH_CITY,
    B.STATE AS BRANCH_STATE,
    B.REGION,
    B.MANAGER_NAME,

    D.DATE_ID,
    D.DATE,
    D.DAY,
    D.DAY_NAME,
    D.WEEK_NO,
    D.MONTH,
    D.QUARTER,
    D.YEAR,
    D.IS_WEEKEND,

    F.QUANTITY,
    F.TOTAL_AMOUNT

FROM FACT_SALES F

JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID

JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID

JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID

JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID

ORDER BY F.SALE_ID;


/* ============================================================
   18. REVENUE CALCULATION VALIDATION
   ============================================================

   TOTAL_AMOUNT should equal:

   PRODUCT PRICE × QUANTITY

   based on the supplied source data.
   ============================================================ */

SELECT
    F.SALE_ID,
    F.PRODUCT_ID,
    F.QUANTITY,
    P.PRICE,
    F.TOTAL_AMOUNT,
    P.PRICE * F.QUANTITY AS CALCULATED_AMOUNT
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
WHERE F.TOTAL_AMOUNT <> P.PRICE * F.QUANTITY;


/* Expected: No rows */


/* ============================================================
   19. CUSTOMER-WISE SALES REPORT
   ============================================================ */

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   20. PRODUCT-WISE REVENUE REPORT
   ============================================================ */

SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   21. BRANCH-WISE REVENUE REPORT
   ============================================================ */

SELECT
    B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   22. STATE-WISE REVENUE REPORT
   ============================================================ */

SELECT
    B.STATE,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY B.STATE
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   23. MONTHLY REVENUE REPORT
   ============================================================ */

SELECT
    D.YEAR,
    D.MONTH,
    SUM(F.TOTAL_AMOUNT) AS MONTHLY_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY
    D.YEAR,
    D.MONTH
ORDER BY
    D.YEAR,
    D.MONTH;


/* ============================================================
   24. QUARTERLY REVENUE REPORT
   ============================================================ */

SELECT
    D.YEAR,
    D.QUARTER,
    SUM(F.TOTAL_AMOUNT) AS QUARTERLY_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY
    D.YEAR,
    D.QUARTER
ORDER BY
    D.YEAR,
    D.QUARTER;


/* ============================================================
   25. TOP 10 CUSTOMERS
   ============================================================ */

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;


/* ============================================================
   26. TOP 10 PRODUCTS
   ============================================================ */

SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;


/* ============================================================
   27. TOP 10 PERFORMING BRANCHES
   ============================================================ */

SELECT
    B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;


/* ============================================================
   28. CATEGORY-WISE REVENUE
   ============================================================ */

SELECT
    P.CATEGORY,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   29. CUSTOMER PURCHASE TREND
   ============================================================ */

SELECT
    C.CUSTOMER_NAME,
    D.DATE,
    SUM(F.QUANTITY) AS UNITS_PURCHASED,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY
    C.CUSTOMER_NAME,
    D.DATE
ORDER BY
    C.CUSTOMER_NAME,
    D.DATE;


/* ============================================================
   30. PRODUCT PERFORMANCE DASHBOARD DATA
   ============================================================ */

SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    P.BRAND,
    SUM(F.QUANTITY) AS UNITS_SOLD,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    P.BRAND
ORDER BY REVENUE DESC;


/* ============================================================
   31. BRANCH PERFORMANCE DASHBOARD DATA
   ============================================================ */

SELECT
    B.BRANCH_ID,
    B.BRANCH_NAME,
    B.CITY,
    B.STATE,
    B.REGION,
    SUM(F.QUANTITY) AS UNITS_SOLD,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.BRANCH_ID,
    B.BRANCH_NAME,
    B.CITY,
    B.STATE,
    B.REGION
ORDER BY REVENUE DESC;


/* ============================================================
   32. REGIONAL SALES ANALYSIS
   ============================================================ */

SELECT
    B.REGION,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY B.REGION
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   33. SALES TREND ANALYSIS
   ============================================================ */

SELECT
    D.DATE,
    SUM(F.TOTAL_AMOUNT) AS DAILY_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY D.DATE
ORDER BY D.DATE;


/* ============================================================
   34. CUSTOMER PURCHASE SUMMARY
   ============================================================ */

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    COUNT(F.SALE_ID) AS PURCHASE_COUNT,
    SUM(F.QUANTITY) AS TOTAL_UNITS,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SPEND
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_SPEND DESC;


/* ============================================================
   35. REVENUE BY MEMBERSHIP
   ============================================================ */

SELECT
    C.MEMBERSHIP,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.MEMBERSHIP
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   36. REVENUE CONTRIBUTION BY CATEGORY
   ============================================================ */

SELECT
    P.CATEGORY,
    SUM(F.TOTAL_AMOUNT) AS REVENUE,

    ROUND(
        100 * SUM(F.TOTAL_AMOUNT)
        / SUM(SUM(F.TOTAL_AMOUNT)) OVER (),
        2
    ) AS REVENUE_PERCENT

FROM FACT_SALES F

JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID

GROUP BY P.CATEGORY
ORDER BY REVENUE DESC;


/* ============================================================
   37. WEEKEND VS WEEKDAY REVENUE
   ============================================================ */

SELECT
    D.IS_WEEKEND,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY D.IS_WEEKEND
ORDER BY TOTAL_REVENUE DESC;


/* ============================================================
   38. PRODUCT CATEGORY + BRAND PERFORMANCE
   ============================================================ */

SELECT
    P.CATEGORY,
    P.BRAND,
    SUM(F.QUANTITY) AS UNITS_SOLD,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
    P.CATEGORY,
    P.BRAND
ORDER BY REVENUE DESC;


/* ============================================================
   39. STATE + REGION PERFORMANCE
   ============================================================ */

SELECT
    B.REGION,
    B.STATE,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.REGION,
    B.STATE
ORDER BY REVENUE DESC;


/* ============================================================
   40. FINAL STAR SCHEMA VALIDATION
   ============================================================

   This query confirms that every fact row can connect to
   all four dimensions.

   An INNER JOIN is used deliberately.

   If the result count equals FACT_SALES row count,
   every fact record successfully connects to all dimensions.
   ============================================================ */

SELECT COUNT(*) AS COMPLETE_STAR_SCHEMA_ROWS
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID;


/* Expected:

   COMPLETE_STAR_SCHEMA_ROWS = 100
*/


/* ============================================================
   41. PROJECT-5 STAR SCHEMA SUMMARY
   ============================================================

   FACT TABLE:
       FACT_SALES

   DIMENSIONS:
       DIM_CUSTOMER
       DIM_PRODUCT
       DIM_BRANCH
       DIM_DATE

   FACT PRIMARY KEY:
       SALE_ID

   FACT FOREIGN KEYS:
       CUSTOMER_ID
       PRODUCT_ID
       BRANCH_ID
       DATE_ID

   MEASURES:
       QUANTITY
       TOTAL_AMOUNT

   GRAIN:
       One product purchased by one customer from one
       branch on one specific date.

   RELATIONSHIPS:
       DIM_CUSTOMER  1:M FACT_SALES
       DIM_PRODUCT   1:M FACT_SALES
       DIM_BRANCH    1:M FACT_SALES
       DIM_DATE      1:M FACT_SALES

   WORKLOAD:
       OLAP / Business Intelligence

   ARCHITECTURE:
       STAR SCHEMA

   ============================================================ */
```