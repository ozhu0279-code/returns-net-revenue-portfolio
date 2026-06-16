WITH order_sales AS (
    SELECT
        MONTH(invoice_date) AS month,
        invoice_no,
        SUM(quantity * unit_price) AS order_amount
    FROM online_retail
    WHERE quantity > 0
      AND unit_price > 0
      and stock_code NOT IN ('Test001','Test002','S','PADS','Post','M',
    'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
    'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
    'Gift_0001_10','Gift','DOT','D',
    'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
    'ADJUST2','ADJUST')
    GROUP BY MONTH(invoice_date), invoice_no
)

SELECT
    month,
    AVG(order_amount) AS avg_order_value
FROM order_sales
GROUP BY month
ORDER BY month;
