USE adv;

# 1. Find all products that have a list price higher than the average list price of all products.

SELECT
	ProductID,
	Name,
	ListPrice 
FROM adv.production_product
WHERE ListPrice > (SELECT avg(ListPrice) FROM adv.production_product);


# 2. Find all territories where the last year sales were below the average sales of all territories.

SELECT *
FROM adv.sales_salesterritory
WHERE SalesLastYear < (SELECT avg(SalesLastYear) FROM adv.sales_salesterritory);


#3. Identify customers who have not placed any orders.

SELECT
	FirstName,
	LastName 
FROM adv.sales_customer sc
JOIN adv.person_person pp 
	ON sc.CustomerID = pp.BusinessEntityID 
WHERE CustomerID NOT IN 
	(
		SELECT CustomerID 
		FROM adv.sales_salesorderheader
	);


# 4. Find the names of products which have never been ordered.

SELECT Name 
FROM adv.production_product
WHERE ProductID NOT IN 
	(
		SELECT DISTINCT ProductID 
		FROM adv.sales_salesorderdetail 
	);


# 5. Retrieve vendors who supply products that have been sold out.

WITH sold_out AS 
(
	SELECT 
		ProductID,
		sum(Quantity) AS StockedQty 
	FROM adv.production_productinventory
	GROUP BY ProductID
	HAVING StockedQty = 0
),
vendors AS 
(
	SELECT BusinessEntityID 
	FROM adv.purchasing_productvendor pp 
	JOIN sold_out so
		ON pp.ProductID = so.ProductID
)
SELECT Name 
FROM adv.purchasing_vendor pv 
JOIN vendors v
	ON pv.BusinessEntityID = v.BusinessEntityID;



# 6. List products that have the highest reorder point in their respective subcategory.

SELECT
	p.ProductID,
    p.Name AS ProductName,
    p.ReorderPoint,
    p.ProductSubcategoryID
FROM adv.production_product AS p
WHERE p.ReorderPoint = 
(
    SELECT MAX(p2.ReorderPoint)
    FROM adv.production_product AS p2
    WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID
)
ORDER BY p.ProductSubcategoryID;


# 7. Identify all product models which have more than 5 products associated with them.

WITH ProductCount AS 
(
	SELECT 
		count(ProductID) AS ProductCount,
		ProductModelID 
	FROM adv.production_product pp 
	GROUP BY ProductModelID
	HAVING ProductCount > 5
)
SELECT 
	pp.Name,
	pc.ProductCount
FROM adv.production_productmodel pp
JOIN ProductCount pc
	ON pp.ProductModelID = pc.ProductModelID;


# 8. List the top 3 product categories in terms of the number of products they contain.

WITH top_categories AS 
(
SELECT
	pc.ProductCategoryID,
	pc.Name,
	count(pp.ProductID) AS ProductCount
FROM adv.production_productcategory pc
JOIN adv.production_productsubcategory ps
	ON pc.ProductCategoryID = ps.ProductCategoryID 
JOIN adv.production_product pp 
	ON ps.ProductSubcategoryID = pp.ProductSubcategoryID
GROUP BY pc.ProductCategoryID, pc.Name
)
SELECT *
FROM top_categories
ORDER BY ProductCount DESC
LIMIT 3;

# 9. Retrieve all employees who were hired in the same month as the oldest (age) current employee.

SELECT 
    e.BusinessEntityID,
    p.FirstName,
    p.LastName,
    e.HireDate
FROM adv.humanresources_employee AS e
JOIN adv.person_person AS p
	ON e.BusinessEntityID = p.BusinessEntityID
WHERE MONTH(e.HireDate) IN 
(
	SELECT MONTH(HireDate)
    FROM adv.humanresources_employee
    WHERE BirthDate = 
    (
		SELECT MIN(BirthDate) 
        FROM adv.humanresources_employee
        WHERE CurrentFlag = 1
	)
)
ORDER BY DAY(e.HireDate);


# 10. List the most expensive products which haven’t been sold in the last year.

SELECT
	ProductID,
	Name,
	ListPrice 
FROM adv.production_product
WHERE ProductID NOT IN 
(
	SELECT
		ProductID 
	FROM adv.sales_salesorderdetail sod
	JOIN adv.sales_salesorderheader soh
		ON sod.SalesOrderID = soh.SalesOrderID
	WHERE YEAR(soh.OrderDate) = YEAR(CURDATE()) - 1
)
AND ListPrice > 
(
	SELECT avg(ListPrice) 
	FROM adv.production_product
) 
ORDER BY ListPrice DESC 
;


