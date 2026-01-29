WITH base AS (
  SELECT
    stock_code,
    invoice_no,
    DATE(invoice_date) AS dt,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM combined_online_retail
),
cancel_inv AS (
  SELECT
    invoice_no,
    SUM(line_amount) AS inv_amount
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
),
tagged AS (
  SELECT
    b.*,
    CASE
      WHEN unit_price < 1 THEN '<1'
      WHEN unit_price < 5 THEN '1-4.99'
      WHEN unit_price < 10 THEN '5-9.99'
      WHEN unit_price < 20 THEN '10-19.99'
      WHEN unit_price < 50 THEN '20-49.99'
      ELSE '50+'
    END AS price_band
  FROM base b
)
SELECT
  price_band,

  COUNT(DISTINCT CASE
    WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND line_amount > 0 THEN invoice_no
  END) AS order_cnt,

  SUM(CASE
        WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND line_amount > 0
        THEN line_amount ELSE 0
      END) AS gross_revenue,

  SUM(CASE
        WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
         AND invoice_no IN (SELECT invoice_no FROM cancel_inv)
         AND line_amount < 0
        THEN ABS(line_amount) ELSE 0
      END) AS canceled_amount,

  1.0 * SUM(CASE
              WHEN UPPER(TRIM(invoice_no)) LIKE 'C%'
               AND invoice_no IN (SELECT invoice_no FROM cancel_inv)
               AND line_amount < 0
              THEN ABS(line_amount) ELSE 0
            END)
  / NULLIF(SUM(CASE WHEN UPPER(TRIM(invoice_no)) NOT LIKE 'C%' AND line_amount > 0 THEN line_amount ELSE 0 END), 0)
  AS cancel_revenue_share
FROM tagged
GROUP BY price_band
ORDER BY MIN(unit_price);
