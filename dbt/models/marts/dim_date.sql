with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}
)
select
    {% if target.type == 'bigquery' %}
    cast(format_date('%Y%m%d', date_day) as int64) as date_key,
    {% else %}
    cast(to_char(date_day, 'YYYYMMDD') as numeric) as date_key,
    {% endif %}
    cast(date_day as date) as full_date,
    extract(year from date_day)    as year,
    extract(quarter from date_day) as quarter,
    extract(month from date_day)   as month,
    extract(day from date_day)     as day,
    {% if target.type == 'bigquery' %}
    extract(dayofweek from date_day) as day_of_week
    {% else %}
    extract(isodow from date_day) as day_of_week
    {% endif %}
from spine

-- with date_range as (
--     select date_value
--     from unnest(generate_date_array(
--         (select min(order_date) from {{ ref('stg_orders') }}),
--         (select max(order_date) from {{ ref('stg_orders') }})
--     )) as date_value
-- )

-- select
--     cast(format_date('%Y%m%d', date_value) as int64) as date_key,
--     date_value as full_date,
--     extract(year from date_value) as year,
--     extract(quarter from date_value) as quarter,
--     extract(month from date_value) as month,
--     extract(day from date_value) as day,
--     extract(dayofweek from date_value) as day_of_week
-- from date_range
