with products as (

    select * from {{ ref('stg_products') }}

),

category_translation as (

    select * from {{ ref('stg_product_category_translation') }}

)

select
    p.product_id,
    coalesce(t.product_category_name_english,p.product_category_name, 'unknown') as category_name,
    p.product_weight_g   as weight_g,
    p.product_length_cm   as length_cm,
    p.product_height_cm  as height_cm,
    p.product_width_cm   as width_cm,
    p.product_length_cm * p.product_height_cm * p.product_width_cm as volume_cm3

from products as p
left join category_translation as t
    on p.product_category_name = t.product_category_name