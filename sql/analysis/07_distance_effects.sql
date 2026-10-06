-- 07: delivery time, on-time rate and freight by seller–customer distance

with items as (

    select
        i.order_id,
        i.distance_km,
        i.price,
        i.freight_value,
        o.total_delivery_days,
        o.is_on_time,
        case
            when i.distance_km < 100  then '1. under 100 km'
            when i.distance_km < 300  then '2. 100–300 km'
            when i.distance_km < 600  then '3. 300–600 km'
            when i.distance_km < 1000 then '4. 600–1,000 km'
            when i.distance_km < 2000 then '5. 1,000–2,000 km'
            else                           '6. 2,000+ km'
        end as distance_band

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
        using (order_id)
    where o.is_delivered
      and o.is_in_analysis_window
      and i.distance_km is not null

)

select
    distance_band,
    count(*)                                         as items,
    round(avg(freight_value), 2)                     as avg_freight_brl,
    round(sum(freight_value) / sum(price) * 100, 1)  as freight_pct_of_price,
    round(avg(total_delivery_days), 1)               as avg_delivery_days,
    round(countif(is_on_time) / count(*) * 100, 1)   as on_time_pct

from items
group by distance_band
order by distance_band