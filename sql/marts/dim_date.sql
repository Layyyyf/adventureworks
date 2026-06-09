{{ config(materialized='table') }}

with stg_calendar as (
    select * from {{ ref('stg_calendar') }}
),

final as (
    select
        -- Surrogate key (YYYYMMDD integer for fast BI joins)
        cast(convert(varchar(8), date_day, 112) as int)                     as date_key,

        date_day,
        year(date_day)                                                      as year,
        month(date_day)                                                     as month_number,
        datename(month, date_day)                                           as month_name,
        datepart(quarter, date_day)                                         as quarter,
        datepart(week, date_day)                                            as week_of_year,
        datepart(weekday, date_day)                                         as day_of_week,
        datename(weekday, date_day)                                         as day_name,
        case when datepart(weekday, date_day) in (1, 7) then 1 else 0 end  as is_weekend
    from stg_calendar
)

select * from final
