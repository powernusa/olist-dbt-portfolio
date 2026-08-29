with source as (
    select * from {{ source('my_olist', 'olist_order_items') }}
),

staged as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        
        -- Light transforms: timestamps and numerics using Postgres :: operator
        shipping_limit_date::timestamp as shipping_limit_at,
        price::numeric(16, 2) as price,
        freight_value::numeric(16, 2) as freight_value
        
    from source
)

select * from staged

-- with source as (
--     select * from {{ source('my_olist', 'olist_order_items') }}
-- ),

-- staged as (
--     select
--         order_id,
--         order_item_id,
--         product_id,
--         seller_id,
        
--         -- Light transforms: timestamps and numerics
--         cast(shipping_limit_date as timestamp) as shipping_limit_at,
--         cast(price as numeric(16, 2)) as price,
--         cast(freight_value as numeric(16, 2)) as freight_value
        
--     from source
-- )

-- select * from staged