{{ config(materialized='table') }}

with stg_sales as (
    select * from {{ ref('stg_sales') }}
),

dim_product as (
    select
        product_key,
        product_price,
        product_cost
    from {{ ref('dim_product') }}
),

final as (
    select
        -- Keys
        s.order_number,
        s.order_line_item,
        s.product_key,
        s.customer_key,
        s.territory_key,

        -- Dates
        s.order_date,
        cast(convert(varchar(8), s.order_date, 112) as int)                             as order_date_key,
        s.stock_date,

        -- Measures
        s.order_quantity,
        p.product_price,
        p.product_cost,
        s.order_quantity * p.product_price                                              as order_line_revenue,
        s.order_quantity * p.product_cost                                               as order_line_cost,
        (s.order_quantity * p.product_price) - (s.order_quantity * p.product_cost)      as order_line_profit,
        round(
            ((s.order_quantity * p.product_price) - (s.order_quantity * p.product_cost))
            / nullif(s.order_quantity * p.product_price, 0) * 100
        , 2)                                                                            as profit_margin_pct
    from stg_sales       as s
    left join dim_product as p
        on s.product_key = p.product_key
)

select * from final
