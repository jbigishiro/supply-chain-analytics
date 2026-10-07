-- 13: monthly orders, GMV, average order value and freight share
-- Population: orders purchased Jan 2017 – Aug 2018, excluding canceled and unavailable

with monthly as (

    select
        purchase_month,
        count(*)            as orders,
        sum(order_value)    as gmv,
        sum(freight_value)  as freight

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_in_analysis_window
      and order_status not in ('canceled', 'unavailable')
    group by purchase_month

)

select
    purchase_month,
    orders,
    round(gmv, 0)                                            as gmv_brl,
    round(gmv / orders, 2)                                   as aov_brl,
    round(freight / gmv * 100, 1)                            as freight_share_pct,
    round((gmv - lag(gmv) over (order by purchase_month))
    / lag(gmv) over (order by purchase_month) * 100, 1)      as gmv_growth_pct

from monthly
order by purchase_month