# 11. Find the top 5 products by sales based on order quantity.

WITH best_sellers AS 
(
	SELECT
		ProductID,
		sum(OrderQty) AS TotalSold
	FROM adv.sales_salesorderdetail
	GROUP BY ProductID 
	ORDER BY TotalSold DESC 
	LIMIT 5
)
SELECT
	Name,
	TotalSold
FROM adv.production_product pp 
JOIN best_sellers bs 
	ON pp.ProductID = bs.ProductID ;


# 12. Find all orders where the order quantity is higher than the average order quantity for that product.

WITH avg_per_product AS 
(	
	SELECT
		ProductID,
		avg(OrderQty) AS avg_order_qty
	FROM adv.sales_salesorderdetail
	GROUP BY ProductID 
)	
SELECT
	ss.SalesOrderID,
	ss.ProductID,
	ss.OrderQty,
	app.avg_order_qty
FROM adv.sales_salesorderdetail ss 
JOIN avg_per_product app 
	ON ss.ProductID = app.ProductID
WHERE ss.OrderQty > avg_order_qty;


# 13. List vendors who supply the highest number of distinct products.

WITH product_count AS 
(
	SELECT
		BusinessEntityID,
		count(DISTINCT ProductID) AS num_products 
	FROM adv.purchasing_productvendor
	GROUP BY BusinessEntityID
)
SELECT
	pv.BusinessEntityID,
	pv.Name,
	num_products
FROM adv.purchasing_vendor pv 
JOIN product_count pc 
	ON pv.BusinessEntityID = pc.BusinessEntityID
ORDER BY num_products DESC;


# 14. Identify products with the highest number of reviews.

WITH review_count AS 
(
	SELECT
		ProductID,
		count(ProductReviewID) review_count
	FROM adv.production_productreview
	GROUP BY ProductID
)
SELECT
	pp.ProductID,
	pp.Name,
	review_count
FROM adv.production_product pp 
JOIN review_count rc 
	ON pp.ProductID = rc.ProductID
ORDER BY review_count DESC;


 # 15. List all salespersons who have made sales above the average sales of all salespersons.

WITH sales_per_sp AS 
(
	SELECT 
		SalesPersonID,
		sum(SubTotal) TotalSales
	FROM adv.sales_salesorderheader
	WHERE SalesPersonID IS NOT NULL 
	GROUP BY SalesPersonID 
)
SELECT
	pp.FirstName,
	pp.LastName,
	spsp.TotalSales
FROM adv.person_person pp 
JOIN sales_per_sp spsp 
	ON pp.BusinessEntityID = spsp.SalesPersonID
WHERE spsp.TotalSales > 
	(
		SELECT avg(TotalSales)
		FROM sales_per_sp
	)
ORDER BY spsp.TotalSales DESC; 


# 16. Identify products that have been ordered by the maximum number of different customers.

WITH customer_count AS 
(
	SELECT
		ProductID,
		count(DISTINCT CustomerID) CustomerCount
	FROM adv.sales_salesorderheader sod
	JOIN adv.sales_salesorderdetail ss 
		ON sod.SalesOrderID = ss.SalesOrderID 
	GROUP BY ProductID 
	ORDER BY CustomerCount DESC 
)
SELECT
	pp.ProductID,
	pp.Name,
	CustomerCount
FROM adv.production_product pp
JOIN customer_count cc 
	ON pp.ProductID = cc.ProductID
WHERE CustomerCount = 
(
	SELECT max(CustomerCount)
	FROM customer_count
);


 # 17. Retrieve sales territories which have fewer salespeople than the average of all territories.

WITH sales_people_count AS 
(
	SELECT
		TerritoryID,
		count(SalesPersonID) SalesPeople
	FROM adv.sales_salesorderheader
	GROUP BY TerritoryID 
)
SELECT
	ss.TerritoryID,
	ss.Name,
	SalesPeople
FROM adv.sales_salesterritory ss 
JOIN sales_people_count sp 
	ON ss.TerritoryID = sp.TerritoryID
WHERE SalesPeople <
(
	SELECT avg(SalesPeople)
	FROM sales_people_count
)
ORDER BY SalesPeople DESC; 


 # 18. Retrieve all categories which have more products than the average number of products per category.

