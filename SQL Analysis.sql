-- Sales Performance & Revenue:
-- What are total sales, revenue, and average order value over time (daily / monthly / seasonal)?
-- Which products and categories generate the highest revenue and volume?
-- How does discounting impact revenue and quantity sold? (Do higher discounts actually increase net revenue?)
-- What percentage of sales come from discounted vs full-price items?
-- Which stores have the highest revenue per square meter (size_m2)?

-- Product & Merchandising Insights:
-- Which categories, colors, and sizes sell best? (Critical for fashion inventory planning.)
-- Which products have the largest gap between list price and actual selling price?
-- What is the sell-through performance by season (Spring/Summer/Fall/Winter)?
-- Which suppliers contribute the most to revenue—and which to returns?
-- Are there products with high sales volume but low profitability due to discounting?

-- Customer Behavior & Segmentation:
-- Who are our most valuable customers (by total spend and purchase frequency)?
-- How does purchasing behavior differ by age group and gender?
-- What is the repeat purchase rate across customer segments?
-- Which cities generate the highest revenue per customer?
-- Do younger customers respond more to discounts than older age groups?

-- Returns & Quality Signals:
-- What is the return rate by product, category, and supplier?
-- Are certain sizes or colors returned more frequently than others?
-- How do returns affect net revenue by store and product category?

-- Store Performance:
-- Which stores outperform or underperform relative to their size (m²)?
-- How does product mix differ across stores, and does it align with local customer demographics?


-- 1. What are total sales, revenue, and average order value over time (daily / monthly / seasonal)?

SELECT
SUM(order_price) AS total_sales,
ROUND(SUM(total_returned_sales)- SUM(item_price)) AS total_revenue,
ROUND(AVG(order_price)) AS AOV,
p.season
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY p.season;

SELECT
SUM(order_price) AS total_sales,
ROUND(SUM(total_returned_sales)- SUM(item_price)) AS total_revenue,
ROUND(AVG(order_price)) AS AOV,
days
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY days
ORDER BY days;

SELECT
SUM(order_price) AS total_sales,
ROUND(SUM(total_returned_sales)- SUM(item_price))) AS total_revenue,
ROUND(AVG(order_price)) AS AOV,
months
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY months
ORDER BY months;



-- 2. Which products and categories generate the highest revenue and volume?


SELECT 
ROUND(SUM(order_price) - SUM(item_price)) AS total_revenue_per_product,
COUNT(s.product_id) AS total_volume_per_product,
s.product_id,
category
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY product_id, category
ORDER BY total_volume_per_product DESC;



-- 3. How does discounting impact revenue and quantity sold? (Do higher discounts actually increase net revenue?)



SELECT
ROUND(SUM(order_price_after_discount)) total_revenue,
SUM(quantity) total_items,
discount
FROM sales
GROUP BY discount
ORDER BY total_revenue DESC , total_items DESC;




-- 4. What percentage of sales come from discounted vs full-price items?

SELECT 
ROUND(SUM(order_price_after_discount)) AS total_sales_after_discount,
SUM(order_price) AS total_sales,
ROUND((SUM(order_price_after_discount)/SUM(order_price)) * 100,1) AS discount_percentage
FROM sales;



-- 5. Which stores have the highest revenue per square meter (size_m2)?

SELECT
s.site_id,
ROUND(SUM(order_price_after_discount)) AS total_sales_after_discount,
ROUND(SUM(order_price_after_discount) / size_m2) AS total_revenue_per_m2,
size_m2
FROM sales s
JOIN stores st
	ON s.site_id = st.site_id
GROUP BY s.site_id, size_m2;


-- 6. Which categories, colors, and sizes sell best? (Critical for fashion inventory planning.)

SELECT
COUNT(*) number_of_orders,
category,
color,
size
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY category, color, size
ORDER BY number_of_orders DESC;



-- 7. Which products have the largest gap between list price and actual selling price?


SELECT
*,
ROUND((list_item_price - item_price),2) AS price_gap
FROM products
ORDER BY price_gap DESC;


-- 8. What is the sell-through performance by season (Spring/Summer/Fall/Winter)?


-- 8. Which suppliers contribute the most to revenue—and which to returns?


SELECT
ROUND(SUM(total_returned_sales)) AS total_revenue,
SUM(returned) AS total_returns,
supplier
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY supplier
ORDER BY total_revenue DESC, total_returns DESC;

-- 9. Are there products with high sales volume but low profitability due to discounting?

