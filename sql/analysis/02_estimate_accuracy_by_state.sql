-- 02: estimate accuracy by state, Brazil

with by_state as (

    select
        customer_state
        count(*)                                  as delivered_orders,
        avg(promised_days)                        as avg_promised_days,
        avg(total_delivery_days)                  as avg_delivery_days,
        avg(days_late)                            as avg_estimate_error_days,
        countif(is_on_time) / count(*) * 100      as on_time_pct,
        countif(days_late <= -7) / count(*) * 100  as seven_or_more_days_early_pct


    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and is_in_analysis_window
    group by customer_state
    

)

select
    customer_state,
    delivered_orders,
    round(avg_promised_days, 1)                    as avg_promised_days,
    round(avg_delivery_days, 1)                    as avg_delivery_days,
    round(avg_estimate_error_days, 1)              as aavg_estimate_error_days,
    round(on_time_pct)                             as on_time_pct
    round(seven_or_more_days_early_pct,1)          as seven_or_more_days_early_pct

from by_state
order by avg_estimate_error_days