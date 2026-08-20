-- =============================================================================
-- FLIPKART E-COMMERCE 360: BUSINESS QUESTIONS & ANALYTICAL SQL SCRIPT
-- =============================================================================
USE flipkart360;

-- =============================================================================
-- SECTION 1: SALES & FINANCIAL PERFORMANCE
-- =============================================================================

-- Q1: What is the total gross revenue, net revenue, total profit, and overall profit margin %?
SELECT 
    ROUND(SUM(gross_amount), 2) AS total_gross_revenue,
    ROUND(SUM(net_amount), 2)   AS total_net_revenue,
    ROUND(SUM(profit), 2)       AS total_profit,
    ROUND((SUM(profit) / SUM(net_amount)) * 100, 2) AS overall_margin_pct
FROM orders
WHERE status != 'Cancelled';

-- Q2: What is the monthly trend of order volume, revenue, and average order value (AOV)?
SELECT 
    year,
    month,
    month_name,
    COUNT(order_id)           AS total_orders,
    ROUND(SUM(net_amount), 2) AS monthly_revenue,
    ROUND(AVG(net_amount), 2) AS avg_order_value
FROM orders
WHERE status = 'Delivered'
GROUP BY year, month, month_name
ORDER BY year, month;

-- Q3: What is the Quarter-over-Quarter (QoQ) revenue performance?
SELECT 
    year,
    quarter,
    COUNT(order_id)           AS order_volume,
    ROUND(SUM(net_amount), 2) AS quarterly_revenue
FROM orders
GROUP BY year, quarter
ORDER BY year, quarter;

-- Q4: What is the revenue contribution and transaction count by payment method?
SELECT 
    payment_method,
    COUNT(order_id)           AS transaction_count,
    ROUND(SUM(net_amount), 2) AS total_revenue,
    ROUND(AVG(net_amount), 2) AS aov
FROM orders
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- Q5: What is the percentage distribution of all order statuses?
SELECT 
    status,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_share
FROM orders
GROUP BY status;

-- Q6: How does weekend sales performance compare against weekdays?
SELECT 
    CASE WHEN is_weekend_order = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(order_id)           AS total_orders,
    ROUND(SUM(revenue), 2)    AS total_revenue,
    ROUND(AVG(revenue), 2)    AS aov
FROM analytics_base_table
GROUP BY is_weekend_order;

-- Q7: What is the revenue and profit generated across different price buckets?
SELECT 
    price_bucket,
    COUNT(order_id)           AS total_orders,
    ROUND(SUM(revenue), 2)    AS total_revenue,
    ROUND(SUM(profit), 2)     AS total_profit
FROM analytics_base_table
GROUP BY price_bucket
ORDER BY total_revenue DESC;


-- =============================================================================
-- SECTION 2: CUSTOMER DEMOGRAPHICS & BEHAVIOR
-- =============================================================================

-- Q8: Who are the top 10 highest-spending customers?
SELECT 
    c.customer_id,
    c.full_name,
    c.city,
    c.customer_segment,
    COUNT(o.order_id)         AS order_count,
    ROUND(SUM(o.net_amount), 2) AS total_spend
FROM customers_ref c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.full_name, c.city, c.customer_segment
ORDER BY total_spend DESC
LIMIT 10;

-- Q9: What is the revenue contribution and average revenue per user (ARPU) across customer segments?
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(o.order_id)             AS total_orders,
    ROUND(SUM(o.net_amount), 2)   AS total_revenue,
    ROUND(SUM(o.net_amount) / COUNT(DISTINCT c.customer_id), 2) AS arpu
FROM customers_ref c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

-- Q10: What percentage of buyers are repeat customers vs. one-time buyers?
WITH buyer_summary AS (
    SELECT customer_id, COUNT(order_id) AS orders_count
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE WHEN orders_count > 1 THEN 'Repeat Buyer' ELSE 'One-Time Buyer' END AS customer_type,
    COUNT(customer_id) AS total_users,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM buyer_summary), 2) AS user_pct
FROM buyer_summary
GROUP BY CASE WHEN orders_count > 1 THEN 'Repeat Buyer' ELSE 'One-Time Buyer' END;

