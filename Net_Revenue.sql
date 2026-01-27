SELECT 
   SUM(CASE WHEN unit_price * quantity > 0 THEN unit_price * quantity 
            ELSE 0 
            END) AS gross_revenue,
   SUM(CASE WHEN unit_price * quantity < 0 THEN ABS(unit_price * quantity) 
            ELSE 0 
            END) AS canceled_revenue,
   SUM(CASE WHEN unit_price * quantity > 0 THEN unit_price * quantity 
            ELSE 0 
            END)
   - SUM(CASE WHEN unit_price * quantity < 0 THEN ABS(unit_price * quantity) 
            ELSE 0 
            END) AS net_revenue
FROM cleaned_final;
