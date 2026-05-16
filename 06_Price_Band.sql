WITH base AS (
  SELECT
    invoice_no,
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    quantity,
    unit_price,
    quantity * unit_price AS line_amount,
    CASE 
      WHEN stock_code IN ('Test001','Test002','S','PADS','Post','M',
        'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
        'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
        'Gift_0001_10','Gift','DOT','D',
        'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
        'ADJUST2','ADJUST'
      ) THEN 'Non-Product'
      ELSE 'Product'
    END AS product_type
  FROM online_retail
),
monthly_metrics AS (
  SELECT
    month,
    SUM(CASE WHEN quantity > 0 AND unit_price > 0 AND product_type = 'Product' 
             THEN line_amount ELSE 0 END) AS gross_revenue,
    SUM(CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' AND product_type = 'Product' 
             THEN ABS(line_amount) ELSE 0 END) AS canceled_revenue,
    COUNT(DISTINCT CASE WHEN product_type = 'Product' THEN invoice_no END) AS total_orders,
    COUNT(DISTINCT CASE WHEN quantity < 0 AND invoice_no LIKE 'C%' AND product_type = 'Product' 
                        THEN invoice_no END) AS canceled_orders
  FROM base
  GROUP BY month
)
SELECT
  month,
  gross_revenue,
  canceled_revenue,
  total_orders,
  canceled_orders,
  canceled_revenue / NULLIF(gross_revenue, 0) AS canceled_revenue_share,
  canceled_orders * 1.0 / NULLIF(total_orders, 0) AS cancel_rate
FROM monthly_metrics
ORDER BY month;




  
