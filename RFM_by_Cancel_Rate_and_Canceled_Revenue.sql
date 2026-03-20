WITH base AS (
  SELECT
    stock_code,
    customer_id,
    country,
    invoice_no,
    DATE(invoice_date) AS dt,
    unit_price * quantity AS line_amount
  FROM cleaned_final
  WHERE customer_id IS NOT NULL
  AND stock_code <> 'B%'
),

inv AS (
  SELECT
    customer_id, invoice_no, dt, country,
    SUM(line_amount) AS invoice_amount
  FROM base
  GROUP BY customer_id, invoice_no, dt, country
),

first_purchase AS (
  SELECT
    customer_id,
    MIN(dt) AS first_purchase_date
  FROM base
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%'
    AND line_amount > 0
  GROUP BY customer_id
),

valid_cancel AS (
  SELECT customer_id, invoice_no, dt, country
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
),

orders_scope_has_fp AS (
  SELECT
    i.customer_id,
    i.invoice_no,
    i.dt,
    i.country,
    i.invoice_amount,
    fp.first_purchase_date,
    CASE WHEN vc.invoice_no IS NOT NULL THEN 1 ELSE 0 END AS is_cancel
  FROM inv i
  JOIN first_purchase fp
    ON fp.customer_id = i.customer_id
  LEFT JOIN valid_cancel vc
    ON vc.customer_id = i.customer_id
   AND vc.invoice_no  = i.invoice_no
   AND vc.dt          = i.dt
   AND vc.country     = i.country
  WHERE
      (UPPER(TRIM(i.invoice_no)) NOT LIKE 'C%' AND i.invoice_amount > 0)
   OR (vc.invoice_no IS NOT NULL)
),

order_labeled_has_fp AS (
  SELECT
    country,
    customer_id,
    invoice_no,
    dt,
    first_purchase_date,
    is_cancel,
    invoice_amount,
    CASE
      WHEN is_cancel = 1 AND dt < first_purchase_date THEN 'Pre-first-purchase cancel'
      WHEN dt = first_purchase_date THEN 'New'
      WHEN dt > first_purchase_date THEN 'Returning'
      ELSE 'Other'
    END AS customer_type
  FROM orders_scope_has_fp
),


all_orders_labeled AS (
  SELECT * FROM order_labeled_has_fp
),

purchase_inv AS (
  SELECT *
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%'
    AND invoice_amount > 0
),

asof AS (
  SELECT DATE_ADD(MAX(dt), INTERVAL 1 DAY) AS as_of_date
  FROM purchase_inv
),

rfm_raw AS (
  SELECT
    p.customer_id,
    MAX(p.dt) AS last_purchase_date,
    COUNT(DISTINCT p.invoice_no) AS freq_orders,
    SUM(p.invoice_amount) AS monetary_amount
  FROM purchase_inv p
  GROUP BY p.customer_id
),

rfm_scored AS (
  SELECT
    r.customer_id,
    (6 - NTILE(5) OVER (ORDER BY DATEDIFF(a.as_of_date, r.last_purchase_date) ASC)) AS r_score,
    NTILE(5) OVER (ORDER BY r.freq_orders ASC) AS f_score,
    NTILE(5) OVER (ORDER BY r.monetary_amount ASC) AS m_score
  FROM rfm_raw r
  CROSS JOIN asof a
),

rfm_segment_base AS (
  SELECT
    r.customer_id,
    CASE
      WHEN r.r_score >= 4 AND r.f_score >= 4 AND r.m_score >= 4 THEN 'Champions'
      WHEN r.r_score >= 4 AND r.f_score >= 3 THEN 'Loyal'
      WHEN r.r_score >= 4 AND r.f_score <= 2 THEN 'New/Promising'
      WHEN r.r_score <= 2 AND r.f_score >= 3 THEN 'At Risk'
      WHEN r.r_score = 1 THEN 'Lost'
      ELSE 'Others'
    END AS rfm_segment_base
  FROM rfm_scored r
),

customer_metrics AS (
  SELECT
    aol.country,
    aol.customer_type,
    aol.customer_id,

    COUNT(*) AS orders,
    SUM(aol.is_cancel) AS canceled_orders,

    SUM(CASE WHEN aol.is_cancel = 1 THEN -aol.invoice_amount ELSE 0 END) AS canceled_revenue,

    CASE WHEN SUM(aol.is_cancel) > 0 THEN 1 ELSE 0 END AS customer_has_cancel
  FROM all_orders_labeled aol
  WHERE aol.customer_type IN ('New','Returning','Pre-first-purchase cancel')
  GROUP BY aol.country, aol.customer_type, aol.customer_id
),

customer_metrics_with_seg AS (
  SELECT
    cm.*,
    CASE
      WHEN cm.customer_type = 'Cancel-only' THEN 'Cancel-only'
      WHEN cm.customer_type = 'Pre-first-purchase cancel'
        THEN CONCAT('Pre-first: ', COALESCE(rs.rfm_segment_base, 'Others'))
      ELSE COALESCE(rs.rfm_segment_base, 'Others')
    END AS rfm_segment
  FROM customer_metrics cm
  LEFT JOIN rfm_segment_base rs
    ON rs.customer_id = cm.customer_id
)

SELECT
  country,
  customer_type,
  rfm_segment,
  COUNT(DISTINCT customer_id) AS customers,
  SUM(orders) AS total_orders,
  SUM(canceled_orders) AS cancel_orders,
  1.0 * SUM(canceled_orders) / NULLIF(SUM(orders), 0) AS cancel_order_rate,
  SUM(canceled_revenue) AS canceled_revenue_total
FROM customer_metrics_with_seg
GROUP BY country, customer_type, rfm_segment
ORDER BY
  FIELD(customer_type, 'New','Returning','Pre-first-purchase cancel','Cancel-only'),
  country,
  rfm_segment;
