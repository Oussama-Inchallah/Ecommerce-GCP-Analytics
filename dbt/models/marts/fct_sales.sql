select
    orders.order_id,
    orders.customer_id,
    cities.city_id,
    products.product_key,
    -- cast(format_date('%Y%m%d', orders.order_date) as numeric) as date_key, --- BigQuery
    cast(to_char(orders.order_date, 'YYYYMMDD') as integer) as date_key,   -- Postgres
    orders.seller_id,
    orders.unit_price,
    orders.quantity,
    orders.discount,
    orders.tax,
    orders.shipping_cost,
    orders.total_amount,
    orders.payment_method,
    orders.order_status
from {{ ref('stg_orders') }} as orders
left join {{ ref('dim_cities') }} as cities
    on orders.city = cities.city
    and orders.state = cities.state
    and orders.country = cities.country
left join {{ ref('dim_products') }} as products
    on orders.product_id = products.product_id
   
