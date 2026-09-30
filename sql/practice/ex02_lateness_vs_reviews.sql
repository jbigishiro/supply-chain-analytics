WITH orders AS (
  SELECT
    order_id,
    order_status,
    SAFE_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
    SAFE_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at
  FROM `supply-chain-analytics-510105.olist_raw.orders`
),

delivered AS (
  -- one row per delivered order, with days late (negative = early)
  SELECT
    order_id,
    DATE_DIFF(DATE(delivered_at), DATE(estimated_at), DAY) AS lateness_days
  FROM orders
  WHERE order_status = 'delivered'
    AND delivered_at IS NOT NULL
),

late_buckets AS (
  SELECT
    order_id,
    lateness_days,
    CASE
      WHEN lateness_days <= -7 THEN '7+ days early'
      WHEN lateness_days <= -1 THEN '1-6 days early'
      WHEN lateness_days = 0   THEN 'on the estimated day'
      WHEN lateness_days <= 3  THEN '1-3 days late'
      WHEN lateness_days <= 7  THEN '4-7 days late'
      ELSE '8+ days late'
    END AS lateness_bucket
  FROM delivered
),

reviews AS (
  -- one row per order: keep only the latest review
  SELECT
    order_id,
    SAFE_CAST(review_score AS INT64) AS review_score
  FROM `supply-chain-analytics-510105.olist_raw.order_reviews`
  WHERE review_score IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id
    ORDER BY review_answer_timestamp DESC
  ) = 1
)

SELECT
  l.lateness_bucket,
  COUNT(*)                      AS orders,
  COUNT(r.review_score)         AS reviewed_orders,
  ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM late_buckets AS l
LEFT JOIN reviews AS r USING (order_id)
GROUP BY l.lateness_bucket
ORDER BY MIN(l.lateness_days);