WITH base AS (
  SELECT
    customer_id,
    invoice_no,
    DATE(invoice_date) AS dt,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM cleaned_final
  WHERE customer_id IS NOT NULL
),
inv AS (
  SELECT
    customer_id,
    invoice_no,
    dt,
    SUM(line_amount) AS invoice_amount
  FROM base
  GROUP BY customer_id, invoice_no, dt
),
cancels AS (
  SELECT
    customer_id,
    invoice_no,
    dt AS cancel_date,
    invoice_amount
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
),
repeat_cancel_flag AS (
  SELECT
    c1.customer_id,
    MAX(
      CASE
        WHEN c2.cancel_date > c1.cancel_date
         AND c2.cancel_date <= DATE_ADD(c1.cancel_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS has_repeat_cancel_30d
  FROM cancels c1
  JOIN cancels c2
    ON c2.customer_id = c1.customer_id
  GROUP BY c1.customer_id
),
purchase_orders AS (
  SELECT
    customer_id,
    invoice_no,
    dt AS order_date,
    SUM(line_amount) AS order_amount
  FROM base
  WHERE UPPER(TRIM(invoice_no)) NOT LIKE 'C%'
    AND line_amount > 0
  GROUP BY customer_id, invoice_no, dt
),
cust_metrics AS (
  SELECT
    p.customer_id,
    MAX(p.order_date) AS last_purchase_date,
    COUNT(DISTINCT p.invoice_no) AS frequency,
    SUM(p.order_amount) AS gross_sales
  FROM purchase_orders p
  GROUP BY p.customer_id
),
cust_cancel AS (
  SELECT
    customer_id,
    SUM(ABS(invoice_amount)) AS canceled_amount,
    COUNT(DISTINCT invoice_no) AS canceled_orders
  FROM cancels
  GROUP BY customer_id
),
cust_net AS (
  SELECT
    m.customer_id,
    m.last_purchase_date,
    m.frequency,
    m.gross_sales,
    COALESCE(cc.canceled_amount, 0) AS canceled_amount,
    (m.gross_sales - COALESCE(cc.canceled_amount, 0)) AS net_monetary,
    COALESCE(cc.canceled_orders, 0) AS canceled_orders,
    COALESCE(r.has_repeat_cancel_30d, 0) AS has_repeat_cancel_30d
  FROM cust_metrics m
  LEFT JOIN cust_cancel cc ON cc.customer_id = m.customer_id
  LEFT JOIN repeat_cancel_flag r ON r.customer_id = m.customer_id
),
rfm_scored AS (
  SELECT
    customer_id,
    DATEDIFF((SELECT MAX(last_purchase_date) FROM cust_net), last_purchase_date) AS recency_days,
    frequency,
    net_monetary,
    canceled_orders,
    has_repeat_cancel_30d,
    NTILE(5) OVER (
      ORDER BY DATEDIFF((SELECT MAX(last_purchase_date) FROM cust_net), last_purchase_date) ASC
    ) AS r_score,
    NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
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
  COUNT(*) AS customers_in_segment,
  SUM(canceled_orders > 0) AS cancel_customers,
  SUM(CASE WHEN canceled_orders > 0 AND has_repeat_cancel_30d = 1 THEN 1 ELSE 0 END) AS repeat_cancel_customers_30d,
  1.0 * SUM(CASE WHEN canceled_orders > 0 AND has_repeat_cancel_30d = 1 THEN 1 ELSE 0 END)
    / NULLIF(SUM(canceled_orders > 0), 0) AS repeat_cancel_rate_30d_among_cancelers
FROM seg
GROUP BY segment
ORDER BY repeat_cancel_rate_30d_among_cancelers DESC;
