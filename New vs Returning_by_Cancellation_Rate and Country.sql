WITH base AS (
  SELECT
    customer_id,
    country,
    invoice_no,
    DATE(invoice_date) AS dt,
    unit_price * quantity AS line_amount
  FROM cleaned_final
  WHERE customer_id IS NOT NULL
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
  SELECT customer_id, invoice_no, dt
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
),
orders_scope AS (
  SELECT
    i.customer_id,
    i.invoice_no,
    i.dt,
    i.country,
    fp.first_purchase_date,
    CASE WHEN vc.invoice_no IS NOT NULL THEN 1 ELSE 0 END AS is_cancel
  FROM inv i
  JOIN first_purchase fp ON fp.customer_id = i.customer_id
  LEFT JOIN valid_cancel vc ON vc.invoice_no = i.invoice_no
  WHERE
   (UPPER(TRIM(i.invoice_no)) NOT LIKE 'C%' AND i.invoice_amount > 0)
    OR (vc.invoice_no IS NOT NULL)
)
SELECT
    country,
  CASE
    WHEN is_cancel = 1 AND dt < first_purchase_date THEN 'Pre-first-purchase cancel'
    WHEN dt = first_purchase_date THEN 'New'
    WHEN dt > first_purchase_date THEN 'Returning'
    ELSE 'Other'
  END AS customer_type,
  COUNT(*) AS total_orders,
  SUM(is_cancel) AS cancel_orders,
  1.0 * SUM(is_cancel) / NULLIF(COUNT(*), 0) AS cancel_order_rate
FROM orders_scope
GROUP BY customer_type, country
ORDER BY FIELD(customer_type, 'New', 'Returning', 'Pre-first-purchase cancel', 'Other'), country;





