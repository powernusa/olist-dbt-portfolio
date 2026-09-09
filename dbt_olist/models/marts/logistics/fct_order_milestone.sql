WITH unpivoted_milestones AS (
    -- 1. Purchase Event
    SELECT 
        order_id, 
        customer_id, 
        '1_purchased' AS milestone_name, 
        order_purchase_at AS milestone_timestamp
    FROM {{ ref('stg_olist__orders') }}
    WHERE order_purchase_at IS NOT NULL

    UNION ALL 

    -- 2. Approval Event
    SELECT 
        order_id, 
        customer_id, 
        '2_approved' AS milestone_name, 
        order_approved_at AS milestone_timestamp
    FROM {{ ref('stg_olist__orders') }}
    WHERE order_approved_at IS NOT NULL

    UNION ALL 

    -- 3. Carrier Pickup Event
    SELECT 
        order_id, 
        customer_id, 
        '3_carrier_pickup' AS milestone_name, 
        order_delivered_carrier_at AS milestone_timestamp
    FROM {{ ref('stg_olist__orders') }}
    WHERE order_delivered_carrier_at IS NOT NULL

    UNION ALL 

    -- 4. Customer Delivery Event
    SELECT 
        order_id, 
        customer_id, 
        '4_delivered' AS milestone_name, 
        order_delivered_customer_at AS milestone_timestamp
    FROM {{ ref('stg_olist__orders') }}
    WHERE order_delivered_customer_at IS NOT NULL
),

event_sequencing AS (
    -- Apply window functions to track the time between each logistic step
    SELECT 
        order_id,
        customer_id,
        milestone_name,
        milestone_timestamp,
        LAG(milestone_timestamp) OVER (
            PARTITION BY order_id 
            ORDER BY milestone_timestamp ASC
        ) AS previous_milestone_timestamp
    FROM unpivoted_milestones
)

SELECT 
    order_id,
    customer_id,
    milestone_name,
    milestone_timestamp,
    previous_milestone_timestamp,
    -- Snowflake native calculation for fractional hours
    TIMESTAMPDIFF(SECOND, previous_milestone_timestamp, milestone_timestamp) / 3600.0 AS hours_since_last_step
FROM event_sequencing
ORDER BY order_id ASC, milestone_timestamp ASC