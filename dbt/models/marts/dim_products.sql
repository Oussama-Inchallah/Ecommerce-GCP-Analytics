select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,
    product_id,
    product_name,
    category,
    brand,
    unit_price
from {{ ref('snap_products') }}
where product_id is not null
