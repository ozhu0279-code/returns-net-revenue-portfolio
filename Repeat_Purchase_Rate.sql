/*
The quantity of order is more than 2 for the same customer.
*/
WITH orders AS (
   SELECT
       customer_id,
       invoice_no
   FROM cleaned_final
   WHERE customer_id IS NOT NULL
       AND quantity > 0
       AND unit_price > 0
       AND invoice_no NOT LIKE 'C%'
   GROUP BY customer_id, invoice_no
), 
   customer_orders AS (
      SELECT
          customer_id,
          COUNT(*) AS order_count
      FROM orders
      GROUP BY customer_id
   )
   SELECT
       COUNT(*) AS customers,
       SUM(order_count >= 2) AS repeat_customers,
       SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS repeat_rate
   FROM customer_orders;
