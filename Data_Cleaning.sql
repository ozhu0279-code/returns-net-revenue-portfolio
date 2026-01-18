/* 

Cleaning Data in SQLTool

*/


-- Retrieve the database
SELECT *
FROM  online_retail_2009_2010
	UNION ALL
SELECT *
FROM  online_retail_2010_2011


-- [1] Checking duplicate rows
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country) AS RowNum
    FROM online_retail_2009_2010
    UNION ALL
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country) AS RowNum
    FROM online_retail_2010_2011
)
SELECT *
FROM CTE
WHERE RowNum > 1
ORDER BY RowNum DESC;
-- Result: 537594 duplicate rows, the maximum numbers of repetition is 20, and the minimum is 2.



/* [2] Checking MISSING value's dis 
		- NULL
		- empty string 
		- '0'
*/

-- [2].1 NULL Value 

--Counting NULL value in each column
WITH toll AS (
  SELECT
    SUM(CASE WHEN invoice_no IS NULL THEN 1 ELSE 0 END) AS InvoiceNo_null_count,
    SUM(CASE WHEN stock_code IS NULL THEN 1 ELSE 0 END) AS StockCode_null_count,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS Description_null_count,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_null_count,
    SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS InvoiceDate_null_count,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS UnitPrice_null_count,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS CustomerID_null_count,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS Country_null_count
FROM online_retail_2009_2010
UNION ALL
SELECT
    SUM(CASE WHEN invoice_no IS NULL THEN 1 ELSE 0 END) AS InvoiceNo_null_count,
    SUM(CASE WHEN stock_code IS NULL THEN 1 ELSE 0 END) AS StockCode_null_count,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS Description_null_count,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_null_count,
    SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS InvoiceDate_null_count,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS UnitPrice_null_count,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS CustomerID_null_count,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS Country_null_count
FROM online_retail_2010_2011
)
SELECT
  SUM(InvoiceNo_null_count) AS Total_InvoiceNo_null_count,
  SUM(StockCode_null_count) AS Total_StockCode_null_count,
  SUM(Description_null_count) AS Total_Description_null_count,
  SUM(Quantity_null_count) AS Total_Quantity_null_count,
  SUM(InvoiceDate_null_count) AS Total_InvoiceDate_null_count,
  SUM(UnitPrice_null_count) AS Total_UnitPrice_null_count,
  SUM(CustomerID_null_count) AS Total_CustomerID_null_count,
  SUM(Country_null_count) AS Total_Country_null_count
FROM toll;
-- Result: 7310 NULL cells in Description column and 350.934 NULL cells in CustomerID column and the rest do not contain NULL values.

/* Conclusion of [2].1
There are two columns containing NULL value: "Description" and "CustomerID".
*/


-- [2].2 Checking empty string '' Value

WITH emt AS (
  SELECT
    SUM(CASE WHEN invoice_no = '' THEN 1 ELSE 0 END) AS InvoiceNo_empty_string_count,
    SUM(CASE WHEN stock_code = '' THEN 1 ELSE 0 END) AS StockCode_empty_string_count,
    SUM(CASE WHEN description = '' THEN 1 ELSE 0 END) AS Description_empty_string_count,
    SUM(CASE WHEN quantity = '' THEN 1 ELSE 0 END) AS Quantity_empty_string_count,
    SUM(CASE WHEN unit_price = '' THEN 1 ELSE 0 END) AS UnitPrice_empty_string_count,
    SUM(CASE WHEN customer_id = '' THEN 1 ELSE 0 END) AS CustomerID_empty_string_count,
    SUM(CASE WHEN country = '' THEN 1 ELSE 0 END) AS Country_empty_string_count
FROM online_retail_2009_2010
UNION ALL
    SELECT
    SUM(CASE WHEN invoice_no = '' THEN 1 ELSE 0 END) AS InvoiceNo_empty_string_count,
    SUM(CASE WHEN stock_code = '' THEN 1 ELSE 0 END) AS StockCode_empty_string_count,
    SUM(CASE WHEN description = '' THEN 1 ELSE 0 END) AS Description_empty_string_count,
    SUM(CASE WHEN quantity = '' THEN 1 ELSE 0 END) AS Quantity_empty_string_count,
    SUM(CASE WHEN unit_price = '' THEN 1 ELSE 0 END) AS UnitPrice_empty_string_count,
    SUM(CASE WHEN customer_id = '' THEN 1 ELSE 0 END) AS CustomerID_empty_string_count,
    SUM(CASE WHEN country = '' THEN 1 ELSE 0 END) AS Country_empty_string_count
FROM online_retail_2010_2011
)
SELECT
  SUM(InvoiceNo_empty_string_count) AS Total_InvoiceNo_empty_string_count,
  SUM(StockCode_empty_string_count) AS Total_StockCode_empty_string_count,
  SUM(Description_empty_string_count) AS Total_Description_empty_string_count,
  SUM(Quantity_empty_string_count) AS Total_Quantity_empty_string_count,
  SUM(UnitPrice_empty_string_count) AS Total_UnitPrice_empty_string_count,
  SUM(CustomerID_empty_string_count) AS Total_CustomerID_empty_string_count,
  SUM(Country_empty_string_count) AS Total_Country_empty_string_count
