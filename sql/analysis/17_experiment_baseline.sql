-- Baselines for the proactive delay-notification A/B test.
-- Trigger: order still not delivered 2 days before its estimated delivery date.
-- Period: Jan–Jun 2018 (recent, complete months; avoids Aug 2018 right-censoring).

with orders as (
    select
        order_id,
        purchase_date,
        is_on_time,
        has_review,
        review_score,
        date(delivered_at) > date_sub(estimated_delivery_date, interval 2 day) as is_triggered
    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
      and purchase_date between '2018-01-01' and '2018-06-30'
)

select
    is_triggered,
    count(*)                                                        as orders,
    round(count(*) / 26, 0)                                         as orders_per_week,
    round(avg(if(is_on_time, 0, 1)), 3)                             as late_rate,
    round(avg(if(has_review, 1, 0)), 3)                             as review_rate,
    round(avg(if(review_score <= 2, 1, 0)), 3)                      as low_review_rate,  -- among reviewed (NULLs ignored)
    round(avg(review_score), 2)                                     as avg_review
from orders
group by is_triggered
order by is_triggered