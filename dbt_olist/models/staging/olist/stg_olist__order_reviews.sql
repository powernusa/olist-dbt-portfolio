SELECT
    review_id::VARCHAR(32) as review_id,
    order_id::VARCHAR(32) as order_id,
    review_score::INT as review_score
FROM {{ source('my_olist', 'olist_order_reviews') }}

-- select
--     review_id,
--     order_id,
--     review_score
-- from {{ source('my_olist', 'olist_order_reviews') }}