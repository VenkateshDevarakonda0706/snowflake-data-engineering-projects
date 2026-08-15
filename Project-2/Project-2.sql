/* =========================================================
 PROJECT-2
 RETAIL SALES ANALYTICS
 ========================================================= */
/* =========================================================
 PHASE 1 — SNOWFLAKE ENVIRONMENT
 ========================================================= */
/* 1. Create Warehouse */
CREATE WAREHOUSE IF NOT EXISTS RETAIL_WH WITH WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
/* 2. Use Warehouse */
USE WAREHOUSE RETAIL_WH;
/* 3. Create Database */
CREATE DATABASE IF NOT EXISTS RETAIL_DB;
/* 4. Use Database */
USE DATABASE RETAIL_DB;
/* 5. Create Schema */
CREATE SCHEMA IF NOT EXISTS SALES_SCHEMA;
/* 6. Use Schema */
USE SCHEMA SALES_SCHEMA;
/* 7. Create CSV File Format */
CREATE OR REPLACE FILE FORMAT RETAIL_CSV_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1;
/* 8. Create Internal Stage */
CREATE OR REPLACE STAGE RETAIL_STAGE FILE_FORMAT = RETAIL_CSV_FORMAT;
/* 9. Check Stage */
LIST @RETAIL_STAGE;
/* =========================================================
 PHASE 2 — TABLE CREATION
 ========================================================= */
/* 10. Create Customers Table */
CREATE OR REPLACE TABLE CUSTOMERS (
        customer_id NUMBER,
        customer_name VARCHAR(100),
        city VARCHAR(100),
        membership VARCHAR(50)
    );
/* 11. Create Products Table */
CREATE OR REPLACE TABLE PRODUCTS (
        product_id NUMBER,
        product_name VARCHAR(100),
        category VARCHAR(100),
        price NUMBER(12, 2)
    );
/* 12. Create Branches Table */
CREATE OR REPLACE TABLE BRANCHES (
        branch_id NUMBER,
        branch_name VARCHAR(100),
        city VARCHAR(100)
    );
/* 13. Create Sales Table */
CREATE OR REPLACE TABLE SALES (
        sale_id NUMBER,
        customer_id NUMBER,
        product_id NUMBER,
        branch_id NUMBER,
        quantity NUMBER,
        sale_date DATE,
        total_amount NUMBER(12, 2)
    );
/* =========================================================
 PHASE 2 — DATA LOADING
 ========================================================= */
/* 14. Load Customers */
COPY INTO CUSTOMERS
FROM @RETAIL_STAGE / customers.csv FILE_FORMAT = RETAIL_CSV_FORMAT;
/* 15. Load Products */
COPY INTO PRODUCTS
FROM @RETAIL_STAGE / products.csv FILE_FORMAT = RETAIL_CSV_FORMAT;
/* 16. Load Branches */
COPY INTO BRANCHES
FROM @RETAIL_STAGE / branches.csv FILE_FORMAT = RETAIL_CSV_FORMAT;
/* 17. Load Sales */
COPY INTO SALES
FROM @RETAIL_STAGE / sales.csv FILE_FORMAT = RETAIL_CSV_FORMAT;
/* 18. Verify Customers */
SELECT *
FROM CUSTOMERS
ORDER BY customer_id;
/* 19. Verify Products */
SELECT *
FROM PRODUCTS
ORDER BY product_id;
/* 20. Verify Branches */
SELECT *
FROM BRANCHES
ORDER BY branch_id;
/* 21. Verify Sales */
SELECT *
FROM SALES
ORDER BY sale_id;
/* =========================================================
 PHASE 3 — SQL ANALYTICS
 ========================================================= */
