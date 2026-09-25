--1) Querying imported data
SELECT *
FROM   raw_retail_stores_sales;

--2) Checking the number of rows
SELECT count(*)
FROM   raw_retail_stores_sales;

--3) Checking column names, no of columns and data types
SELECT *
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  table_name = 'raw_retail_stores_sales';

--4)  Renaming column names for consistency
EXECUTE sp_rename 'raw_retail_stores_sales.[Transaction ID]', 'Transaction_ID', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Customer ID]', 'Customer_ID', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Price Per Unit]', 'Price_per_unit', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Total spent]', 'Total_spent', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Payment Method]', 'Payment_method', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Transaction Date]', 'Transaction_date', 'COLUMN';

EXECUTE sp_rename 'raw_retail_stores_sales.[Discount Applied]', 'Discount_applied', 'COLUMN';

--4) Checking for missing values
SELECT count(*) AS total_rows,
       sum(CASE WHEN Transaction_ID IS NULL THEN 1 ELSE 0 END) AS missing_transaction_ID,
       sum(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS missing_category,
       sum(CASE WHEN Item IS NULL THEN 1 ELSE 0 END) AS missing_item,
       sum(CASE WHEN Price_per_unit IS NULL THEN 1 ELSE 0 END) AS missing_price_per_unit,
       sum(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS missing_quantity,
       sum(CASE WHEN Total_spent IS NULL THEN 1 ELSE 0 END) AS missing_total_spent,
       sum(CASE WHEN Payment_method IS NULL THEN 1 ELSE 0 END) AS missing_payment_method,
       sum(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS missing_location,
       sum(CASE WHEN Transaction_date IS NULL THEN 1 ELSE 0 END) AS missing_transaction_date,
       sum(CASE WHEN Discount_applied IS NULL THEN 1 ELSE 0 END) AS missing_discount_applied
FROM   raw_retail_stores_sales;

--5) Checking for duplicate Transaction_ID values
SELECT   Transaction_ID,
         COUNT(*) AS transaction_count
FROM     raw_retail_stores_sales
GROUP BY Transaction_ID
HAVING   COUNT(*) > 1;

--6) Reviewing distinct values in categorical columns

SELECT DISTINCT Category
FROM   raw_retail_stores_sales;

SELECT DISTINCT Payment_method
FROM   raw_retail_stores_sales;

SELECT DISTINCT Location
FROM   raw_retail_stores_sales;

--7) Checking numerical ranges

SELECT min(Price_per_unit),
       max(Price_per_unit),
       min(Quantity),
       max(Quantity),
       min(Total_spent),
       max(Total_spent)
FROM   raw_retail_stores_sales;

--8) Checking for negative numerical values

SELECT *
FROM   raw_retail_stores_sales
WHERE  Price_per_unit < 0
       OR Quantity < 0
       OR Total_spent < 0;

--9) Investigating rows with missing Price_per_unit & Quantity

SELECT *
FROM   raw_retail_stores_sales
WHERE  Price_per_unit IS NULL
       OR Quantity IS NULL;

--10) Investigating whether Discount_applied affects Total_spent
SELECT *
FROM   (SELECT TOP 50 Transaction_ID,
                      Item,
                      Price_per_unit,
                      Quantity,
                      Discount_applied,
                      Total_spent,
                      (Price_per_unit * Quantity) AS calculated_price
        FROM   raw_retail_stores_sales
        WHERE  Price_per_unit IS NOT NULL
               AND Quantity IS NOT NULL
               AND Total_spent IS NOT NULL) AS a
WHERE  Discount_applied = 1;

--11) Creating the cleaned table and recovering Price_per_unit or Quantity where possible

SELECT Transaction_ID,
       Customer_ID,
       Category,
       Item,
       (CASE WHEN Price_per_unit IS NULL
                  AND Quantity IS NOT NULL
                  AND Total_spent IS NOT NULL THEN Total_spent / NULLIF (quantity, 0) ELSE Price_per_unit END) AS Price_per_unit,
       (CASE WHEN Quantity IS NULL
                  AND Price_per_unit IS NOT NULL
                  AND Total_spent IS NOT NULL THEN Total_spent / NULLIF (Price_per_unit, 0) ELSE Quantity END) AS Quantity,
       Total_spent,
       Payment_method,
       Location,
       Transaction_date,
       Discount_applied
INTO   cleaned_retail_stores_sales
FROM   raw_retail_stores_sales;

--12) Updating data types and constraints in the cleaned table

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Transaction_ID VARCHAR (50) NOT NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Customer_ID VARCHAR (50) NOT NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Category VARCHAR (50) NOT NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Total_spent DECIMAL (10, 2) NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Payment_method VARCHAR (50) NOT NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Location VARCHAR (50) NOT NULL;

ALTER TABLE cleaned_retail_stores_sales 
ALTER COLUMN Transaction_date DATE NOT NULL;

-- 13) Adding primary key to uniquely identify each transaction

ALTER TABLE cleaned_retail_stores_sales
ADD CONSTRAINT PK_cleaned_retail_stores_sales PRIMARY KEY (Transaction_ID);

-- 14) Final validation of cleaned data

SELECT count(*)
FROM   cleaned_retail_stores_sales;

SELECT *
FROM   cleaned_retail_stores_sales;

--15) Checking remaining missing values after cleaning

SELECT count(*) AS total_rows,
       sum(CASE WHEN Item IS NULL THEN 1 ELSE 0 END) AS missing_item,
       sum(CASE WHEN Price_per_unit IS NULL THEN 1 ELSE 0 END) AS missing_price_per_unit,
       sum(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS missing_quantity,
       sum(CASE WHEN Total_spent IS NULL THEN 1 ELSE 0 END) AS missing_total_spent,
       sum(CASE WHEN Discount_applied IS NULL THEN 1 ELSE 0 END) AS missing_discount_applied
FROM   cleaned_retail_stores_sales;



  