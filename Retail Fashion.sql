CREATE DATABASE RFD;
USE RFD;

CREATE TABLE Sales1 (
transaction_id VARCHAR(225),
dates VARCHAR(225),
product_id VARCHAR(225),
site_id VARCHAR(225),
customer_id VARCHAR(225),
quantity INT,
discount DOUBLE,
returned INT
);

CREATE TABLE products (
product_id VARCHAR(225),
category VARCHAR(225),
color VARCHAR(225),
size VARCHAR(225),
season VARCHAR(225),
supplier VARCHAR(225),
item_price DOUBLE,
list_item_price DOUBLE
);

CREATE TABLE customers (
customer_id VARCHAR(225),
age INT,
gender VARCHAR(225),
city VARCHAR(225),
email VARCHAR(225)
);

CREATE TABLE stores (
site_id VARCHAR(225),
store_name VARCHAR(225),
region VARCHAR(225),
size_m2 VARCHAR(225)
);

-- Creating tables to load data into

LOAD DATA INFILE 'sales_data.csv'
INTO TABLE Sales
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE 'product_data.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE 'customer_data.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE 'store_data.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

-- Loading data 

SELECT *
FROM Sales;

-- Validating which date formats are in dataset

SELECT
CASE WHEN 
dates REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'yyyy-mm-dd'
ELSE 'other'
END AS date_format,
COUNT(*) AS format_Count
FROM Sales
GROUP BY date_format;

-- Date format is unified

WITH date_format_ratio AS (
SELECT
CASE 
WHEN (CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(dates,"-",-2),"-",1) AS UNSIGNED)) > 12
	THEN 'dd/mm'
WHEN(CAST(SUBSTRING_INDEX(dates,"-",-1) AS UNSIGNED)) > 12
	THEN 'mm/dd'
ELSE 'ambiguous' END AS ambiguous_dates,
COUNT(*) AS format_count
FROM sales
GROUP BY ambiguous_dates
)
SELECT
*,
ROUND((format_count / 50000) * 100,2) AS date_format_percentage
FROM date_format_ratio;

-- 60.46% - mm/dd
-- 39.54% - ambiguous
-- Since only mm/dd was found, safe to say this is the format of the data.

ALTER TABLE sales
MODIFY COLUMN dates DATE;

SELECT 
*
FROM sales
WHERE dates IS NULL;

-- Changed column type to DATE and validated all values converted without issues

SELECT
COUNT(DISTINCT transaction_id)
FROM sales;

-- Transaction_id is only column with all unique values

WITH duplicate_purge AS (
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY dates, product_id, site_id, customer_id) AS duplicates
FROM Sales
)
SELECT *
FROM duplicate_purge
WHERE duplicates > 1;

-- No duplicate rows

SELECT 
COUNT(DISTINCT product_id)
FROM sales;

SELECT 
*
FROM Sales
WHERE customer_id IN(NULL, " ", "", 'N/A', 'NA') 
	OR
	  returned IN(NULL, " ", "", 'N/A', 'NA')
      OR
	  discount IN(NULL, " ", "", 'N/A', 'NA')
LIMIT 0, 100000;

SELECT
*
FROM Sales
WHERE customer_id IN(NULL, " ", "", 'N/A', 'NA')
LIMIT 0, 100000;

-- 1844 empty customer_id rows, if we had order_id's in customers table we could populate some of this, however we do not.

UPDATE sales
SET customer_id = 'Unknown'
WHERE customer_id IN(NULL, " ", "", 'N/A', 'NA');

-- Removed null values

SELECT
DISTINCT site_id
FROM Sales;

SELECT
*
FROM Sales
WHERE site_id = 'S999';

-- 200 rows with non-existing store ID

UPDATE SALES 
SET site_id = 'Unknown'
WHERE site_id = 'S999';


SELECT 
COUNT(DISTINCT product_id)
FROM products
LIMIT 0, 100000;

-- product_id row has only unique values

SELECT *
FROM products
WHERE product_id IS NULL;

SELECT
DISTINCT supplier
FROM products;

SELECT *
FROM products
WHERE category = '???';

-- ~500 rows of unknown category 

UPDATE products
SET category = 'Other'
WHERE category = '???';

SELECT *
FROM products
WHERE color = '';

-- ~1000 rows with empty color rows

UPDATE products
SET color = 'Unknown'
WHERE color = '';

SELECT *
FROM products
WHERE item_price IN(NULL, " ", "", 'N/A', 'NA');

SELECT *
FROM products
WHERE list_item_price IN(NULL, " ", "", 'N/A', 'NA');

SELECT 
COUNT(DISTINCT customer_id)
FROM customers;

-- customer_id has only unique values

SELECT
DISTINCT age
FROM customers
ORDER BY age;

SELECT 
*
FROM customers
WHERE gender = '???';

-- ~ 300 unknown gender rows

UPDATE customers
SET gender = 'Not Disclosed' 
WHERE gender = '???';

SELECT 
*
FROM customers
WHERE email IN(NULL, " ", "", 'N/A', 'NA');

-- ~ 496 empty email rows

UPDATE customers
SET email = 'Unknown'
WHERE email = '';

SELECT 
COUNT(DISTINCT site_id)
FROM stores

-- site_id has only unique values

SELECT 
*
FROM stores


-- Adding primary/foreign keys and prepping dataset for data modeling & analysis in BI software

ALTER TABLE stores 
ADD PRIMARY KEY (site_id);

ALTER TABLE customers 
ADD PRIMARY KEY (customer_id);

ALTER TABLE products 
ADD PRIMARY KEY (product_id);

ALTER TABLE sales 
ADD PRIMARY KEY (transaction_id);

INSERT INTO stores (site_id)
VALUES ('Unknown');

ALTER TABLE sales 
ADD CONSTRAINT fk_site_id
FOREIGN KEY (site_id) REFERENCES stores(site_id);

ALTER TABLE sales 
ADD CONSTRAINT fk_product_id
FOREIGN KEY (product_id) REFERENCES products(product_id);

INSERT INTO customers (customer_id)
VALUES ('Unknown');

ALTER TABLE sales 
ADD CONSTRAINT fk_customer_id
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- Adding a couple of columns required for an in-depth analysis


ALTER TABLE customers
ADD COLUMN age_group VARCHAR(225);

UPDATE customers
SET age_group = 
CASE 
	WHEN age < '18' THEN 'Teenager'
    WHEN age BETWEEN '18' AND '30' THEN 'Young Adult'
    WHEN age BETWEEN '31' AND '45' THEN 'Middle Aged Adult'
    WHEN age BETWEEN '46' AND '55' THEN 'Adult'
    WHEN age > '55' THEN 'Senior Citizen'
    END;
    
 -- adding age groups
 
ALTER TABLE sales
ADD COLUMN order_price INT;

UPDATE sales s
JOIN products p
	ON p.product_id = s.product_id
SET order_price = ROUND(list_item_price * quantity);

SELECT 
*
FROM sales;

SELECT 
*
FROM products
WHERE product_id = 'P004681';

-- adding order price and validating the result

ALTER TABLE sales
ADD COLUMN order_price_after_discount DOUBLE;

UPDATE sales
SET order_price_after_discount = 
ROUND(order_price - (order_price * discount),2);

-- adding total price after applied discount

ALTER TABLE sales
ADD COLUMN total_returned_sales DOUBLE;

UPDATE sales
SET total_returned_sales = order_price_after_discount;

UPDATE sales
SET total_returned_sales =
total_returned_sales * '0'
WHERE returned = '1'

-- adding total revenue after refunds 