/* 22. Display All Customers */
SELECT *
FROM CUSTOMERS
ORDER BY customer_id;
/* 23. Display All Products */
SELECT *
FROM PRODUCTS
ORDER BY product_id;
/* 24. Display All Branches */
SELECT *
FROM BRANCHES
ORDER BY branch_id;
/* 25. Display All Sales Transactions */
SELECT *
FROM SALES
ORDER BY sale_id;
/* 26. Total Business Revenue */
SELECT SUM(total_amount) AS total_business_revenue
FROM SALES;
/* 27. Customer-wise Sales */
SELECT c.customer_id,
    c.customer_name,
    c.city,
    c.membership,
    SUM(s.total_amount) AS total_spent
FROM SALES s
    JOIN CUSTOMERS c ON s.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.customer_name,
    c.city,
    c.membership
ORDER BY total_spent DESC;
/* 28. Branch-wise Sales */
SELECT b.branch_id,
    b.branch_name,
    b.city,
    SUM(s.total_amount) AS total_sales
FROM SALES s
    JOIN BRANCHES b ON s.branch_id = b.branch_id
GROUP BY b.branch_id,
    b.branch_name,
    b.city
ORDER BY total_sales DESC;
/* 29. Product-wise Sales */
SELECT p.product_id,
    p.product_name,
    p.category,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue
FROM SALES s
    JOIN PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.product_id,
    p.product_name,
    p.category
ORDER BY total_revenue DESC;
/* 30. Category-wise Sales */
SELECT p.category,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue
FROM SALES s
    JOIN PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
/* 31. Highest Revenue Branch */
SELECT b.branch_id,
    b.branch_name,
    SUM(s.total_amount) AS total_revenue
FROM SALES s
    JOIN BRANCHES b ON s.branch_id = b.branch_id
GROUP BY b.branch_id,
    b.branch_name
ORDER BY total_revenue DESC
LIMIT 1;
/* 32. Highest Spending Customer */
SELECT c.customer_id,
    c.customer_name,
    SUM(s.total_amount) AS total_spending
FROM SALES s
    JOIN CUSTOMERS c ON s.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.customer_name
ORDER BY total_spending DESC
LIMIT 1;
/* 33. Top Three Products by Revenue */
SELECT p.product_id,
    p.product_name,
    SUM(s.total_amount) AS total_revenue
FROM SALES s
    JOIN PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.product_id,
    p.product_name
ORDER BY total_revenue DESC
LIMIT 3;
/* 34. Top Three Customers by Spending */
SELECT c.customer_id,
    c.customer_name,
    SUM(s.total_amount) AS total_spending
FROM SALES s
    JOIN CUSTOMERS c ON s.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.customer_name
ORDER BY total_spending DESC
LIMIT 3;
/* =========================================================
 PHASE 4 — WINDOW FUNCTIONS
 ========================================================= */
/* 35. Rank Customers by Total Spending */
SELECT customer_id,
    customer_name,
    total_spending,
    RANK() OVER (
        ORDER BY total_spending DESC
    ) AS customer_rank
FROM (
        SELECT c.customer_id,
            c.customer_name,
            SUM(s.total_amount) AS total_spending
        FROM SALES s
            JOIN CUSTOMERS c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id,
            c.customer_name
    );
/* 36. Rank Branches by Total Sales */
SELECT branch_id,
    branch_name,
    total_sales,
    RANK() OVER (
        ORDER BY total_sales DESC
    ) AS branch_rank
FROM (
        SELECT b.branch_id,
            b.branch_name,
            SUM(s.total_amount) AS total_sales
        FROM SALES s
            JOIN BRANCHES b ON s.branch_id = b.branch_id
        GROUP BY b.branch_id,
            b.branch_name
    );
/* 37. Top-Selling Product in Each Category */
SELECT product_id,
    product_name,
    category,
    total_revenue
FROM (
        SELECT p.product_id,
            p.product_name,
            p.category,
            SUM(s.total_amount) AS total_revenue,
            ROW_NUMBER() OVER (
                PARTITION BY p.category
                ORDER BY SUM(s.total_amount) DESC
            ) AS rn
        FROM SALES s
            JOIN PRODUCTS p ON s.product_id = p.product_id
        GROUP BY p.product_id,
            p.product_name,
            p.category
    )
