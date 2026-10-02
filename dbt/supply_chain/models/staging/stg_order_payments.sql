with source as (

    select * from {{ source('olist_raw', 'order_payments') }}

),

renamed as (

    select
        concat(order_id, '-', payment_sequential) AS payment_key,
        order_id, 
        SAFE_CAST(payment_sequential AS INT64) AS payment_sequential,
        payment_type, 
        SAFE_CAST(payment_installments AS INT64) AS payment_installments,
        SAFE_CAST(payment_value AS NUMERIC) AS payment_value
       
    from source

)

select * from renamed