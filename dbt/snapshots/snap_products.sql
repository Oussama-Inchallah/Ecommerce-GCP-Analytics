{% snapshot snap_products %}

{{
    config(
        unique_key='product_id',
        strategy='check',
        check_cols=['product_name', 'category', 'brand', 'unit_price']
    )
}}

select
    product_id,
    product_name,
    category,
    brand,
    unit_price
from {{ ref('stg_orders') }}
group by 1, 2, 3, 4, 5

{% endsnapshot %}
