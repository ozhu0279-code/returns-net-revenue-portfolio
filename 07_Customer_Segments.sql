-- New VS. Returning(customer type comparison)
WITH first_purchase_bucket AS (
  SELECT 
    customer_id,
    MIN(invoice_date) AS first_purchase_date
  FROM online_retail
  WHERE customer_id IS NOT NULL  
    AND quantity > 0 
    AND unit_price > 0           
    AND stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
  GROUP BY customer_id
),

enriched_transactions AS (
  SELECT 
    r.country,
    r.invoice_no,
    r.quantity,
    r.unit_price,
    r.quantity * r.unit_price AS line_amount,
    CASE 
      WHEN r.invoice_date < f.first_purchase_date THEN 'Pre_first_purchase_cancel'
      WHEN f.first_purchase_date = r.invoice_date THEN 'New'
      WHEN f.first_purchase_date < r.invoice_date THEN 'Returning'
      ELSE 'Other' 
    END AS customer_type
  FROM online_retail r
  INNER JOIN first_purchase_bucket f ON r.customer_id = f.customer_id
  WHERE r.stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
)

SELECT 
  country,
  customer_type,
  COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) AS total_orders,
  COUNT(DISTINCT CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN invoice_no END) AS canceled_orders,
  
  SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN line_amount ELSE 0 END) AS gross_revenue,
  SUM(CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN ABS(line_amount) ELSE 0 END) AS canceled_revenue,
  
  SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN line_amount ELSE 0 END) - 
  SUM(CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN ABS(line_amount) ELSE 0 END) AS net_revenue,

  1.0 * COUNT(DISTINCT CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN invoice_no END)
    / NULLIF(COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END), 0) AS cancel_rate,
    
  1.0 * SUM(CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN ABS(line_amount) ELSE 0 END)
    / NULLIF(SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN line_amount ELSE 0 END), 0) AS canceled_revenue_share,

  1.0 * SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN line_amount ELSE 0 END)
    / NULLIF(COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END), 0) AS avg_gross_revenue,

  1.0 * SUM(CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN ABS(line_amount) ELSE 0 END)
    / NULLIF(COUNT(DISTINCT CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN invoice_no END), 0) AS avg_canceled_revenue

FROM enriched_transactions
WHERE customer_type IN ('New', 'Returning', 'Pre_first_purchase_cancel') 
GROUP BY country, customer_type
ORDER BY country ASC, field(customer_type, 'New', 'Returning', 'Pre_first_purchase_cancel'); 


--



