WITH orders AS (
  SELECT
    order_id,
    customer_id,
    order_status,
    SAFE_CAST(order_purchase_timestamp      AS TIMESTAMP) AS purchased_at,
    SAFE_CAST(order_approved_at             AS TIMESTAMP) AS approved_at,
    SAFE_CAST(order_delivered_carrier_date  AS TIMESTAMP) AS shipped_at,
    SAFE_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
    SAFE_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at
  FROM `supply-chain-analytics-510105.olist_raw.orders`
),

delivered AS (
  SELECT
    order_id,
    DATE_DIFF(DATE(delivered_at), DATE(purchased_at), DAY) AS delivery_days,
    DATE(delivered_at) <= DATE(estimated_at)              AS is_on_time
  FROM orders
  WHERE order_status = 'delivered'
    AND delivered_at IS NOT NULL
)

SELECT
  COUNT(*)                                       AS delivered_orders,
  ROUND(AVG(delivery_days), 1)                   AS avg_delivery_days,
  ROUND(COUNTIF(is_on_time) / COUNT(*) * 100, 1) AS on_time_pct
FROM delivered;