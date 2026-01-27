WITH orders AS (
   SELECT
       customer_id,
       invoice_no,
       DATE(invoice_date) AS order_date,
       SUM(quantity * unit_price) AS order_amount
   FROM cleaned_final
   WHERE customer_id IS NOT NULL AND quantity > 0 AND unit_price > 0 AND invoice_no NOT LIKE 'C%'  
   GROUP BY customer_id, invoice_no, DATE(invoice_date)
),
rfm_base AS (
   SELECT
       customer_id,
       MAX(order_date) AS last_order_date,
       COUNT(DISTINCT invoice_no) AS frequency,
       SUM(order_amount) AS monetary
   FROM orders
   GROUP BY customer_id
),
rfm_scored AS (
   SELECT
       customer_id,
       DATEDIFF((SELECT MAX(order_date) FROM orders), last_order_date) AS recency,
       frequency,
       monetary,
       NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(order_date) FROM orders), last_order_date) DESC) AS recency_score,
       NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score,
       NTILE(5) OVER (ORDER BY monetary DESC) AS monetary_score
   FROM rfm_base
),
seg AS (
   SELECT
         customer_id,
         monetary,
         CASE
             WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
             WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
             WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New/Promising Customers'
             WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk Customers'
             WHEN recency_score = 1 THEN'Lost Customers'
             ELSE 'Others'
         END AS segment
      FROM rfm_scored
)
SELECT
   segment,
   COUNT(customer_id) AS customer_count,
   SUM(monetary) AS gross_revenue,
   AVG(monetary) AS avg_revenue_per_customer
FROM seg
GROUP BY segment
ORDER BY gross_revenue DESC;
