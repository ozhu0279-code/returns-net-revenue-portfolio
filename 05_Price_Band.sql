WITH base AS (
  SELECT
    invoice_no,
    stock_code,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount,
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
  
metrics_step AS (
  SELECT
   TRIM(BOTH ' ' FROM REPLACE(REPLACE(REPLACE(price_band, '\n', ''), '\r', ''), '\t', '')) AS cleaned_price_band,
    SUM(CASE 
        WHEN quantity > 0 AND unit_price > 0 
        THEN line_amount ELSE 0 
      END) AS band_gross_revenue,
      
    SUM(CASE 
        WHEN quantity < 0 AND invoice_no LIKE 'C%' 
        THEN ABS(line_amount) ELSE 0 
      END) AS band_canceled_revenue,
    COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 
          THEN invoice_no END) AS total_orders
  FROM base
  WHERE product_type = 'Product' 
  GROUP BY cleaned_price_band        
)

SELECT
  cleaned_price_band AS price_band,
  total_orders,
  band_gross_revenue,
  band_canceled_revenue,
  1.0 * band_canceled_revenue / NULLIF(band_gross_revenue, 0) AS canceled_revenue_share
FROM metrics_step
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




  
