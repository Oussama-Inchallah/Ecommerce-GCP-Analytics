{{ config(materialized='view') }}

select
    payment_method,
    count(*) as order_count,
    round({{ dbt_utils.safe_divide('count(*)', 'sum(count(*)) over ()') }}, 2)*100 as order_share
    from {{ ref('stg_orders') }}
group by payment_method
