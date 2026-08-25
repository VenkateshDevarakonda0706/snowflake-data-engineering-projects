/*
=============================================================
PROJECT-4 : RETAIL SALES DATA WAREHOUSE
=============================================================

Business Process:
    Retail Sales Analytics

Grain:
    One row in FACT_SALES represents one product purchased
    by one customer from one branch on one specific date.

Dimensions:
    DIM_CUSTOMER
    DIM_PRODUCT
    DIM_BRANCH
    DIM_DATE

Fact:
    FACT_SALES

Measures:
    QUANTITY
    TOTAL_AMOUNT

Architecture:
    Star Schema
=============================================================
*/


/*
=============================================================
1. DATABASE AND SCHEMA SETUP
=============================================================
*/

USE WAREHOUSE RETAIL_WH;

USE DATABASE RETAIL_DB_P4;

CREATE SCHEMA IF NOT EXISTS RETAIL;

USE SCHEMA RETAIL;


/*
=============================================================
2. FILE FORMAT
=============================================================
*/

CREATE OR REPLACE FILE FORMAT RETAIL_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE;


/*
=============================================================
3. STAGE
=============================================================
*/

CREATE OR REPLACE STAGE RETAIL_STAGE
    FILE_FORMAT = RETAIL_CSV_FORMAT;


/*
=============================================================
4. DIMENSION TABLES
=============================================================
*/


/*-----------------------------------------------------------
4.1 CUSTOMER DIMENSION
-----------------------------------------------------------*/

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_ID   NUMBER PRIMARY KEY,
    CUSTOMER_NAME VARCHAR,
    CITY          VARCHAR,
    STATE         VARCHAR,
    MEMBERSHIP    VARCHAR
);


/*-----------------------------------------------------------
4.2 PRODUCT DIMENSION
-----------------------------------------------------------*/

CREATE OR REPLACE TABLE DIM_PRODUCT (
    PRODUCT_ID   NUMBER PRIMARY KEY,
    PRODUCT_NAME VARCHAR,
    CATEGORY     VARCHAR,
    BRAND        VARCHAR,
    PRICE        NUMBER(12,2)
);


/*-----------------------------------------------------------
4.3 BRANCH DIMENSION
-----------------------------------------------------------*/

CREATE OR REPLACE TABLE DIM_BRANCH (
    BRANCH_ID    NUMBER PRIMARY KEY,
    BRANCH_NAME  VARCHAR,
    CITY         VARCHAR,
    STATE        VARCHAR,
    REGION       VARCHAR,
    MANAGER_NAME VARCHAR
);


/*-----------------------------------------------------------
4.4 DATE DIMENSION
-----------------------------------------------------------*/

CREATE OR REPLACE TABLE DIM_DATE (
    DATE_ID    NUMBER PRIMARY KEY,
    DATE       DATE,
    DAY        NUMBER,
    DAY_NAME   VARCHAR,
    WEEK_NO    NUMBER,
    MONTH      VARCHAR,
    QUARTER    VARCHAR,
    YEAR       NUMBER,
    IS_WEEKEND VARCHAR
);


/*
=============================================================
5. FACT TABLE
=============================================================
*/

CREATE OR REPLACE TABLE FACT_SALES (
    SALE_ID      NUMBER PRIMARY KEY,
    CUSTOMER_ID  NUMBER,
    PRODUCT_ID   NUMBER,
    BRANCH_ID    NUMBER,
    DATE_ID      NUMBER,
    QUANTITY     NUMBER,
    TOTAL_AMOUNT NUMBER(14,2),

    CONSTRAINT FK_SALES_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES DIM_CUSTOMER(CUSTOMER_ID),

    CONSTRAINT FK_SALES_PRODUCT
        FOREIGN KEY (PRODUCT_ID)
        REFERENCES DIM_PRODUCT(PRODUCT_ID),

    CONSTRAINT FK_SALES_BRANCH
        FOREIGN KEY (BRANCH_ID)
        REFERENCES DIM_BRANCH(BRANCH_ID),

    CONSTRAINT FK_SALES_DATE
        FOREIGN KEY (DATE_ID)
        REFERENCES DIM_DATE(DATE_ID)
);


