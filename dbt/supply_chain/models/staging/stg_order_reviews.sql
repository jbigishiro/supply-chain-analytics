with source as (

    select * from {{ source('olist_raw', 'order_reviews') }}

),

renamed as (

    select
        concat(review_id, '-', order_id) as review_key,
        review_id, 
        order_id, 
        SAFE_CAST(review_score AS INT64) AS review_score,
        review_comment_title, 
        review_comment_message, 
        SAFE_CAST(review_creation_date AS TIMESTAMP) AS review_created_at,
        SAFE_CAST(review_answer_timestamp AS TIMESTAMP) AS review_answered_at

    from source

)

select * from renamed