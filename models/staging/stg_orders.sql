{{ config(materialized='view') }}

with source_data as (
    select
        id as order_id,
        user_id as customer_id,
        order_date,
        status as order_status,
        
        -- Convertir la date en timestamp
        cast(order_date as timestamp) as order_date_ts,
        
        -- Indicateurs de statut
        case 
            when status = 'completed' then true 
            else false 
        end as is_completed,
        
        case 
            when status in ('returned', 'return_pending') then true 
            else false 
        end as is_returned,
        
        current_timestamp() as loaded_at
        
    from {{ source('retail_analytics', 'orders') }}
)

select * from source_data
