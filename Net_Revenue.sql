WITH base AS (
  SELECT
    invoice_no,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),
inv AS (
  SELECT
    invoice_no,
    SUM(line_amount) AS invoice_amount
  FROM base
  GROUP BY invoice_no
),
gross_r AS (
  SELECT
    SUM(invoice_amount) AS gross_revenue
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND UPPER(TRIM(invoice_no)) NOT LIKE 'A%'
    AND invoice_amount > 0
),
canceled_r AS (
  SELECT
    SUM(ABS(invoice_amount)) AS canceled_revenue
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
)
SELECT
  gr.gross_revenue,
  cr.canceled_revenue,
  gr.gross_revenue - cr.canceled_revenue AS net_revenue
FROM gross_r gr, canceled_r cr;
