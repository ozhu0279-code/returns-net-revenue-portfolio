WITH inv AS (
  SELECT
    invoice_no,
    SUM(unit_price * quantity) AS invoice_amount
  FROM cleaned_final
  GROUP BY invoice_no
)
SELECT
  (SELECT COUNT(DISTINCT invoice_no) FROM cleaned_final) AS total_orders,
  COUNT(*) AS cancelled_orders,
  1.0 * COUNT(*) / NULLIF((SELECT COUNT(DISTINCT invoice_no) FROM cleaned_final), 0) AS cancellation_rate
FROM inv
WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  AND invoice_amount < 0;
