WITH base AS (
  SELECT
    stock_code,
    invoice_no,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),

inv AS (
  SELECT
    invoice_no,
    stock_code,
    SUM(line_amount) AS invoice_amount
  FROM base
  GROUP BY invoice_no, stock_code
),

gross_r AS (
  SELECT
    SUM(invoice_amount) AS gross_revenue
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND UPPER(TRIM(invoice_no)) NOT LIKE 'A%'
    AND invoice_amount > 0
),
canceled_r AS (
  SELECT
    SUM(ABS(invoice_amount)) AS canceled_revenue
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
),

cancel_inv AS (
  SELECT DISTINCT invoice_no
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
),

tagged_lines AS (
  SELECT
    invoice_no,
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
    CASE
      WHEN stock_code IN (
        'AMAZONFEE','B','BANK CHARGES','C2','CRUK','DCGS0003','DCGS0004','DCGS0055','DCGS0057','DCGS0066P',
        'DCGS0067','DCGS0068','DCGS0069','DCGS0070','DCGS0071','DCGS0072','DCGS0073','DCGS0074','DCGS0076',
        'DCGSSBOY','DCGSSGIRL','DOT','gift_0001_10','gift_0001_20','gift_0001_30','gift_0001_40','gift_0001_50',
        'M','PADS','POST','S'
      ) THEN 'Non-product'
      ELSE 'Product'
    END AS sku_type
   FROM base
),

band_orders AS (
  SELECT
    tl.price_band,
    tl.invoice_no,
    tl.sku_type,
    CASE
      WHEN tl.invoice_no LIKE 'C%'
       AND tl.invoice_no IN (SELECT invoice_no FROM cancel_inv)
      THEN 1 ELSE 0
    END AS is_cancel
  FROM tagged_lines tl
  GROUP BY tl.price_band, tl.invoice_no, tl.sku_type
)

SELECT
  price_band,
  sku_type,
  COUNT(*) AS total_orders,
  SUM(is_cancel) AS cancel_orders,
  1.0 * SUM(is_cancel) / NULLIF(COUNT(*), 0) AS cancel_order_rate,
  MAX(gr.gross_revenue) AS gross_revenue,
  MAX(cr.canceled_revenue) AS canceled_revenue,
  1.0 * MAX(cr.canceled_revenue) / NULLIF(MAX(gr.gross_revenue), 0) AS cancel_revenue_rate
FROM band_orders
CROSS JOIN gross_r gr
CROSS JOIN canceled_r cr
GROUP BY price_band, sku_type
ORDER BY
  CASE price_band
    WHEN '<1' THEN 1
    WHEN '1-4.99' THEN 2
    WHEN '5-9.99' THEN 3
    WHEN '10-19.99' THEN 4
    WHEN '20-49.99' THEN 5
    WHEN '50-99.99' THEN 6
    ELSE 7
  END;