/*
=============================================================
6. VERIFY TABLE CREATION
=============================================================
*/

SHOW TABLES;

DESC TABLE DIM_CUSTOMER;

DESC TABLE DIM_PRODUCT;

DESC TABLE DIM_BRANCH;

DESC TABLE DIM_DATE;

DESC TABLE FACT_SALES;


/*
=============================================================
7. LOAD DATA FROM STAGE
=============================================================
*/


/*-----------------------------------------------------------
7.1 CUSTOMER DATA
-----------------------------------------------------------*/

COPY INTO DIM_CUSTOMER
FROM @RETAIL_STAGE/customers.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';


/*-----------------------------------------------------------
7.2 PRODUCT DATA
-----------------------------------------------------------*/

COPY INTO DIM_PRODUCT
FROM @RETAIL_STAGE/products.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';


/*-----------------------------------------------------------
7.3 BRANCH DATA
-----------------------------------------------------------*/

COPY INTO DIM_BRANCH
FROM @RETAIL_STAGE/branches.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';


/*-----------------------------------------------------------
7.4 DATE DATA
-----------------------------------------------------------*/

COPY INTO DIM_DATE
FROM @RETAIL_STAGE/calendar.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';


/*-----------------------------------------------------------
7.5 SALES FACT DATA
-----------------------------------------------------------*/

COPY INTO FACT_SALES
FROM @RETAIL_STAGE/sales.csv
FILE_FORMAT = 'RETAIL_CSV_FORMAT';


/*
=============================================================
8. ROW COUNT VALIDATION
=============================================================
*/

SELECT
    (SELECT COUNT(*) FROM DIM_CUSTOMER) AS CUSTOMERS,
    (SELECT COUNT(*) FROM DIM_PRODUCT)  AS PRODUCTS,
    (SELECT COUNT(*) FROM DIM_BRANCH)   AS BRANCHES,
    (SELECT COUNT(*) FROM DIM_DATE)     AS DATES,
    (SELECT COUNT(*) FROM FACT_SALES)   AS SALES;


/*
Expected:
    CUSTOMERS = 20
    PRODUCTS  = 20
    BRANCHES  = 10
    DATES     = 31
    SALES     = 100
*/


/*
=============================================================
9. DATA QUALITY VALIDATION
=============================================================
*/


/*-----------------------------------------------------------
9.1 Check NULL values in FACT_SALES
-----------------------------------------------------------*/

SELECT *
FROM FACT_SALES
WHERE CUSTOMER_ID IS NULL
   OR PRODUCT_ID IS NULL
   OR BRANCH_ID IS NULL
   OR DATE_ID IS NULL
   OR QUANTITY IS NULL
   OR TOTAL_AMOUNT IS NULL;


/*-----------------------------------------------------------
9.2 Check orphan CUSTOMER_ID values
-----------------------------------------------------------*/

SELECT F.CUSTOMER_ID
FROM FACT_SALES F
LEFT JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;


/*-----------------------------------------------------------
9.3 Check orphan PRODUCT_ID values
-----------------------------------------------------------*/

SELECT F.PRODUCT_ID
FROM FACT_SALES F
LEFT JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_ID IS NULL;


/*-----------------------------------------------------------
9.4 Check orphan BRANCH_ID values
-----------------------------------------------------------*/

SELECT F.BRANCH_ID
FROM FACT_SALES F
LEFT JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
WHERE B.BRANCH_ID IS NULL;


/*-----------------------------------------------------------
9.5 Check orphan DATE_ID values
-----------------------------------------------------------*/

SELECT F.DATE_ID
FROM FACT_SALES F
LEFT JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
WHERE D.DATE_ID IS NULL;


/*
=============================================================
10. FACT MEASURE VALIDATION
=============================================================
*/

SELECT
    MIN(QUANTITY) AS MIN_QUANTITY,
    MAX(QUANTITY) AS MAX_QUANTITY,
    SUM(QUANTITY) AS TOTAL_UNITS,
    MIN(TOTAL_AMOUNT) AS MIN_AMOUNT,
    MAX(TOTAL_AMOUNT) AS MAX_AMOUNT,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES;