FROM emt;

/* Conclusion of [2].2
There is only UnitPrice column contain empty_string value with 9921 cells.
*/


-- [2].3 Checking '0' Value

WITH zero AS (
  SELECT
    SUM(CASE WHEN invoice_no = '0' THEN 1 ELSE 0 END) AS InvoiceNo_0_count,
    SUM(CASE WHEN stock_code = '0' THEN 1 ELSE 0 END) AS StockCode_0_count,
    SUM(CASE WHEN description = '0' THEN 1 ELSE 0 END) AS Description_0_count,
    SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END) AS Quantity_0_count,
    SUM(CASE WHEN unit_price = 0 THEN 1 ELSE 0 END) AS UnitPrice_0_count,
    SUM(CASE WHEN customer_id = '0' THEN 1 ELSE 0 END) AS CustomerID_0_count,
    SUM(CASE WHEN country = '0' THEN 1 ELSE 0 END) AS Country_0_count
FROM online_retail_2009_2010
UNION ALL
SELECT
    SUM(CASE WHEN invoice_no = '0' THEN 1 ELSE 0 END) AS InvoiceNo_0_count,
    SUM(CASE WHEN stock_code = '0' THEN 1 ELSE 0 END) AS StockCode_0_count,
    SUM(CASE WHEN description = '0' THEN 1 ELSE 0 END) AS Description_0_count,
    SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END) AS Quantity_0_count,
    SUM(CASE WHEN unit_price = 0 THEN 1 ELSE 0 END) AS UnitPrice_0_count,
    SUM(CASE WHEN customer_id = '0' THEN 1 ELSE 0 END) AS CustomerID_0_count,
    SUM(CASE WHEN country = '0' THEN 1 ELSE 0 END) AS Country_0_count
  FROM online_retail_2010_2011
)
SELECT
  SUM(InvoiceNo_0_count) AS InvoiceNo_0_count,
  SUM(StockCode_0_count) AS StockCode_0_count,
  SUM(Description_0_count) AS Description_0_count,
  SUM(Quantity_0_count) AS Quantity_0_count,
  SUM(UnitPrice_0_count) AS UnitPrice_0_count,
  SUM(CustomerID_0_count) AS CustomerID_0_count,
  SUM(Country_0_count) AS Country_0_count
FROM zero;

/* Conclusion of [2].3
There is only UnitPrice column contain '0' value with 9921 cells
*/



/* [3] Checking Invalid Data
		- Negative value in "Quantity" column - NEGATIVE QUANTITY / POSITIVE QUANTITY
		- The negative and '0' value in "UnitPrice" column - NEGATIVE UNITPRICE / 0 UNITPRICE
*/

-- [3].a Checking negative value in Quantity column - NEGATIVE QUANTITY
WITH neg AS (
  SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0
UNION ALL
  SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0
)
SELECT count(*) AS disticnt_quantity_negative_records
FROM neg;
-- There are 35,276 rows has values < 0 in Quantity column
-- Need to identify the meaning of these rows -> Check with other important columns.

-- [3].b Checking negative value in Quantity together win C InvoiceNo - NEGATIVE QUANTITY - CANCELLATION
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no LIKE 'C%'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result: 29,698 rows of cancellation
-- ->can include these rows in Cancelation Dashboard

-- [3].c Checking negative Quantitive, C InvoiceNo and 0 = UnitPrice - NEGATIVE QUANTITY
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price = 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price = 0;
-- Result: no associated rows

-- [3].d Checking negative Quantitive, C InvoiceNo and UnitPrice > 0 - NEGATIVE QUANTITY - CANCELLATION 
SELECT *
FROM online_retail_UCI_DB..online_retail_main
WHERE Quantity < 0 AND InvoiceNo LIKE 'C%' AND UnitPrice > 0 AND StockCode <> 'B'
-- Result: 29,698 rows

-- [3].e Checking negative Quantitive, C InvoiceNo and UnitPrice < 0 - NEGATIVE QUANTITY
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price < 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no LIKE 'C%' AND unit_price < 0;
-- Result: no associated rows.

-- [3].f Checking negative value in Quantity together without C InvoiceNo - NEGATIVE QUANTITY - TEST
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%';
/* Result: there are 5,578 associated rows. 
It is clearly to see that all these rows have '0' value at associated cells in UnitPrice column; 
and 'NULL' value at associated cells in CustomerID column. 
So the author assumed that all these rows are the result of system test 
-> We can exclude these rows in our Sales Dashboard and Cancellation DashBoard
-> Should we delete them in Sales view
-> Maybe I can group them into a TEST table */

