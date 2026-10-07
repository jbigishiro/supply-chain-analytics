-- 10: weekly performance around Black Friday 2017 (Nov 24)
-- Population: delivered orders with valid timelines, full weeks Oct 2, 2017 – Jan 28, 2018

with orders_by_week as (

    select
        d.week_start,
        o.is_on_time,
        o.missed_shipping_deadline,
        o.seller_processing_days,
        o.carrier_transit_days

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
    inner join `supply-chain-analytics-510105.dbt_dev_marts.dim_date` as d
        on o.purchase_date = d.date_day
    where o.is_delivered
      and o.has_valid_timeline
      and o.purchase_date between date '2017-10-02' and date '2018-01-28'

)

select
    week_start,
    count(*)                                                    as orders,
    round(countif(is_on_time) / count(*) * 100, 1)              as on_time_pct,
    round(countif(missed_shipping_deadline) / count(*) * 100, 1) as missed_deadline_pct,
    round(avg(seller_processing_days), 1)                       as avg_seller_processing_days,
    round(avg(carrier_transit_days), 1)                         as avg_carrier_transit_days

from orders_by_week
group by week_start
order by week_start