-- Q11: Which top 10 cities generate the highest revenue?
SELECT 
    c.city,
    c.state,
    COUNT(DISTINCT c.customer_id) AS active_buyers,
    ROUND(SUM(o.net_amount), 2)   AS city_revenue
FROM customers_ref c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city, c.state
ORDER BY city_revenue DESC
LIMIT 10;

-- Q12: How does revenue break down across age groups and gender?
SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 35 THEN '25-35'
        WHEN age BETWEEN 36 AND 50 THEN '36-50'
        ELSE '50+' 
    END AS age_group,
    gender,
    COUNT(o.order_id)           AS total_orders,
    ROUND(SUM(o.net_amount), 2) AS total_revenue
FROM customers_ref c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY age_group, gender
ORDER BY age_group, total_revenue DESC;

-- Q13: What is the customer RFM foundation (Recency, Frequency, Monetary)?
SELECT 
    customer_id,
    MAX(order_date)             AS last_purchase_date,
    COUNT(order_id)             AS frequency,
    ROUND(SUM(net_amount), 2)   AS monetary_value
FROM orders
GROUP BY customer_id
ORDER BY monetary_value DESC
LIMIT 20;

-- Q14: Which customers have not placed an order in the last 90 days of recorded data (churn risk)?
SELECT 
    c.customer_id, 
    c.full_name, 
    c.email, 
    MAX(o.order_date) AS last_order_date
FROM customers_ref c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email
HAVING last_order_date < DATE_SUB((SELECT MAX(order_date) FROM orders), INTERVAL 90 DAY);

-- Q15: What is the monthly rate of new customer registrations?
SELECT 
    DATE_FORMAT(signup_date, '%Y-%m') AS registration_month,
    COUNT(customer_id)                AS new_signups
FROM customers_ref
GROUP BY registration_month
ORDER BY registration_month;


-- =============================================================================
-- SECTION 3: PRODUCT PERFORMANCE & CATALOG HEALTH
-- =============================================================================

-- Q16: What are the top 10 best-selling products by net revenue?
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    SUM(o.quantity)           AS units_sold,
    ROUND(SUM(o.net_amount), 2) AS total_revenue,
    ROUND(SUM(o.profit), 2)   AS total_profit
FROM products_ref p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, p.category, p.brand
ORDER BY total_revenue DESC
LIMIT 10;

-- Q17: Which product categories yield the highest total profit and margin %?
SELECT 
    p.category,
    COUNT(o.order_id)         AS total_orders,
    SUM(o.quantity)           AS units_sold,
    ROUND(SUM(o.net_amount), 2) AS category_revenue,
    ROUND(SUM(o.profit), 2)   AS category_profit,
    ROUND((SUM(o.profit) / SUM(o.net_amount)) * 100, 2) AS margin_pct
FROM products_ref p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY category_profit DESC;

-- Q18: What are the top 3 selling brands within each category?
WITH BrandRanking AS (
    SELECT 
        p.category,
        p.brand,
        ROUND(SUM(o.net_amount), 2) AS brand_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(o.net_amount) DESC) AS ranking
    FROM products_ref p
    JOIN orders o ON p.product_id = o.product_id
    GROUP BY p.category, p.brand
)
SELECT category, brand, brand_revenue, ranking
FROM BrandRanking
WHERE ranking <= 3;

-- Q19: Which products have poor customer satisfaction (average rating < 3.0 with at least 5 reviews)?
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(r.review_id)      AS total_reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM products_ref p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_reviews >= 5 AND avg_rating < 3.0
ORDER BY avg_rating ASC;

-- Q20: Are there any catalog products that have generated zero sales?
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.list_price
FROM products_ref p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.order_id IS NULL;

-- Q21: Which product subcategories have the highest average discount rates?
SELECT 
    p.subcategory,
    ROUND(AVG(o.discount_pct), 2)    AS avg_discount_pct,
    ROUND(SUM(o.discount_amount), 2) AS total_discounts_given
FROM products_ref p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.subcategory
ORDER BY avg_discount_pct DESC;

