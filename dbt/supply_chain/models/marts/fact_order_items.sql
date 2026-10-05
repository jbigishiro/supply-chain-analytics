with items as (

    select * from {{ ref('stg_order_items') }}

),

orders as (

    select * from {{ ref('fact_orders') }}

),

sellers as (

    select * from {{ ref('stg_sellers') }}

),

geo as (

    select * from {{ ref('int_geolocation_by_zip') }}

)

select
    -- keys
    i.order_item_key,
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    o.customer_unique_id,
    o.purchase_date,

    -- money
    i.price,
    i.freight_value,
    i.price + i.freight_value                                     as item_value,

    -- seller deadline, per item
    i.shipping_limit_at,
    o.carrier_handoff_at > i.shipping_limit_at                    as missed_shipping_deadline,

    -- distance seller -> customer, in km
    round(
        st_distance(
            st_geogpoint(sg.longitude, sg.latitude),
            st_geogpoint(cg.longitude, cg.latitude)
        ) / 1000, 1
    )                                                             as distance_km,

    -- order outcome, copied down for item-level analysis
    o.is_delivered,
    o.is_on_time,
    o.days_late,
    o.is_in_analysis_window

from items as i
inner join orders as o using (order_id)
left join sellers as s using (seller_id)
left join geo as sg
    on s.seller_zip_code_prefix = sg.zip_code_prefix
left join geo as cg
    on o.customer_zip_code_prefix = cg.zip_code_prefix