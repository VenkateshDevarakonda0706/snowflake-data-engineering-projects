/*
 ===============================================================================
 PROJECT-3
 Enterprise Incremental Sales Data Warehouse using Snowflake
 ===============================================================================
 
 WAREHOUSE : ENTERPRISE_WH
 DATABASE  : ENTERPRISE_DB
 SCHEMA    : SALES_SCHEMA
 
 Main Concepts:
 - Snowflake Warehouse
 - Database
 - Schema
 - File Format
 - Internal Stage
 - COPY INTO
 - Streams
 - MERGE
 - Tasks
 - Time Travel
 - Zero Copy Clone
 - Views
 - Materialized Views
 - JOIN
 - GROUP BY
 - CTE
 - Window Functions
 - Ranking
 ===============================================================================
 */
/*
 ===============================================================================
 PHASE 1: SNOWFLAKE ENVIRONMENT
 ===============================================================================
 */
-- 1. Create Warehouse
CREATE OR REPLACE WAREHOUSE ENTERPRISE_WH WITH WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
-- Use Warehouse
USE WAREHOUSE ENTERPRISE_WH;
-- 2. Create Database
CREATE OR REPLACE DATABASE ENTERPRISE_DB;
-- Use Database
USE DATABASE ENTERPRISE_DB;
-- 3. Create Schema
CREATE OR REPLACE SCHEMA SALES_SCHEMA;
-- Use Schema
USE SCHEMA SALES_SCHEMA;
-- 4. Create CSV File Format
CREATE OR REPLACE FILE FORMAT ENTERPRISE_CSV_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('NULL', 'null');
-- 5. Create Internal Stage
CREATE OR REPLACE STAGE ENTERPRISE_STAGE FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
/*
 ===============================================================================
 PHASE 2: DATA LOADING
 ===============================================================================
 */
-- Check files uploaded to the stage
LIST @ENTERPRISE_STAGE;
-- ============================================================================
-- Create Customers Table
-- ============================================================================
CREATE OR REPLACE TABLE CUSTOMERS (
        CUSTOMER_ID NUMBER,
        CUSTOMER_NAME VARCHAR,
        CITY VARCHAR,
        MEMBERSHIP VARCHAR
    );
-- Load Customers
COPY INTO CUSTOMERS
FROM @ENTERPRISE_STAGE / customers.csv FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
-- Verify Customers
SELECT *
FROM CUSTOMERS
ORDER BY CUSTOMER_ID;
-- ============================================================================
-- Create Products Table
-- ============================================================================
CREATE OR REPLACE TABLE PRODUCTS (
        PRODUCT_ID NUMBER,
        PRODUCT_NAME VARCHAR,
        CATEGORY VARCHAR,
        PRICE NUMBER(10, 2)
    );
-- Load Products
COPY INTO PRODUCTS
FROM @ENTERPRISE_STAGE / products.csv FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
-- Verify Products
SELECT *
FROM PRODUCTS
ORDER BY PRODUCT_ID;
-- ============================================================================
-- Create Branches Table
-- ============================================================================
CREATE OR REPLACE TABLE BRANCHES (
        BRANCH_ID NUMBER,
        BRANCH_NAME VARCHAR,
        STATE VARCHAR
    );
-- Load Branches
COPY INTO BRANCHES
FROM @ENTERPRISE_STAGE / branches.csv FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
-- Verify Branches
SELECT *
FROM BRANCHES
ORDER BY BRANCH_ID;
-- ============================================================================
-- Create Historical Sales Table
-- ============================================================================
CREATE OR REPLACE TABLE SALES (
        SALE_ID NUMBER,
        CUSTOMER_ID NUMBER,
        PRODUCT_ID NUMBER,
        BRANCH_ID NUMBER,
        QUANTITY NUMBER,
        SALE_DATE DATE,
        TOTAL_AMOUNT NUMBER(12, 2)
    );
-- Load Historical Sales
COPY INTO SALES
FROM @ENTERPRISE_STAGE / sales_history.csv FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
-- Verify Historical Sales
SELECT *
FROM SALES
ORDER BY SALE_ID;
-- ============================================================================
-- Create New Sales Table
-- ============================================================================
CREATE OR REPLACE TABLE NEW_SALES (
        SALE_ID NUMBER,
        CUSTOMER_ID NUMBER,
        PRODUCT_ID NUMBER,
        BRANCH_ID NUMBER,
        QUANTITY NUMBER,
        SALE_DATE DATE,
        TOTAL_AMOUNT NUMBER(12, 2)
    );
