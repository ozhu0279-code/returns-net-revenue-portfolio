--SKU Scatter
WITH base AS (
  SELECT 
    invoice_no,
    stock_code,
    quantity,
    unit_price,
    quantity * unit_price AS line_amount,
    CASE 
      WHEN stock_code IN (
        'Test001','Test002','S','PADS','Post','M',
        'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
        'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
        'Gift_0001_10','Gift','DOT','D',
        'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
        'ADJUST2','ADJUST'
      ) THEN 'Non-Product'
      ELSE 'Product'
    END AS product_type
  FROM online_retail
  WHERE invoice_date >= '2010-01-01'
),
orders_summary AS (
SELECT 
  stock_code,
  COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 
                      THEN invoice_no END) AS total_orders,
  COUNT(DISTINCT CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 
                      THEN invoice_no END) AS canceled_orders,
  SUM(CASE WHEN quantity < 0 AND invoice_no LIKE 'C%'
             THEN ABS(line_amount) ELSE 0 END) AS canceled_revenue
FROM base
WHERE product_type = 'Product'
GROUP BY stock_code
)
SELECT 
  stock_code,
  total_orders,
  canceled_orders,
  canceled_revenue,
  1.0 * canceled_orders / NULLIF(total_orders, 0) AS cancel_rate
FROM orders_summary
GROUP BY stock_code
HAVING total_orders > 0 AND cancel_rate <= 1.0
ORDER BY total_orders DESC;

-------------------------------------------------------------------------------------------

--SKU Scatter x Price Band 
WITH base AS (
  SELECT 
    invoice_no,
    stock_code,
    quantity,
    unit_price,
    quantity * unit_price AS line_amount,
    CASE 
      WHEN stock_code IN (
        'Test001','Test002','S','PADS','Post','M',
        'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
        'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
        'Gift_0001_10','Gift','DOT','D',
        'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
        'ADJUST2','ADJUST'
      ) THEN 'Non-Product'
      ELSE 'Product'
    END AS product_type
  FROM online_retail
  WHERE invoice_date >= '2010-01-01'
),
orders_summary AS (
  SELECT 
    stock_code,
    CASE
      WHEN unit_price < 1 THEN '<1'
      WHEN unit_price < 5 THEN '1-4.99'
      WHEN unit_price < 10 THEN '5-9.99'
      WHEN unit_price < 20 THEN '10-19.99'
      WHEN unit_price < 50 THEN '20-49.99'
      WHEN unit_price < 100 THEN '50-99.99'
      ELSE '100+'
    END AS price_band,
    COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 
                        THEN invoice_no END) AS total_orders,
    COUNT(DISTINCT CASE WHEN invoice_no LIKE 'C%' AND quantity < 0 
                        THEN invoice_no END) AS canceled_orders,
    SUM(CASE WHEN quantity < 0 AND invoice_no LIKE 'C%'
             THEN ABS(line_amount) ELSE 0 END) AS canceled_revenue,
    SUM(CASE 
          WHEN quantity > 0 AND unit_price > 0 
          THEN line_amount ELSE 0 
        END) AS gross_revenue
  FROM base
  WHERE product_type = 'Product'
  GROUP BY stock_code, 
           CASE
             WHEN unit_price < 1 THEN '<1'
             WHEN unit_price < 5 THEN '1-4.99'
             WHEN unit_price < 10 THEN '5-9.99'
             WHEN unit_price < 20 THEN '10-19.99'
             WHEN unit_price < 50 THEN '20-49.99'
             WHEN unit_price < 100 THEN '50-99.99'
             ELSE '100+'
           END
)
SELECT 
  stock_code,
  TRIM(BOTH ' ' FROM REPLACE(REPLACE(REPLACE(price_band, '\n', ''), '\r', ''), '\t', '')) AS cleaned_price_band,
  total_orders,
  canceled_orders,
  canceled_revenue,
  gross_revenue,
  1.0 * canceled_orders / NULLIF(total_orders, 0) AS cancel_rate,
  1.0 * canceled_revenue / NULLIF(gross_revenue, 0) AS canceled_revenue_share
FROM orders_summary
ORDER BY stock_code, cleaned_price_band;
