with source as (

    select * from {{ source('olist_raw', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_status,
        safe_cast(order_purchase_timestamp      as timestamp) as purchased_at,
        safe_cast(order_approved_at             as timestamp) as approved_at,
        safe_cast(order_delivered_carrier_date  as timestamp) as carrier_handoff_at,
        safe_cast(order_delivered_customer_date as timestamp) as delivered_at,
        date(safe_cast(order_estimated_delivery_date as timestamp)) as estimated_delivery_date

    from source

)

select * from renamed