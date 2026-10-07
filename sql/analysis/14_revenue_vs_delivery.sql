-- 14: which states and categories drive revenue, and how do they perform on delivery?
-- Revenue population: orders purchased Jan 2017 – Aug 2018, excluding canceled and unavailable.
-- On-time rate: delivered orders only (countif(is_on_time) / countif(is_delivered)).


-- 14A: revenue and delivery performance by customer state

with by_state as (

    select
        customer_state,
        count(*)                                           as orders,
        sum(order_value)                                   as gmv,
        countif(is_on_time) / countif(is_delivered) * 100  as on_time_pct,
        avg(review_score)                                  as avg_review_score

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_in_analysis_window
      and order_status not in ('canceled', 'unavailable')
    group by customer_state

)

select
    customer_state,
    orders,
    round(gmv, 0)                                   as gmv_brl,
    round(gmv / sum(gmv) over () * 100, 1)          as gmv_share_pct,
    round(on_time_pct, 1)                           as on_time_pct,
    round(avg_review_score, 2)                      as avg_review_score

from by_state
order by gmv desc;


-- 14B: revenue and delivery performance by product category (top 15 by revenue)

with order_items as (

    select
        p.category_name,
        i.item_value,
        o.is_on_time,
        o.is_delivered,
        o.review_score

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o using (order_id)
    left join `supply-chain-analytics-510105.dbt_dev_marts.dim_products` as p using (product_id)
    where o.is_in_analysis_window
      and o.order_status not in ('canceled', 'unavailable')

),

by_category as (

    select
        category_name,
        count(*)                                           as items,
        sum(item_value)                                    as revenue,
        countif(is_on_time) / countif(is_delivered) * 100  as on_time_pct,
        avg(review_score)                                  as avg_review_score

    from order_items
    group by category_name

)

select
    category_name,
    items,
    round(revenue, 0)                                  as revenue_brl,
    round(revenue / sum(revenue) over () * 100, 1)     as revenue_share_pct,
    round(on_time_pct, 1)                              as on_time_pct,
    round(avg_review_score, 2)                         as avg_review_score

from by_category
order by revenue desc
limit 15;