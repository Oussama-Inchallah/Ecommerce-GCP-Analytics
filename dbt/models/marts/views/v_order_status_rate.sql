{{ config(materialized='view') }}

select
    order_status,
    count(*) as order_count,
    round({{ dbt_utils.safe_divide('count(*)', 'sum(count(*)) over ()') }}, 2)*100 as order_rate
from {{ ref('stg_orders') }}
group by order_status
