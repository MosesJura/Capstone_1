
-- Moses Jura
-- 11/3/2026
-- Querying a database
 ## Sales Territory
-- - Assigned Territory: **NJ**

USE sample_sales;
SELECT database();
SHOW tables;
-- Just by looking at management table, I release online sales is defined under states, 
-- Online sales is mainly in the west region and its managed by Regional Director = Cassie Chambers

 ## JOINING TABLES and how they are related.
--  store_sales joins products thru ProdNum
--  store_sales joins store_locations thru StoreID
--  store_locations joins management thru States
--  products joins inventory_subcategories thru SubcategoryID
--  inventory_subcategories joins inventory_categories thru CategoryID


 ## Filtering by State to find Sales Manager for Assigned Territory: **NJ**.  = Manager: Miami Vue

SELECT *
FROM management;

SELECT State, SalesManager
FROM management
where State = 'New Jersey';


 ## Checking the list of states and how many states we do business insert

SELECT DISTINCT State FROM store_locations;

SELECT COUNT(DISTINCT State)  Count_Of_State FROM store_locations;

 ## Number of store Locations per state

SELECT COUNT(StoreLocation) , State
FROM store_locations
GROUP BY State;

 ## Joining  tables, store_sales, store_locations and management filtered by sales Manager 

SELECT * FROM store_sales;

SELECT  ss.id, ss.Sale_Amount, ss.Store_ID, ss.Transaction_Date,
        ss.Prod_Num, sl.StoreLocation, sl.State, m.SalesManager,
        m.Region, m.RegionalDirector
 FROM   store_sales ss
 JOIN    store_locations sl ON sl.StoreId = ss.Store_ID
 JOIN management m ON m.State = sl.State
 WHERE SalesManager = (SELECT SalesManager
FROM management
where State = 'New Jersey')
;



 ## 1. What is total revenue overall for sales in the assigned territory, 
 ##   plus the start date and end date that tell you what period the data covers?

      ##  Total Revenue, Start date and End date of data collected 
SELECT  sl.State,
	 ROUND(SUM(ss.Sale_Amount),2) 'Total Revenue',
     MIN(ss.Transaction_Date) 'Start Date', 
     MAX(ss.Transaction_Date) 'End Date'
 FROM   store_sales ss
 JOIN    store_locations sl 
 ON sl.StoreId = ss.Store_ID
 JOIN management m 
 ON m.State = sl.State
 WHERE sl.state = 'New Jersey';

## 2. What is the revenue breakdown by year and month for the sales territory?
-- Finding the revenue breakdown by year and month filtered state NJ, By joinning store sales and store location
 
 SELECT 
 YEAR(Transaction_Date) 'yearly Transaction',
 MONTH(Transaction_Date) 'monthly Transaction',
 SUM(Sale_Amount) 'Total Revenue'
 FROM store_sales ss
 JOIN store_locations sl ON sl.StoreId = ss.Store_ID
WHERE sl.State = 'New Jersey'
 GROUP BY 
 YEAR(Transaction_Date),
 MONTH(Transaction_Date)
 ORDER BY 'yearly Transaction' , 'monthly Transaction';


## 3. Provide a comparison of total revenue for the specific sales territory and the region it belongs to

-- First Step 
SELECT  SUM(ss.Sale_Amount) Total_Revenue, sl.State, m.Region
 FROM   store_sales ss
 JOIN    store_locations sl ON sl.StoreId = ss.Store_ID
 JOIN management m ON m.State = sl.State
 WHERE Region = (SELECT Region
FROM management
where State = 'New Jersey')
GROUP BY  sl.State, m.Region
;

-- Second and final step, using first step for guide the 2nd step 
-- I use ## partision by :
-- This is the magic of window functions. It says: "Take the sum of the sales, and then sum those sums up, 
-- but only over a specific 'window'—in this case, partitioning (grouping) them by the Region.
-- " This gives you the grand total for the entire Northeast region repeated on every row.

