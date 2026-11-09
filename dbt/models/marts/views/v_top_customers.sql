{{ config(materialized='view') }}

select
    customer_id,
    customer_name,
    count(*) as order_count,
    sum(total_amount) as total_spend
from {{ ref('stg_orders') }}
group by customer_id, customer_name
order by total_spend desc
