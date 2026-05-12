-- =============================================
-- Supply Chain Database — Analysis Queries (20+)

-- 1 Count records in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders;

-- 2 Total overall revenue
SELECT 
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id;

-- 3 Revenue by year (YoY trend analysis)
SELECT 
    YEAR(o.order_date) AS order_year,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units_sold,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue,
    ROUND(AVG(o.quantity * p.unit_price), 2) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY YEAR(o.order_date)
ORDER BY order_year;

-- 4 Monthly revenue breakdown
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    MONTHNAME(o.order_date) AS month_name,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS monthly_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date), MONTHNAME(o.order_date)
ORDER BY year, month;

-- 5 Top 5 products by revenue
SELECT 
    p.product_name,
    p.category,
    SUM(o.quantity) AS total_units_sold,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 5;

-- 6 Category wise revenue analysis
SELECT 
    p.category,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units_sold,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue,
    ROUND(SUM(o.quantity * p.unit_price) * 100.0 / 
        (SELECT SUM(o2.quantity * p2.unit_price) 
         FROM orders o2 
         JOIN products p2 ON o2.product_id = p2.product_id), 2) AS revenue_percentage
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 7 Supplier wise revenue and order analysis
SELECT 
    s.supplier_name,
    s.rating AS supplier_rating,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units_supplied,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue_generated
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.supplier_name, s.rating
ORDER BY total_revenue_generated DESC;

-- 8 Most valuable customers
SELECT 
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_items_bought,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_spent
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_spent DESC
LIMIT 5;

-- 9 How many orders each customer placed
SELECT 
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS number_of_orders,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_spent,
    ROUND(AVG(o.quantity * p.unit_price), 2) AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY number_of_orders DESC;

-- 10 Products with stock below 100 units
SELECT 
    p.product_name,
    p.category,
    p.stock_quantity,
    s.supplier_name,
    s.contact_email
FROM products p
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.stock_quantity < 100
ORDER BY p.stock_quantity ASC;

-- 11 Products generating above average revenue
SELECT 
    product_name,
    category,
    total_revenue
FROM (
    SELECT 
        p.product_name,
        p.category,
        ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category
) AS product_revenue
WHERE total_revenue > (
    SELECT AVG(total_rev) FROM (
        SELECT SUM(o.quantity * p.unit_price) AS total_rev
        FROM orders o
        JOIN products p ON o.product_id = p.product_id
        GROUP BY p.product_id
    ) AS avg_table
)
ORDER BY total_revenue DESC;

-- 12 Customers who spent more than average customer spending
SELECT 
    customer_name,
    city,
    total_spent
FROM (
    SELECT 
        c.customer_name,
        c.city,
        ROUND(SUM(o.quantity * p.unit_price), 2) AS total_spent
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON o.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name, c.city
) AS customer_spending
WHERE total_spent > (
    SELECT AVG(total_s) FROM (
        SELECT SUM(o.quantity * p.unit_price) AS total_s
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN products p ON o.product_id = p.product_id
        GROUP BY c.customer_id
    ) AS avg_spend
)
ORDER BY total_spent DESC;

-- 13 Average delivery time per supplier
SELECT 
    s.supplier_name,
    ROUND(AVG(DATEDIFF(o.delivery_date, o.order_date)), 1) AS avg_delivery_days,
    MIN(DATEDIFF(o.delivery_date, o.order_date)) AS fastest_delivery,
    MAX(DATEDIFF(o.delivery_date, o.order_date)) AS slowest_delivery
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY avg_delivery_days ASC;

-- 14 Revenue contribution by customer city
SELECT 
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.city
ORDER BY total_revenue DESC;

-- 15 Quarterly revenue breakdown
SELECT 
    YEAR(o.order_date) AS year,
    QUARTER(o.order_date) AS quarter,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS quarterly_revenue,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY YEAR(o.order_date), QUARTER(o.order_date)
ORDER BY year, quarter;

-- 16 UPDATE: Apply 10% discount on Electronics products
UPDATE products 
SET unit_price = ROUND(unit_price * 0.90, 2)
WHERE category = 'Electronics';

-- Validate the update
SELECT product_name, category, unit_price 
FROM products 
WHERE category = 'Electronics';

-- ROLLBACK price update
UPDATE products 
SET unit_price = ROUND(unit_price / 0.90, 2)
WHERE category = 'Electronics';

-- 17 Stored Procedure to get customer order summary
DELIMITER $$

CREATE PROCEDURE GetCustomerReport(IN cust_id INT)
BEGIN
    SELECT 
        c.customer_name,
        c.city,
        COUNT(o.order_id) AS total_orders,
        ROUND(SUM(o.quantity * p.unit_price), 2) AS total_spent,
        MAX(o.order_date) AS last_order_date
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON o.product_id = p.product_id
    WHERE c.customer_id = cust_id
    GROUP BY c.customer_name, c.city;
END$$

DELIMITER ;

-- Call the procedure
CALL GetCustomerReport(1);
CALL GetCustomerReport(5);

-- 18 Stored Procedure for yearly revenue report
DELIMITER $$

CREATE PROCEDURE GetYearlyRevenue(IN input_year INT)
BEGIN
    SELECT 
        YEAR(o.order_date) AS year,
        COUNT(o.order_id) AS total_orders,
        ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE YEAR(o.order_date) = input_year
    GROUP BY YEAR(o.order_date);
END$$

DELIMITER ;

-- Call for each year
CALL GetYearlyRevenue(2022);
CALL GetYearlyRevenue(2023);

-- 19 Do higher rated suppliers generate more revenue?
SELECT 
    s.supplier_name,
    s.rating,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.quantity * p.unit_price), 2) AS total_revenue,
    CASE 
        WHEN s.rating >= 4.5 THEN 'Excellent'
        WHEN s.rating >= 4.0 THEN 'Good'
        WHEN s.rating >= 3.5 THEN 'Average'
        ELSE 'Poor'
    END AS performance_category
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.supplier_name, s.rating
ORDER BY s.rating DESC;

-- 20 Complete business summary dashboard
SELECT 'Total Customers' AS metric, COUNT(*) AS value FROM customers
UNION ALL
SELECT 'Total Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Total Products', COUNT(*) FROM products
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Total Revenue (INR)', 
    ROUND(SUM(o.quantity * p.unit_price), 2)
FROM orders o JOIN products p ON o.product_id = p.product_id
UNION ALL
SELECT 'Avg Order Value (INR)',
    ROUND(AVG(o.quantity * p.unit_price), 2)
FROM orders o JOIN products p ON o.product_id = p.product_id;