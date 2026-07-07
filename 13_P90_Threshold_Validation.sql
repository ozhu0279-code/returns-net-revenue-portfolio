---Finding the suitable p90 threshold
WITH at_risk_customers AS (
  SELECT customer_id FROM (
    SELECT 
      customer_id,
      NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(invoice_date) FROM online_retail WHERE invoice_date >= '2010-01-01'), MAX(invoice_date)) DESC) AS r_score,
      NTILE(5) OVER (ORDER BY COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) ASC) AS f_score
    FROM online_retail 
    WHERE customer_id IS NOT NULL 
      AND invoice_date >= '2010-01-01' 
    GROUP BY customer_id
  ) t 
  WHERE r_score <= 2 AND f_score >= 3
),

sku_order_counts AS (
  SELECT 
    stock_code, 
    COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) as cnt
  FROM online_retail r
  INNER JOIN at_risk_customers arc ON r.customer_id = arc.customer_id
  WHERE r.invoice_date >= '2010-01-01' 
  GROUP BY stock_code
),

decile_calc AS (
  SELECT 
    stock_code,
    cnt,
    NTILE(10) OVER (ORDER BY cnt ASC) as decile
  FROM sku_order_counts
)

SELECT 
  decile,
  MIN(cnt) as min_orders,
  MAX(cnt) as max_orders
FROM decile_calc
GROUP BY decile
ORDER BY decile DESC;