-- [3].g Checking negative value in Quantity together without C InvoiceNo, UnitPricxce = 0 - NEGATIVE QUANTITY - TEST
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0';
-- Result: same with (f)

-- [3].h Checking negative value in Quantity together without C InvoiceNo, UnitPricxce > 0 - NEGATIVE QUANTITY 
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0;
-- Result: no associated rows.

-- [3].j Checking negative value in Quantity together without C InvoiceNo, UnitPricxce < 0 - NEGATIVE QUANTITY 
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0;
-- Result: no associated rows.

-- [3].k Checking negative value in Quantity together without C InvoiceNo, UnitPrice = 0, CustomerID = NULL - NEGATIVE QUANTITY - TEST
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0' AND customer_id IS NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0' AND customer_id IS NULL;
-- Result: 5,578 rows (same with f)

-- [3].l Checking negative value in Quantity together without C InvoiceNo, UnitPrice = 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0' AND customer_id IS NOT NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price ='0' AND customer_id IS NOT NULL;
-- Result: no associated rows

-- [3].m Checking negative value in Quantity together without C InvoiceNo, UnitPrice > 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0 AND customer_id IS NOT NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price > 0 AND customer_id IS NOT NULL;
-- Result: no associated rows

-- [3].n Checking negative value in Quantity together without C InvoiceNo, UnitPrice < 0, CustomerID not null - NEGATIVE QUANTITY
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0 AND customer_id IS NOT NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%' AND unit_price < 0 AND customer_id IS NOT NULL;
-- Result: no associated rows

-------------------------------------------------------------------------------------------------------------------------------------------
-- [3].o NEGATIVE UnitPrice
SELECT *
FROM online_retail_2009_2010
WHERE unit_price < 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price < 0;
-- It shows only 8 rows with strange InvoiceNo starting with letter 'A', CustomerID is NULL.

-- [3].p InvoiceNo start with letter A - OUT OF SALE, CANCELLATION, TEST -> VAGUE rows
SELECT *
FROM online_retail_2009_2010
WHERE invoice_no LIKE 'A%'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE invoice_no LIKE 'A%';
-- It reveals 9 strange rows. 

-- [3].q UnitPrice = 0 
SELECT *
FROM online_retail_2009_2010
WHERE unit_price = 0
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price = 0;
-- 9,921 rows, which views do these row belong to? NOT SALE. BUT TEST OR CANCELLATION?

-- [3].r UnitPrice = 0, InvoiceNo start with letter C
SELECT *
FROM online_retail_2009_2010
WHERE unit_price = 0 AND invoice_no LIKE 'C%'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price = 0 AND invoice_no LIKE 'C%';
-- no associated rows

-- [3].s UnitPrice = 0 , InvoiceNo not start with letter C 
SELECT *
FROM online_retail_UCI_DB..online_retail_main
WHERE UnitPrice = 0 AND InvoiceNo NOT LIKE 'C%'
-- 9,921 rows, same result with q -> NOT SALE AND CANCELLATION. ONLY TEST?

-- [3].t UnitPrice = 0, InvoiceNo not start with letter C, Quantity > 0, CustomerID IS NULL - TEST view
SELECT *
FROM online_retail_2009_2010
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id IS NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id IS NULL;
-- 4209 rows - TEST view (no real customer since CustomerID is NULL, No revenue since UnitPrice = 0)

-- [3].u UnitPrice = 0, InvoiceNo not start with letter C, Quantity > 0, CustomerID IS NOT NULL - SALE view
SELECT *
FROM online_retail_2009_2010
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id IS NOT NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND quantity > 0 AND customer_id IS NOT NULL;
-- 134 rows - would be promotion item in an invoice with multiple products -> SALE view

---------------------------------------------------------------------------------------
-- Conclusion of SALE VIEW from initial EDA
SELECT * 
FROM online_retail_2009_2010
WHERE quantity > 0 AND unit_price > 0  AND StockCode <> 'B'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity > 0 AND unit_price > 0  AND StockCode <> 'B';
-- Result: 1,553,204 associated rows.


-- Conclusion of CANCELLATION VIEW from initial EDA
SELECT *
FROM online_retail_2009_2010
WHERE quantity < 0 AND invoice_no LIKE 'C%'
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result 29,698 rows (from b and d above)


-- Conclusion of TEST VIEW from initial EDA
SELECT *
FROM online_retail_2009_2010
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND customer_id IS NULL
UNION ALL
SELECT *
FROM online_retail_2010_2011
WHERE unit_price = 0 AND invoice_no NOT LIKE 'C%' AND customer_id IS NULL;
-- Result: 9,787 rows ( from f,g,k,t above)


-- Conclusion of VAGUE rows from initial EDA
SELECT *
FROM online_retail_UCI_DB..online_retail_main
WHERE InvoiceNo LIKE 'A%'
-- Result: 9 rows






