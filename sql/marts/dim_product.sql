{{ config(materialized='table') }}

with stg_product as (
    select * from {{ ref('stg_product') }}
),

product_subcategory as (
    select * from {{ source('awdb_dbo', 'product_subcategory') }}
),

product_category as (
    select * from {{ source('awdb_dbo', 'product_category') }}
),

final as (
    select
        p.product_key,
        p.product_sku,
        p.product_name,
        p.model_name,
        p.product_description,
        p.product_color,
        p.product_size,
        p.product_style,
        p.product_cost,
        p.product_price,
        sc.subcategoryname          as product_subcategory,
        c.categoryname              as product_category
    from stg_product              as p
    left join product_subcategory as sc
        on p.product_subcategory_key = sc.productsubcategorykey
    left join product_category    as c
        on sc.productcategorykey = c.productcategorykey
)

select * from final
