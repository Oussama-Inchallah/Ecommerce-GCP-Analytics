select
    {{ dbt_utils.generate_surrogate_key(['city', 'state', 'country']) }} as city_id,
    city,
    state,
    country
from {{ ref('stg_orders') }}
group by city, state, country
