select
    review_id,
    order_id,
    review_score
from {{ source('my_olist', 'olist_order_reviews') }}