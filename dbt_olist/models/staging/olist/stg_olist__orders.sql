WITH source AS (
    -- This macro compiles to olist_raw.olist.olist_orders
    SELECT * FROM {{ source('my_olist', 'olist_orders') }}
),

staged AS (
    SELECT
        order_id,
        customer_id,
        order_status, 
        
        -- Postgres-style shorthand casting
        order_purchase_timestamp::TIMESTAMP AS order_purchase_at,
        order_approved_at::TIMESTAMP AS order_approved_at,
        order_delivered_carrier_date::TIMESTAMP AS order_delivered_carrier_at,
        order_delivered_customer_date::TIMESTAMP AS order_delivered_customer_at,
        order_estimated_delivery_date::TIMESTAMP AS order_estimated_delivery_at
        
    FROM source
)

SELECT * FROM staged
