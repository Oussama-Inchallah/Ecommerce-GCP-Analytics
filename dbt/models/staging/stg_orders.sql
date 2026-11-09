with source_orders as (
    select *
    from
    {% if target.type == 'bigquery' %}
        {{ source('raw', 'amazon_sales') }}
    {% else %}
        {{ ref('Amazon') }}
    {% endif %}
)

{% if target.type == 'bigquery' %}
select
    cast(order_id as string) as order_id,
    cast(order_date as date) as order_date,
    cast(customer_id as string) as customer_id,
    cast(customer_name as string) as customer_name,
    cast(product_id as string) as product_id,
    cast(product_name as string) as product_name,
    cast(category as string) as category,
    cast(brand as string) as brand,
    cast(quantity as numeric) as quantity,
    cast(unit_price as numeric) as unit_price,
    cast(discount as numeric) as discount,
    cast(tax as numeric) as tax,
    cast(shipping_cost as numeric) as shipping_cost,
    cast(total_amount as numeric) as total_amount,
    cast(payment_method as string) as payment_method,
    cast(order_status as string) as order_status,
    cast(city as string) as city,
    cast(state as string) as state,
    cast(country as string) as country,
    cast(seller_id as string) as seller_id
{% else %}
select
    cast("OrderID" as text) as order_id,
    cast("OrderDate" as date) as order_date,
    cast("CustomerID" as text) as customer_id,
    cast("CustomerName" as text) as customer_name,
    cast("ProductID" as text) as product_id,
    cast("ProductName" as text) as product_name,
    cast("Category" as text) as category,
    cast("Brand" as text) as brand,
    cast("Quantity" as numeric) as quantity,
    cast("UnitPrice" as numeric) as unit_price,
    cast("Discount" as numeric) as discount,
    cast("Tax" as numeric) as tax,
    cast("ShippingCost" as numeric) as shipping_cost,
    cast("TotalAmount" as numeric) as total_amount,
    cast("PaymentMethod" as text) as payment_method,
    cast("OrderStatus" as text) as order_status,
    cast("City" as text) as city,
    cast("State" as text) as state,
    cast("Country" as text) as country,
    cast("SellerID" as text) as seller_id
{% endif %}
from source_orders
