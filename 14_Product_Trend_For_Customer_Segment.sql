WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND quantity > 0
      AND unit_price > 0
      AND invoice_date >= '2010-01-01'
      AND stock_code NOT IN (
          'Test001','Test002','S','PADS','Post','M',
          'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
          'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
          'Gift_0001_10','Gift','DOT','D','CRUK','C2','C3',
          'BANK CHARGES','B','AMAZONFEE','ADJUST2','ADJUST'
      )
    GROUP BY customer_id
),

enriched_retail AS (
    SELECT
        r.invoice_no,
        r.invoice_date,
        DATE_FORMAT(r.invoice_date, '%Y-%m') AS invoice_month,
        r.customer_id,
        r.stock_code,
        r.quantity,
        r.unit_price,
        CASE
            WHEN r.invoice_date < fp.first_purchase_date THEN 'Pre_first_purchase_cancel'
            WHEN r.invoice_date = fp.first_purchase_date THEN 'New'
            WHEN r.invoice_date > fp.first_purchase_date THEN 'Returning'
            ELSE 'Other'
        END AS customer_type
    FROM online_retail r
    LEFT JOIN first_purchase fp 
        ON r.customer_id = fp.customer_id
    WHERE r.invoice_date >= '2010-01-01'
      AND r.stock_code IN ('22138', '22617','22328') 
),

customer_rfm_labels AS (
    SELECT
        customer_id,
        CASE
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            ELSE 'Other'
        END AS rfm_segment
    FROM (
        SELECT
            customer_id,
            NTILE(5) OVER (
                ORDER BY DATEDIFF((SELECT MAX(invoice_date) FROM online_retail), MAX(invoice_date)) DESC
            ) AS r_score,
            NTILE(5) OVER (
                ORDER BY COUNT(DISTINCT CASE WHEN quantity > 0 AND unit_price > 0 THEN invoice_no END) ASC
            ) AS f_score
        FROM online_retail
        WHERE customer_id IS NOT NULL
        GROUP BY customer_id
    ) t
),

aggregated_data AS (
    SELECT
        r.invoice_month,
        r.stock_code,
        COUNT(DISTINCT CASE WHEN r.quantity > 0 AND r.unit_price > 0 THEN r.invoice_no END) AS global_gross_orders,
        COUNT(DISTINCT CASE WHEN r.quantity < 0 AND r.invoice_no LIKE 'C%' THEN r.invoice_no END) AS global_canceled_orders,
        SUM(CASE WHEN  r.quantity < 0 AND r.invoice_no LIKE 'C%' THEN ABS(r.quantity * r.unit_price) ELSE 0 END) AS global_canceled_revenue,
    
        COUNT(DISTINCT CASE 
            WHEN rfm.rfm_segment = 'At Risk' AND r.customer_type = 'Returning' AND r.quantity > 0 AND r.unit_price > 0 
            THEN r.invoice_no 
        END) AS at_risk_gross_orders,
        
        COUNT(DISTINCT CASE 
            WHEN rfm.rfm_segment = 'At Risk' AND r.customer_type = 'Returning' AND r.quantity < 0 AND r.invoice_no LIKE 'C%' 
            THEN r.invoice_no 
        END) AS at_risk_canceled_orders,
        
        SUM(CASE 
            WHEN rfm.rfm_segment = 'At Risk' AND r.customer_type = 'Returning' AND r.quantity < 0 AND r.invoice_no LIKE 'C%' 
            THEN ABS(r.quantity * r.unit_price) 
            ELSE 0 
        END) AS at_risk_canceled_revenue

    FROM enriched_retail r
    LEFT JOIN customer_rfm_labels rfm 
        ON r.customer_id = rfm.customer_id
    GROUP BY r.invoice_month, r.stock_code
)

SELECT
    invoice_month AS month,
    stock_code,
    global_gross_orders,
    global_canceled_orders,
    ROUND(100.0 * global_canceled_orders / NULLIF(global_gross_orders, 0), 2) AS global_cancel_rate_pct,
    global_canceled_revenue,
    at_risk_gross_orders,
    at_risk_canceled_orders,
    ROUND(100.0 * at_risk_canceled_orders / NULLIF(at_risk_gross_orders, 0), 2) AS at_risk_cancel_rate_pct,
    at_risk_canceled_revenue
FROM aggregated_data
ORDER BY stock_code, month;
