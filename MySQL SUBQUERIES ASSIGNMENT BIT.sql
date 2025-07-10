USE adv;

/*
1. Find the names of the products that have been ordered in quantities of 20 or more.
*/
 
SELECT Name
FROM adv.production_product pp 
WHERE ProductID IN 
	(
		SELECT ProductID 
		FROM adv.sales_salesorderdetail ss 
		WHERE ss.OrderQty >= 20
	);
	

/*
2. Write a query to return the name and list price for the product(s) that have the lowest list price within a given product subcategory (ProductSubcategoryID = 12).
 Ensure the query filters the results to this specific subcategory and correctly identifies the least expensive product(s).
*/

SELECT
	Name,
	ListPrice 
FROM adv.production_product pp
WHERE ListPrice IN 
	(
		SELECT min(ListPrice)
		FROM adv.production_product pp2 
		WHERE ProductSubcategoryID = 12
	);


/*
3. Write a query to get employees with Johnson last names. Return first name and last name.
*/

SELECT 
	FirstName,
	LastName 
FROM adv.person_person pp
WHERE LastName = 'Johnson' AND BusinessEntityID IN 
	(
		SELECT BusinessEntityID 
		FROM adv.humanresources_employee he
	);


/*
4. Write a query to find employees of departments that start with ’P’. Return first name, last name, job title.
*/

SELECT
	pp.FirstName,
	pp.LastName,
	he.JobTitle 
FROM adv.person_person pp 
JOIN adv.humanresources_employee he 
	ON pp.BusinessEntityID = he.BusinessEntityID
JOIN adv.humanresources_employeedepartmenthistory he2 
	ON he.BusinessEntityID = he2.BusinessEntityID
WHERE he2.DepartmentID IN 
	(
		SELECT DepartmentID
		FROM adv.humanresources_department hd
		WHERE name like 'P%'
	);


/*
5. Write a query to return rows only when both the productid and startdate values in the two tables matches.
   Use a subquery in a WHERE EXISTS clause.
*/

SELECT *
FROM adv.production_workorder pw 
WHERE EXISTS 
	(
		SELECT *
		FROM adv.production_workorderrouting pw2 
		WHERE pw.ProductID = pw2.ProductID AND pw.StartDate = pw2.actualstartdate
	);


/*
6. Write a query to find the full names and job titles of employees which had their pay rates changed effective in 2009.
*/

SELECT 
	concat(pp.FirstName, ' ' , pp.LastName) AS FullName,
	he.JobTitle 
FROM adv.person_person pp 
JOIN adv.humanresources_employee he 
	ON pp.BusinessEntityID = he.BusinessEntityID 
WHERE pp.BusinessEntityID IN 
	(
		SELECT BusinessEntityID 
		FROM adv.humanresources_employeepayhistory he 
		WHERE YEAR(RateChangeDate) = 2009
	);


/*
7. Write a query to retrieve the product ID, name, cost, and list price for each product along with the average unit price for which that product has been sold.
   Filter the results to include only products where the cost price is higher than the average selling price.
*/

SELECT 
	pp.ProductID,
    pp.Name,
    pp.StandardCost,
    pp.ListPrice,
	(
		SELECT AVG(UnitPrice)
		FROM adv.sales_salesorderdetail ss
		WHERE pp.ProductID = ss.ProductID
	) AS AvgSellingPrice
FROM adv.production_product pp
HAVING StandardCost > AvgSellingPrice
ORDER BY pp.ProductID;


/*
8. Write a query to retrieve the product ID, name, and list price for each product where the list price is 100 or more,
   and the product has been sold for less than 100.
*/

SELECT
	ProductID,
	Name,
	ListPrice
FROM adv.production_product
WHERE ListPrice >= 100 AND ProductID IN 
	(
		SELECT ProductID 
		FROM adv.sales_salesorderdetail 
		WHERE UnitPrice - UnitPriceDiscount < 100
	);


/*
9. Using WITH clause write a query to find the SalesPersonID, salesyear, totalsales, salesquota, and AmtAboveOrBelowQuota columns.
   Sort the result in ascending order on SalesPersonID, and SalesYear columns.
*/

WITH cte_sales AS
(
	SELECT 
		SalesPersonID,
		SUM(SubTotal) AS TotalSales,
		YEAR(OrderDate) AS SalesYear
	FROM adv.sales_salesorderheader
	WHERE SalesPersonID IS NOT NULL 
	GROUP BY SalesPersonID, SalesYear
),
cte_quota AS 
(
	SELECT
		BusinessEntityID,
		SUM(SalesQuota) AS SalesQuota,
		YEAR(QuotaDate) AS SalesQuotaYear
	FROM adv.sales_salespersonquotahistory
	GROUP BY BusinessEntityID, SalesQuotaYear
)
SELECT 
	SalesPersonID,
	SalesYear,
	SalesQuota,
	TotalSales - SalesQuota AS AmtAboveOrBelowQuota
FROM cte_sales s
JOIN cte_quota q
	ON s.SalesPersonID = q.BusinessEntityID 
	AND s.SalesYear = q.SalesQuotaYear
ORDER BY SalesPersonID, SalesYear;


/*
10. Write a query to find the first and last names of employees who have sold a product with the ProductNumber ’BK-M68B-42’.
    Return the distinct columns LastName and FirstName.
*/

SELECT DISTINCT 
	FirstName,
	LastName 
FROM adv.person_person
WHERE BusinessEntityID IN 
	(
		SELECT BusinessEntityID
		FROM adv.humanresources_employee
		WHERE BusinessEntityID IN 
			(
				SELECT SalesPersonID
				FROM adv.sales_salesorderheader
				WHERE SalesOrderID IN 
					(
						SELECT SalesOrderID
						FROM adv.sales_salesorderdetail
						WHERE ProductID IN 
							(	
								SELECT ProductID
								FROM adv.production_product pp 
								WHERE ProductNumber = 'BK-M68B-42'
							))));
							
					









