/* =========================================================
 PROJECT-1
 CUSTOMER SALES ANALYTICS USING SNOWFLAKE
 ========================================================= */
/* =========================================================
 PHASE 1 — SNOWFLAKE ENVIRONMENT SETUP
 ========================================================= */
/* ---------------------------------------------------------
 TASK 1 — CREATE WAREHOUSE
 --------------------------------------------------------- */
CREATE WAREHOUSE IF NOT EXISTS SALES_WH WITH WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
/* Use the warehouse */
USE WAREHOUSE SALES_WH;
/* ---------------------------------------------------------
 TASK 2 — CREATE DATABASE
 --------------------------------------------------------- */
CREATE DATABASE IF NOT EXISTS CUSTOMER_SALES_DB;
/* ---------------------------------------------------------
 TASK 3 — CREATE SCHEMA
 --------------------------------------------------------- */
CREATE SCHEMA IF NOT EXISTS CUSTOMER_SALES_DB.SALES_SCHEMA;
/* ---------------------------------------------------------
 TASK 4 — SELECT DATABASE AND SCHEMA
 --------------------------------------------------------- */
USE DATABASE CUSTOMER_SALES_DB;
USE SCHEMA SALES_SCHEMA;
/* ---------------------------------------------------------
 TASK 5 — CREATE CSV FILE FORMAT
 --------------------------------------------------------- */
CREATE OR REPLACE FILE FORMAT SALES_CSV_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1;
/* ---------------------------------------------------------
 TASK 6 — CREATE INTERNAL STAGE
 --------------------------------------------------------- */
CREATE OR REPLACE STAGE SALES_STAGE FILE_FORMAT = SALES_CSV_FORMAT;
/* =========================================================
 PHASE 2 — DATA LOADING
 ========================================================= */
/* ---------------------------------------------------------
 TASK 8 — CREATE TABLE: CUSTOMERS
 --------------------------------------------------------- */
CREATE OR REPLACE TABLE CUSTOMERS (
        customer_id NUMBER,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        email VARCHAR(255),
        phone VARCHAR(20),
        address VARCHAR(100)
    );
/* ---------------------------------------------------------
 CREATE TABLE: FOODITEMS
 --------------------------------------------------------- */
CREATE OR REPLACE TABLE FOODITEMS (
        food_id NUMBER,
        name VARCHAR(100),
        price NUMBER(10, 2),
        category VARCHAR(100),
        availability VARCHAR(50)
    );
/* ---------------------------------------------------------
 CREATE TABLE: ORDERS
 --------------------------------------------------------- */
CREATE OR REPLACE TABLE ORDERS (
        order_id NUMBER,
        customer_id NUMBER,
        food_id NUMBER,
        quantity NUMBER,
        order_date TIMESTAMP,
        status VARCHAR(50),
        total_amount NUMBER(10, 2)
    );
/* =========================================================
 TASK 9 — LOAD DATA USING COPY INTO
 ========================================================= */
/* Customers */
COPY INTO CUSTOMERS
FROM @SALES_STAGE / customers.csv FILE_FORMAT = SALES_CSV_FORMAT;
/* Food items */
COPY INTO FOODITEMS
FROM @SALES_STAGE / fooditems.csv FILE_FORMAT = SALES_CSV_FORMAT;
/* Orders */
COPY INTO ORDERS
FROM @SALES_STAGE / orders.csv FILE_FORMAT = SALES_CSV_FORMAT;
/* =========================================================
 TASK 10 — VERIFY DATA
 ========================================================= */
/* Customers */
SELECT *
FROM CUSTOMERS;
/* Food items */
SELECT *
FROM FOODITEMS;
/* Orders */
SELECT *
FROM ORDERS;
/* =========================================================
 PHASE 3 — OFFICIAL ANALYTICAL QUERIES
 ========================================================= */
/* ---------------------------------------------------------
 TASK 11 — DISPLAY ALL CUSTOMER DETAILS
 --------------------------------------------------------- */
SELECT *
FROM CUSTOMERS
ORDER BY customer_id;
/* ---------------------------------------------------------
 TASK 12 — DISPLAY ALL FOOD ITEM DETAILS
 --------------------------------------------------------- */
SELECT *
FROM FOODITEMS
ORDER BY food_id;
/* ---------------------------------------------------------
 TASK 13 — DISPLAY ALL ORDER DETAILS
 --------------------------------------------------------- */
