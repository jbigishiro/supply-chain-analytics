-- Stage durations must never be negative; invalid timelines should be NULL.
select
    order_id,
    approval_days,
    seller_processing_days,
    carrier_transit_days

from {{ ref('fact_orders') }}
where approval_days < 0
   or seller_processing_days < 0
   or carrier_transit_days < 0