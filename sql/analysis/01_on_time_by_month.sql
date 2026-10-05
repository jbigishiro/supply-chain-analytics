-- 01: on-time delivery rate by purchase month, Jan 2017 – Aug 2018

with monthly as (

    select
        purchase_month,
        count(*)                                  as delivered_orders,
        countif(is_on_time) / count(*) * 100      as on_time_pct,
        avg(total_delivery_days)                  as avg_delivery_days,
        avg(if(not is_on_time, days_late, null))  as avg_days_late_when_late

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and is_in_analysis_window
    group by purchase_month

)

select
    purchase_month,
    delivered_orders,
    round(on_time_pct, 1)                                              as on_time_pct,
    round(on_time_pct - lag(on_time_pct) over (order by purchase_month), 1) as change_pp,
    round(avg_delivery_days, 1)                                        as avg_delivery_days,
    round(avg_days_late_when_late, 1)                                  as avg_days_late_when_late

from monthly
order by purchase_month