with sellers as (

    select * from {{ ref('stg_sellers') }}

),

geo as (

    select * from {{ ref('int_geolocation_by_zip') }}

)

select
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.latitude,
    g.longitude
    
from sellers as s
left join geo as g
    on s.seller_zip_code_prefix = g.zip_code_prefix