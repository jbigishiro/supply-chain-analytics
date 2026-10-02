with source as (

    select * from {{ source('olist_raw', 'order_items') }}

),

renamed as (

    select
        concat(order_id, '-', order_item_id) AS order_item_key,
        order_id,
        SAFE_CAST(order_item_id AS INT64) AS order_item_id,
        product_id,
        seller_id,
        SAFE_CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_at,
        SAFE_CAST(price AS NUMERIC) AS price,
        SAFE_CAST(freight_value AS NUMERIC) AS freight_value

    from source

)

select * from renamed