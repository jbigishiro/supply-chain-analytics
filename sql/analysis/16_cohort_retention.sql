-- 16: monthly cohort retention by first-purchase month
-- Population: orders purchased Jan 2017 – Aug 2018, excluding canceled and unavailable.
-- A cohort's month-N cell is NULL when month N falls after Aug 2018 (not yet observable).

with orders as (

    select
        customer_unique_id,
        purchase_month

    from `supply-chain-analytics-510105.dbt_dev_marts.fact_orders`
    where is_in_analysis_window
      and order_status not in ('canceled', 'unavailable')

),

cohorts as (

    -- each person's first purchase month
    select
        customer_unique_id,
        min(purchase_month) as cohort_month

    from orders
    group by customer_unique_id

),

activity as (

    -- one row per person per month in which they ordered, with months since their first order
    select distinct
        c.cohort_month,
        o.customer_unique_id,
        date_diff(o.purchase_month, c.cohort_month, month) as month_number

    from orders as o
    inner join cohorts as c using (customer_unique_id)

),

cohort_sizes as (

    select
        cohort_month,
        count(*) as customers

    from cohorts
    group by cohort_month

)

select
    a.cohort_month,
    s.customers,

    if(date_add(a.cohort_month, interval 1 month) <= date '2018-08-01',
       round(countif(a.month_number = 1) / s.customers * 100, 2), null)   as m1_pct,

    if(date_add(a.cohort_month, interval 2 month) <= date '2018-08-01',
       round(countif(a.month_number = 2) / s.customers * 100, 2), null)   as m2_pct,

    if(date_add(a.cohort_month, interval 3 month) <= date '2018-08-01',
       round(countif(a.month_number = 3) / s.customers * 100, 2), null)   as m3_pct,

    if(date_add(a.cohort_month, interval 6 month) <= date '2018-08-01',
       round(countif(a.month_number = 6) / s.customers * 100, 2), null)   as m6_pct,

    if(date_add(a.cohort_month, interval 12 month) <= date '2018-08-01',
       round(countif(a.month_number = 12) / s.customers * 100, 2), null)  as m12_pct

from activity as a
inner join cohort_sizes as s using (cohort_month)
group by a.cohort_month, s.customers
order by a.cohort_month