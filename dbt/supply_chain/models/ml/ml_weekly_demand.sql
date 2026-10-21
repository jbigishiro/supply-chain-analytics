-- Weekly orders placed (excluding canceled/unavailable): all orders plus the top 5 categories.
-- Complete Monday-to-Sunday weeks only: 2017-01-02 to 2018-08-20.

with orders as (

    select order_id, purchase_date
    from {{ ref('fact_orders') }}
    where order_status not in ('canceled', 'unavailable')

),

-- one row per order per category it contains
order_categories as (

    select distinct
        i.order_id,
        p.category_name

    from {{ ref('fact_order_items') }} as i
    inner join {{ ref('dim_products') }} as p using (product_id)
    inner join orders as o using (order_id)

),

top_categories as (

    select category_name
    from order_categories
    group by category_name
    order by count(*) desc
    limit 5

),

weekly as (

    select d.week_start, 'all_orders' as series, count(*) as orders
    from orders as o
    inner join {{ ref('dim_date') }} as d on o.purchase_date = d.date_day
    group by d.week_start

    union all

    select d.week_start, oc.category_name as series, count(*) as orders
    from order_categories as oc
    inner join orders as o using (order_id)
    inner join {{ ref('dim_date') }} as d on o.purchase_date = d.date_day
    where oc.category_name in (select category_name from top_categories)
    group by d.week_start, oc.category_name

)

select
    concat(series, '_', cast(week_start as string)) as series_week_key,
    series,
    week_start,
    orders

from weekly
where week_start between date '2017-01-02' and date '2018-08-20'