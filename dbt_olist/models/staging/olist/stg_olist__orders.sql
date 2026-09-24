WITH source AS (
    -- Compiles to the raw Olist orders table
    SELECT * FROM {{ source('my_olist', 'olist_orders') }}
),

staged AS (
    SELECT
        -- Hash key explicit string casts (32-character MD5 hex strings)
        order_id::VARCHAR(32) AS order_id,
        customer_id::VARCHAR(32) AS customer_id,

        -- Status column explicit length-bounded string cast
        order_status::VARCHAR(50) AS order_status, 
        
        -- Timestamp conversions & column alias standardization
        order_purchase_timestamp::TIMESTAMP AS order_purchase_at,
        order_approved_at::TIMESTAMP AS order_approved_at,
        order_delivered_carrier_date::TIMESTAMP AS order_delivered_carrier_at,
        order_delivered_customer_date::TIMESTAMP AS order_delivered_customer_at,
        order_estimated_delivery_date::TIMESTAMP AS order_estimated_delivery_at
        
    FROM source
)

SELECT * FROM staged