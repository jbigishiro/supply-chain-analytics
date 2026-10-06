-- 05: seller shipping deadline misses and what happens to those orders
-- Population: delivered orders, Jan 2017 – Aug 2018

with deadline_groups as (

    select
        missed_shipping_deadline,
        count(*)                                  as orders,
        count(*) / sum(count(*)) over () * 100    as share_of_orders_pct,
        countif(is_on_time) / count(*) * 100      as on_time_pct,
        avg(total_delivery_days)                  as avg_delivery_days,
        avg(review_score)                         as avg_review_score

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and is_in_analysis_window
    group by missed_shipping_deadline

)

select
    missed_shipping_deadline,
    orders,
    round(share_of_orders_pct, 1)  as share_of_orders_pct,
    round(on_time_pct, 1)          as on_time_pct,
    round(avg_delivery_days, 1)    as avg_delivery_days,
    round(avg_review_score, 2)     as avg_review_score

from deadline_groups
order by missed_shipping_deadline