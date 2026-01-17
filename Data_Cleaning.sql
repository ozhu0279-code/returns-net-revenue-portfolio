/* [1] Checking MISSING value's dis 
		- NULL
		- empty string 
		- '0'
*/

-- [1].1 NULL Value 

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

/* Conclusion of [1].1
There are two columns containing NULL value: "Description" and "CustomerID".
*/


-- [1].2 Checking empty string '' Value

WITH emt AS (
  SELECT
    SUM(CASE WHEN invoice_no = '0' OR invoice_no = '' THEN 1 ELSE 0 END) AS InvoiceNo_empty_string_count,
    SUM(CASE WHEN stock_code = '0' OR stock_code = '' THEN 1 ELSE 0 END) AS StockCode_empty_string_count,
    SUM(CASE WHEN description = '0' OR description = '' THEN 1 ELSE 0 END) AS Description_empty_string_count,
    SUM(CASE WHEN quantity = '0' OR quantity = '' THEN 1 ELSE 0 END) AS Quantity_empty_string_count,
    SUM(CASE WHEN unit_price = '0' OR unit_price = '' THEN 1 ELSE 0 END) AS UnitPrice_empty_string_count,
    SUM(CASE WHEN customer_id = '0' OR customer_id = '' THEN 1 ELSE 0 END) AS CustomerID_empty_string_count,
    SUM(CASE WHEN country = '0' OR country = '' THEN 1 ELSE 0 END) AS Country_empty_string_count
FROM online_retail_2009_2010
UNION ALL
    SELECT
    SUM(CASE WHEN invoice_no = '0' OR invoice_no = '' THEN 1 ELSE 0 END) AS InvoiceNo_empty_string_count,
    SUM(CASE WHEN stock_code = '0' OR stock_code = '' THEN 1 ELSE 0 END) AS StockCode_empty_string_count,
    SUM(CASE WHEN description = '0' OR description = '' THEN 1 ELSE 0 END) AS Description_empty_string_count,
    SUM(CASE WHEN quantity = '0' OR quantity = '' THEN 1 ELSE 0 END) AS Quantity_empty_string_count,
    SUM(CASE WHEN unit_price = '0' OR unit_price = '' THEN 1 ELSE 0 END) AS UnitPrice_empty_string_count,
    SUM(CASE WHEN customer_id = '0' OR customer_id = '' THEN 1 ELSE 0 END) AS CustomerID_empty_string_count,
    SUM(CASE WHEN country = '0' OR country = '' THEN 1 ELSE 0 END) AS Country_empty_string_count
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

/* Conclusion of [1].2
There is only UnitPrice column contain empty_string value with 9921 cells.
*/


-- [1].3 Checking '0' Value

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

/* Conclusion of [1].3
There is only UnitPrice column contain '0' value with 9921 cells
--> Let's explore the meaning of these '0' values of UnitPrice column
*/



/* [2] Checking Invalid Data
		- Negative value in "Quantity" column - NEGATIVE QUANTITY / POSITIVE QUANTITY
		- The negative and '0' value in "UnitPrice" column - NEGATIVE UNITPRICE / 0 UNITPRICE
*/

-- [2].1 Checking negative value in Quantity column - NEGATIVE QUANTITY

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

-- [2].2 








