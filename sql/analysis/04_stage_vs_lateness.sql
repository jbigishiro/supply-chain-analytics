-- 04: which fulfillment stage makes orders late?
-- Population: delivered orders with a valid timeline, Jan 2017 – Aug 2018

-- 04A: stage durations, late vs on-time orders

with stage_durations as (

    select
        is_on_time,
        count(*)                                                   as orders,

        avg(approval_days)                                         as avg_approval_days,
        approx_quantiles(approval_days, 100)[offset(50)]           as med_approval_days,
        approx_quantiles(approval_days, 100)[offset(90)]           as p90_approval_days,

        avg(seller_processing_days)                                as avg_seller_processing_days,
        approx_quantiles(seller_processing_days, 100)[offset(50)]  as med_seller_processing_days,
        approx_quantiles(seller_processing_days, 100)[offset(90)]  as p90_seller_processing_days,

        avg(carrier_transit_days)                                  as avg_carrier_transit_days,
        approx_quantiles(carrier_transit_days, 100)[offset(50)]    as med_carrier_transit_days,
        approx_quantiles(carrier_transit_days, 100)[offset(90)]    as p90_carrier_transit_days,

        avg(total_delivery_days)                                   as avg_total_delivery_days,
        approx_quantiles(total_delivery_days, 100)[offset(50)]     as med_total_delivery_days,
        approx_quantiles(total_delivery_days, 100)[offset(90)]     as p90_total_delivery_days

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and has_valid_timeline
      and is_in_analysis_window
    group by is_on_time

)

select
    is_on_time,
    orders,

    round(avg_approval_days, 1)           as avg_approval_days,
    round(med_approval_days, 1)           as med_approval_days,
    round(p90_approval_days, 1)           as p90_approval_days,

    round(avg_seller_processing_days, 1)  as avg_seller_processing_days,
    round(med_seller_processing_days, 1)  as med_seller_processing_days,
    round(p90_seller_processing_days, 1)  as p90_seller_processing_days,

    round(avg_carrier_transit_days, 1)    as avg_carrier_transit_days,
    round(med_carrier_transit_days, 1)    as med_carrier_transit_days,
    round(p90_carrier_transit_days, 1)    as p90_carrier_transit_days,

    round(avg_total_delivery_days, 1)     as avg_total_delivery_days,
    round(med_total_delivery_days, 1)     as med_total_delivery_days,
    round(p90_total_delivery_days, 1)     as p90_total_delivery_days

from stage_durations
order by is_on_time;


-- 04B: stage durations by purchase month

with monthly_stages as (

    select
        purchase_month,
        count(*)                              as delivered_orders,
        countif(is_on_time) / count(*) * 100  as on_time_pct,
        avg(approval_days)                    as avg_approval_days,
        avg(seller_processing_days)           as avg_seller_processing_days,
        avg(carrier_transit_days)             as avg_carrier_transit_days,
        avg(total_delivery_days)              as avg_total_delivery_days

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and has_valid_timeline
      and is_in_analysis_window
    group by purchase_month

)

select
    purchase_month,
    delivered_orders,
    round(on_time_pct, 1)                 as on_time_pct,
    round(avg_approval_days, 1)           as avg_approval_days,
    round(avg_seller_processing_days, 1)  as avg_seller_processing_days,
    round(avg_carrier_transit_days, 1)    as avg_carrier_transit_days,
    round(avg_total_delivery_days, 1)     as avg_total_delivery_days

from monthly_stages
order by purchase_month;