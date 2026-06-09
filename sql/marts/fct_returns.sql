{{ config(materialized='table') }}

with stg_return as (
    select * from {{ ref('stg_return') }}
),

dim_product as (
    select
        product_key,
        product_price
    from {{ ref('dim_product') }}
),

final as (
    select
        -- Surrogate key (no natural unique ID in source)
        row_number() over (
            order by r.return_date, r.product_key, r.territory_key
        )                                                       as return_id,

        -- Keys
        r.product_key,
        r.territory_key,

        -- Dates
        r.return_date,
        cast(convert(varchar(8), r.return_date, 112) as int)   as return_date_key,

        -- Measures
        r.return_quantity,
        p.product_price,
        r.return_quantity * p.product_price                     as return_value
    from stg_return      as r
    left join dim_product as p
        on r.product_key = p.product_key
)

select * from final
