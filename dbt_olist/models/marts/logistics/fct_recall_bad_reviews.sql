{{ config(
    materialized='table',
    tags=['ml_feature_engineering']
) }}

WITH orders AS (
    SELECT * FROM {{ ref('stg_olist__orders') }}
),

items AS (
    SELECT * FROM {{ ref('stg_olist__order_items') }}
),

payments AS (
    SELECT * FROM {{ ref('stg_olist__order_payments') }}
),

reviews AS (
    SELECT * FROM {{ ref('stg_olist__order_reviews') }}
),

-- ==========================================
-- 1. AGGREGATE THE DATA
-- ==========================================
item_agg AS (
    SELECT 
        order_id,
        AVG(price) AS price,
        AVG(freight_value) AS freight_value
    FROM items
    GROUP BY order_id
),

payment_agg AS (
    SELECT 
        order_id,
        MAX(payment_installments) AS payment_installments
    FROM payments
    GROUP BY order_id
),

-- ==========================================
-- 2. JOIN & DROP NULLS
-- ==========================================
joined_data AS (
    SELECT 
        o.order_id,
        o.order_estimated_delivery_at,
        o.order_delivered_customer_at,
        i.price,
        i.freight_value,
        p.payment_installments,
        r.review_score
    FROM orders o
    INNER JOIN item_agg i 
        ON o.order_id = i.order_id
    LEFT JOIN payment_agg p 
        ON o.order_id = p.order_id
    INNER JOIN reviews r 
        ON o.order_id = r.order_id
    WHERE r.review_score IS NOT NULL 
      AND o.order_delivered_customer_at IS NOT NULL
      AND o.order_estimated_delivery_at IS NOT NULL
      AND i.price IS NOT NULL
      AND i.freight_value IS NOT NULL
      AND p.payment_installments IS NOT NULL
),

-- ==========================================
-- 3. FEATURE ENGINEERING
-- ==========================================
features_calc AS (
    SELECT 
        order_id,
        price,
        freight_value,
        payment_installments,
        --review_score, -- don't have to include this
        
        -- Target variable (y_binary): PostgreSQL / ANSI CASE WHEN
        CASE 
            WHEN review_score <= 3 THEN 1 
            ELSE 0 
        END AS is_bad_review,

        -- SLA Delay Days (PostgreSQL timestamp subtraction converted to integer days)
        GREATEST(
            0, 
            (order_delivered_customer_at::DATE - order_estimated_delivery_at::DATE)
        ) AS sla_delay_days,

        -- PostgreSQL Windowed Median Calculation
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER () AS median_price
    FROM joined_data
)

-- ==========================================
-- 4. FINAL LOGIC (Interactions) - PostgreSQL
-- ==========================================
SELECT
    order_id,
    price,
    freight_value,
    payment_installments,
    sla_delay_days,
    
    -- High value flag
    CASE 
        WHEN price > median_price THEN 1 
        ELSE 0 
    END AS is_high_value,
    
    -- Interaction term (delay * is_high_value)
    sla_delay_days * (
        CASE 
            WHEN price > median_price THEN 1 
            ELSE 0 
        END
    ) AS delay_x_high_value,
    
    is_bad_review AS y_binary

FROM features_calc