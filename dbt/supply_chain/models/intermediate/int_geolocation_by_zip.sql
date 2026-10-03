with geolocation as (

    select * from {{ ref('stg_geolocation') }}

),

by_zip AS (

    SELECT
        zip_code_prefix,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude,
        count(*) AS n_points
    FROM geolocation
    WHERE latitude BETWEEN -33.75 AND 5.27 
        AND longitude BETWEEN -73.99 AND 34.79
    GROUP BY zip_code_prefix

)

select * from by_zip