SELECT
s.product_id,
COUNT(*) AS number_of_orders,
SUM(order_price) AS sales_pre_discount,
ROUND(SUM(order_price_after_discount),2) AS profitability,
ROUND(SUM(order_price) - SUM(order_price_after_discount)) AS total_discount_price,
ROUND(((SUM(order_price) - SUM(order_price_after_discount)) / SUM(order_price)) * 100,2) AS loss_percentage
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
WHERE discount > 0
GROUP BY s.product_id
ORDER BY number_of_orders DESC, total_discount_price DESC;


-- Who are our most valuable customers (by total spend and purchase frequency)?


SELECT 
s.customer_id,
SUM(order_price) total_spent,
COUNT(*) number_of_orders
FROM sales s
JOIN customers c
	ON s.customer_id = c.customer_id
WHERE s.customer_id != 'Unknown'
GROUP BY customer_id
ORDER BY total_spent DESC, number_of_orders DESC





-- How does purchasing behavior differ by age group and gender?

SELECT
age_group,
gender,
SUM(order_price) AS total_spent,
COUNT(*) AS number_of_orders
FROM customers c
JOIN sales s
	ON c.customer_id = s.customer_id
WHERE age IS NOT NULL 
	AND
	  gender IS NOT NULL
GROUP BY age_group, gender
ORDER BY number_of_orders DESC, total_spent DESC;

-- What is the repeat purchase rate across customer segments?

WITH repeat_customers AS (
SELECT
transaction_id,
c.customer_id, 
LAG(dates, 1) OVER(PARTITION BY customer_id ORDER BY customer_id) AS previous_purchase_date,
ROW_NUMBER() OVER(PARTITION BY customer_id) AS ranking
FROM customers c
JOIN sales s
	ON c.customer_id = s.customer_id
)
SELECT
age_group,
gender,
COUNT(*) AS number_of_orders
FROM repeat_customers rc
JOIN customers c
	ON rc.customer_id = c.customer_id
WHERE ranking > '2' 
	AND
	 age_group IS NOT NULL
	AND
	 gender IS NOT NULL
GROUP BY age_group, gender
ORDER BY number_of_orders DESC;


-- Which cities generate the highest revenue per customer?

SELECT
city,
s.customer_id,
ROUND(SUM(order_price_after_discount) - SUM(item_price)) AS total_revenue_per_customer
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
JOIN customers c
	ON s.customer_id = c.customer_id
WHERE city IS NOT NULL
GROUP BY city, s.customer_id
ORDER BY city;

-- Do younger customers respond more to discounts than older age groups?

SELECT
age_group,
COUNT(*) AS number_of_orders
FROM customers c
JOIN sales s
	ON c.customer_id = s.customer_id
WHERE discount > '0'
	AND
      age_group IS NOT NULL
GROUP BY age_group
ORDER BY number_of_orders DESC;

-- Returns & Quality Signals:
-- What is the return rate by product, category, and supplier?
WITH return_rate AS (
SELECT
s.product_id,
category,
supplier,
COUNT(*) AS number_of_returns
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
WHERE returned = '1'
GROUP BY s.product_id, category, supplier
), number_of_orders AS (
SELECT
COUNT(*) total_number_of_orders
FROM sales
)
SELECT
product_id,
category,
supplier,
ROUND((number_of_returns / total_number_of_orders) * 100,2) AS return_rate
FROM return_rate 
JOIN number_of_orders
ORDER BY return_rate DESC;

-- Are certain sizes or colors returned more frequently than others?

SELECT
color,
size,
COUNT(*) AS number_of_returns
FROM products p
JOIN sales s
	ON p.product_id = s.product_id
WHERE returned = '1'
GROUP BY color, size
ORDER BY number_of_returns DESC;


-- How do returns affect net revenue by store and product category?
WITH returned_price AS (
SELECT
site_id,
category,
ROUND(SUM(order_price_after_discount)) AS returned_revenue
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
WHERE returned = '1'
GROUP BY site_id, category
),
total_revenue AS (
SELECT
site_id,
category,
ROUND(SUM(order_price_after_discount)) AS total_revenue
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
GROUP BY site_id, category
)
SELECT
rp.site_id,
rp.category,
total_revenue,
returned_revenue,
total_revenue - returned_revenue AS revenue_gap
FROM returned_price rp
JOIN total_revenue tr
	ON rp.site_id = tr.site_id
ORDER BY revenue_gap DESC










