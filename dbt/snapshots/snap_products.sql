{% snapshot snap_products %}

{{
    config(
        unique_key='product_id',
        strategy='check',
        check_cols=['product_name', 'category', 'brand', 'unit_price']
    )
}}

with ranked_products as (
    select
        product_id,
        product_name,
        category,
        brand,
        unit_price,
        row_number() over (
            partition by product_id
            order by order_date desc, order_id desc
        ) as product_rank
    from {{ ref('stg_orders') }}
    where product_id is not null
)

select
    product_id,
    product_name,
    category,
    brand,
    unit_price
from ranked_products
where product_rank = 1

{% endsnapshot %}
