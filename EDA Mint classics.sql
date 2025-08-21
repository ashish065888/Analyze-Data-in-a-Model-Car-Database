-- Total distinct products in the company
SELECT COUNT(DISTINCT productName) as Number_of_products
FROM products;

-- Number of products in each product line
SELECT pl.productLine, COUNT(pd.productName) as product_count
from productlines pl
JOIN products pd ON pd.productLine = pl.productLine
GROUP BY pl.productLine
ORDER BY product_count DESC;

-- Sales Analysis

-- Total sales for each productline
SELECT p.productLine, 
SUM(od.quantityOrdered) AS TotalQuantitySold,
ROUND(SUM(od.quantityOrdered*od.priceEach)) AS TotalSales
FROM products p
JOIN orderdetails od ON od.productCode = p.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
GROUP BY productLine
ORDER BY TotalSales DESC;

-- Average monthly sales for each productLine 
With monthly_sales as
(
	SELECT pl.productLine, MONTH(o.orderDate) as month, YEAR(o.orderDate) as year, pd.quantityInStock, pd.warehouseCode,
	SUM(od.quantityOrdered ) as total_quantity, 
    SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM productlines pl
    JOIN products pd ON pd.productLine = pl.productLine
    JOIN orderDetails od ON od.productCode = pd.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    WHERE o.status in ('Shipped', 'In Process')
    GROUP BY 1,2,3,4,5
)
SELECT productLine,
ROUND(AVG(CASE WHEN year = 2005 then total_sales else null end)) as '2005_average_monthly_sales',
ROUND(AVG(CASE WHEN year = 2004 then total_sales else null end)) as '2004_average_monthly_sales',
ROUND(AVG(CASE WHEN year = 2003 then total_sales else null end)) as '2003_average_monthly_sales'
FROM monthly_sales
GROUP BY productLine
ORDER BY productLine, 2005_average_monthly_sales DESC;

-- Average Quaterly sales for each productLine
With quaterly_sales as
(
	SELECT pl.productLine, CONCAT('Q',Quarter(o.orderDate)) as quarter,
	SUM(od.quantityOrdered ) as total_quantity, 
    SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM productlines pl
    JOIN products pd ON pd.productLine = pl.productLine
    JOIN orderDetails od ON od.productCode = pd.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    WHERE o.status in ('Shipped', 'In Process')
    GROUP BY 1,2
)
SELECT productLine,
ROUND(AVG(CASE WHEN quarter = 'Q1' then total_sales else null end)) as 'Q1_average_sales',
ROUND(AVG(CASE WHEN quarter = 'Q2' then total_sales else null end)) as 'Q2_average_sales',
ROUND(AVG(CASE WHEN quarter = 'Q3' then total_sales else null end)) as 'Q3_average_sales',
ROUND(AVG(CASE WHEN quarter = 'Q4' then total_sales else null end)) as 'Q4_average_sales'
FROM quaterly_sales
GROUP BY productLine
ORDER BY productLine;

-- Top 3 ALL time best selling product from each productLine
With cte as(
SELECT pl.productLine, pd.productName,
	SUM(od.quantityOrdered ) as total_quantity, 
    SUM(od.quantityOrdered * od.priceEach) AS total_sales,
    RANK() OVER(PARTITION BY pl.productLine ORDER BY SUM(od.quantityOrdered * od.priceEach) DESC) as rnk
FROM productlines pl
JOIN products pd ON pd.productLine = pl.productLine
JOIN orderDetails od ON od.productCode = pd.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
WHERE o.status in ('Shipped', 'In Process')
GROUP BY 1,2)
SELECT * FROM cte where rnk<=3;

-- Top 3 ALL time worst selling product from each productLine
With cte as(
SELECT pl.productLine, pd.productName,
	SUM(od.quantityOrdered ) as total_quantity, 
    ROUND(SUM(od.quantityOrdered * od.priceEach)) AS total_sales,
    RANK() OVER(PARTITION BY pl.productLine ORDER BY SUM(od.quantityOrdered * od.priceEach)) as rnk
FROM productlines pl
JOIN products pd ON pd.productLine = pl.productLine
JOIN orderDetails od ON od.productCode = pd.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
WHERE o.status in ('Shipped', 'In Process')
GROUP BY 1,2)
SELECT * FROM cte where rnk<=3;

