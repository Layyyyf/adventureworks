{{ config(materialized='view') }}

-- Staging model wraps raw customers 1:1.
-- DQ fixes applied:
--   1. birthdate  — COALESCE two TRY_CONVERT styles to handle ISO + US locale formats
--   2. first/last — UPPER(LEFT) + LOWER(SUBSTRING) to title-case ALL CAPS names
--   3. prefix     — normalised to title case (MR. → Mr.) and NULL-filled from gender
--   4. marital    — single-char codes expanded (M → Married, S → Single)
--   5. homeowner  — Y/N flag cast to 1/0 BIT-style integer

with source as (
    select * from {{ source('awdb_dbo', 'customers') }}
),

renamed as (
    select
        -- Keys
        customerkey                                                     as customer_key,

        -- Name  (title-case ALL CAPS source values)
        prefix_derived.prefix                                           as prefix,

        upper(left(trim(firstname), 1))
            + lower(substring(trim(firstname), 2, len(trim(firstname))))
                                                                        as first_name,

        upper(left(trim(lastname), 1))
            + lower(substring(trim(lastname), 2, len(trim(lastname))))
                                                                        as last_name,

        -- Demographics
        case
            when gender = 'NA' then 'Unknown'
            else gender
        end                                                             as gender,

        -- birthdate: handle both ISO (YYYY-MM-DD, style 23)
        --            and US locale (M/DD/YYYY, style 101)
        coalesce(
            try_convert(date, birthdate, 23),
            try_convert(date, birthdate, 101)
        )                                                               as birth_date,

        case maritalstatus
            when 'M' then 'Married'
            when 'S' then 'Single'
            else maritalstatus
        end                                                             as marital_status,

        totalchildren                                                   as total_children,
        educationlevel                                                  as education_level,
        occupation,

        -- homeowner: Y/N flag → 1/0
        case homeowner when 'Y' then 1 else 0 end                      as is_home_owner,

        -- Contact
        trim(emailaddress)                                              as email_address,

        -- Financials: strip leading '$', thousands commas, trailing spaces
        try_cast(
            replace(replace(annualincome, '$', ''), ',', '')
            as decimal(18, 2)
        )                                                               as annual_income

    from source

    -- Derive and normalise prefix in one step:
    --   NULL + M/F  → derive 'Mr.' / 'Ms.'
    --   ALL CAPS    → normalise to title case
    cross apply (
        select
            case
                when prefix is null and gender = 'M' then 'Mr.'
                when prefix is null and gender = 'F' then 'Ms.'
                when prefix = 'MR.'                 then 'Mr.'
                when prefix = 'MRS.'                then 'Mrs.'
                when prefix = 'MS.'                 then 'Ms.'
                else prefix
            end as prefix
    ) as prefix_derived
)

select * from renamed
