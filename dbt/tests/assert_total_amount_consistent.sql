with calculated as (
    select
        order_id,
        total_amount,
        quantity * unit_price
            * (1 - case when discount > 1 then discount / 100 else discount end)
            + tax
            + shipping_cost as expected_total_amount
    from {{ ref('stg_orders') }}
)

select *
from calculated
where abs(total_amount - expected_total_amount) > 0.01
