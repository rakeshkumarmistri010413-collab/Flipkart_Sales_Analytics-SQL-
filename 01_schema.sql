-- ============================================================
-- FLIPKART E-COMMERCE 360 PROJECT
-- Database Schema Definition (Phase 1)
-- ============================================================

DROP DATABASE IF EXISTS flipkart360;
CREATE DATABASE flipkart360
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE flipkart360;

-- ------------------------------------------------------------
-- 1. Reference / Master-Data Tables (Dimensions)
-- ------------------------------------------------------------

-- Customers Dimension
CREATE TABLE customers_ref (
    customer_id      VARCHAR(20)  NOT NULL,
    full_name        VARCHAR(150),
    email            VARCHAR(150),
    phone_number     VARCHAR(30),
    city             VARCHAR(100),
    state            VARCHAR(100),
    signup_date      DATE,
    age              INT,
    gender           VARCHAR(20),
    customer_segment VARCHAR(30),
    CONSTRAINT pk_customers_ref PRIMARY KEY (customer_id),
    INDEX idx_customers_city (city),
    INDEX idx_customers_segment (customer_segment)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Products Dimension
CREATE TABLE products_ref (
    product_id   VARCHAR(20)   NOT NULL,
    product_name VARCHAR(200),
    category     VARCHAR(100),
    subcategory  VARCHAR(100),
    list_price   DECIMAL(10,2),
    unit_cost    DECIMAL(10,2),
    brand        VARCHAR(100),
    CONSTRAINT pk_products_ref PRIMARY KEY (product_id),
    INDEX idx_products_category (category),
    INDEX idx_products_brand (brand)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Sellers Dimension
CREATE TABLE sellers_ref (
    seller_id      VARCHAR(20)   NOT NULL,
    seller_name    VARCHAR(150),
    contact_person VARCHAR(150),
    city           VARCHAR(100),
    seller_type    VARCHAR(50),
    seller_rating  DECIMAL(3,2),
    seller_tier    VARCHAR(30),
    CONSTRAINT pk_sellers_ref PRIMARY KEY (seller_id),
    INDEX idx_sellers_city (city),
    INDEX idx_sellers_tier (seller_tier)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;


-- ------------------------------------------------------------
-- 2. Transactional Core (Fact Tables)
-- ------------------------------------------------------------

-- Main Fact Table: Orders
CREATE TABLE orders (
    order_id        VARCHAR(20)   NOT NULL,
    customer_id     VARCHAR(20)   NOT NULL,
    product_id      VARCHAR(20)   NOT NULL,
    seller_id       VARCHAR(20)   NOT NULL,
    order_date      DATE          NOT NULL,
    quantity        INT           NOT NULL DEFAULT 1,
    payment_method  VARCHAR(30),
    status          VARCHAR(20),
    list_price      DECIMAL(10,2),
    unit_cost       DECIMAL(10,2),
    discount_pct    DECIMAL(5,2),
    gross_amount    DECIMAL(12,2),
    discount_amount DECIMAL(12,2),
    net_amount      DECIMAL(12,2),
    cost_amount     DECIMAL(12,2),
    profit          DECIMAL(12,2),
    delivery_days   INT,
    promised_days   INT,
    on_time         TINYINT,
    year            INT,
    month           INT,
    month_name      VARCHAR(10),
    quarter         VARCHAR(5),
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_product (product_id),
    INDEX idx_orders_seller (seller_id),
    INDEX idx_orders_date (order_date),
    INDEX idx_orders_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Fact Table: Returns
CREATE TABLE returns (
    return_id     INT AUTO_INCREMENT NOT NULL,
    order_id      VARCHAR(20)        NOT NULL,
    customer_id   VARCHAR(20),
    product_id    VARCHAR(20),
    order_date    DATE,
    net_amount    DECIMAL(12,2),
    return_date   DATE,
    return_reason VARCHAR(100),
    refund_amount DECIMAL(12,2),
    CONSTRAINT pk_returns PRIMARY KEY (return_id),
    CONSTRAINT fk_returns_orders FOREIGN KEY (order_id) 
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_returns_order (order_id),
    INDEX idx_returns_date (return_date)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Fact Table: Reviews
CREATE TABLE reviews (
    review_id   VARCHAR(20) NOT NULL,
    order_id    VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20),
    product_id  VARCHAR(20),
    rating      TINYINT,
    review_date DATE,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_orders FOREIGN KEY (order_id) 
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_reviews_order (order_id),
    INDEX idx_reviews_rating (rating)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Fact Table: Discounts
CREATE TABLE discounts (
    discount_id     INT AUTO_INCREMENT NOT NULL,
    order_id        VARCHAR(20)        NOT NULL,
    product_id      VARCHAR(20),
    discount_pct    DECIMAL(5,2),
    discount_amount DECIMAL(12,2),
    campaign_id     VARCHAR(20),
    CONSTRAINT pk_discounts PRIMARY KEY (discount_id),
    CONSTRAINT fk_discounts_orders FOREIGN KEY (order_id) 
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_discounts_order (order_id),
    INDEX idx_discounts_campaign (campaign_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Fact Table: Payments
CREATE TABLE payments (
    payment_id     INT AUTO_INCREMENT NOT NULL,
    order_id       VARCHAR(20)        NOT NULL,
    customer_id    VARCHAR(20),
    order_date     DATE,
    payment_method VARCHAR(30),
    net_amount     DECIMAL(12,2),
    status         VARCHAR(20),
    payment_status VARCHAR(20),
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id) 
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_payments_order (order_id),
    INDEX idx_payments_status (payment_status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Fact Table: Cart Events
CREATE TABLE cart_events (
    event_id    VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20),
    product_id  VARCHAR(20),
    event_date  DATE,
    event_type  VARCHAR(20),
    CONSTRAINT pk_cart_events PRIMARY KEY (event_id),
    INDEX idx_cart_customer (customer_id),
    INDEX idx_cart_product (product_id),
    INDEX idx_cart_type (event_type),
    INDEX idx_cart_date (event_date)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;


-- ------------------------------------------------------------
-- 3. Analytics Base Table (Denormalized OLAP Layer)
-- ------------------------------------------------------------
CREATE TABLE analytics_base_table (
    order_id          VARCHAR(20) NOT NULL,
    customer_id       VARCHAR(20),
    product_id        VARCHAR(20),
    seller_id         VARCHAR(20),
    order_date        DATE,
    quantity          INT,
    payment_method    VARCHAR(30),
    status            VARCHAR(20),
    list_price        DECIMAL(10,2),
    unit_cost         DECIMAL(10,2),
    discount_pct      DECIMAL(5,2),
    gross_amount      DECIMAL(12,2),
    discount_amount   DECIMAL(12,2),
    net_amount        DECIMAL(12,2),
    cost_amount       DECIMAL(12,2),
    profit            DECIMAL(12,2),
    delivery_days     INT,
    promised_days     INT,
    on_time           TINYINT,
    year              INT,
    month             INT,
    month_name        VARCHAR(10),
    quarter           VARCHAR(5),
    return_date       DATE NULL,
    return_reason     VARCHAR(100),
    refund_amount     DECIMAL(12,2),
    is_returned       TINYINT,
    review_count      INT,
    avg_rating        DECIMAL(3,2),
    campaign_id       VARCHAR(20),
    payment_status    VARCHAR(20),
    revenue           DECIMAL(12,2),
    margin_pct        DECIMAL(6,2),
    delivery_gap_days INT,
    order_month       VARCHAR(10),
    is_weekend_order  TINYINT,
    price_bucket      VARCHAR(30),
    CONSTRAINT pk_abt PRIMARY KEY (order_id),
    INDEX idx_abt_date (order_date),
    INDEX idx_abt_status (status),
    INDEX idx_abt_customer (customer_id),
    INDEX idx_abt_product (product_id),
    INDEX idx_abt_seller (seller_id),
    INDEX idx_abt_revenue (revenue)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;