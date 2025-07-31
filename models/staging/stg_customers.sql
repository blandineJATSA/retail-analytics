{{ config(materialized='view') }}

with source_data as (
    select
        id as customer_id,
        first_name,
        last_name,
        concat(first_name, ' ', last_name) as full_name,
        initcap(first_name) as first_name_clean,
        initcap(last_name) as last_name_clean,
        current_timestamp() as loaded_at
        
    from {{ source('retail_analytics', 'customers') }}
)

select * from source_data
