{{ config(materialized='table') }}

with stg_customer as (
    select * from {{ ref('stg_customer') }}
),

final as (
    select
        customer_key,
        prefix,
        first_name,
        last_name,
        concat(first_name, ' ', last_name)  as full_name,  -- CONCAT handles NULLs safely
        gender,
        birth_date,
        marital_status,
        total_children,
        education_level,
        occupation,
        is_home_owner,
        email_address,
        annual_income
    from stg_customer
)

select * from final
