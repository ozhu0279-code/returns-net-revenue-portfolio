WITH base AS (
  SELECT
    customer_id,
    invoice_no,
    DATE(invoice_date) AS order_date,
    unit_price,
    quantity
  FROM combined_online_retail
  WHERE customer_id IS NOT NULL
    AND unit_price IS NOT NULL
    AND quantity IS NOT NULL
),
cust_metrics AS (
  SELECT
    customer_id,
    MAX(CASE
          WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%'
           AND unit_price * quantity > 0
          THEN order_date
        END) AS last_purchase_date,
    COUNT(DISTINCT CASE
      WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' THEN invoice_no END
    ) AS freq_orders,
    SUM(CASE
          WHEN unit_price * quantity > 0 THEN unit_price * quantity
          ELSE 0
        END) AS gross_sales,
    SUM(CASE
          WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
           AND unit_price * quantity < 0
          THEN ABS(unit_price * quantity)
          ELSE 0
        END) AS canceled_amount,
    COUNT(DISTINCT CASE
      WHEN UPPER(TRIM(invoice_no)) LIKE 'C%' THEN invoice_no END
    ) AS canceled_orders,
    COUNT(DISTINCT invoice_no) AS total_orders
  FROM base
  GROUP BY customer_id
),
cust_net AS (
  SELECT
    customer_id,
    last_purchase_date,
    freq_orders,
    gross_sales,
    canceled_amount,
    (gross_sales - canceled_amount) AS net_monetary,
    canceled_orders,
    total_orders,
    1.0 * canceled_amount / NULLIF(gross_sales, 0) AS cancel_amount_share,
    1.0 * canceled_orders / NULLIF(total_orders, 0) AS cancel_order_rate
  FROM cust_metrics
  WHERE last_purchase_date IS NOT NULL 
),
rfm_scored AS (
  SELECT
    customer_id,
    DATEDIFF((SELECT MAX(last_purchase_date) FROM cust_net), last_purchase_date) AS recency_days,
    freq_orders,
    net_monetary,
    cancel_amount_share,
    cancel_order_rate,
    NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(last_purchase_date) FROM cust_net), last_purchase_date) ASC) AS r_score,
    NTILE(5) OVER (ORDER BY freq_orders DESC) AS f_score,
    NTILE(5) OVER (ORDER BY net_monetary DESC) AS m_score
  FROM cust_net
),
seg AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
      WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
      WHEN r_score >= 4 AND f_score <= 2 THEN 'New/Promising'
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
      WHEN r_score = 1 THEN 'Lost'
      ELSE 'Others'
    END AS segment
  FROM rfm_scored
)
SELECT
  segment,
  COUNT(*) AS customers,
  AVG(recency_days) AS avg_recency_days,
  AVG(freq_orders) AS avg_frequency,
  AVG(net_monetary) AS avg_net_monetary,
  AVG(cancel_amount_share) AS avg_cancel_amount_share,
  AVG(cancel_order_rate) AS avg_cancel_order_rate,
  SUM(cancel_amount_share > 0.1) / NULLIF(COUNT(*), 0) AS pct_customers_cancel_share_gt_10pct
FROM seg
GROUP BY segment
ORDER BY avg_cancel_amount_share DESC;
