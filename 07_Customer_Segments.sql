-- New VS. Returning Segments
WITH first_purchase_bucket AS (
  SELECT 
    customer_id,
    MIN(invoice_date) AS first_purchase_date
  FROM online_retail
  WHERE customer_id IS NOT NULL  
    AND quantity > 0 
    AND unit_price > 0           
    AND stock_code NOT IN (
      'Test001','Test002','S','PADS','Post','M',
      'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
      'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
      'Gift_0001_10','Gift','DOT','D',
      'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
      'ADJUST2','ADJUST'
    )
  GROUP BY customer_id
),

enriched_transactions AS (
  SELECT 
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
    / NULLIF(SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN line_amount ELSE 0 END), 0) AS canceled_revenue_share
  
FROM enriched_transactions
WHERE customer_type IN ('New', 'Returning', 'Pre_first_purchase_cancel') 
GROUP BY customer_type
ORDER BY field(customer_type, 'New', 'Returning', 'Pre_first_purchase_cancel'); 

--------------------------------------------------------------------------------------------------

--RFM Segments
WITH base_perf AS (
  SELECT 
    customer_id, country, invoice_no, invoice_date, quantity * unit_price AS line_amount
  FROM online_retail
  WHERE customer_id IS NOT NULL
    AND quantity > 0 AND unit_price > 0
    AND stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
),

customer_rfm_labels AS (
  SELECT 
    customer_id,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
      WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
      WHEN r_score >= 4 AND f_score <= 2 THEN 'New/Promising'
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
      WHEN r_score = 1 THEN 'Lost'
      ELSE 'Others'
    END AS rfm_segment
  FROM (
    SELECT 
      customer_id,
      NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(invoice_date) FROM base_perf), MAX(invoice_date)) DESC) AS r_score,
      NTILE(5) OVER (ORDER BY COUNT(DISTINCT invoice_no) ASC) AS f_score,
      NTILE(5) OVER (ORDER BY SUM(line_amount) ASC) AS m_score
    FROM base_perf
    GROUP BY customer_id
  ) t
),

all_transactions_summary AS (
  SELECT 
    customer_id,
    SUM(CASE WHEN quantity > 0 AND unit_price > 0 THEN quantity * unit_price ELSE 0 END) AS user_gross_revenue,
    SUM(CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 THEN ABS(quantity * unit_price) ELSE 0 END) AS user_canceled_revenue
  FROM online_retail
  WHERE customer_id IS NOT NULL
    AND stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
  GROUP BY customer_id
)

SELECT 
  f.rfm_segment,
  COUNT(f.customer_id) AS customer_count,
  ROUND(SUM(a.user_gross_revenue), 2) AS total_gross_revenue,
  ROUND(SUM(a.user_canceled_revenue), 2) AS total_canceled_revenue,
  ROUND(SUM(a.user_canceled_revenue) / NULLIF(COUNT(f.customer_id), 0), 2) AS avg_canceled_revenue_per_user,
  ROUND(1.0 * SUM(a.user_canceled_revenue) / NULLIF(SUM(a.user_gross_revenue), 0), 4) AS canceled_revenue_share
FROM customer_rfm_labels f
INNER JOIN all_transactions_summary a ON f.customer_id = a.customer_id
GROUP BY f.rfm_segment
ORDER BY FIELD(f.rfm_segment, 'Champions', 'Loyal', 'New/Promising', 'At Risk', 'Lost', 'Others');

-------------------------------------------------------------------------------------------------

--At Risk SKU (SKU Scatter × Price Band × RFM Segments)
WITH constant_thresholds AS (
  SELECT 541 AS p90_threshold, 0.0404 AS avg_cancel_rate
),

customer_rfm_scores AS (
  SELECT 
    customer_id,
    NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(invoice_date) FROM online_retail), MAX(invoice_date)) DESC) AS r_score,
    NTILE(5) OVER (ORDER BY COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) ASC) AS f_score
  FROM online_retail 
  WHERE customer_id IS NOT NULL 
    AND quantity > 0 AND unit_price > 0
  GROUP BY customer_id
),

customer_segments AS (
  SELECT *,
    CASE 
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
      ELSE 'Other' 
    END AS rfm_segment
  FROM customer_rfm_scores
),

sku_risk_analysis AS (
  SELECT 
    stock_code,
    AVG(unit_price) AS avg_sku_price, 
    COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) AS gross_orders,
    COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' THEN invoice_no END) AS canceled_orders,
    1.0 * COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' THEN invoice_no END)
      / NULLIF(COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END), 0) AS cancel_rate
  FROM online_retail
  WHERE stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
  GROUP BY stock_code
)

SELECT 
  cs.rfm_segment,
  CASE
    WHEN s.avg_sku_price < 1 THEN '<1'
    WHEN s.avg_sku_price < 5 THEN '1-4.99'
    WHEN s.avg_sku_price < 10 THEN '5-9.99'
    WHEN s.avg_sku_price < 20 THEN '10-19.99'
    WHEN s.avg_sku_price < 50 THEN '20-49.99'
    WHEN s.avg_sku_price < 100 THEN '50-99.99'
    ELSE '100+'
  END AS price_band,
  s.stock_code,
  s.gross_orders,
  s.canceled_orders,
  ROUND(s.cancel_rate * 100, 2) AS cancel_rate_pct,
  SUM(ABS(r.quantity * r.unit_price)) AS at_risk_canceled_revenue
FROM sku_risk_analysis s
CROSS JOIN constant_thresholds ct
INNER JOIN online_retail r ON s.stock_code = r.stock_code
INNER JOIN customer_segments cs ON r.customer_id = cs.customer_id
WHERE r.invoice_no LIKE 'C%' 
  AND r.quantity < 0
  AND s.gross_orders > ct.p90_threshold 
  AND s.cancel_rate > ct.avg_cancel_rate
  AND cs.rfm_segment <> 'Other' 
GROUP BY 1, 2, 3, 6
ORDER BY 1, 2 DESC, 7 DESC;
