with dates as (

    select date_day
    from unnest(generate_date_array(date '2016-09-01', date '2018-12-31')) as date_day

)

select
    date_day,
    extract(year from date_day)                    as year,
    extract(quarter from date_day)                 as quarter,
    extract(month from date_day)                   as month,
    format_date('%b', date_day)                    as month_name,
    date_trunc(date_day, month)                    as month_start,
    date_trunc(date_day, week(monday))             as week_start,
    format_date('%A', date_day)                    as day_name,
    extract(dayofweek from date_day) in (1, 7)     as is_weekend

from dates