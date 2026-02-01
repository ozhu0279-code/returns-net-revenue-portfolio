WITH base AS (
  SELECT
    invoice_no,
    invoice_date,
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),

rate_m AS (
  SELECT
    month,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT CASE
      WHEN quantity < 0 AND UPPER(TRIM(invoice_no)) LIKE 'C%' THEN invoice_no
    END) AS cancelled_orders,
    1.0 * COUNT(DISTINCT CASE
      WHEN quantity < 0 AND UPPER(TRIM(invoice_no)) LIKE 'C%' THEN invoice_no
    END) / NULLIF(COUNT(DISTINCT invoice_no), 0) AS cancellation_rate
  FROM base
  GROUP BY month
),

inv AS (
  SELECT
    invoice_no,
    month,
    SUM(line_amount) AS invoice_amount
  FROM base
  GROUP BY invoice_no, month
),

gross_m AS (
  SELECT
    month,
    SUM(line_amount) AS gross_revenue
  FROM base
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND UPPER(TRIM(invoice_no)) NOT LIKE 'A%'
    AND line_amount > 0
  GROUP BY month
),

cancel_m AS (
  SELECT
    month,
    SUM(ABS(invoice_amount)) AS canceled_revenue
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
  GROUP BY month
)

SELECT
  r.month,
  r.total_orders,
  r.cancelled_orders,
  r.cancellation_rate,
  COALESCE(g.gross_revenue, 0) AS gross_revenue,
  COALESCE(c.canceled_revenue, 0) AS canceled_revenue,
  COALESCE(g.gross_revenue, 0) - COALESCE(c.canceled_revenue, 0) AS net_revenue,
  1.0 * COALESCE(c.canceled_revenue, 0) / NULLIF(COALESCE(g.gross_revenue, 0), 0) AS canceled_revenue_share
FROM rate_m r
LEFT JOIN gross_m g ON g.month = r.month
LEFT JOIN cancel_m c ON c.month = r.month
ORDER BY r.month;
