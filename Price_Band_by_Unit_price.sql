WITH base AS (
  SELECT
    invoice_no,
    unit_price,
    quantity,
    unit_price * quantity AS line_amount
  FROM cleaned_final
  WHERE unit_price > 0
),

cancel_inv AS (
  SELECT
    invoice_no
  FROM base
  WHERE invoice_no LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
),

tagged_lines AS (
  SELECT
    invoice_no,
    CASE
      WHEN unit_price < 1 THEN '<1'
      WHEN unit_price < 5 THEN '1-4.99'
      WHEN unit_price < 10 THEN '5-9.99'
      WHEN unit_price < 20 THEN '10-19.99'
      WHEN unit_price < 50 THEN '20-49.99'
      WHEN unit_price < 100 THEN '50-99.99'
      ELSE '100+'
    END AS price_band
  FROM base
),

band_orders AS (
  SELECT
    tl.price_band,
    tl.invoice_no,
    CASE
      WHEN tl.invoice_no LIKE 'C%'
       AND tl.invoice_no IN (SELECT invoice_no FROM cancel_inv)
      THEN 1 ELSE 0
    END AS is_cancel
  FROM tagged_lines tl
  GROUP BY tl.price_band, tl.invoice_no
)

SELECT
  price_band,
  COUNT(*) AS total_orders,
  SUM(is_cancel) AS cancel_orders,
  1.0 * SUM(is_cancel) / NULLIF(COUNT(*), 0) AS cancel_order_rate
FROM band_orders
GROUP BY price_band
ORDER BY
  CASE price_band
    WHEN '<1' THEN 1
    WHEN '1-4.99' THEN 2
    WHEN '5-9.99' THEN 3
    WHEN '10-19.99' THEN 4
    WHEN '20-49.99' THEN 5
    WHEN '50-99.99' THEN 6
    ELSE 7
  END;
