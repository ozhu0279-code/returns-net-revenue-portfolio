WITH base AS (
  SELECT
    customer_id,
    invoice_no,
    DATE(invoice_date) AS dt,
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

purchase_inv AS (
  SELECT
    i.customer_id,
    i.invoice_no,
    i.dt,
    i.invoice_amount
  FROM inv i
  WHERE UPPER(TRIM(i.invoice_no)) NOT LIKE 'C%'
    AND EXISTS (
      SELECT 1
      FROM base b
      WHERE b.customer_id=i.customer_id AND b.invoice_no=i.invoice_no AND b.dt=i.dt AND b.line_amount > 0
    )
),
first_purchase AS (
  SELECT customer_id, MIN(dt) AS first_purchase_date
  FROM purchase_inv
  GROUP BY customer_id
),

cancel_inv AS (
  SELECT
    customer_id,
    invoice_no,
    dt AS cancel_date,
    invoice_amount
  FROM inv
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
    AND invoice_amount < 0
),

window_cnt AS (
  SELECT
    c1.customer_id,
    c1.cancel_date,
    COUNT(DISTINCT c2.invoice_no) AS cancel_orders_in_30d
  FROM cancel_inv c1
  JOIN cancel_inv c2
    ON c2.customer_id = c1.customer_id
   AND c2.cancel_date BETWEEN c1.cancel_date AND DATE_ADD(c1.cancel_date, INTERVAL 30 DAY)
  GROUP BY c1.customer_id, c1.cancel_date
),
cust_max AS (
  SELECT customer_id, MAX(cancel_orders_in_30d) AS max_cancel_30d
  FROM window_cnt
  GROUP BY customer_id
),

cust_purchase AS (
  SELECT
    customer_id,
    MAX(dt) AS last_purchase_date,
    COUNT(DISTINCT invoice_no) AS purchase_orders,
    SUM(CASE WHEN invoice_amount > 0 THEN invoice_amount ELSE 0 END) AS gross_monetary
  FROM purchase_inv
  GROUP BY customer_id
),
cust_cancel AS (
  SELECT
    c.customer_id,
    COUNT(DISTINCT c.invoice_no) AS cancel_orders,
    SUM(CASE WHEN fp.first_purchase_date IS NOT NULL AND c.cancel_date < fp.first_purchase_date THEN 1 ELSE 0 END) AS cancel_orders_pre_first
  FROM cancel_inv c
  LEFT JOIN first_purchase fp ON fp.customer_id = c.customer_id
  GROUP BY c.customer_id
),
cust_universe AS (
  SELECT customer_id FROM cust_purchase
  UNION
  SELECT customer_id FROM cust_cancel
),
cust AS (
  SELECT
    u.customer_id,
    fp.first_purchase_date,
    p.last_purchase_date,
    COALESCE(p.purchase_orders, 0) AS purchase_orders,
    COALESCE(p.gross_monetary, 0) AS gross_monetary,
    COALESCE(cc.cancel_orders, 0) AS cancel_orders,
    COALESCE(cc.cancel_orders_pre_first, 0) AS cancel_orders_pre_first,
    CASE
      WHEN fp.first_purchase_date IS NULL AND COALESCE(cc.cancel_orders, 0) > 0 THEN 'Cancel-only'
      WHEN fp.first_purchase_date IS NOT NULL AND COALESCE(cc.cancel_orders_pre_first, 0) > 0 THEN 'Pre-first-purchase cancel'
      WHEN fp.first_purchase_date IS NOT NULL THEN 'Normal'
      ELSE 'Other'
    END AS customer_status
  FROM cust_universe u
  LEFT JOIN first_purchase fp ON fp.customer_id = u.customer_id
  LEFT JOIN cust_purchase p ON p.customer_id = u.customer_id
  LEFT JOIN cust_cancel cc ON cc.customer_id = u.customer_id
),
rfm_scored AS (
  SELECT
    customer_id,
    NTILE(5) OVER (
      ORDER BY DATEDIFF((SELECT MAX(last_purchase_date) FROM cust WHERE last_purchase_date IS NOT NULL), last_purchase_date) ASC
    ) AS r_score,
    NTILE(5) OVER (ORDER BY purchase_orders DESC) AS f_score,
    NTILE(5) OVER (ORDER BY gross_monetary DESC) AS m_score
  FROM cust
  WHERE last_purchase_date IS NOT NULL
),
seg AS (
  SELECT
    c.customer_id,
    CASE
      WHEN c.customer_status = 'Cancel-only' THEN 'Cancel-only'
      WHEN c.customer_status = 'Pre-first-purchase cancel' THEN
        CASE
          WHEN r.r_score >= 4 AND r.f_score >= 4 AND r.m_score >= 4 THEN 'Pre-first: Champions'
          WHEN r.r_score >= 4 AND r.f_score >= 3 THEN 'Pre-first: Loyal'
          WHEN r.r_score >= 4 AND r.f_score <= 2 THEN 'Pre-first: New/Promising'
          WHEN r.r_score <= 2 AND r.f_score >= 3 THEN 'Pre-first: At Risk'
          WHEN r.r_score = 1 THEN 'Pre-first: Lost'
          ELSE 'Pre-first: Others'
        END
      ELSE
        CASE
          WHEN r.r_score >= 4 AND r.f_score >= 4 AND r.m_score >= 4 THEN 'Champions'
          WHEN r.r_score >= 4 AND r.f_score >= 3 THEN 'Loyal'
          WHEN r.r_score >= 4 AND r.f_score <= 2 THEN 'New/Promising'
          WHEN r.r_score <= 2 AND r.f_score >= 3 THEN 'At Risk'
          WHEN r.r_score = 1 THEN 'Lost'
          ELSE 'Others'
        END
    END AS segment
  FROM cust c
  LEFT JOIN rfm_scored r ON r.customer_id = c.customer_id
),

seg_cancel_customers AS (
  SELECT
    s.segment,
    COUNT(*) AS customers_with_cancel
  FROM cust_max cm
  JOIN seg s ON s.customer_id = cm.customer_id
  GROUP BY s.segment
),

seg_repeat_customers AS (
  SELECT
    s.segment,
    COUNT(*) AS repeat_cancel_customers_ge_2
  FROM cust_max cm
  JOIN seg s ON s.customer_id = cm.customer_id
  WHERE cm.max_cancel_30d >= 2
  GROUP BY s.segment
)

SELECT
  d.segment AS customer_category,
  d.customers_with_cancel,
  COALESCE(n.repeat_cancel_customers_ge_2, 0) AS repeat_cancel_customers_ge_2,
  1.0 * COALESCE(n.repeat_cancel_customers_ge_2, 0) / NULLIF(d.customers_with_cancel, 0) AS repeat_cancel_rate_ge_2
FROM seg_cancel_customers d
LEFT JOIN seg_repeat_customers n
  ON n.segment = d.segment
ORDER BY
  FIELD(d.segment,
    'Cancel-only',
    'Pre-first: Loyal',
    'Pre-first: Champions',
    'Pre-first: At Risk',
    'Pre-first: Others',
    'Pre-first: New/Promising',
    'Pre-first: Lost',
    'Loyal',
    'New/Promising',
    'Lost',
    'Others',
    'At Risk',
    'Champions'
  );
