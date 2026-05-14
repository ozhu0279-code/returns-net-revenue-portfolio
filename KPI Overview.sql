--Gross/Canceled/Net revenue (including non-product data)
WITH base AS (
  SELECT
    invoice_no,
    quantity,
    unit_price,
    stock_code, 
    quantity * unit_price AS line_amount 
  FROM online_retail
),
gross_r AS (
  SELECT
    SUM(line_amount) AS gross_revenue
  FROM base
  WHERE quantity > 0 
    AND unit_price > 0 
),
canceled_r AS (
  SELECT
    SUM(ABS(line_amount)) AS canceled_revenue
  FROM base
  WHERE quantity < 0 
    AND invoice_no LIKE 'C%'
)
SELECT
  gr.gross_revenue,
  cr.canceled_revenue,
  COALESCE(gr.gross_revenue, 0) - COALESCE(cr.canceled_revenue, 0) AS net_revenue
FROM gross_r gr, canceled_r cr;


--Gross/Canceled/Net revenue (only product data)
WITH base AS (
  SELECT
    invoice_no,
    quantity,
    unit_price,
    stock_code, 
    quantity * unit_price AS line_amount,
  CASE 
    WHEN stock_code IN (
    'Test001','Test002','S','PADS','Post','M',
    'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
    'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
    'Gift_0001_10','Gift','DOT','D',
    'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
    'ADJUST2','ADJUST'
    ) THEN 'Non-product'
    ELSE 'Product'
  END AS product_type
 FROM online_retail
),
gross_r AS (
  SELECT
    SUM(line_amount) AS gross_revenue
  FROM base
  WHERE quantity > 0 
    AND unit_price > 0 
    AND product_type = 'Product'
),
canceled_r AS (
  SELECT
    SUM(ABS(line_amount)) AS canceled_revenue
  FROM base
  WHERE quantity < 0 
    AND invoice_no LIKE 'C%'
    AND product_type = 'Product'
)
SELECT
  gr.gross_revenue,
  cr.canceled_revenue,
  COALESCE(gr.gross_revenue, 0) - COALESCE(cr.canceled_revenue, 0) AS net_revenue
FROM gross_r gr, canceled_r cr;


--Cancel Rate (only product data)
WITH base AS (
  SELECT 
    invoice_no,
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
),
product_orders AS (
  SELECT DISTINCT invoice_no
  FROM base
  WHERE product_type = 'Product'
)
SELECT 
  COUNT(invoice_no) AS total_orders,
  COUNT(CASE WHEN invoice_no LIKE 'C%' THEN 1 END) AS canceled_orders,
  COUNT(CASE WHEN invoice_no LIKE 'C%' THEN 1 END) * 1.0 / NULLIF(COUNT(invoice_no), 0) AS cancel_rate
FROM product_orders;


--Canceled Revenue Share (only product data)
WITH base AS (
  SELECT
    invoice_no,
    quantity,
    unit_price,
    stock_code, 
    quantity * unit_price AS line_amount,
  CASE 
    WHEN stock_code IN (
    'Test001','Test002','S','PADS','Post','M',
    'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
    'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
    'Gift_0001_10','Gift','DOT','D',
    'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
    'ADJUST2','ADJUST'
    ) THEN 'Non-product'
    ELSE 'Product'
  END AS product_type
 FROM online_retail
),
gross_r AS (
  SELECT
    SUM(line_amount) AS gross_revenue
  FROM base
  WHERE quantity > 0 
    AND unit_price > 0 
    AND product_type = 'Product'
),
canceled_r AS (
  SELECT
    SUM(ABS(line_amount)) AS canceled_revenue
  FROM base
  WHERE quantity < 0 
    AND invoice_no LIKE 'C%'
    AND product_type = 'Product'
)
SELECT
  gr.gross_revenue,
  cr.canceled_revenue,
  COALESCE(cr.canceled_revenue, 0) / COALESCE(gr.gross_revenue, 0) AS canceled_revenue_share
FROM gross_r gr, canceled_r cr;
