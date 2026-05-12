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
-- Result: 34,335 duplicate rows, the maximum numbers of repetition is 20, and the minimum is 2.

/* Conclusion of [1]
These complete duplicate rows should be deleted because they may reduce the accuracy on calculation of the total order quantity and total sales amount and cause the interference of inflated data on decision-making.
*/

-- [1].1 Deleting duplicate rows
CREATE TABLE online_retail_clean AS
SELECT DISTINCT *
FROM combined_online_retail;

SELECT COUNT(*) FROM online_retail_clean;


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
FROM online_retail_clean;
-- Result: There is only UnitPrice column contain '0' value with 6,032 cells.

/* Conclusion of [2].1
'0' values cannot represent the purchase behavior from customers.These are the outliers which may cause the pull-down of average sales price in the product analysis.So these values should be excluded in the query.
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
FROM online_retail_clean;

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
FROM online_retail_clean;
-- Result: 4,275 cells with empty string in Description column and 235,151 cells with empty string in CustomerID column.

/* Conclusion of [2].3
For Description column,the empty string has no effect on the following analysis,while in CustomerID column should be excluded in the analysis with RFM Model. 
*/

-- [2].4 Changing empty string '' into NULL value 
DROP TABLE IF EXISTS online_retail;

CREATE TABLE online_retail AS
SELECT
  invoice_no,
  stock_code,
  NULLIF(TRIM(description), '') AS description,
  quantity,
  invoice_date,
  unit_price,
  NULLIF(TRIM(customer_id), '') AS customer_id,
  country
FROM online_retail_clean;



/* [3] Checking Invalid Data
		- Negative value in "Quantity" and "UnitPrice" column
		- Non-product data
*/

-- [3].a Checking negative value in Quantity column
SELECT *
FROM online_retail
WHERE quantity < 0;
-- There are 22,496 rows including negative values in Quantity column
-- Most of them are canceled orders because invoice number begins with letter 'C',but some of them shows '0' value in "UnitPrice" column while there are no letter 'C' amongst these invoice numbers.

-- [3].b Checking negative value in Quantity together win C InvoiceNo - NEGATIVE QUANTITY - CANCELLATION
SELECT *
FROM online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result: 19,103 rows of cancellation

-- [3].c Checking negative value in Quantity together without C InvoiceNo - NEGATIVE QUANTITY - TEST
SELECT *
FROM online_retail
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%';
/* Result: there are 3,393 associated rows. 
It is clear to see that all these rows have '0' value at associated cells in "UnitPrice" column and all invoice numbers have no letter "C" at the begnning.
As description shows the status of products,like discolored,damaged,missing,wet,test and etc,so the author assumed that all these rows are the inventory adjustment. 
-> We can exclude these rows in product analysis dashboard.

--------------------------------------------------------------------------------------

-- [3].d Checking negative value in Unitprice column
SELECT *
FROM online_retail
WHERE unit_price < 0;
---Result: 5 rows
/* Conclusion of [3].d
These rows show the adjustment of bad debt,so they should be excluded in the SQL query.
Invoice number begins with letter 'A',which is different from canceled orders,so it need to be further checked.
*/

-- [3].e InvoiceNo starts with letter A
SELECT *
FROM online_retail
WHERE unit_price < 0;
---Result: 6 rows
/* Conclusion of [3].e
There is 1 special row that unitprice shows positive.So it should be ruled out in the calculation of sales view.
Stock code shows letter 'B',which is different from common codes.
*/

-- [3].f Checking non-product data
As previously mentioned,stock code 'B' is not the usual code,so we need to check non-product data.
In this dataset,most stock codes are divided into 5 numbers even some of them include 1 letter additionally.So stock codes usually contain 5 or 6 digits that 5 numbers or 5 numbers plus 1 letter.
However,part of stock codes are different,like 'B','S','Test001' and etc.
So the auther summerize all non-product codes stored in excel file to avoid the noise during the calculation of revenue.

--------------------------------------------------------------------------------------

-- Conclusion of SALE VIEW from initial EDA
SELECT * 
FROM online_retail
WHERE quantity > 0 AND unit_price > 0 AND stock_code <> 'B';
-- Result: 1,007,895 associated rows.

-- Conclusion of CANCELLATION VIEW from initial EDA
SELECT *
FROM online_retail
WHERE quantity < 0 AND invoice_no LIKE 'C%';
-- Result: 19,103 rows

-- Conclusion of Non-product VIEW from initial EDA
SELECT *
FROM online_retail
WHERE stock_code IN (
    'Test001','Test002','S','PADS','Post','M',
    'Gift_0001_90','Gift_0001_80','Gift_0001_70','Gift_0001_60',
    'Gift_0001_50','Gift_0001_40','Gift_0001_30','Gift_0001_20',
    'Gift_0001_10','Gift','DOT','D',
    'CRUK','C2','C3','BANK CHARGES','B','AMAZONFEE',
    'ADJUST2','ADJUST'
);
-- Result: 5,820 rows








