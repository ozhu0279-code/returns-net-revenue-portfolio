WITH filtered_retail AS (
    SELECT 
        DATE_FORMAT(STR_TO_DATE(invoice_date, '%Y/%m/%d %H:%i'), '%Y-%m') AS invoice_month,
        invoice_no,
        customer_id,
        stock_code,
        quantity,
        unit_price,
        quantity * unit_price AS line_amount
    FROM online_retail
    WHERE STR_TO_DATE(invoice_date, '%Y/%m/%d %H:%i') >= '2010-08-01'
      AND quantity > 0
      AND unit_price > 0
      AND stock_code NOT IN ('Test001','Test002','S','PADS','Post','M','Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60','Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20','Gift_0001_10','Gift','DOT','D','CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST')
),

order_level_summary AS (
    SELECT 
        invoice_month,
        invoice_no,
        customer_id,
        COUNT(DISTINCT stock_code) AS unique_skus,
        SUM(quantity) AS total_items,
        SUM(line_amount) AS order_amount
    FROM filtered_retail
    GROUP BY invoice_month, invoice_no, customer_id
),

ranked_orders AS (
    SELECT 
        invoice_month,
        invoice_no,
        customer_id,
        unique_skus,
        total_items,
        ROUND(order_amount, 2) AS order_amount,
        ROW_NUMBER() OVER (PARTITION BY invoice_month ORDER BY order_amount DESC) AS order_rank
    FROM order_level_summary
)

SELECT * 
FROM ranked_orders
WHERE order_rank <= 5 
ORDER BY invoice_month ASC, order_rank ASC;