SELECT 
    sl.State, 
    m.Region,
    SUM(ss.Sale_Amount) AS State_Total_Revenue,
    SUM(SUM(ss.Sale_Amount)) OVER (PARTITION BY m.Region) AS Region_Total_Revenue,
    (SUM(ss.Sale_Amount) / SUM(SUM(ss.Sale_Amount)) OVER (PARTITION BY m.Region)) * 100 AS Percent_of_Region_Total
FROM store_sales ss
JOIN store_locations sl ON sl.StoreId = ss.Store_ID
JOIN management m ON m.State = sl.State
WHERE m.Region = 'Northeast'
GROUP BY sl.State, m.Region
ORDER BY Percent_of_Region_Total DESC;

                        ## OR
## I use self join table compare state of new jersey to northeast region only

SELECT New_Jersey_revenue,
       northeast_revenue,
       ROUND(New_Jersey_revenue / northeast_revenue * 100, 2) AS New_Jersey_share_prcnt
FROM (
	SELECT
     (SELECT SUM(ss.sale_amount)
     FROM store_sales ss 
     JOIN store_locations sl ON ss.store_id =sl.storeid
     WHERE sl.state = 'New Jersey')                              AS New_Jersey_revenue,
     (SELECT SUM(ss.sale_amount)
     FROM store_sales ss
     JOIN store_locations sl ON ss.store_id = sl.storeid
     JOIN management m ON sl.state = m.state
     WHERE m.region = 'Northeast')                             AS northeast_revenue
     ) T;


## 4. What is the number of transactions per month and average transaction amount by product category for the sales territory?

SELECT Category Product_Category, 
YEAR(Transaction_Date) Yearly_Transactions,
MONTH(Transaction_Date) Montly_Transactions,
COUNT(Transaction_Date) Transactions_Count, 
 AVG(Sale_Amount) Average_Transaction_Amount
FROM management m 
JOIN store_locations sl ON sl.state = m.state
JOIN store_sales ss ON ss.store_id = sl.storeid
JOIN products p ON p.ProdNum = ss.Prod_Num
JOIN inventory_subcategories s ON s.Subcategoryid = p.Subcategoryid
JOIN inventory_categories c ON c.Categoryid = s.Categoryid 
WHERE sl.State ='New Jersey'
GROUP BY  Yearly_Transactions, Montly_Transactions, Product_Category
ORDER BY Yearly_Transactions, Montly_Transactions, Average_Transaction_Amount DESC;

## 5. Can you provide a ranking of in-store sales performance by each store in the sales territory?

SELECT ss.Store_ID AS Store_ID,
	   sl.StoreLocation AS Store_City,
    SUM(ss.Sale_Amount) AS Total_Revenue,
	COUNT(ss.Sale_Amount) AS Transaction_Count,
	ROUND(AVG(ss.Sale_Amount), 2) AS Average_Transaction_Size,
	RANK() OVER (ORDER BY SUM(ss.Sale_Amount) DESC) AS Store_Rank
FROM management m 
JOIN store_locations sl ON sl.state = m.state
JOIN store_sales ss ON ss.store_id = sl.storeid
JOIN products p ON p.ProdNum = ss.Prod_Num
JOIN inventory_subcategories s ON s.Subcategoryid = p.Subcategoryid
JOIN inventory_categories c ON c.Categoryid = s.Categoryid 
WHERE sl.State ='New Jersey'
GROUP BY Store_ID
ORDER BY Store_Rank DESC;

## 6. What is your recommendation for where to focus sales attention in the next quarter?







## JOINED ALL TABLE TO EXPORT TO EXCEL, USE THE DATA TO ANALYZE
SELECT *
FROM management m 
JOIN store_locations sl ON sl.state = m.state
JOIN store_sales ss ON ss.store_id = sl.storeid
JOIN products p ON p.ProdNum = ss.Prod_Num
JOIN inventory_subcategories s ON s.Subcategoryid = p.Subcategoryid
JOIN inventory_categories c ON c.Categoryid = s.Categoryid  ;



