-- Q22: What is the average and maximum quantity purchased per single order?
SELECT 
    ROUND(AVG(quantity), 2) AS avg_basket_size,
    MAX(quantity)           AS max_basket_size
FROM orders;


-- =============================================================================
-- SECTION 4: SELLER METRICS & SLA COMPLIANCE
-- =============================================================================

-- Q23: Who are the top 10 sellers by gross fulfilled sales and rating?
SELECT 
    s.seller_id,
    s.seller_name,
    s.seller_tier,
    s.seller_rating,
    COUNT(o.order_id)           AS orders_fulfilled,
    ROUND(SUM(o.net_amount), 2) AS total_sales
FROM sellers_ref s
JOIN orders o ON s.seller_id = o.seller_id
WHERE o.status = 'Delivered'
GROUP BY s.seller_id, s.seller_name, s.seller_tier, s.seller_rating
ORDER BY total_sales DESC
LIMIT 10;

-- Q24: What is the revenue contribution across seller tiers?
SELECT 
    s.seller_tier,
    COUNT(DISTINCT s.seller_id) AS total_sellers,
    ROUND(SUM(o.net_amount), 2) AS total_revenue,
    ROUND(AVG(o.net_amount), 2) AS aov
FROM sellers_ref s
JOIN orders o ON s.seller_id = o.seller_id
GROUP BY s.seller_tier
ORDER BY total_revenue DESC;

