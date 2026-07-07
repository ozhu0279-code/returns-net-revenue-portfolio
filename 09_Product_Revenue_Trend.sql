--SKU:71477,21843,22138,22423,85123A
  WITH base AS (
  SELECT
    invoice_no,
    quantity,
    unit_price,
    quantity * unit_price AS line_amount,
   DATE_FORMAT(invoice_date,'%Y-%m') AS invoice_month
  FROM online_retail
WHERE stock_code ='SKU' -------------------Filling in specific stock code
  AND DATE_FORMAT(invoice_date,'%Y-%m') >= '2010-01'
),
revenue AS (
  SELECT
    invoice_month,
    SUM(CASE 
        WHEN quantity > 0 AND unit_price > 0  
        THEN line_amount ELSE 0 
      END) AS gross_revenue,

    SUM(CASE 
        WHEN quantity < 0 AND invoice_no LIKE 'C%' 
        THEN ABS(line_amount) ELSE 0 
      END) AS canceled_revenue
 FROM base
 GROUP BY invoice_month
)
SELECT
  invoice_month AS month,
  r.gross_revenue AS gross_revenue,
  r.canceled_revenue AS canceled_revenue,
  (gross_revenue - canceled_revenue) AS net_revenue
FROM revenue r
ORDER BY month;