/*
=============================================================
11. STAR SCHEMA JOIN VALIDATION
=============================================================
*/

SELECT
    F.SALE_ID,
    C.CUSTOMER_NAME,
    P.PRODUCT_NAME,
    B.BRANCH_NAME,
    D.DATE,
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


/*
=============================================================
12. CUSTOMER REVENUE REPORT
=============================================================
*/

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_SALES DESC;


/*
=============================================================
13. PRODUCT REVENUE REPORT
=============================================================
*/

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


/*
=============================================================
14. BRANCH PERFORMANCE REPORT
=============================================================
*/

SELECT
    B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_SALES DESC;


/*
=============================================================
15. MONTHLY REVENUE REPORT
=============================================================
*/

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


/*
=============================================================
16. STATE-WISE SALES REPORT
=============================================================
*/

SELECT
    B.STATE,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY B.STATE
ORDER BY TOTAL_REVENUE DESC;


/*
=============================================================
17. CATEGORY-WISE REVENUE REPORT
=============================================================
*/

SELECT
    P.CATEGORY,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.CATEGORY
ORDER BY TOTAL_REVENUE DESC;


/*
=============================================================
18. TOP 10 CUSTOMERS
=============================================================
*/

SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_SALES DESC
LIMIT 10;


/*
=============================================================
19. TOP 10 PRODUCTS
=============================================================
*/

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


/*
=============================================================
20. TOP 10 BRANCHES
=============================================================
*/

SELECT
    B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY
    B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_SALES DESC
LIMIT 10;


/*
=============================================================
21. SALES TREND ANALYSIS
=============================================================
*/

SELECT
    D.DATE,
    SUM(F.TOTAL_AMOUNT) AS DAILY_REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY D.DATE
ORDER BY D.DATE;


/*
=============================================================
22. REGIONAL SALES ANALYSIS
=============================================================
*/

SELECT
    B.REGION,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM FACT_SALES F
JOIN DIM_BRANCH B
    ON F.BRANCH_ID = B.BRANCH_ID
GROUP BY B.REGION
ORDER BY TOTAL_REVENUE DESC;


/*
=============================================================
23. QUARTERLY REVENUE
=============================================================
*/

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


/*
=============================================================
24. CUSTOMER PURCHASE ANALYSIS
=============================================================
*/

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


/*
=============================================================
25. PRODUCT PERFORMANCE
=============================================================
*/

SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    SUM(F.QUANTITY) AS UNITS_SOLD,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY
ORDER BY REVENUE DESC;


/*
=============================================================
26. REVENUE BY MEMBERSHIP
=============================================================
*/

SELECT
    C.MEMBERSHIP,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.MEMBERSHIP
ORDER BY REVENUE DESC;


/*
=============================================================
27. REVENUE CONTRIBUTION BY CATEGORY
=============================================================
*/

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


/*
=============================================================
28. WEEKEND VS WEEKDAY REVENUE
=============================================================
*/

SELECT
    D.IS_WEEKEND,
    SUM(F.TOTAL_AMOUNT) AS REVENUE
FROM FACT_SALES F
JOIN DIM_DATE D
    ON F.DATE_ID = D.DATE_ID
GROUP BY D.IS_WEEKEND
ORDER BY REVENUE DESC;


/*
=============================================================
END OF PROJECT-4
=============================================================

Project completed:

✓ Snowflake warehouse/database/schema
✓ File format
✓ Internal stage
✓ Dimension tables
✓ Fact table
✓ PK/FK relationships
✓ CSV ingestion
✓ Data validation
✓ Star-schema joins
✓ Customer analysis
✓ Product analysis
✓ Branch analysis
✓ Time analysis
✓ Geographic analysis
✓ Category analysis
✓ Top-N analysis
✓ Sales trend analysis
✓ Regional analysis
✓ Quarterly analysis
✓ Customer purchase analysis
✓ Product performance
✓ Additional business analysis

KPIs are intentionally excluded from this file as requested.
=============================================================
*/