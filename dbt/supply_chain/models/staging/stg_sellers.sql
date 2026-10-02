with source as (

    select * from {{ source('olist_raw', 'sellers') }}

),

renamed as (

    select

        seller_id, 
        LPAD(seller_zip_code_prefix, 5, '0') AS seller_zip_code_prefix,
        seller_city, 
        UPPER(TRIM(seller_state)) AS seller_state

    from source

)

select * from renamed