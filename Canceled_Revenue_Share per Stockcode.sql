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
    invoice_no,
    SUM(line_amount) AS inv_amount
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
),
sku_agg AS (
  SELECT
    b.stock_code,
    COUNT(DISTINCT CASE
      WHEN UPPER(TRIM(b.invoice_no)) NOT LIKE 'C%' AND b.line_amount > 0 THEN b.invoice_no
    END) AS order_cnt,
    SUM(CASE
          WHEN UPPER(TRIM(b.invoice_no)) NOT LIKE 'C%' AND b.line_amount > 0
          THEN b.line_amount ELSE 0
        END) AS gross_revenue,
    SUM(CASE
          WHEN UPPER(TRIM(b.invoice_no)) LIKE 'C%'
           AND b.invoice_no IN (SELECT invoice_no FROM cancel_inv)
           AND b.line_amount < 0
          THEN ABS(b.line_amount) ELSE 0
        END) AS canceled_revenue
  FROM base b
  GROUP BY b.stock_code
)
SELECT
  stock_code,
  order_cnt,
  gross_revenue,
  canceled_revenue,
  1.0 * canceled_revenue / NULLIF(gross_revenue, 0) AS cancel_revenue_share
FROM sku_agg
WHERE gross_revenue >= 100
ORDER BY cancel_revenue_share DESC;

