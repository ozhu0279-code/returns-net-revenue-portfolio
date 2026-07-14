WITH base AS (
  SELECT
    invoice_no,
    DATE_FORMAT(invoice_date,'%Y-%m') AS invoice_month,
    stock_code,
    quantity,
    unit_price
  FROM online_retail
  WHERE stock_code IN ('22138', '22617')
    AND invoice_date >= '2010-01-01'
),

orders_summary AS (
  SELECT 
    stock_code,
    invoice_month,
    COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) AS total_orders,
    COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' THEN invoice_no END) AS canceled_orders
  FROM base
  GROUP BY stock_code, invoice_month
  )

  SELECT
    stock_code,
    invoice_month AS month,
    o.total_orders AS total_orders,
    o.canceled_orders AS canceled_orders,
    1.0 * canceled_orders / NULLIF(total_orders,0) AS cancel_rate
  FROM orders_summary o
  ORDER BY stock_code,month;
