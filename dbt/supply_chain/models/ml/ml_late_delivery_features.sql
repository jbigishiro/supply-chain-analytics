-- One row per delivered order (Jan 2017 - Aug 2018) with features known AT APPROVAL TIME
-- and the target is_late. Nothing observed after approval is used, to avoid leakage.

with orders as (

    select * from {{ ref('fact_orders') }}
    where is_delivered
      and is_in_analysis_window
      and approved_at is not null

),

items as (

    select * from {{ ref('fact_order_items') }}

),

-- item-level facts collapsed to one row per order
item_features as (

    select
        i.order_id,
        max(i.distance_km)                                                 as max_distance_km,
        sum(p.weight_g)                                                    as total_weight_g,
        sum(p.volume_cm3)                                                  as total_volume_cm3,
        min(i.shipping_limit_at)                                           as earliest_shipping_limit_at,
        -- the most expensive item defines the order's main category and seller
        array_agg(p.category_name order by i.price desc limit 1)[offset(0)] as main_category,
        array_agg(i.seller_id     order by i.price desc limit 1)[offset(0)] as main_seller_id,
        array_agg(s.seller_state  order by i.price desc limit 1)[offset(0)] as seller_state

    from items as i
    left join {{ ref('dim_products') }} as p using (product_id)
    left join {{ ref('dim_sellers') }}  as s using (seller_id)
    group by i.order_id

),

-- every delivered order per seller, with its known outcome
seller_orders as (

    select
        i.seller_id,
        i.order_id,
        any_value(o.delivered_at)              as delivered_at,
        any_value(o.is_on_time)                as is_on_time,
        logical_or(i.missed_shipping_deadline) as missed_deadline

    from items as i
    inner join {{ ref('fact_orders') }} as o using (order_id)
    where o.is_delivered
    group by i.seller_id, i.order_id

),

-- seller track record, using ONLY orders delivered before this order was approved
seller_history as (

    select
        o.order_id,
        count(h.order_id)                       as seller_prior_orders,
        avg(if(h.is_on_time, 0, 1))             as seller_prior_late_rate,
        avg(if(h.missed_deadline, 1, 0))        as seller_prior_missed_rate

    from orders as o
    inner join item_features as x using (order_id)
    left join seller_orders as h
        on  h.seller_id = x.main_seller_id
        and h.delivered_at < o.approved_at
        and h.order_id != o.order_id
    group by o.order_id

)

select
    o.order_id,
    o.purchased_at,
    o.approved_at,

    -- target
    not o.is_on_time                                                    as is_late,

    -- timing
    o.promised_days,
    timestamp_diff(o.approved_at, o.purchased_at, minute) / 60          as approval_hours,
    timestamp_diff(x.earliest_shipping_limit_at, o.approved_at, hour) / 24 as seller_deadline_slack_days,
    extract(month from o.purchased_at)                                  as purchase_month,
    extract(dayofweek from o.purchased_at)                              as purchase_dow,
    extract(month from o.purchased_at) in (11, 12)                      as is_peak_season,

    -- geography
    o.customer_state,
    x.seller_state,
    o.customer_state = x.seller_state                                   as is_same_state,
    x.max_distance_km,

    -- order contents
    o.n_items,
    o.n_sellers,
    o.items_value,
    o.freight_value,
    safe_divide(o.freight_value, o.items_value)                         as freight_ratio,
    x.total_weight_g,
    x.total_volume_cm3,
    x.main_category,

    -- seller track record (known at approval)
    coalesce(h.seller_prior_orders, 0)                                  as seller_prior_orders,
    h.seller_prior_late_rate,
    h.seller_prior_missed_rate

from orders as o
inner join item_features as x using (order_id)
left join seller_history as h using (order_id)