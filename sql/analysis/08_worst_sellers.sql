-- 08: seller on-time scorecard — sellers with at least 50 delivered orders

with seller_orders as (

    -- one row per order per seller
    select distinct
        i.seller_id,
        i.order_id,
        i.is_on_time,
        i.missed_shipping_deadline,
        o.review_score

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
        using (order_id)
    where o.is_delivered
      and o.is_in_analysis_window

),

seller_stats as (

    -- all sellers, so the share below is out of ALL late orders
    select
        seller_id,
        count(*)                                                              as orders,
        countif(is_on_time) / count(*) * 100                                  as on_time_pct,
        countif(not is_on_time)                                               as late_orders,
        countif(not is_on_time) / sum(countif(not is_on_time)) over () * 100  as share_of_all_late_pct,
        countif(missed_shipping_deadline) / count(*) * 100                    as missed_deadline_pct,
        avg(review_score)                                                     as avg_review_score

    from seller_orders
    group by seller_id

)

select
    seller_id,
    orders,
    round(on_time_pct, 1)            as on_time_pct,
    late_orders,
    round(share_of_all_late_pct, 2)  as share_of_all_late_pct,
    round(missed_deadline_pct, 1)    as missed_deadline_pct,
    round(avg_review_score, 2)       as avg_review_score

from seller_stats
where orders >= 50
order by late_orders desc
limit 20