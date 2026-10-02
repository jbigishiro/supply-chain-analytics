with source as (

    select * from {{ source('olist_raw', 'geolocation') }}

),

renamed as (

    select
        geolocation_zip_code_prefix              as zip_code_prefix,
        safe_cast(geolocation_lat as float64)    as latitude,
        safe_cast(geolocation_lng as float64)    as longitude,
        geolocation_city                         as city,
        upper(trim(geolocation_state))           as state

    from source

)

select * from renamed