/* 

Cleaning Data in SQLTool

*/


-- Retrieve the database
SELECT *
FROM  online_retail_2009_2010
  UNION ALL
SELECT *
FROM  online_retail_2010_2011

-- Merging into a new table
CREATE TABLE combined_online_retail AS
SELECT invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
FROM online_retail_2009_2010
UNION ALL
SELECT invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
FROM online_retail_2010_2011;


-- [1] Checking duplicate rows
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country) AS RowNum
    FROM combined_online_retail
)
SELECT *
FROM CTE
WHERE RowNum > 1
ORDER BY RowNum DESC;
-- Result: 537,594 duplicate rows, the maximum numbers of repetition is 20, and the minimum is 2.
※ Duplicates may not the dirty date,because one invoice may include more than 1 same stockcodes,so we just combined them into a new table


/* [2] Checking MISSING value 
		- '0'
		- NULL
		- empty string
*/

-- [2].1 Checking '0' Value
SELECT
    SUM(CASE WHEN invoice_no = '0' THEN 1 ELSE 0 END) AS InvoiceNo_0_count,
    SUM(CASE WHEN stock_code = '0' THEN 1 ELSE 0 END) AS StockCode_0_count,
    SUM(CASE WHEN "Description" = '0' THEN 1 ELSE 0 END) AS Description_0_count,
    SUM(CASE WHEN quantity = '0' THEN 1 ELSE 0 END) AS Quantity_0_count,
    SUM(CASE WHEN unit_price = '0' THEN 1 ELSE 0 END) AS UnitPrice_0_count,
    SUM(CASE WHEN customer_id = '0' THEN 1 ELSE 0 END) AS CustomerID_0_count,
    SUM(CASE WHEN country = '0' THEN 1 ELSE 0 END) AS Country_0_count
FROM cleaned_online_retail;


/* Conclusion of [2].1
There is only UnitPrice column contain '0' value with 6032 cells
*/

-- [2].2 Checking NULL Value
SELECT
  SUM(invoice_no IS NULL) AS invoice_no_null_count,
  SUM(stock_code IS NULL) AS stock_code_null_count,
  SUM(description IS NULL) AS description_null_count,
  SUM(invoice_date IS NULL) AS invoice_date_null_count,
  SUM(quantity IS NULL) AS quantity_null_count,
  SUM(customer_id IS NULL) AS customer_id_null_count,
  SUM(country IS NULL) AS country_null_count
FROM combined_online_retail;

/* Conclusion of [2].2
There are no null values in the cleaned table.
*/

-- [2].3 Checking empty string '' Value
SELECT
  SUM(TRIM(invoice_no) = '') AS invoice_no_blank,
  SUM(TRIM(stock_code) = '') AS stock_code_blank,
  SUM(TRIM(description) = '') AS description_blank,
  SUM(TRIM(invoice_date) = '') AS invoice_date_blank,
  SUM(TRIM(quantity) = '') AS quantity_blank,
  SUM(TRIM(customer_id) = '') AS customer_id_blank,
  SUM(TRIM(country) = '') AS country_blank_count
FROM combined_online_retail;
-- Result: 4,275 cells with empty string in Description column and 235.151 cells with empty string in CustomerID column and the rest do not contain empty string cells.

/* Conclusion of [2].3
There are Description and CustomerID column contain empty string value.
*/

-- [2].4 Changing empty string '' into NUL value 
DROP TABLE IF EXISTS cleaned_final;

CREATE TABLE cleaned_final AS
SELECT
  invoice_no,
  stock_code,
  NULLIF(TRIM(description), '') AS description,
  quantity,
  invoice_date,
  unit_price,
  NULLIF(TRIM(customer_id), '') AS customer_id,
  country
FROM combined_online_retail;



/* [3] Checking Invalid Data
		- Negative value in "Quantity" column - NEGATIVE QUANTITY / POSITIVE QUANTITY
		- The negative and '0' value in "UnitPrice" column - NEGATIVE UNITPRICE / 0 UNITPRICE
*/

-- [3].a Checking negative value in Quantity column - NEGATIVE QUANTITY
SELECT COUNT(*)
FROM cleaned_online_retail
WHERE quantity < 0;
-- There are 22,496 rows has values < 0 in Quantity column
-- Need to identify the meaning of these rows -> Check with other important columns.

-- [3].b Checking negative value in Quantity together win C InvoiceNo - NEGATIVE QUANTITY - CANCELLATION
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result: 19,103 rows of cancellation
-- ->can include these rows in Cancelation Dashboard

-- [3].c Checking negative Quantitive, C InvoiceNo and 0 = UnitPrice - NEGATIVE QUANTITY
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price = 0;
-- Result: no associated rows

