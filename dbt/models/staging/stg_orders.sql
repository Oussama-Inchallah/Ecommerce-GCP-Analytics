with source_orders as (
    select *
    from {{ref('Amazon')}}
)

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
from source_orders
