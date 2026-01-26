/*
Cancellation Rate per Month.
*/
SELECT 
  DATE_FORMAT(invoice_date, '%Y-%m') AS month,
  COUNT(DISTINCT invoice_no) AS total_orders,
  COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' THEN invoice_no END) AS cancelled_orders,
  COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' THEN invoice_no END)
    / NULLIF (COUNT(DISTINCT invoice_no),0) AS cancellation_rate
FROM cleaned_final
GROUP BY month
ORDER BY month;
