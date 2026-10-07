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
    round(avg(review_score), 1)                            as avg_review_score, 
    round(countif(review_score <= 2) / count(*) * 100, 1)  as one_to_two_review_pct

    from orders
    group by days_late_capped
    order by days_late_capped;


select 
    review_score,
    count(*)                                               as reviews,
    round(countif(not is_on_time) / count(*) * 100, 1)     as late_orders_pct,
    countif(not is_on_time)/sum(count(*)) over ()          as late_orders_shares,
    
    from orders
    group by review_score
    order by review_score


