WITH base AS (
  SELECT
    stock_code,
    invoice_no,
    DATE(invoice_date) AS dt,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),

cancel_inv AS (
  SELECT
    invoice_no
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
),

sku_orders AS (
  SELECT
    stock_code,
    COUNT(DISTINCT CASE
      WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' THEN invoice_no
    END) AS non_cancel_orders,

    COUNT(DISTINCT CASE
      WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
       AND invoice_no IN (SELECT invoice_no FROM cancel_inv)
      THEN invoice_no
    END) AS cancel_orders,

    SUM(CASE
          WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
           AND invoice_no IN (SELECT invoice_no FROM cancel_inv)
           AND line_amount < 0
          THEN ABS(line_amount)
          ELSE 0
        END) AS canceled_revenue
  FROM base
  GROUP BY stock_code
)

SELECT
  stock_code,
  (non_cancel_orders + cancel_orders) AS total_orders,
  cancel_orders,
  non_cancel_orders,
  1.0 * cancel_orders / NULLIF(non_cancel_orders + cancel_orders, 0) AS cancel_order_rate,
  canceled_revenue
FROM sku_orders
WHERE (non_cancel_orders + cancel_orders) >= 20
ORDER BY cancel_order_rate DESC, canceled_revenue DESC;