SELECT *
FROM ORDERS
ORDER BY order_id;
/* ---------------------------------------------------------
 TASK 14 — CUSTOMER-WISE SALES REPORT
 --------------------------------------------------------- */
SELECT c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_amount_spent
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_amount_spent DESC;
/* ---------------------------------------------------------
 TASK 15 — HIGHEST SPENDING CUSTOMER
 --------------------------------------------------------- */
SELECT c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_spent
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC
LIMIT 1;
/* ---------------------------------------------------------
 TASK 16 — TOTAL BUSINESS REVENUE
 --------------------------------------------------------- */
SELECT SUM(total_amount) AS total_revenue
FROM ORDERS;
/* ---------------------------------------------------------
 TASK 17 — CATEGORY-WISE REVENUE
 --------------------------------------------------------- */
SELECT f.category,
    SUM(o.total_amount) AS total_revenue
FROM ORDERS o
    JOIN FOODITEMS f ON o.food_id = f.food_id
GROUP BY f.category
ORDER BY total_revenue DESC;
/* ---------------------------------------------------------
 TASK 18 — ORDER STATUS-WISE REVENUE
 --------------------------------------------------------- */
SELECT status,
    SUM(total_amount) AS total_revenue
FROM ORDERS
GROUP BY status
ORDER BY total_revenue DESC;
/* ---------------------------------------------------------
 TASK 19 — TOP THREE CUSTOMERS
 --------------------------------------------------------- */
SELECT c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(o.total_amount) AS total_spent
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC
LIMIT 3;
/* ---------------------------------------------------------
 TASK 20 — CUSTOMER PURCHASE FREQUENCY
 --------------------------------------------------------- */
SELECT c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(*) AS total_orders
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_orders DESC;
/* ---------------------------------------------------------
 TASK 21 — DELIVERED ORDERS ONLY
 --------------------------------------------------------- */
SELECT *
FROM ORDERS
WHERE status = 'Delivered'
ORDER BY order_id;
/* ---------------------------------------------------------
 TASK 22 — ORDERS AFTER 12 JULY 2026
 --------------------------------------------------------- */
SELECT *
FROM ORDERS
WHERE order_date >= '2026-07-13'
ORDER BY order_date;
/* =========================================================
 ADDITIONAL ANALYSIS QUERIES
 These are the extra queries you actually practiced
 during Project-1.
 ========================================================= */
/* ---------------------------------------------------------
 EXTRA 1 — COMPLETE ORDER DETAIL WITH CUSTOMER + FOOD
 --------------------------------------------------------- */
SELECT o.order_id,
    o.order_date,
    o.status,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    f.food_id,
    f.name AS food_name,
    f.category,
    o.quantity,
    f.price,
    o.total_amount
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
    JOIN FOODITEMS f ON o.food_id = f.food_id
ORDER BY o.order_id;
/* ---------------------------------------------------------
 EXTRA 2 — CREATE CUSTOMER_ORDER_DETAILS VIEW
 --------------------------------------------------------- */
CREATE OR REPLACE VIEW CUSTOMER_ORDER_DETAILS AS
SELECT o.order_id,
    o.order_date,
    o.status,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    f.food_id,
    f.name AS food_name,
    f.category,
    o.quantity,
    f.price,
    o.total_amount
FROM ORDERS o
    JOIN CUSTOMERS c ON o.customer_id = c.customer_id
    JOIN FOODITEMS f ON o.food_id = f.food_id;
/* Verify view */
SELECT *
FROM CUSTOMER_ORDER_DETAILS
ORDER BY order_id;
/* ---------------------------------------------------------
 EXTRA 3 — OVERALL SALES SUMMARY
 --------------------------------------------------------- */
SELECT COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS total_items_sold,
    SUM(total_amount) AS total_sales,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM CUSTOMER_ORDER_DETAILS;
/* ---------------------------------------------------------
 EXTRA 4 — FOOD-WISE SALES
 --------------------------------------------------------- */
SELECT food_id,
    food_name,
    category,
    SUM(quantity) AS items_sold,
    SUM(total_amount) AS revenue
FROM CUSTOMER_ORDER_DETAILS
GROUP BY food_id,
    food_name,
    category
ORDER BY revenue DESC;
/* ---------------------------------------------------------
 EXTRA 5 — CATEGORY-WISE SALES SUMMARY
 --------------------------------------------------------- */
