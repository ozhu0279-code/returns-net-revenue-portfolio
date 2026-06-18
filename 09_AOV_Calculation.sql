WITH monthly_raw_data AS (
    SELECT 
      DATE_FORMAT(invoice_date, '%Y-%m') AS invoice_month,
        invoice_no,
        quantity,
        unit_price,
        quantity * unit_price AS line_amount
    FROM online_retail
    WHERE quantity > 0
      AND unit_price > 0
      AND invoice_date >= '2010-01-01'
      AND stock_code NOT IN (
          'Test001','Test002','S','PADS','Post','M',
          'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
          'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
          'Gift_0001_10','Gift','DOT','D','CRUK','C2','C3',
          'BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST'
      )
),

monthly_metrics AS (
    SELECT
        invoice_month,
        COUNT(DISTINCT invoice_no) AS total_orders,
        SUM(line_amount) AS total_revenue,
        SUM(quantity) AS total_quantity,
        AVG(unit_price) AS avg_unit_price,
        SUM(line_amount) / SUM(quantity) AS weighted_avg_sku_price
    FROM monthly_raw_data
    GROUP BY invoice_month
)

SELECT
    invoice_month AS month,
    total_orders,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(total_revenue / total_orders, 2) AS aov,
    total_quantity,
    ROUND(avg_unit_price, 2) AS sql_avg_price,
    ROUND(weighted_avg_sku_price, 2) AS customer_paid_price
FROM monthly_metrics
ORDER BY invoice_month;
