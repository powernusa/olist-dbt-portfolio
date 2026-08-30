WITH source AS (
    SELECT * FROM {{ source('my_olist', 'olist_order_payments') }}
),

staged AS (
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        
        -- Cast the value to a numeric type for accurate math later
        payment_value::NUMERIC(16, 2) AS payment_value
        
    FROM source
)

SELECT * FROM staged