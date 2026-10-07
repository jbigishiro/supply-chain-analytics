-- 11: are "in progress" orders really failed deliveries?

with extract_date as (

    -- the last moment in the data = when it was extracted
    select date(max(purchased_at)) as extract_date
    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`

),

open_orders as (

    select
        o.order_id,
        o.order_status,
        o.estimated_delivery_date,
        date_diff(e.extract_date, date(o.purchased_at), day)      as days_since_purchase,
        date_diff(e.extract_date, o.estimated_delivery_date, day) as days_past_estimate

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
    cross join extract_date as e
    where o.order_status in ('shipped', 'invoiced', 'processing', 'created', 'approved')

)

select
    order_status,
    count(*)                                                     as orders,
    approx_quantiles(days_since_purchase, 100)[offset(50)]       as med_days_since_purchase,
    countif(days_past_estimate > 30)                             as overdue_30_plus,
    round(countif(days_past_estimate > 30) / count(*) * 100, 1)  as overdue_pct

from open_orders
group by order_status
order by orders desc