WHERE rn = 1;
/* 38. Cumulative Sales */
SELECT sale_id,
    sale_date,
    total_amount,
    SUM(total_amount) OVER (
        ORDER BY sale_date,
            sale_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM SALES
ORDER BY sale_date,
    sale_id;
/* 39. Average Sale Amount */
SELECT sale_id,
    sale_date,
    total_amount,
    ROUND(
        AVG(total_amount) OVER (),
        2
    ) AS average_sale_amount
FROM SALES
ORDER BY sale_date,
    sale_id;
/* =========================================================
 PHASE 5 — COMMON TABLE EXPRESSIONS
 ========================================================= */
/* 40. Customer-wise Revenue Using CTE */
WITH customer_sales AS (
    SELECT c.customer_id,
        c.customer_name,
        SUM(s.total_amount) AS total_revenue
    FROM SALES s
        JOIN CUSTOMERS c ON s.customer_id = c.customer_id
    GROUP BY c.customer_id,
        c.customer_name
)
SELECT *
FROM customer_sales
ORDER BY total_revenue DESC;
/* 41. Customers Spending Greater Than Average */
WITH customer_sales AS (
    SELECT c.customer_id,
        c.customer_name,
        SUM(s.total_amount) AS total_spending
    FROM SALES s
        JOIN CUSTOMERS c ON s.customer_id = c.customer_id
    GROUP BY c.customer_id,
        c.customer_name
),
average_spending AS (
    SELECT AVG(total_spending) AS avg_spending
    FROM customer_sales
)
SELECT cs.customer_id,
    cs.customer_name,
    cs.total_spending
FROM customer_sales cs
    CROSS JOIN average_spending av
WHERE cs.total_spending > av.avg_spending
ORDER BY cs.total_spending DESC;
/* =========================================================
 PHASE 6 — VIEWS
 ========================================================= */
/* 42. Create SALES_REPORT View */
CREATE OR REPLACE VIEW SALES_REPORT AS
SELECT s.sale_id,
    s.sale_date,
    c.customer_name,
    p.product_name,
    p.category,
    b.branch_name,
    s.quantity,
    s.total_amount
FROM SALES s
    JOIN CUSTOMERS c ON s.customer_id = c.customer_id
    JOIN PRODUCTS p ON s.product_id = p.product_id
    JOIN BRANCHES b ON s.branch_id = b.branch_id;
/* 43. Query SALES_REPORT */
SELECT *
FROM SALES_REPORT
ORDER BY sale_id;
/* 44. Create TOP_CUSTOMERS Materialized View */
CREATE OR REPLACE MATERIALIZED VIEW TOP_CUSTOMERS AS
SELECT customer_id,
    SUM(total_amount) AS total_spending
FROM SALES
GROUP BY customer_id;
/* 45. Query TOP_CUSTOMERS */
SELECT tc.customer_id,
    c.customer_name,
    tc.total_spending
FROM TOP_CUSTOMERS tc
    JOIN CUSTOMERS c ON tc.customer_id = c.customer_id
ORDER BY tc.total_spending DESC;
/* =========================================================
 FINAL VERIFICATION
 ========================================================= */
/* 46. Show Tables */
SHOW TABLES;
/* 47. Show Views */
SHOW VIEWS;
/* 48. Show Materialized Views */
SHOW MATERIALIZED VIEWS;
/* 49. Describe Materialized View */
DESC MATERIALIZED VIEW TOP_CUSTOMERS;
/* 50. Final Sales Report */
SELECT *
FROM SALES_REPORT
ORDER BY sale_id;
/* 51. Final Top Customers Report */
SELECT tc.customer_id,
    c.customer_name,
    tc.total_spending
FROM TOP_CUSTOMERS tc
    JOIN CUSTOMERS c ON tc.customer_id = c.customer_id
ORDER BY tc.total_spending DESC;