-- [3].d Checking negative Quantitive, C InvoiceNo and UnitPrice > 0 - NEGATIVE QUANTITY - CANCELLATION 
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price > 0 AND stock_code<>'B';
-- Result: 19,103 rows

-- [3].e Checking negative Quantitive, C InvoiceNo and UnitPrice < 0 - NEGATIVE QUANTITY
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price < 0；
-- Result: no associated rows.

-- [3].f Checking negative value in Quantity together without C InvoiceNo - NEGATIVE QUANTITY - TEST
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%';
/* Result: there are 3,393 associated rows. 
It is clearly to see that all these rows have '0' value at associated cells in UnitPrice column; 
and empty string cell at associated cells in CustomerID column. 
So the author assumed that all these rows are the result of system test 
-> We can exclude these rows in our Sales Dashboard and Cancellation DashBoard
-> Should we delete them in Sales view
-> Maybe I can group them into a TEST table */

-- [3].g Checking negative value in Quantity together without C InvoiceNo, UnitPricxce = 0 - NEGATIVE QUANTITY - TEST
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0';
-- Result: same with (f)

-- [3].h Checking negative value in Quantity together without C InvoiceNo, UnitPricxce > 0 - NEGATIVE QUANTITY 
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0;
-- Result: no associated rows.

-- [3].j Checking negative value in Quantity together without C InvoiceNo, UnitPricxce < 0 - NEGATIVE QUANTITY 
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0;
-- Result: no associated rows.

-- [3].k Checking negative value in Quantity together without C InvoiceNo, UnitPrice = 0, CustomerID = NULL - NEGATIVE QUANTITY - TEST
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price = 0 AND customer_id = '';
-- Result: 3,393 rows (same with f)

-- [3].l Checking negative value in Quantity together without C InvoiceNo, UnitPrice = 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price = 0 AND customer_id <>'';
-- Result: no associated rows

-- [3].m Checking negative value in Quantity together without C InvoiceNo, UnitPrice > 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0 AND customer_id <>'';
-- Result: no associated rows

-- [3].n Checking negative value in Quantity together without C InvoiceNo, UnitPrice < 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0 AND customer_id <>'';
-- Result: no associated rows

-------------------------------------------------------------------------------------------------------------------------------------------
-- [3].o NEGATIVE UnitPrice
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0;
-- Result: 22,496 rows

-- [3].p InvoiceNo start with letter A - OUT OF SALE, CANCELLATION, TEST -> VAGUE rows
SELECT *
FROM cleaned_online_retail
WHERE invoice_no LIKE 'A%';
-- It includes 6 rows,which description shows 'adjust bad debt'.

-- [3].q UnitPrice = 0 
SELECT *
FROM cleaned_online_retail
WHERE unit_price = 0;
-- 6,032 rows, which views do these row belong to? NOT SALE. BUT TEST OR CANCELLATION?

-- [3].r UnitPrice = 0, InvoiceNo start with letter C
SELECT *
FROM cleaned_online_retail
WHERE unit_price = 0 AND invoice_no LIKE 'C%'
-- no associated rows

-- [3].s UnitPrice = 0 , InvoiceNo not start with letter C 
SELECT *
FROM cleaned_online_retail
WHERE UnitPrice = 0 AND InvoiceNo NOT LIKE 'C%'
-- 6,032 rows, same result with q -> NOT SALE AND CANCELLATION. ONLY TEST?

-- [3].t UnitPrice = 0, InvoiceNo not start with letter C, Quantity > 0, CustomerID IS NULL - TEST view
SELECT *
FROM cleaned_online_retail
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id = '';
-- 2,551 rows - TEST view (no real customer since CustomerID is empty, No revenue since UnitPrice = 0)

-- [3].u UnitPrice = 0, InvoiceNo not start with letter C, Quantity > 0, CustomerID IS NOT NULL - SALE view
SELECT *
FROM cleaned_online_retail
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id <> '';
-- 88 rows - would be promotion item in an invoice with multiple products -> SALE view

---------------------------------------------------------------------------------------
-- Conclusion of SALE VIEW from initial EDA
SELECT * 
FROM cleaned_online_retail
WHERE quantity > 0 AND unit_price > 0  AND stock_code <> 'B';
-- Result: 1,007,895 associated rows.


-- Conclusion of CANCELLATION VIEW from initial EDA
SELECT *
FROM cleaned_online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result 19,103 rows (from b and d above)


-- Conclusion of TEST VIEW from initial EDA
SELECT *
FROM cleaned_online_retail
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND customer_id = '';
-- Result: 5,944 rows ( from f,g,k,t above)


-- Conclusion of VAGUE rows from initial EDA (Description shows 'adjust bad debt'.Stock_code shows 'B')
SELECT *
FROM cleaned_online_retail
WHERE invoice_no LIKE 'A%';
-- Result: 6 rows