-- Load New Sales
COPY INTO NEW_SALES
FROM @ENTERPRISE_STAGE / new_sales.csv FILE_FORMAT = ENTERPRISE_CSV_FORMAT;
-- Verify New Sales
SELECT *
FROM NEW_SALES
ORDER BY SALE_ID;
/*
 ===============================================================================
 PHASE 3: INCREMENTAL LOADING
 ===============================================================================
 */
-- 10. Create Stream on SALES
CREATE OR REPLACE STREAM SALES_STREAM ON TABLE SALES;
-- Check Stream
SELECT *
FROM SALES_STREAM;
-- ============================================================================
-- Insert New Sales into NEW_SALES
-- ============================================================================
-- The new_sales.csv data was initially loaded into NEW_SALES.
-- We use NEW_SALES as the source for incremental processing.
SELECT *
FROM NEW_SALES
ORDER BY SALE_ID;
-- ============================================================================
-- MERGE New Sales into SALES
-- ============================================================================
MERGE INTO SALES AS TARGET USING NEW_SALES AS SOURCE ON TARGET.SALE_ID = SOURCE.SALE_ID
WHEN MATCHED THEN
UPDATE
SET TARGET.CUSTOMER_ID = SOURCE.CUSTOMER_ID,
    TARGET.PRODUCT_ID = SOURCE.PRODUCT_ID,
    TARGET.BRANCH_ID = SOURCE.BRANCH_ID,
    TARGET.QUANTITY = SOURCE.QUANTITY,
    TARGET.SALE_DATE = SOURCE.SALE_DATE,
    TARGET.TOTAL_AMOUNT = SOURCE.TOTAL_AMOUNT
    WHEN NOT MATCHED THEN
INSERT (
        SALE_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        BRANCH_ID,
        QUANTITY,
        SALE_DATE,
        TOTAL_AMOUNT
    )
VALUES (
        SOURCE.SALE_ID,
        SOURCE.CUSTOMER_ID,
        SOURCE.PRODUCT_ID,
        SOURCE.BRANCH_ID,
        SOURCE.QUANTITY,
        SOURCE.SALE_DATE,
        SOURCE.TOTAL_AMOUNT
    );
-- Verify Incremental Load
SELECT *
FROM SALES
ORDER BY SALE_ID;
/*
 ===============================================================================
 PHASE 4: DATA VALIDATION
 ===============================================================================
 */
-- 14. Identify Duplicate Sale IDs
SELECT SALE_ID,
    COUNT(*) AS DUPLICATE_COUNT
FROM SALES
GROUP BY SALE_ID
HAVING COUNT(*) > 1;
-- 15. Identify Missing Customer IDs
SELECT S.*
FROM SALES AS S
    LEFT JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;
-- 16. Display Invalid Product IDs
SELECT S.*
FROM SALES AS S
    LEFT JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_ID IS NULL;
-- 17. Count Total Newly Inserted Records
SELECT COUNT(*) AS TOTAL_NEW_RECORDS
FROM NEW_SALES;
/*
 ===============================================================================
 PHASE 5: TIME TRAVEL
 ===============================================================================
 */
-- 18. Delete one sales record
DELETE FROM SALES
WHERE SALE_ID = 5;
-- Verify deletion
SELECT *
FROM SALES
WHERE SALE_ID = 5;
-- 19. Recover Deleted Record Using Time Travel
-- Replace the timestamp with the appropriate time from your execution.
SELECT *
FROM SALES BEFORE (STATEMENT => '<DELETE_QUERY_ID>');
/*
            or
SELECT *
FROM CUSTOMER
AT (TIMESTAMP => '2026-08-20 10:00:00');
            or
SELECT *
FROM CUSTOMER
AT (OFFSET => -60*5);
            or
UNDROP TABLE CUSTOMER;
*/

-- Recover by inserting the historical record back
INSERT INTO SALES
SELECT *
FROM SALES BEFORE (STATEMENT => '<DELETE_QUERY_ID>')
WHERE SALE_ID = 5;
-- 20. Verify Recovery
SELECT *
FROM SALES
WHERE SALE_ID = 5;
/*
 ===============================================================================
 PHASE 6: ZERO COPY CLONE
 ===============================================================================
 */
-- 21. Create Zero Copy Clone
CREATE OR REPLACE TABLE SALES_TEST CLONE SALES;
-- 22. Display Cloned Records
SELECT *
FROM SALES_TEST
ORDER BY SALE_ID;
-- 23. Insert New Record into Clone
INSERT INTO SALES_TEST (
        SALE_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        BRANCH_ID,
        QUANTITY,
        SALE_DATE,
        TOTAL_AMOUNT
    )
