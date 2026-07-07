WITH monthly_raw_data AS (
    SELECT 
        DATE_FORMAT(invoice_date, '%Y-%m') AS invoice_month,
        invoice_no,
        quantity,
        unit_price,
        quantity * unit_price AS line_amount
    FROM online_retail
    WHERE quantity > 0 AND unit_price > 0 
      AND DATE_FORMAT (invoice_date,'%Y-%M') >= '2010-08'
      AND stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
),
monthly_metrics AS (
    SELECT
        invoice_month,
        COUNT(DISTINCT invoice_no) AS total_orders,
        SUM(line_amount) AS total_revenue,
        SUM(quantity) AS total_quantity
    FROM monthly_raw_data
    GROUP BY invoice_month
),
monthly_indicators AS (
    SELECT
    invoice_month,
    total_orders,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(total_revenue / total_orders, 2) AS aov,
    ROUND(total_quantity / total_orders, 2) AS items_per_order,
    ROUND(total_revenue / total_quantity, 2) AS price_per_item
FROM monthly_metrics
),
metrics_lag AS (
    SELECT 
        invoice_month,
        total_orders,
        aov,
        items_per_order AS upo,
        price_per_item AS asp, 
        LAG(aov) OVER (ORDER BY invoice_month) AS prev_aov,
        LAG(items_per_order) OVER (ORDER BY invoice_month) AS prev_upo,
        LAG(price_per_item) OVER (ORDER BY invoice_month) AS prev_asp
    FROM monthly_indicators
)
SELECT 
    invoice_month AS month,
    total_orders,
    aov,
    upo,
    asp,
    (aov - prev_aov) / prev_aov AS aov_change_pct,
    (upo - prev_upo) / prev_upo AS upo_change_pct,
    (asp - prev_asp) / prev_asp AS asp_change_pct
FROM metrics_lag;
