/*
Top10 skus by canceled revenue
*/
WITH SKU AS (
  SELECT
     stock_code,
         SUM (CASE
            WHEN unit_price * quantity > 0 THEN unit_price * quantity
            ELSE 0
         END) AS gross_revenue,
         SUM (CASE
            WHEN invoice_no LIKE 'C%' AND unit_price * quantity < 0 THEN ABS(unit_price * quantity)
            ELSE 0
         END) AS canceled_revenue
  FROM cleaned_final
  GROUP BY stock_code
)
SELECT
    stock_code,
    gross_revenue,
    canceled_revenue
FROM SKU
ORDER BY canceled_revenue DESC
LIMIT 10;



/*
Top 10 countries by canceled revenue
*/
WITH ctr AS (
  SELECT
     country,
         SUM (CASE
            WHEN unit_price * quantity > 0 THEN unit_price * quantity
            ELSE 0
         END) AS gross_revenue,
         SUM (CASE
            WHEN invoice_no LIKE 'C%' AND unit_price * quantity < 0 THEN ABS(unit_price * quantity)
            ELSE 0
         END) AS canceled_revenue
  FROM cleaned_final
  GROUP BY country
)
SELECT
    country,
    gross_revenue,
    canceled_revenue
FROM ctr
ORDER BY canceled_revenue DESC
LIMIT 10;
