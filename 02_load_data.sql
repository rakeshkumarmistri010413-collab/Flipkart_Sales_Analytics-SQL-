-- ============================================================
-- Phase 2 — Load Cleaned CSVs into MySQL
-- Project: Flipkart E-Commerce 360
-- ============================================================

USE flipkart360;

-- ------------------------------------------------------------
-- Environment Setup & Optimizations
-- ------------------------------------------------------------
SET GLOBAL local_infile = 1;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. Reference / Dimension Tables
-- ------------------------------------------------------------

-- Customers Reference
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/dim_customers_reference.csv'
INTO TABLE customers_ref
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, full_name, email, phone_number, city, state, @v_signup_date, age, gender, customer_segment)
SET signup_date = CASE 
    WHEN @v_signup_date IS NULL OR TRIM(@v_signup_date) = '' THEN NULL
    WHEN @v_signup_date LIKE '%/%' THEN STR_TO_DATE(TRIM(@v_signup_date), '%d/%m/%Y')
    WHEN @v_signup_date LIKE '%-%' AND LENGTH(TRIM(@v_signup_date)) = 10 AND SUBSTRING(TRIM(@v_signup_date), 3, 1) = '-' THEN STR_TO_DATE(TRIM(@v_signup_date), '%d-%m-%Y')
    ELSE STR_TO_DATE(TRIM(@v_signup_date), '%Y-%m-%d')
END;

-- Products Reference
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/dim_products_reference.csv'
INTO TABLE products_ref
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, subcategory, list_price, unit_cost, brand);

-- Sellers Reference
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/dim_sellers_reference.csv'
INTO TABLE sellers_ref
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_name, contact_person, city, seller_type, seller_rating, seller_tier);


-- ------------------------------------------------------------
-- 2. Core Fact Table
-- ------------------------------------------------------------

-- Fact Orders
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, product_id, seller_id, @v_order_date, quantity, payment_method,
 status, list_price, unit_cost, discount_pct, gross_amount, discount_amount, net_amount,
 cost_amount, profit, delivery_days, promised_days, on_time, year, month, month_name, quarter)
SET order_date = CASE 
    WHEN @v_order_date IS NULL OR TRIM(@v_order_date) = '' THEN NULL
    WHEN @v_order_date LIKE '%/%' THEN STR_TO_DATE(TRIM(@v_order_date), '%d/%m/%Y')
    ELSE STR_TO_DATE(TRIM(@v_order_date), '%Y-%m-%d')
END;


-- ------------------------------------------------------------
-- 3. Dependent Fact Tables
-- ------------------------------------------------------------

-- Fact Returns
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, product_id, @v_order_date, net_amount, @v_return_date, return_reason, refund_amount)
SET order_date = STR_TO_DATE(TRIM(@v_order_date), '%Y-%m-%d'),
    return_date = NULLIF(STR_TO_DATE(TRIM(@v_return_date), '%Y-%m-%d'), '0000-00-00');

-- Fact Reviews
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_reviews.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, customer_id, product_id, rating, @v_review_date)
SET review_date = STR_TO_DATE(TRIM(@v_review_date), '%Y-%m-%d');

-- Fact Discounts
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_discounts.csv'
INTO TABLE discounts
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, discount_pct, discount_amount, campaign_id);

-- Fact Payments
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, @v_order_date, payment_method, net_amount, status, payment_status)
SET order_date = STR_TO_DATE(TRIM(@v_order_date), '%Y-%m-%d');

-- Fact Cart Events
LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/fact_cart_events.csv'
INTO TABLE cart_events
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(event_id, customer_id, product_id, @v_event_date, event_type)
SET event_date = STR_TO_DATE(TRIM(@v_event_date), '%Y-%m-%d');


-- ------------------------------------------------------------
-- 4. Analytics Base Table (Denormalized)
-- ------------------------------------------------------------

LOAD DATA LOCAL INFILE 'D:/Rakesh/flipkart360/flipkart360_final/data/clean/analytics_base_table.csv'
INTO TABLE analytics_base_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, product_id, seller_id, @v_order_date, quantity, payment_method, status,
 list_price, unit_cost, discount_pct, gross_amount, discount_amount, net_amount, cost_amount,
 profit, delivery_days, promised_days, on_time, year, month, month_name, quarter,
 @v_return_date, return_reason, refund_amount, is_returned, review_count, avg_rating,
 campaign_id, payment_status, revenue, margin_pct, delivery_gap_days, order_month,
 is_weekend_order, price_bucket)
SET order_date = STR_TO_DATE(TRIM(@v_order_date), '%Y-%m-%d'),
    return_date = NULLIF(STR_TO_DATE(TRIM(@v_return_date), '%Y-%m-%d'), '0000-00-00');


-- ------------------------------------------------------------
-- Re-enable System Checks
-- ------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;


-- ------------------------------------------------------------
-- 5. Verification & Sanity Check
-- ------------------------------------------------------------
SELECT 'customers_ref' AS table_name, COUNT(*) AS row_count FROM customers_ref
UNION ALL SELECT 'products_ref', COUNT(*) FROM products_ref
UNION ALL SELECT 'sellers_ref', COUNT(*) FROM sellers_ref
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'returns', COUNT(*) FROM returns
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'discounts', COUNT(*) FROM discounts
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'cart_events', COUNT(*) FROM cart_events
UNION ALL SELECT 'analytics_base_table', COUNT(*) FROM analytics_base_table;