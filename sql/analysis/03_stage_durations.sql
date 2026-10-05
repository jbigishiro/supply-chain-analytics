-- 03: fulfillment stage durations (days) — delivered orders with valid timelines

with stage_durations as (

    select
        avg(approval_days)                                          as avg_approval_days,
        approx_quantiles(approval_days, 100)[offset(50)]            as med_approval_days,
        approx_quantiles(approval_days, 100)[offset(90)]            as q90_approval_days,

        avg(seller_processing_days)                                 as avg_seller_processing_days,
        approx_quantiles(seller_processing_days, 100)[offset(50)]   as med_seller_processing_days,
        approx_quantiles(seller_processing_days, 100)[offset(90)]   as q90_seller_processing_days,

        avg(carrier_transit_days)                                   as avg_carrier_transit_days,
        approx_quantiles(carrier_transit_days, 100)[offset(50)]     as med_carrier_transit_days,
        approx_quantiles(carrier_transit_days, 100)[offset(90)]     as q90_carrier_transit_days,

        avg(total_delivery_days)                                    as avg_total_delivery_days,
        approx_quantiles(total_delivery_days, 100)[offset(50)]      as med_total_delivery_days,
        approx_quantiles(total_delivery_days, 100)[offset(90)]      as q90_total_delivery_days

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and has_valid_timeline
      and is_in_analysis_window

    
)

select

    round(avg_approval_days, 1)                    as avg_approval_days,
    round(med_approval_days, 1)                    as med_approval_days,
    round(q90_approval_days, 1)                    as q90_approval_days,

    round(avg_seller_processing_days, 1)           as avg_seller_processing_days,
    round(med_seller_processing_days, 1)           as med_seller_processing_days,
    round(q90_seller_processing_days, 1)           as q90_seller_processing_days,

    round(avg_carrier_transit_days, 1)             as avg_carrier_transit_days,
    round(med_carrier_transit_days, 1)             as med_carrier_transit_days,
    round(q90_carrier_transit_days, 1)             as q90_carrier_transit_days,

    round(avg_total_delivery_days, 1)              as avg_total_delivery_days,
    round(med_total_delivery_days, 1)              as med_total_delivery_days,
    round(q90_total_delivery_days, 1)              as q90_total_delivery_days

from stage_durations
