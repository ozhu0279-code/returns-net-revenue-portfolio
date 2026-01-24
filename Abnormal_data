/* 

Note:The cancellation amount only includes the details of cancelled invoices (where the invoice number starts with "C") that result in negative revenue, and takes the absolute value of these amounts.
An abnormal record of 1 cancelled invoice with a positive amount (C496350) was found. 
To avoid deviation in measurement, this amount was not included in the cancellation amount.
invoice_no--C496350 
quantity--1
invoice_date--2010/2/1 08:24

*/

/* There's difference of cancelld invoiced counting by different condtions.

SELECT *
FROM combined_online_retail
WHERE invoice_no LIKE 'C%';
----Result:19,494 rows

SELECT *
FROM combined_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%';
----Result:19,493 rows

/* 
Conclusion

---I think the problem is 'quantity' column,so i counted the quantity of rows under 3 different conditions where quantity is greater than or less than or equals to 0.
SELECT
  SUM(CASE WHEN quantity < 0 THEN 1 ELSE 0 END) AS c_rows_qty_negative,
  SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END) AS c_rows_qty_zero,
  SUM(CASE WHEN quantity > 0 THEN 1 ELSE 0 END) AS c_rows_qty_positive,
  COUNT(*) AS c_rows_total
FROM combined_online_retail
WHERE UPPER(TRIM(invoice_no)) LIKE 'C%';
---Result: 
c_rows_qty_negative:19,493 rows
c_rows_qty_zero:0 row
c_rows_qty_positive:1 rows

Conclusion:This result demonstrates there's an order that status shows canceled but quantity is positive.That's contradictory.

---I explored the specific issue row.
SELECT
  invoice_no,
  stock_code,
  description,
  quantity,
  unit_price,
  unit_price * quantity AS line_amount,
  invoice_date,
  customer_id,
  country
FROM combined_online_retail
WHERE invoice_no LIKE 'C%'
  AND quantity > 1;
---Result:No data.

---I changed the condtion to count the issue row again.
SELECT
  COUNT(*) AS c_rows_total,
  SUM(quantity > 1) AS c_rows_qty_gt_1,
  SUM(quantity = 1) AS c_rows_qty_eq_1,
  SUM(quantity < 0) AS c_rows_qty_lt_0
FROM combined_online_retail
WHERE invoice_no LIKE 'C%';
---Result:
c_rows_qty_gt_1:0 row
c_rows_qty_eq_1:1 row
c_rows_qty_lt_0:19,493 rows

---I kept exploring the specific issue row.
SELECT
  invoice_no,
  stock_code,
  description,
  quantity,
  unit_price,
  unit_price * quantity AS line_amount,
  invoice_date,
  customer_id,
  country
FROM combined_online_retail
WHERE invoice_no LIKE 'C%'
  AND quantity = 1;

---Finally,issue row came out.
