-- 15: repeat purchases — does a late first delivery reduce the chance of a second order?
-- Customers whose first order was purchased Jan 2017 – Feb 2018 and delivered,
-- so every customer has a full 180 days to return before the data ends.

with customer_orders as (

    select
        customer_unique_id,
        purchased_at,
        is_delivered,
        is_on_time,
        days_late,
        row_number() over (partition by customer_unique_id order by purchased_at)  as order_number,
        min(purchased_at) over (partition by customer_unique_id)                   as first_order_at

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where order_status not in ('canceled', 'unavailable')
),

first_orders as (

    select
        customer_unique_id,
        case
            when is_on_time    then '1. on time'
            when days_late <= 3 then '2. 1–3 days late'
            else                     '3. 4+ days late'
        end as first_delivery

    from customer_orders
    where order_number = 1
      and is_delivered
      and date(purchased_at) between date '2017-01-01' and date '2018-02-28'

),

returns as (

    -- did the customer order again between 1 and 180 days after their first order?
    select
        customer_unique_id,
        countif(
            purchased_at >  timestamp_add(first_order_at, interval 1 day)
            and purchased_at <= timestamp_add(first_order_at, interval 180 day)
        ) > 0 as returned_within_180d

    from customer_orders
    group by customer_unique_id

)

select
    f.first_delivery,
    count(*)                                                   as customers,
    countif(r.returned_within_180d)                            as returned,
    round(countif(r.returned_within_180d) / count(*) * 100, 2) as repeat_rate_pct

from first_orders as f
inner join returns as r using (customer_unique_id)
group by f.first_delivery
order by f.first_delivery