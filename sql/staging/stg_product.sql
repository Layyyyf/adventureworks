{{ config(materialized='view') }}

-- DQ fixes:
--   productsize / productstyle use '0' as a sentinel for N/A → replaced with NULL
--   productsize / productstyle short forms expanded to full words
--   productcolor 'NA' → NULL
--   productcost / productprice are already DECIMAL(18,2) in source — passed through
--   text columns trimmed

with source as (
    select * from {{ source('awdb_dbo', 'products') }}
),

renamed as (
    select
        -- Keys
        productkey                              as product_key,
        productsubcategorykey                   as product_subcategory_key, -- FK → stg_product_subcategory

        -- Identifiers
        trim(productsku)                        as product_sku,

        -- Descriptors
        trim(productname)                       as product_name,
        trim(modelname)                         as model_name,
        trim(productdescription)                as product_description,
        nullif(trim(productcolor), 'NA')        as product_color,

        -- Attributes: '0' sentinel → NULL; short forms → full words
        case trim(productsize)
            when '0'  then null
            when 'S'  then 'Small'
            when 'M'  then 'Medium'
            when 'L'  then 'Large'
            when 'XL' then 'Extra Large'
            else trim(productsize)             -- numeric EU sizes (38, 40 … 70) passed through
        end                                     as product_size,

        case trim(productstyle)
            when '0' then null
            when 'U' then 'Unisex'
            when 'M' then 'Men'
            when 'W' then 'Women'
            else trim(productstyle)
        end                                     as product_style,

        -- Financials (already DECIMAL(18,2) in source)
        productcost                             as product_cost,
        productprice                            as product_price
    from source
)

select * from renamed