WITH product_count AS 
(
	SELECT
		ProductCategoryID,
		count(pp.ProductID) ProductCount 
	FROM adv.production_productsubcategory ps 
	JOIN adv.production_product pp 
		ON ps.ProductSubcategoryID = pp.ProductSubcategoryID
	GROUP BY ProductCategoryID
)
SELECT
	pc.ProductCategoryID,
	pc.Name,
	ProductCount
FROM adv.production_productcategory pc
JOIN product_count prc 
	ON pc.ProductCategoryID = prc.ProductCategoryID
WHERE ProductCount >
(
	SELECT avg(ProductCount)
	FROM product_count
)
ORDER BY ProductCount DESC; 


# 19. List the products that have been ordered in every month in 2012.

WITH order_month AS 
(
	SELECT
		ProductID, 
		count(DISTINCT MONTH(OrderDate)) AS MonthCount
	FROM adv.sales_salesorderheader soh
	JOIN adv.sales_salesorderdetail sod
		ON soh.SalesOrderID = sod.SalesOrderID 
	WHERE YEAR(OrderDate) = 2012
	GROUP BY ProductID 
)
SELECT 
	pp.ProductID,
	pp.Name
FROM order_month om 
JOIN adv.production_product pp
	ON om.ProductID = pp.ProductID 
WHERE MonthCount = 12;


# 20. List the employees who have worked in more than one department.

WITH department_count AS 
(
	SELECT
		BusinessEntityID,
		count(DISTINCT DepartmentID) AS DepartmentCount
	FROM adv.humanresources_employeedepartmenthistory
	GROUP BY BusinessEntityID 
	HAVING DepartmentCount > 1
)
SELECT 
	pp.BusinessEntityID,
	pp.FirstName,
	pp.LastName
FROM department_count dc
JOIN adv.person_person pp
	ON dc.BusinessEntityID = pp.BusinessEntityID;


# 21. List employees who were hired in the year with the highest number of new hires.

WITH hires_by_year AS 
(
	SELECT
		YEAR(HireDate) AS HireYear,
		count(DISTINCT BusinessEntityID) AS HireCount
	FROM adv.humanresources_employee
	GROUP BY HireYear
),
	year_with_most_hires AS
(	
	SELECT HireYear
	FROM hires_by_year
	WHERE HireCount = 
		(
			SELECT max(HireCount)
			FROM hires_by_year
		)
)
SELECT
	he.BusinessEntityID,
	pp.FirstName,
	pp.LastName
FROM adv.humanresources_employee he 
JOIN adv.person_person pp 
	ON he.BusinessEntityID = pp.BusinessEntityID
WHERE YEAR(he.HireDate) = 
	(
		SELECT HireYear
		FROM year_with_most_hires
	)
;


# 22. List products which have a standard cost higher than the average cost of products in the same product category.

WITH avg_cost_per_category AS 
(
	SELECT
		avg(pp.StandardCost) AverageCost, 
		ps.ProductCategoryID 
	FROM adv.production_product pp 
	JOIN adv.production_productsubcategory ps 
		ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
	GROUP BY ps.ProductCategoryID
)
SELECT 
	pp.ProductID,
	pp.Name,
	pp.StandardCost, 
	cpc.AverageCost, 
	cpc.ProductCategoryID
FROM avg_cost_per_category cpc 
JOIN adv.production_productsubcategory ps 
	ON cpc.ProductCategoryID = ps.ProductCategoryID 
JOIN adv.production_product pp 
	ON pp.ProductSubcategoryID = ps.ProductSubcategoryID 
WHERE pp.StandardCost > cpc.AverageCost;
	

# 23. List sales orders placed by customers from the city which has the maximum number of customers.

WITH customers_per_city AS
(
	SELECT
		pa.City,
		count(ss.CustomerID) AS CustomerCount
	FROM adv.sales_salesorderheader ss 
	JOIN adv.person_address pa 
		ON ss.BillToAddressID = pa.AddressID 
	GROUP BY pa.City 
),
	city_with_most_customers AS 
(
	SELECT City
	FROM customers_per_city
	WHERE CustomerCount = (SELECT max(CustomerCount) FROM customers_per_city)
)
SELECT
	soh.SalesOrderID,
	soh.CustomerID,
	pa.City 
FROM adv.sales_salesorderheader soh
JOIN adv.person_address pa 
	ON soh.BillToAddressID = pa.AddressID 
WHERE pa.City = (SELECT City FROM city_with_most_customers);



# 24. List the second most expensive product from each product subcategory.

