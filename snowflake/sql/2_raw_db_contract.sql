-- The Snowflake DDL below:

-- Set the environment context
USE ROLE dbt_olist_role;
USE DATABASE olist_github_raw;
USE SCHEMA public; 

-- 1. Sellers
CREATE TABLE IF NOT EXISTS olist_sellers (
    seller_id VARCHAR,
    seller_zip_code_prefix VARCHAR, 
    seller_city VARCHAR,
    seller_state VARCHAR
);

-- 2. Product Category Name Translation
CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name VARCHAR,
    product_category_name_english VARCHAR
);

-- 3. Orders
CREATE TABLE IF NOT EXISTS olist_orders (
    order_id VARCHAR,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 4. Order Items
CREATE TABLE IF NOT EXISTS olist_order_items (
    order_id VARCHAR,
    order_item_id INT,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price FLOAT,
    freight_value FLOAT
);

-- 5. Customers
CREATE TABLE IF NOT EXISTS olist_customers (
    customer_id VARCHAR,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city VARCHAR,
    customer_state VARCHAR
);

-- 6. Geolocation
CREATE TABLE IF NOT EXISTS olist_geolocation (
    geolocation_zip_code_prefix VARCHAR,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR,
    geolocation_state VARCHAR
);

-- 7. Order Payments
CREATE TABLE IF NOT EXISTS olist_order_payments (
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value FLOAT
);

-- 8. Order Reviews
CREATE TABLE IF NOT EXISTS olist_order_reviews (
    review_id VARCHAR,
    order_id VARCHAR,
    review_score INT,
    review_comment_title VARCHAR,
    review_comment_message VARCHAR,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- 9. Products
CREATE TABLE IF NOT EXISTS olist_products (
    product_id VARCHAR,
    product_category_name VARCHAR,
    product_name_lenght INT, 
    product_description_lenght INT, 
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);