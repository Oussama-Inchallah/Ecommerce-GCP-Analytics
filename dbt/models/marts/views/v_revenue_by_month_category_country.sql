{{ config(materialized='view') }}

select
    extract(year from order_date) as year,
    extract(month from order_date) as month,
    category,
    country,
    sum(total_amount) as revenue,
    count(*) as order_count
from {{ ref('stg_orders') }}
group by year, month, category, country