VALUES (
        999,
        1,
        101,
        1,
        1,
        '2026-07-20',
        60000
    );
-- Verify Clone
SELECT *
FROM SALES_TEST
ORDER BY SALE_ID;
-- 24. Verify Original SALES Remains Unchanged
SELECT *
FROM SALES
ORDER BY SALE_ID;
/*
 ===============================================================================
 PHASE 7: TASK AUTOMATION
 ===============================================================================
 */
-- Create Task for Incremental Loading
CREATE OR REPLACE TASK DAILY_SALES_INCREMENTAL_TASK WAREHOUSE = ENTERPRISE_WH SCHEDULE = 'USING CRON 0 0 * * * UTC' AS MERGE INTO SALES AS TARGET USING NEW_SALES AS SOURCE ON TARGET.SALE_ID = SOURCE.SALE_ID
    WHEN MATCHED THEN
UPDATE
SET TARGET.CUSTOMER_ID = SOURCE.CUSTOMER_ID,
    TARGET.PRODUCT_ID = SOURCE.PRODUCT_ID,
    TARGET.BRANCH_ID = SOURCE.BRANCH_ID,
    TARGET.QUANTITY = SOURCE.QUANTITY,
    TARGET.SALE_DATE = SOURCE.SALE_DATE,
    TARGET.TOTAL_AMOUNT = SOURCE.TOTAL_AMOUNT
    WHEN NOT MATCHED THEN
INSERT (
        SALE_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        BRANCH_ID,
        QUANTITY,
        SALE_DATE,
        TOTAL_AMOUNT
    )
VALUES (
        SOURCE.SALE_ID,
        SOURCE.CUSTOMER_ID,
        SOURCE.PRODUCT_ID,
        SOURCE.BRANCH_ID,
        SOURCE.QUANTITY,
        SOURCE.SALE_DATE,
        SOURCE.TOTAL_AMOUNT
    );
-- Resume Task
ALTER TASK DAILY_SALES_INCREMENTAL_TASK RESUME;
-- Check Task
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
-- Manual Task Execution for Testing
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
-- ============================================================================
-- Task Testing: UPDATE
-- ============================================================================
UPDATE NEW_SALES
SET TOTAL_AMOUNT = 27000
WHERE SALE_ID = 6;
SELECT *
FROM NEW_SALES
WHERE SALE_ID = 6;
-- Execute Task
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
-- Verify Update
SELECT *
FROM SALES
WHERE SALE_ID = 6;
-- ============================================================================
-- Task Testing: INSERT
-- ============================================================================
INSERT INTO NEW_SALES (
        SALE_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        BRANCH_ID,
        QUANTITY,
        SALE_DATE,
        TOTAL_AMOUNT
    )
VALUES (
        11,
        1,
        103,
        1,
        1,
        '2026-07-11',
        15000
    );
SELECT *
FROM NEW_SALES
WHERE SALE_ID = 11;
-- Execute Task
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
-- Verify Insert
SELECT *
FROM SALES
WHERE SALE_ID = 11;
-- ============================================================================
-- Task Testing: UPDATE SALE_ID = 11
-- ============================================================================
UPDATE NEW_SALES
SET TOTAL_AMOUNT = 18000
WHERE SALE_ID = 11;
SELECT *
FROM NEW_SALES
WHERE SALE_ID = 11;
-- Execute Task
EXECUTE TASK DAILY_SALES_INCREMENTAL_TASK;
-- Verify Update
SELECT *
FROM SALES
WHERE SALE_ID = 11;
-- ============================================================================
-- Change Schedule for Testing
-- ============================================================================
ALTER TASK DAILY_SALES_INCREMENTAL_TASK SUSPEND;
ALTER TASK DAILY_SALES_INCREMENTAL_TASK
SET SCHEDULE = '5 MINUTE';
ALTER TASK DAILY_SALES_INCREMENTAL_TASK RESUME;
-- Verify Task Configuration
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
-- ============================================================================
-- Automatic Task Test
-- ============================================================================
INSERT INTO NEW_SALES (
        SALE_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        BRANCH_ID,
        QUANTITY,
        SALE_DATE,
        TOTAL_AMOUNT
    )
VALUES (
        12,
        2,
        105,
        2,
        2,
        '2026-07-12',
        30000
    );
