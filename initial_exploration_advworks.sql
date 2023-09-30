-- Adventure Works Sale Sale Analysis

-- 1. Performance of each sales person
SELECT
    sp.BusinessEntityID,
    st.Name,
    st.[Group],
    sp.SalesQuota,
    sp.SalesYTD,
    sp.SalesLastYear,
    sp.SalesLastYear / st.SalesLastYear AS PctSalesContributionToTerritory,
    COUNT(SalesOrderID) AS NumberOfOrdersLastYear,
    AVG(TotalDue) AS AverageOrderTotalLastYear
FROM
    Sales.SalesPerson sp 
    JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID
    JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
WHERE YEAR(OrderDate) = 2013 AND OnlineOrderFlag = 0
GROUP BY sp.BusinessEntityID, st.Name, st.[Group], sp.SalesQuota, sp.SalesYTD, sp.SalesLastYear;

-- 2. Performance of each sales territory
WITH TotalSale2012 AS (
    SELECT
        st.TerritoryID,
        COUNT(SalesOrderID) AS NumberOfOrders,
        AVG(TotalDue) AS AverageOrderTotal,
        SUM(TotalDue) AS TotalSales
    FROM
        Sales.SalesTerritory st
        JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
    WHERE YEAR(OrderDate) = 2012
    GROUP BY st.TerritoryID
)

SELECT
    st.TerritoryID,
    st.Name,
    st.CountryRegionCode,
    st.[Group],
    st.SalesYTD,
    -- st.SalesLastYear,
    SUM(TotalDue) AS TotalSales,
    -- ts.TotalSales AS TotalSales2012,
    -- ts.NumberOfOrders AS NumberOfOrders2012,
    st.CostYTD,
    st.CostLastYear,
    (SUM(TotalDue) - ts.TotalSales) / ts.TotalSales AS PctSalesGrowth,
    COUNT(SalesOrderID) AS NumberOfOrdersLastYear,
    AVG(TotalDue) AS AverageSaleLastYear,
    (AVG(TotalDue) - AverageOrderTotal) / AverageOrderTotal AS PctAverageSaleGrowth
    -- ts.AverageOrderTotal AS AverageOrderTotal2012
FROM
    Sales.SalesTerritory st
    JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
    JOIN TotalSale2012 ts ON st.TerritoryID = ts.TerritoryID
WHERE YEAR(OrderDate) = 2013
GROUP BY st.TerritoryID, st.Name, st.CountryRegionCode, st.[Group], st.SalesYTD, st.SalesLastYear, st.CostYTD, st.CostLastYear, ts.TotalSales, ts.NumberOfOrders, ts.AverageOrderTotal;

-- 3. Performance of special offers
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    soh.SalesPersonID,
    sp.BusinessEntityID,
    sp.TerritoryID,
    st.Name,
    st.[Group],
    soh.SpecialOfferID,
    so.Description,
    so.DiscountPct,
    soh.TotalDue * (1 - so.DiscountPct) AS DiscountedTotalDue
FROM
    Sales.SalesOrderDetail soh
    JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
    JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID
    JOIN Sales.SpecialOffer so ON soh.SpecialOfferID = so.SpecialOfferID
WHERE YEAR(OrderDate) = 2013;

-- 4. Top 5 product in each territory
WITH Top5Product AS (
    SELECT
        st.TerritoryID,
        st.Name,
        st.[Group],
        p.ProductID,
        p.Name AS ProductName,
        SUM(sod.OrderQty) AS TotalOrderQty
    FROM
        Sales.SalesOrderDetail sod
        JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
        JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
        JOIN Production.Product p ON sod.ProductID = p.ProductID
    WHERE YEAR(OrderDate) = 2013
    GROUP BY st.TerritoryID, st.Name, st.[Group], p.ProductID, p.Name
)

SELECT
    TerritoryID,
    Name,
    [Group],
    ProductID,
    ProductName,
    TotalOrderQty,
    RowNumber AS Rank
FROM (
    SELECT
        TerritoryID,
        Name,
        [Group],
        ProductID,
        ProductName,
        TotalOrderQty,
        ROW_NUMBER() OVER (PARTITION BY TerritoryID ORDER BY TotalOrderQty DESC) AS RowNumber
    FROM Top5Product
) AS Top5Product
WHERE RowNumber <= 5;
