/*
Canceled Revenue per Stockcode per Month
*/
WITH base AS (
  SELECT
    invoice_no,
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    stock_code,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),
valid_cancel_inv AS (
  SELECT invoice_no
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
)
SELECT
  month,
  stock_code,
  SUM(ABS(line_amount)) AS canceled_revenue
FROM base
WHERE invoice_no IN (SELECT invoice_no FROM valid_cancel_inv)
  AND line_amount < 0
GROUP BY month, stock_code;


/*
Canceled Revenue per Country per Month
*/
WITH base AS (
  SELECT
    invoice_no,
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    country,
    unit_price * quantity AS line_amount
  FROM cleaned_final
),
valid_cancel_inv AS (
  SELECT invoice_no
  FROM base
  WHERE UPPER(TRIM(invoice_no)) LIKE 'C%'
  GROUP BY invoice_no
  HAVING SUM(line_amount) < 0
)
SELECT
  month,
  country,
  SUM(ABS(line_amount)) AS canceled_revenue
FROM base
WHERE invoice_no IN (SELECT invoice_no FROM valid_cancel_inv)
  AND line_amount < 0
GROUP BY month, country;
