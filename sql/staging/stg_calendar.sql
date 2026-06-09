{{ config(materialized='view') }}

-- Source stores dates as varchar in two formats:
--   • YYYY-MM-DD  (ISO)       → days 1-12 of each month
--   • M/DD/YYYY or MM/DD/YYYY → days 13-31 of each month
-- COALESCE tries ISO style 23 first, then US style 101.
-- Both resolve to a native DATE; downstream models reference date_day.

with source as (
    select * from {{ source('awdb_dbo', 'calendar') }}
),

renamed as (
    select
        coalesce(
            try_convert(date, date, 23),   -- YYYY-MM-DD (ISO 8601)
            try_convert(date, date, 101)   -- M/DD/YYYY  (US locale)
        ) as date_day
    from source
)

select * from renamed
