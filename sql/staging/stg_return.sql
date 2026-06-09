{{ config(materialized='view') }}

-- DQ fix: returndate stored as varchar in M/DD/YYYY or MM/DD/YYYY format.
-- COALESCE pattern consistent with stg_calendar and stg_sales:
--   style 23  → YYYY-MM-DD (ISO)
--   style 101 → M/DD/YYYY  (US locale)

with source as (
    select * from {{ source('awdb_dbo', 'returns_data') }}
),

renamed as (
    select
        coalesce(
            try_convert(date, returndate, 23),    -- YYYY-MM-DD (ISO 8601)
            try_convert(date, returndate, 101)    -- M/DD/YYYY  (US locale)
        )                   as return_date,
        territorykey        as territory_key,     -- FK → dim_territory
        productkey          as product_key,       -- FK → dim_product
        returnquantity      as return_quantity
    from source
)

select * from renamed