-- Q25: Which sellers have the highest order cancellation rates?
SELECT 
    s.seller_id,
    s.seller_name,
    COUNT(o.order_id) AS total_assigned_orders,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND((SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 2) AS cancellation_rate_pct
FROM sellers_ref s
JOIN orders o ON s.seller_id = o.seller_id
GROUP BY s.seller_id, s.seller_name
HAVING total_assigned_orders >= 10
ORDER BY cancellation_rate_pct DESC
LIMIT 10;

-- Q26: What is the on-time delivery SLA compliance percentage for each seller?
SELECT 
    s.seller_id,
    s.seller_name,
    COUNT(o.order_id) AS delivered_orders,
    SUM(CASE WHEN o.on_time = 1 THEN 1 ELSE 0 END) AS on_time_orders,
    ROUND((SUM(CASE WHEN o.on_time = 1 THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 2) AS on_time_sla_pct
FROM sellers_ref s
JOIN orders o ON s.seller_id = o.seller_id
WHERE o.status = 'Delivered'
GROUP BY s.seller_id, s.seller_name
HAVING delivered_orders >= 10
ORDER BY on_time_sla_pct ASC;

-- Q27: How are sellers distributed across different seller types?
SELECT 
    seller_type,
    COUNT(seller_id)         AS seller_count,
    ROUND(AVG(seller_rating), 2) AS avg_rating
FROM sellers_ref
GROUP BY seller_type;


-- =============================================================================
-- SECTION 5: RETURNS, LOGISTICS & FULFILLMENT
-- =============================================================================

-- Q28: What is the overall return rate % and total financial refund impact?
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS total_returned_orders,
    ROUND((COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS return_rate_pct,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;

-- Q29: What are the primary reasons for product returns and their financial weight?
SELECT 
    return_reason,
    COUNT(return_id)               AS return_occurrences,
    ROUND(SUM(refund_amount), 2)   AS total_refunded_value,
    ROUND(COUNT(return_id) * 100.0 / (SELECT COUNT(*) FROM returns), 2) AS reason_share_pct
FROM returns
GROUP BY return_reason
ORDER BY return_occurrences DESC;

-- Q30: Which products have the highest return rate (minimum 15 orders)?
SELECT 
    p.product_id,
    p.product_name,
    COUNT(o.order_id)  AS total_orders,
    COUNT(r.return_id) AS total_returns,
    ROUND((COUNT(r.return_id) / COUNT(o.order_id)) * 100, 2) AS return_rate_pct
FROM products_ref p
JOIN orders o ON p.product_id = o.product_id
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY p.product_id, p.product_name
HAVING total_orders >= 15
ORDER BY return_rate_pct DESC
LIMIT 10;

-- Q31: What is the average delivery delay across states?
SELECT 
    c.state,
    ROUND(AVG(o.delivery_days), 1) AS avg_actual_delivery_days,
    ROUND(AVG(o.promised_days), 1) AS avg_promised_delivery_days,
    ROUND(AVG(o.delivery_days - o.promised_days), 1) AS avg_delivery_gap_days
FROM customers_ref c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.state
ORDER BY avg_delivery_gap_days DESC;

-- Q32: What is the monthly trend of order returns?
SELECT 
    o.year,
    o.month_name,
    COUNT(o.order_id)  AS total_orders,
    COUNT(r.order_id)  AS total_returns,
    ROUND((COUNT(r.order_id) / COUNT(o.order_id)) * 100, 2) AS monthly_return_rate_pct
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY o.year, o.month, o.month_name
ORDER BY o.year, o.month;

-- Q33: What is the average turnaround time (days) between order placement and return date?
SELECT 
    ROUND(AVG(DATEDIFF(return_date, order_date)), 1) AS avg_days_to_return
FROM returns
WHERE return_date IS NOT NULL;


-- =============================================================================
-- SECTION 6: MARKETING CAMPAIGNS, FUNNEL & ADVANCED METRICS
-- =============================================================================

-- Q34: How did marketing discount campaigns perform in terms of volume and discount value?
SELECT 
    campaign_id,
    COUNT(order_id)                  AS orders_driven,
    ROUND(AVG(discount_pct), 2)      AS avg_discount_pct,
    ROUND(SUM(discount_amount), 2)   AS total_discount_given
FROM discounts
GROUP BY campaign_id
ORDER BY orders_driven DESC;

-- Q35: What is the payment failure rate across different payment methods?
SELECT 
    payment_method,
    COUNT(payment_id) AS total_attempts,
    SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_attempts,
    ROUND((SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) / COUNT(payment_id)) * 100, 2) AS failure_rate_pct
FROM payments
GROUP BY payment_method
ORDER BY failure_rate_pct DESC;

-- Q36: What is the event volume breakdown across the user cart funnel?
SELECT 
    event_type,
    COUNT(event_id) AS event_count,
    ROUND(COUNT(event_id) * 100.0 / (SELECT COUNT(*) FROM cart_events), 2) AS funnel_share_pct
FROM cart_events
GROUP BY event_type;

-- Q37: What is the estimated cart abandonment rate among distinct users?
SELECT 
    COUNT(DISTINCT ce.customer_id) AS users_who_added_to_cart,
    COUNT(DISTINCT o.customer_id)  AS users_who_purchased,
    ROUND((1 - (COUNT(DISTINCT o.customer_id) / COUNT(DISTINCT ce.customer_id))) * 100, 2) AS cart_abandonment_pct
FROM cart_events ce
LEFT JOIN orders o ON ce.customer_id = o.customer_id;

-- Q38: How do product ratings correlate with return rates (using ABT)?
SELECT 
    ROUND(avg_rating, 0)       AS rounded_rating,
    COUNT(order_id)            AS total_orders,
    SUM(is_returned)           AS returned_orders,
    ROUND((SUM(is_returned) / COUNT(order_id)) * 100, 2) AS return_rate_pct
FROM analytics_base_table
WHERE avg_rating IS NOT NULL
GROUP BY rounded_rating
ORDER BY rounded_rating DESC;

-- Q39: What is the cumulative running total revenue over time?
SELECT 
    order_date,
    ROUND(SUM(net_amount), 2) AS daily_revenue,
    ROUND(SUM(SUM(net_amount)) OVER (ORDER BY order_date), 2) AS running_cumulative_revenue
FROM orders
WHERE status = 'Delivered'
GROUP BY order_date
ORDER BY order_date;

-- Q40: Which heavily discounted orders (discount >= 20%) generated low or negative profit margins?
SELECT 
    order_id,
    customer_id,
    net_amount,
    discount_pct,
    discount_amount,
    profit,
    ROUND((profit / net_amount) * 100, 2) AS profit_margin_pct
FROM orders
WHERE discount_pct >= 20.00
ORDER BY profit ASC
LIMIT 15;