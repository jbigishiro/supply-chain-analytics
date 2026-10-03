with reviews as (

    select * from {{ ref('stg_order_reviews') }}

),

latest as (

    select
        order_id,
        review_id,
        review_score,
        review_created_at,
        review_answered_at

    from reviews
    where review_score is not null
    qualify row_number() over (
        partition by order_id
        order by review_answered_at desc
    ) = 1

)

select * from latest