-- 09A: delivery and freight by product weight

with items as (

    select
        i.order_id,
        i.price,
        i.freight_value,
        i.is_on_time,
        o.total_delivery_days,
        p.weight_g,
        case
            when p.weight_g < 500   then '1. under 0.5 kg'
            when p.weight_g < 2000  then '2. 0.5–2 kg'
            when p.weight_g < 5000  then '3. 2–5 kg'
            when p.weight_g < 10000 then '4. 5–10 kg'
            else                         '5. 10+ kg'
        end as weight_band

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
        using (order_id)
    inner join `supply-chain-analytics-510105.dbt_dev_marts.dim_products` as p
        using (product_id)
    where o.is_delivered
      and o.is_in_analysis_window
      and p.weight_g is not null

)

select
    weight_band,
    count(*)                                         as items,
    round(avg(freight_value), 2)                     as avg_freight_brl,
    round(sum(freight_value) / sum(price) * 100, 1)  as freight_pct_of_price,
    round(avg(total_delivery_days), 1)               as avg_delivery_days,
    round(countif(is_on_time) / count(*) * 100, 1)   as on_time_pct

from items
group by weight_band
order by weight_band;


-- 09B: delivery and freight by product category

with items as (

    select
        i.order_id,
        i.price,
        i.freight_value,
        i.is_on_time,
        o.total_delivery_days,
        p.weight_g,
        p.category_name

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_order_items` as i
    inner join `supply-chain-analytics-510105.dbt_dev_marts.fact_orders` as o
        using (order_id)
    inner join `supply-chain-analytics-510105.dbt_dev_marts.dim_products` as p
        using (product_id)
    where o.is_delivered
      and o.is_in_analysis_window
      and p.category_name is not null

)

select
    category_name,
    count(*)                                         as items,
    round(avg(weight_g), 0)                          as avg_weight_g,
    round(avg(freight_value), 2)                     as avg_freight_brl,
    round(sum(freight_value) / sum(price) * 100, 1)  as freight_pct_of_price,
    round(avg(total_delivery_days), 1)               as avg_delivery_days,
    round(countif(is_on_time) / count(*) * 100, 1)   as on_time_pct

from items
group by category_name
having count(*) >= 1000
order by on_time_pct;