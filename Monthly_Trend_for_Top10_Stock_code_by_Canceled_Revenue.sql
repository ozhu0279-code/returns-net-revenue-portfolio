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
sku_month AS (
  SELECT
    stock_code,
    DATE_FORMAT(dt, '%Y-%m') AS month,

    SUM(CASE
          WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND line_amount > 0
          THEN line_amount ELSE 0
        END) AS gross_revenue,

    SUM(CASE
          WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
           AND invoice_no IN (SELECT invoice_no FROM cancel_inv)
           AND line_amount < 0
          THEN ABS(line_amount) ELSE 0
        END) AS canceled_revenue
  FROM base
  GROUP BY stock_code, DATE_FORMAT(dt, '%Y-%m')
)
SELECT
  month,
  gross_revenue,
  canceled_revenue
FROM sku_month
WHERE stock_code = 'SKU'   -- TODO: Changing into any top10 stock_code you wanna drill-down 
ORDER BY month;