-- Wait for automatic task execution, then verify
SELECT *
FROM SALES
WHERE SALE_ID = 12;
-- Update Source
UPDATE NEW_SALES
SET TOTAL_AMOUNT = 35000
WHERE SALE_ID = 12;
-- Wait for automatic task execution, then verify
SELECT *
FROM SALES
WHERE SALE_ID = 12;
-- ============================================================================
-- Task History
-- ============================================================================
SELECT NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(
        INFORMATION_SCHEMA.TASK_HISTORY(
            TASK_NAME => 'DAILY_SALES_INCREMENTAL_TASK',
            RESULT_LIMIT => 10
        )
    )
ORDER BY SCHEDULED_TIME DESC;
-- Final Task Configuration
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
-- Suspend Task After Testing
ALTER TASK DAILY_SALES_INCREMENTAL_TASK SUSPEND;
/*
 ===============================================================================
 PHASE 8: BUSINESS ANALYTICS
 ===============================================================================
 */
-- 28. Customer Revenue Report
SELECT C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_REVENUE DESC;
-- 29. Branch Revenue Report
SELECT B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN BRANCHES AS B ON S.BRANCH_ID = B.BRANCH_ID
GROUP BY B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_REVENUE DESC;
-- 30. Product Revenue Report
SELECT P.PRODUCT_ID,
    P.PRODUCT_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.PRODUCT_ID,
    P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;
-- 31. Monthly Revenue Report
SELECT DATE_TRUNC('MONTH', SALE_DATE) AS MONTH,
    SUM(TOTAL_AMOUNT) AS MONTHLY_REVENUE
FROM SALES
GROUP BY DATE_TRUNC('MONTH', SALE_DATE)
ORDER BY MONTH;
-- 32. Highest Revenue Customer
SELECT C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 1;
-- 33. Highest Revenue Branch
SELECT B.BRANCH_ID,
    B.BRANCH_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN BRANCHES AS B ON S.BRANCH_ID = B.BRANCH_ID
GROUP BY B.BRANCH_ID,
    B.BRANCH_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 1;
-- 34. Top Five Products
SELECT P.PRODUCT_ID,
    P.PRODUCT_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES AS S
    JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY P.PRODUCT_ID,
    P.PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 5;
-- 35. Customer Purchase Frequency
SELECT C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    COUNT(S.SALE_ID) AS PURCHASE_FREQUENCY
FROM SALES AS S
    JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY PURCHASE_FREQUENCY DESC;
-- 36. Running Revenue
SELECT SALE_ID,
    SALE_DATE,
    TOTAL_AMOUNT,
    SUM(TOTAL_AMOUNT) OVER (
        ORDER BY SALE_DATE,
            SALE_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RUNNING_REVENUE
FROM SALES
ORDER BY SALE_DATE,
    SALE_ID;
-- 37. Customer Ranking
SELECT C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE,
    RANK() OVER (
        ORDER BY SUM(S.TOTAL_AMOUNT) DESC
    ) AS CUSTOMER_RANK
FROM SALES AS S
    JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID,
    C.CUSTOMER_NAME
ORDER BY CUSTOMER_RANK;
/*
 ===============================================================================
 PHASE 9: VIEWS
 ===============================================================================
 */
-- 38. Customer Revenue View
CREATE OR REPLACE VIEW CUSTOMER_REVENUE AS
SELECT C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    SUM(S.TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM CUSTOMERS AS C
    JOIN SALES AS S ON S.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID,
    C.CUSTOMER_NAME;
-- Display Customer Revenue View
SELECT *
FROM CUSTOMER_REVENUE
ORDER BY TOTAL_REVENUE DESC;
-- ============================================================================
-- 39. Branch Revenue Materialized View
-- ============================================================================
-- Snowflake Materialized Views have restrictions on table references.
-- Therefore the MV uses only SALES.
CREATE OR REPLACE MATERIALIZED VIEW BRANCH_REVENUE AS
SELECT BRANCH_ID,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM SALES
GROUP BY BRANCH_ID;
-- 40. Display Materialized View with Branch Names
SELECT M.BRANCH_ID,
    B.BRANCH_NAME,
    M.TOTAL_REVENUE
FROM BRANCH_REVENUE AS M
    JOIN BRANCHES AS B ON M.BRANCH_ID = B.BRANCH_ID
ORDER BY M.TOTAL_REVENUE DESC;
/*
 ===============================================================================
 FINAL VERIFICATION
 ===============================================================================
 */
-- Final Sales Count
SELECT COUNT(*) AS TOTAL_SALES
FROM SALES;
-- Final Sales Data
SELECT *
FROM SALES
ORDER BY SALE_ID;
-- Final Task Status
SHOW TASKS LIKE 'DAILY_SALES_INCREMENTAL_TASK';
/*
 ===============================================================================
 END OF PROJECT-3
 ===============================================================================
 */