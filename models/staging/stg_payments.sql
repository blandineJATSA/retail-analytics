{{ config(materialized='view') }}

with source_data as (
    select
        id as payment_id,
        order_id,
        payment_method,
        amount,
        
        -- Convertir les cents en dollars
        amount / 100.0 as amount_usd,
        
        -- Catégoriser les méthodes de paiement
        case 
            when payment_method = 'credit_card' then 'card_payment'
            when payment_method in ('bank_transfer') then 'bank_payment'
            when payment_method in ('coupon', 'gift_card') then 'promotional_payment'
            else 'other'
        end as payment_category,
        
        current_timestamp() as loaded_at
        
    from {{ source('retail_analytics', 'payments') }}
)

select * from source_data
