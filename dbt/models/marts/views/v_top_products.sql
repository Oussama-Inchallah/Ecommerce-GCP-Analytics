{{ config(materialized='view') }}

select
    product_id,
    product_name,
    sum(quantity) as units_sold,
    sum(total_amount) as revenue
from {{ ref('stg_orders') }}
group by product_id, product_name
order by revenue desc
