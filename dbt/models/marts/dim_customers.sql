select
    customer_id,
    any_value(customer_name) as customer_name
from {{ ref('stg_orders') }}
group by customer_id
