
-- 12A: review score by days late (capped at ±15)

with orders as(
    select 
        order_id,
        is_on_time,
        greatest(least(days_late, 15), -15) as days_late_capped,
        review_score
    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
        and is_in_analysis_window
        and has_review
)

select 
    days_late_capped,
    count(*)                                               as orders,
    round(avg(review_score), 2)                            as avg_review_score, 
    round(countif(review_score <= 2) / count(*) * 100, 1)  as pct_1_2_star

    from orders
    group by days_late_capped
    order by days_late_capped;

-- 12B: share of each review score coming from late orders

with reviewed_orders as(
    select 
        order_id,
        is_on_time,
        review_score
    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_delivered
        and is_in_analysis_window
        and has_review
)

select 
    review_score,
    count(*)                                               as reviews,
    round(countif(not is_on_time) / count(*) * 100, 1)     as pct_from_late_orders,
    round(count(*)/sum(count(*)) over ()*100, 1)           as share_of_reviews_pct,
    
from reviewed_orders
group by review_score
order by review_score


