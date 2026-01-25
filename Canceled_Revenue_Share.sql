/*
Canceled Revenue Share 
*/
SELECT 
   SUM(CASE 
         WHEN invoice_no LIKE 'C%' AND unit_price * quantity < 0 THEN ABS(unit_price * quantity) 
         ELSE 0 
       END) AS canceled_revenue,
   SUM(CASE 
         WHEN unit_price * quantity > 0 THEN unit_price * quantity 
         ELSE 0
       END) AS total_revenue,
   SUM(CASE 
         WHEN invoice_no LIKE 'C%' AND unit_price * quantity < 0 THEN ABS(unit_price * quantity) 
         ELSE 0 
       END) / 
NULLIF(SUM(CASE WHEN unit_price * quantity > 0 THEN unit_price * quantity ELSE 0 END), 0) AS canceled_revenue_share
FROM combined_online_retail;
