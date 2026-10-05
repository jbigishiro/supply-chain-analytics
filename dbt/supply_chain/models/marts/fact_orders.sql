with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

reviews as (

    select * from {{ ref('int_order_reviews_latest') }}

)

select
    -- keys
    o.order_id,
    o.customer_id,
    o.customer_unique_id,
    date(o.purchased_at)                                          as purchase_date,

    -- descriptors
    o.order_status,
    o.customer_state,
    o.customer_zip_code_prefix,
    o.purchase_month,

    -- timeline
    o.purchased_at,
    o.approved_at,
    o.carrier_handoff_at,
    o.delivered_at,
    o.estimated_delivery_date,
    o.shipping_limit_at,

    -- money
    o.n_items,
    o.n_sellers,
    o.items_value,
    o.freight_value,
    o.order_value,

    -- stage durations: only where the timeline is in order
    if(o.has_valid_timeline, o.approval_days, null)               as approval_days,
    if(o.has_valid_timeline, o.seller_processing_days, null)      as seller_processing_days,
    if(o.has_valid_timeline, o.carrier_transit_days, null)        as carrier_transit_days,

    -- delivery metrics: only for delivered orders
    if(o.is_delivered, o.total_delivery_days, null)               as total_delivery_days,
    o.promised_days,
    if(o.is_delivered, o.days_late, null)                         as days_late,
    if(o.is_delivered, o.is_on_time, null)                        as is_on_time,
    o.missed_shipping_deadline,

    -- reviews
    r.review_score,
    r.review_score is not null                                    as has_review,

    -- flags
    o.is_delivered,
    o.has_valid_timeline,
    o.is_in_analysis_window

from orders as o
left join reviews as r using (order_id)