SELECT category,
    SUM(quantity) AS items_sold,
    SUM(total_amount) AS revenue,
    COUNT(*) AS order_lines
FROM CUSTOMER_ORDER_DETAILS
GROUP BY category
ORDER BY revenue DESC;
/* ---------------------------------------------------------
 EXTRA 6 — CUSTOMER-WISE DETAILED ANALYSIS
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    COUNT(*) AS total_orders,
    SUM(quantity) AS total_items,
    SUM(total_amount) AS total_spent,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
ORDER BY total_spent DESC;
/* ---------------------------------------------------------
 EXTRA 7 — DAILY SALES
 --------------------------------------------------------- */
SELECT CAST(order_date AS DATE) AS order_day,
    COUNT(*) AS total_orders,
    SUM(quantity) AS items_sold,
    SUM(total_amount) AS daily_revenue
FROM CUSTOMER_ORDER_DETAILS
GROUP BY CAST(order_date AS DATE)
ORDER BY order_day;
/* ---------------------------------------------------------
 EXTRA 8 — HIGHEST SPENDING CUSTOMER
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    SUM(total_amount) AS total_spent
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
ORDER BY total_spent DESC
LIMIT 1;
/* ---------------------------------------------------------
 EXTRA 9 — TOP THREE CUSTOMERS
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    SUM(total_amount) AS total_spent
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
ORDER BY total_spent DESC
LIMIT 3;
/* ---------------------------------------------------------
 EXTRA 10 — CUSTOMERS WHO SPENT MORE THAN 450
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    SUM(total_amount) AS total_spent
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
HAVING SUM(total_amount) > 450
ORDER BY total_spent DESC;
/* ---------------------------------------------------------
 EXTRA 11 — TOP-SELLING FOOD BY QUANTITY
 --------------------------------------------------------- */
SELECT food_id,
    food_name,
    SUM(quantity) AS total_quantity_sold
FROM CUSTOMER_ORDER_DETAILS
GROUP BY food_id,
    food_name
ORDER BY total_quantity_sold DESC
LIMIT 1;
/* ---------------------------------------------------------
 EXTRA 12 — CUSTOMERS WITH MORE THAN 2 ORDERS
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    COUNT(*) AS total_orders
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
HAVING COUNT(*) > 2
ORDER BY total_orders DESC;
/* ---------------------------------------------------------
 EXTRA 13 — CUSTOMERS WITH MORE THAN 1 ITEM
 AND SPENT MORE THAN 450
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    SUM(quantity) AS total_items,
    SUM(total_amount) AS total_spent
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
HAVING SUM(quantity) > 1
    AND SUM(total_amount) > 450
ORDER BY total_spent DESC;
/* ---------------------------------------------------------
 EXTRA 14 — CUSTOMERS WHOSE AVERAGE ORDER VALUE
 IS ABOVE OVERALL AVERAGE
 --------------------------------------------------------- */
SELECT customer_id,
    customer_name,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name
HAVING AVG(total_amount) > (
        SELECT AVG(total_amount)
        FROM CUSTOMER_ORDER_DETAILS
    )
ORDER BY average_order_value DESC;
/* =========================================================
 PHASE 4 — REQUIRED VIEW
 ========================================================= */
/* ---------------------------------------------------------
 TASK 23 — CREATE CUSTOMER_SALES_REPORT
 --------------------------------------------------------- */
CREATE OR REPLACE VIEW CUSTOMER_SALES_REPORT AS
SELECT customer_id,
    customer_name,
    SUM(total_amount) AS total_amount_spent
FROM CUSTOMER_ORDER_DETAILS
GROUP BY customer_id,
    customer_name;
/* ---------------------------------------------------------
 TASK 24 — RETRIEVE VIEW
 --------------------------------------------------------- */
SELECT *
FROM CUSTOMER_SALES_REPORT;
/* ---------------------------------------------------------
 TASK 25 — SORT VIEW DESCENDING
 --------------------------------------------------------- */
SELECT *
FROM CUSTOMER_SALES_REPORT
ORDER BY total_amount_spent DESC;
/* =========================================================
 FINAL VERIFICATION
 ========================================================= */
/* Check warehouse */
SHOW WAREHOUSES;
/* Check database */
SHOW DATABASES;
/* Check schema */
SHOW SCHEMAS;
/* Check tables */
SHOW TABLES;
/* Check views */
SHOW VIEWS;
/* Check stage */
LIST @SALES_STAGE;