{{ config(materialized='table') }}

with source as (
    select * from {{ source('awdb_dbo', 'territories') }}
),

final as (
    select
        salesterritorykey   as territory_key,
        region,
        country,
        continent
    from source
)

select * from final
