-- 1,382 orders currently have out-of-order timestamps (see docs/scoping.md).
-- Warn if this grows past 1,500; fail if it more than doubles.
{{ config(warn_if='>1500', error_if='>3000') }}

select order_id
from {{ ref('fact_orders') }}
where not has_valid_timeline