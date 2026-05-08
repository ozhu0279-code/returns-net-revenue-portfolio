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
      WHEN stock_code IN (
        'AMAZONFEE','B','BANK CHARGES','C2','CRUK','DCGS0003','DCGS0004','DCGS0055','DCGS0057','DCGS0066P',
        'DCGS0067','DCGS0068','DCGS0069','DCGS0070','DCGS0071','DCGS0072','DCGS0073','DCGS0074','DCGS0076',
        'DCGSSBOY','DCGSSGIRL','DOT','gift_0001_10','gift_0001_20','gift_0001_30','gift_0001_40','gift_0001_50',
        'M','PADS','POST','S'
      ) THEN 'Non-product'
      ELSE 'Product'
    END AS sku_type
  FROM cleaned_final
),
  
metrics_step AS (
  SELECT
    price_band,
    sku_type,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(invoice_no)) LIKE 'C%' THEN invoice_no END) AS cancel_orders,
    SUM(CASE 
          WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND UPPER(TRIM(invoice_no)) NOT LIKE 'A%' AND line_amount > 0 
          THEN line_amount ELSE 0 
        END) AS band_gross_revenue,
    SUM(CASE 
          WHEN UPPER(TRIM(invoice_no)) LIKE 'C%' AND line_amount < 0 
          THEN ABS(line_amount) ELSE 0 
        END) AS band_canceled_revenue
  FROM base
  GROUP BY price_band, sku_type
)

SELECT
  price_band,
  sku_type,
  total_orders,
  cancel_orders,
  1.0 * cancel_orders / NULLIF(total_orders, 0) AS cancel_rate,
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




  
