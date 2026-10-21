-- One row per seller with 20+ delivered orders (Jan 2017 - Aug 2018):
-- volume, reliability, speed and review features for segmentation.

with seller_orders as (

    -- one row per order per seller
    select
        i.seller_id,
        i.order_id,
        any_value(o.purchase_month)            as purchase_month,
        any_value(o.is_on_time)                as is_on_time,
        logical_or(i.missed_shipping_deadline) as missed_deadline,
        any_value(o.seller_processing_days)    as seller_processing_days,
        any_value(o.total_delivery_days)       as delivery_days,
        any_value(o.review_score)              as review_score,
        sum(i.price)                           as revenue

    from {{ ref('fact_order_items') }} as i
    inner join {{ ref('fact_orders') }} as o using (order_id)
    where o.is_delivered
      and o.is_in_analysis_window
    group by i.seller_id, i.order_id

)

select
    s.seller_id,
    d.seller_state,

    -- volume
    count(*)                                   as orders,
    round(sum(s.revenue), 2)                   as revenue,
    count(distinct s.purchase_month)           as active_months,

    -- reliability
    avg(if(s.missed_deadline, 1, 0))           as missed_deadline_rate,
    avg(if(s.is_on_time, 1, 0))                as on_time_rate,

    -- speed (valid timelines only, via fact_orders)
    avg(s.seller_processing_days)              as avg_processing_days,
    avg(s.delivery_days)                       as avg_delivery_days,

    -- customer experience
    avg(s.review_score)                        as avg_review_score

from seller_orders as s
inner join {{ ref('dim_sellers') }} as d using (seller_id)
group by s.seller_id, d.seller_state
having count(*) >= 20