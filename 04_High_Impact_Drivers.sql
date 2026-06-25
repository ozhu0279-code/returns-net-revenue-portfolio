--Top10 skus and countries by canceled revenue per month
WITH base AS (
  SELECT
    invoice_no,
    stock_code,
    country,
    quantity * unit_price AS line_amount,
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    CASE WHEN stock_code IN ('Test001','Test002','S','PADS','Post','M',
        'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
        'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
        'Gift_0001_10','Gift','DOT','D',
        'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
        'ADJUST2','ADJUST'
      )  THEN 'Non-Product'
      ELSE 'Product' 
    END AS product_type
  FROM online_retail
  WHERE invoice_no LIKE 'C%' 
  AND quantity < 0
  AND invoice_date >= '2010-01-01'
),
sku_rank AS (
  SELECT 
    month,
    'SKU' AS driver_type,
    stock_code AS driver_name,
    SUM(ABS(line_amount)) AS canceled_revenue,
    ROW_NUMBER() OVER(PARTITION BY month ORDER BY SUM(ABS(line_amount)) DESC) AS ranking
  FROM base
  WHERE product_type = 'Product'
  GROUP BY month, stock_code
),
country_rank AS (
  SELECT 
    month,
    'Country' AS driver_type,
    country AS driver_name,
    SUM(ABS(line_amount)) AS canceled_revenue,
    ROW_NUMBER() OVER(PARTITION BY month ORDER BY SUM(ABS(line_amount)) DESC) AS ranking
  FROM base
  WHERE product_type = 'Product'
  GROUP BY month, country
)
SELECT * FROM sku_rank WHERE ranking <= 10
UNION ALL
SELECT * FROM country_rank WHERE ranking <= 10
ORDER BY month DESC, driver_type ASC, ranking ASC;
