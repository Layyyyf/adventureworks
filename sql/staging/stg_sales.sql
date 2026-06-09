{{ config(materialized='view') }}

-- Combines sales_2015, sales_2016, sales_2017 into a single staging model.
-- DQ fixes:
--   orderdate  is already a datetime — cast to date
--   stockdate  is varchar with mixed formats (YYYY-MM-DD and M/DD/YYYY)
--              → same COALESCE pattern used in stg_calendar

with sales_2015 as (
    select * from {{ source('awdb_dbo', 'sales_2015') }}
),

sales_2016 as (
    select * from {{ source('awdb_dbo', 'sales_2016') }}
),

sales_2017 as (
    select * from {{ source('awdb_dbo', 'sales_2017') }}
),

unioned as (
    select * from sales_2015
    union all
    select * from sales_2016
    union all
    select * from sales_2017
),

renamed as (
    select
        -- Dates
        cast(orderdate as date)                                         as order_date,
        coalesce(
            try_convert(date, stockdate, 23),   -- YYYY-MM-DD (ISO)
            try_convert(date, stockdate, 101)   -- M/DD/YYYY  (US locale)
        )                                                               as stock_date,

        -- Identifiers
        trim(ordernumber)                                               as order_number,
        orderlineitem                                                   as order_line_item,

        -- Foreign keys
        productkey                                                      as product_key,
        customerkey                                                     as customer_key,
        territorykey                                                    as territory_key,

        -- Measures
        orderquantity                                                   as order_quantity
    from unioned
)

select * from renamed
