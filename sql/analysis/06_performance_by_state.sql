-- 06A: delivery performance by customer state, ranked by number of late orders

with by_customer_state as (

    select
        customer_state,
        count(*)                                                               as delivered_orders,
        countif(is_on_time) / count(*) * 100                                   as on_time_pct,
        countif(not is_on_time)                                                as late_orders,
        countif(not is_on_time) / sum(countif(not is_on_time)) over () * 100   as share_of_late_orders_pct,
        avg(total_delivery_days)                                               as avg_delivery_days

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and is_in_analysis_window
    group by customer_state

)

select
    customer_state,
    delivered_orders,
    round(on_time_pct, 1)               as on_time_pct,
    late_orders,
    round(share_of_late_orders_pct, 1)  as share_of_late_orders_pct,
    round(avg_delivery_days, 1)         as avg_delivery_days

from by_customer_state
order by late_orders desc;


-- 06B: delivery performance by seller state

with order_seller_states as (

    -- one row per order per seller state (collapses multiple items)
    select distinct
        i.order_id,
        s.seller_state,
        i.is_on_time,
        i.days_late

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.dim_sellers` as s
        using (seller_id)
    where i.is_delivered
      and i.is_in_analysis_window

)

select
    seller_state,
    count(*)                                         as orders,
    round(countif(is_on_time) / count(*) * 100, 1)   as on_time_pct,
    countif(not is_on_time)                          as late_orders,
    round(avg(days_late), 1)                         as avg_days_late

from order_seller_states
group by seller_state
having count(*) >= 100
order by orders desc;