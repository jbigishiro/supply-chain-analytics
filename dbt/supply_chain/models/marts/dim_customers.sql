with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select order_id, customer_id, purchased_at
    from {{ ref('stg_orders') }}

),

geo as (

    select * from {{ ref('int_geolocation_by_zip') }}

),

customer_orders as (

    select
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.purchased_at

    from customers as c
    inner join orders as o using (customer_id)

),

order_summary as (

    select
        customer_unique_id,
        min(purchased_at) as first_order_at,
        max(purchased_at) as last_order_at,
        count(*)          as n_orders

    from customer_orders
    group by customer_unique_id

),

-- a person can move between orders; keep their most recent address
latest_location as (

    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state

    from customer_orders
    where purchased_at is not null
    qualify row_number() over (
        partition by customer_unique_id
        order by purchased_at desc
    ) = 1

)

select
    l.customer_unique_id,
    l.customer_zip_code_prefix,
    l.customer_city,
    l.customer_state,
    g.latitude,
    g.longitude,
    s.first_order_at,
    s.last_order_at,
    date_trunc(date(s.first_order_at), month) as cohort_month,
    s.n_orders,
    s.n_orders > 1                            as is_repeat_customer

from latest_location as l
inner join order_summary as s using (customer_unique_id)
left join geo as g
    on l.customer_zip_code_prefix = g.zip_code_prefix