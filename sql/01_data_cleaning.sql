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

--4) Checking for missing values
SELECT count(*) AS total_rows,
       sum(CASE WHEN [Transaction ID] IS NULL THEN 1 ELSE 0 END) AS missing_transaction_ID,
       sum(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS missing_category,
       sum(CASE WHEN Item IS NULL THEN 1 ELSE 0 END) AS missing_item,
       sum(CASE WHEN [Price Per Unit] IS NULL THEN 1 ELSE 0 END) AS missing_price_per_unit,
       sum(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS missing_quantity,
       sum(CASE WHEN [Total spent] IS NULL THEN 1 ELSE 0 END) AS missing_total_spent,
       sum(CASE WHEN [Payment Method] IS NULL THEN 1 ELSE 0 END) AS missing_payment_method,
       sum(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS missing_location,
       sum(CASE WHEN [Transaction Date] IS NULL THEN 1 ELSE 0 END) AS missing_transaction_date,
       sum(CASE WHEN [Discount Applied] IS NULL THEN 1 ELSE 0 END) AS missing_discount_applied
FROM   raw_retail_stores_sales;

--5) Checking for duplicate Transaction_ID values
SELECT   [Transaction ID],
         COUNT(*) AS transaction_count
FROM     raw_retail_stores_sales
GROUP BY [Transaction ID]
HAVING   COUNT(*) > 1;

--6) Reviewing distinct values in categorical columns

SELECT DISTINCT Category
FROM   raw_retail_stores_sales;

SELECT DISTINCT [Payment method]
FROM   raw_retail_stores_sales;

SELECT DISTINCT Location
FROM   raw_retail_stores_sales;

--7) Checking numerical ranges

SELECT min([Price per unit]),
       max([Price per unit]),
       min(Quantity),
       max(Quantity),
       min([Total spent]),
       max([Total spent])
FROM   raw_retail_stores_sales;

--8) Checking for negative numerical values

SELECT *
FROM   raw_retail_stores_sales
WHERE  [Price per unit] < 0
       OR Quantity < 0
       OR [Total spent] < 0;

--9) Investigating rows with missing Price_per_unit & Quantity

SELECT *
FROM   raw_retail_stores_sales
WHERE  [Price per unit] IS NULL
       OR Quantity IS NULL;

--10) Investigating whether Discount_applied affects Total_spent
SELECT *
FROM   (SELECT TOP 50 [Transaction ID],
                      Item,
                      [Price per unit],
                      Quantity,
                      [Discount applied],
                      [Total spent],
                      ([Price per unit] * Quantity) AS calculated_price
        FROM   raw_retail_stores_sales
        WHERE  [Price per unit] IS NOT NULL
               AND Quantity IS NOT NULL
               AND [Total spent] IS NOT NULL) AS a
WHERE  [Discount applied] = 1;

SELECT COUNT(*) AS mismatches
FROM   raw_retail_stores_sales
WHERE  [Price per unit] IS NOT NULL AND Quantity IS NOT NULL AND [Total spent] IS NOT NULL
       AND ABS([Price per unit] * Quantity - [Total spent]) > 0.01;

--11) Creating the cleaned table and recovering Price_per_unit or Quantity where possible

SELECT [Transaction ID] AS Transaction_ID,
       [Customer ID] AS Customer_ID,
       Category,
       Item,
       (CASE WHEN [Price per unit] IS NULL
                  AND Quantity IS NOT NULL
                  AND [Total spent] IS NOT NULL THEN [Total spent] / NULLIF (quantity, 0) ELSE [Price per unit] END) AS Price_per_unit,
       (CASE WHEN Quantity IS NULL
                  AND [Price per unit] IS NOT NULL
                  AND [Total spent] IS NOT NULL THEN [Total spent] / NULLIF ([Price per unit], 0) ELSE Quantity END) AS Quantity,
       (CASE WHEN [Total spent] IS NULL
                  AND [Price per unit] IS NOT NULL
                  AND Quantity IS NOT NULL THEN [Price per unit] * Quantity ELSE [Total spent] END) AS Total_spent,
       [Payment method] AS Payment_method,
       Location,
       [Transaction date] AS Transaction_date,
       [Discount applied] AS Discount_applied
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



  