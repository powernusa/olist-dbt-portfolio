{{ config(materialized='table') }}

WITH orders AS (
    SELECT * 
    FROM {{ ref('stg_olist__orders') }}
),

reviews AS (
    SELECT * 
    FROM {{ ref('stg_olist__order_reviews') }}
),

filtered_deliveries AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_at,
        o.order_estimated_delivery_at,
        o.order_delivered_customer_at,
        r.review_score
    FROM orders AS o
    LEFT JOIN reviews AS r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_at IS NOT NULL
      AND o.order_estimated_delivery_at IS NOT NULL
      AND r.review_score IS NOT NULL
),

final AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_at,
        order_estimated_delivery_at,
        order_delivered_customer_at,
        
        -- PostgreSQL date subtraction returning integer days
        (order_delivered_customer_at::DATE - order_estimated_delivery_at::DATE) AS sla_delay_days,

        -- Flag as breached if delivered strictly after estimated date
        CASE 
            WHEN (order_delivered_customer_at::DATE - order_estimated_delivery_at::DATE) > 0 THEN 1 
            ELSE 0 
        END AS is_sla_breached,
        
        review_score
    FROM filtered_deliveries
)

SELECT * 
FROM final