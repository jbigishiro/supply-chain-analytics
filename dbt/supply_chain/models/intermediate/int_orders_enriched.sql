with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

order_items as (

    select * from {{ ref('stg_order_items') }}

),

-- collapse items to one row per order BEFORE joining (protects the grain)
items_per_order as (

    select
        order_id,
        count(*)                  as n_items,
        count(distinct seller_id) as n_sellers,
        sum(price)                as items_value,
        sum(freight_value)        as freight_value,
        max(shipping_limit_at)    as shipping_limit_at

    from order_items
    group by order_id

),

joined as (

    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_state,
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.carrier_handoff_at,
        o.delivered_at,
        o.estimated_delivery_date,
        i.shipping_limit_at,
        coalesce(i.n_items, 0)           as n_items,
        i.n_sellers,
        i.items_value,
        i.freight_value,
        i.items_value + i.freight_value  as order_value

    from orders as o
    left join customers as c using (customer_id)
    left join items_per_order as i using (order_id)

),

enriched as (

    select
        *,

        -- scope flags
        date_trunc(date(purchased_at), month)                       as purchase_month,
        date(purchased_at) between date '2017-01-01'
                               and date '2018-08-31'                as is_in_analysis_window,
        order_status = 'delivered' and delivered_at is not null     as is_delivered,

        -- stage durations, in fractional days
        timestamp_diff(approved_at, purchased_at, minute) / 1440        as approval_days,
        timestamp_diff(carrier_handoff_at, approved_at, minute) / 1440  as seller_processing_days,
        timestamp_diff(delivered_at, carrier_handoff_at, minute) / 1440 as carrier_transit_days,
        timestamp_diff(delivered_at, purchased_at, minute) / 1440       as total_delivery_days,

        -- delivery promise
        date_diff(estimated_delivery_date, date(purchased_at), day) as promised_days,
        date_diff(date(delivered_at), estimated_delivery_date, day) as days_late,
        date(delivered_at) <= estimated_delivery_date               as is_on_time,

        -- seller deadline
        carrier_handoff_at > shipping_limit_at                      as missed_shipping_deadline,

        -- every timestamp that exists must come after the ones before it
        coalesce(approved_at        >= purchased_at,       true)
        and coalesce(carrier_handoff_at >= purchased_at,   true)
        and coalesce(carrier_handoff_at >= approved_at,    true)
        and coalesce(delivered_at   >= carrier_handoff_at, true)
        and coalesce(delivered_at   >= purchased_at,       true)  as has_valid_timeline

    from joined

)

select * from enriched