-- Monthly sales for each productLine
SELECT pl.productLine, MONTH(o.orderDate) as month,
	ROUND(SUM(CASE WHEN Year(o.orderDate)=2005 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) as '2005', 
    ROUND(SUM(CASE WHEN Year(o.orderDate)=2004 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) as '2004',
    ROUND(SUM(CASE WHEN Year(o.orderDate)=2003 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) as '2003'
FROM productlines pl
JOIN products pd ON pd.productLine = pl.productLine
JOIN orderDetails od ON od.productCode = pd.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
WHERE o.status in ('Shipped', 'In Process')
GROUP BY 1,2
ORDER BY pl.productLine, month ASC; -- Much higher sales for month of November --


-- Is the sale in the last three months higher for all the products or some particular products
With monthwise_sales as(
SELECT pl.productLine, pd.productName, MONTH(o.orderDate) as month,
    ROUND(AVG(SUM(CASE WHEN Year(o.orderDate)=2004 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) OVER(PARTITION BY pl.productLine, pd.productName)) AS '2004_average_sales',
    ROUND(SUM(CASE WHEN Year(o.orderDate)=2004 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) as '2004',
    ROUND(AVG(SUM(CASE WHEN Year(o.orderDate)=2003 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) OVER(PARTITION BY pl.productLine, pd.productName)) AS '2003_average_sales',
    ROUND(SUM(CASE WHEN Year(o.orderDate)=2003 THEN od.quantityOrdered * od.priceEach ELSE NULL END )) as '2003'
FROM productlines pl
JOIN products pd ON pd.productLine = pl.productLine
JOIN orderDetails od ON od.productCode = pd.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
WHERE o.status in ('Shipped', 'In Process')
GROUP BY 1,2,3
ORDER BY 1,2,3)
SELECT * FROM monthwise_sales
WHERE month>=10; -- Higher sales for each product in November --

-- Warehouse Analysis
-- Identify the number of different products in each warehouse and their productlines
SELECT w.warehouseName, COUNT(DISTINCT p.productName) as Number_of_products, group_concat(DISTINCT p.productLine) AS productLine
FROM products p
JOIN warehouses w ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseName;

-- Identify the total inventory in each warehouse
SELECT w.warehouseName, w.warehousePctCap AS PercentageUtilization, SUM(p.quantityInStock) AS TotalInventory
FROM warehouses w
JOIN products p ON p.warehouseCode = w.warehouseCode
GROUP BY w.warehouseName,w.warehousePctCap
ORDER BY TotalInventory DESC;

-- Identify the Revenue generated by each warehouse
SELECT w.warehouseName,
ROUND(SUM(od.quantityOrdered * od.priceEach)) AS TotalRevenue, 
SUM(od.quantityOrdered) AS TotalQuantitySold
FROM warehouses w
JOIN products p ON p.warehouseCode = w.warehouseCode
JOIN orderdetails od ON od.productCode = p.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
WHERE o.status IN ('Shipped', 'InProgress')
GROUP BY w.warehouseName
ORDER BY TotalRevenue DESC;

-- Checking if an order has multiple products from the same productline and if they are from the same warehouse
SELECT o.orderNumber, p.productName, p.productLine, w.warehouseName
FROM orders o
JOIN orderdetails od ON od.orderNumber = o.orderNumber
JOIN products p ON p.productCode = od.productCode
JOIN warehouses w ON w.warehouseCode = p.warehouseCode
WHERE o.status IN ('Shipped');
-- An order can contain multiple products from different productlines which can be from differnt warehouses

-- Finding out whether the shipping time is less if an order contains all the items from the same warehouse
SELECT o.orderNumber, DATEDIFF(o.shippedDate, o.orderDate) as shipping_days, 
count(distinct p.productCode) as no_of_products,
count(distinct p.productLine) as no_of_productlines,
COUNT(DISTINCT p.warehouseCode) as no_of_warehouses
FROM orders o
JOIN orderdetails od ON od.orderNumber = o.orderNumber
JOIN products p ON p.productCode = od.productCode
JOIN warehouses w ON w.warehouseCode = p.warehouseCode
WHERE o.status IN ('Shipped')
GROUP BY 1,2;

-- For how many months the stock will last for each product based on the average monthly quantity sold
With monthly_sales as
(
	SELECT pl.productLine, pd.productName, MONTH(o.orderDate) as month, YEAR(o.orderDate) as year, pd.quantityInStock,
	SUM(od.quantityOrdered ) as total_quantity
    FROM productlines pl
    JOIN products pd ON pd.productLine = pl.productLine
    JOIN orderDetails od ON od.productCode = pd.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    WHERE o.status in ('Shipped', 'In Process')
    GROUP BY 1,2,3,4,5
),
stock_available as
(SELECT productLine, productName, ROUND(MIN(quantityInStock)/AVG(total_quantity)) as no_of_months_stock_lasts
FROM monthly_sales
GROUP BY productLine,productName
ORDER BY productLine)
SELECT COUNT(CASE WHEN no_of_months_stock_lasts>=60 THEN 1 ELSE NULL END)*100/count(*) as percent_products
from stock_available;

-- Money that can be saved by maintaining an inventory for only 4 months based on average monthly units sold
With monthly_sales as
(
	SELECT pl.productLine, pd.productName, MONTH(o.orderDate) as month, YEAR(o.orderDate) as year, pd.quantityInStock, 
    pd.buyPrice, SUM(od.quantityOrdered ) as total_quantity
    FROM productlines pl
    JOIN products pd ON pd.productLine = pl.productLine
    JOIN orderDetails od ON od.productCode = pd.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    WHERE o.status in ('Shipped', 'In Process')
    GROUP BY 1,2,3,4,5,6
)
SELECT ROUND(SUM((AVG(quantityInStock) - 4*AVG(total_quantity))*AVG(buyprice)) OVER()) as Amount_saved
FROM monthly_sales
GROUP BY productLine,productName
ORDER BY productLine
limit 1