WITH products_by_price AS 
(
	SELECT 
		pp.ProductID,
		pp.Name,
		ps.ProductSubCategoryID,
		pp.ListPrice,
		DENSE_RANK() OVER(PARTITION BY ps.ProductSubCategoryID ORDER BY pp.ListPrice DESC) AS price_rank
	FROM adv.production_product pp 
	JOIN adv.production_productsubcategory ps 
		ON pp.ProductSubcategoryID = ps.ProductSubcategoryID
)
SELECT
	Name,
	ProductSubCategoryID,
	ListPrice
FROM products_by_price
WHERE price_rank = 2;


# 25. Find the most expensive product each vendor provides. Do not list products with ListPrice equal to 0.

WITH products_by_vendor AS 
(
	SELECT
		pp.ProductID,
		pp.Name,
		pp.ListPrice,
		pv.BusinessEntityID,
		DENSE_RANK () OVER(PARTITION BY PV.BusinessEntityID ORDER BY pp.ListPrice DESC) AS ranked_products 
	FROM adv.production_product pp 
	JOIN adv.purchasing_productvendor pv 
		ON pp.ProductID = pv.ProductID
	WHERE pp.ListPrice != 0
)
SELECT *
FROM products_by_vendor
WHERE ranked_products = 1
ORDER BY ListPrice DESC ;


# 26. Find all products that have been sold every year since their introduction to discontinuation (if discontinued).

WITH product_sales_years AS 
(
	SELECT 
	    sod.ProductID,
		YEAR(soh.OrderDate) AS SalesYear
	FROM adv.sales_salesorderdetail AS sod
	JOIN adv.sales_salesorderheader AS soh
		ON sod.SalesOrderID = soh.SalesOrderID
	GROUP BY sod.ProductID, SalesYear
),
	years_available_count AS 
(
	SELECT 
		p.ProductID,
		YEAR(
				CASE WHEN p.SellEndDate IS NULL
				THEN 
				(
					SELECT MAX(OrderDate)
					FROM adv.sales_salesorderheader
				)
				ELSE SellEndDate
				END
			) - YEAR(p.SellStartDate) + 1 AS AvailableForYears
	    FROM adv.production_product AS p
),
	years_sold_count AS 
(
	SELECT 
		ps.ProductID,
	    COUNT(DISTINCT ps.SalesYear) AS NumberOfYears
	FROM product_sales_years AS ps
	GROUP BY ps.ProductID
)
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    ps.NumberOfYears,
    yac.AvailableForYears
FROM years_sold_count AS ps
JOIN years_available_count AS yac
	ON ps.ProductID = yac.ProductID
JOIN adv.production_product AS p
    ON ps.ProductID = p.ProductID
WHERE ps.NumberOfYears >= yac.AvailableForYears
ORDER BY p.ProductID;



# 27. Find all employees who earn more than the average salary of employees in their respective departments.

WITH latest_department AS 
(
    SELECT 
    	edh.BusinessEntityID,
    	edh.DepartmentID
    FROM adv.humanresources_employeedepartmenthistory edh
    WHERE edh.EndDate IS NULL
),
	current_rate AS 
(
    SELECT 
    	eph.BusinessEntityID,
    	eph.Rate
    FROM adv.humanresources_employeepayhistory eph
    WHERE eph.RateChangeDate = 
    (
        SELECT MAX(RateChangeDate)
        FROM adv.humanresources_employeepayhistory
        WHERE BusinessEntityID = eph.BusinessEntityID
    )
),
avg_salaries_by_department AS 
(
    SELECT 
        ld.DepartmentID,
        ROUND(AVG(cr.Rate), 2) AS AvgDepSalary
    FROM latest_department ld
    JOIN current_rate cr 
    	ON ld.BusinessEntityID = cr.BusinessEntityID
    GROUP BY ld.DepartmentID
)
SELECT 
    ld.BusinessEntityID,
    p.FirstName,
    p.LastName,
    cr.Rate,
    asd.AvgDepSalary,
    ld.DepartmentID
FROM latest_department ld
JOIN current_rate cr 
	ON ld.BusinessEntityID = cr.BusinessEntityID
JOIN avg_salaries_by_department asd 
	ON ld.DepartmentID = asd.DepartmentID
JOIN adv.person_person p 
	ON ld.BusinessEntityID = p.BusinessEntityID
WHERE cr.Rate > asd.AvgDepSalary
ORDER BY ld.DepartmentID, cr.Rate DESC;



	
	





