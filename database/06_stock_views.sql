/*
    06_stock_views.sql
    SQL Server 2019 (compat. level 150), baza tomawebp_oferta, schemat dbo.

    Zmiany (idempotentne, CREATE OR ALTER; dane w dbo.Oferta i typ kolumny stan bez zmian):
      1. dbo.vw_Oferta_Analytics        - nowa logika StockQty/StockStatus + StockValueNet/StockValueGross
      2. dbo.vw_Oferta_DataQualityIssues - 'No stock data' vs 'Out of stock' + 'Duplicate name'
      3. dbo.vw_Oferta_StanyMagazynowe  - agregacja wg jm i InferredProductGroup

    Punkt wyjscia: definicje z database/05_views_for_powerbi.sql.
    Wycofanie: database/06_stock_views_rollback.sql
    Uruchamiaj w kontekscie bazy tomawebp_oferta (bez USE).
*/
GO

-- 1. Analytics -------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Oferta_Analytics AS
WITH Cleaned AS (
    SELECT
        id,
        lp,
        LTRIM(RTRIM(nazwa)) AS ProductName,
        -- ZMIANA: stan '' / NULL -> NULL (TRY_CAST('' AS decimal) zwraca 0, stad NULLIF); przecinek -> kropka
        TRY_CAST(REPLACE(NULLIF(LTRIM(RTRIM(stan)), ''), ',', '.') AS decimal(18,2)) AS StockQty,
        -- ZMIANA: surowy stan, by odroznic brak danych od wartosci nieliczbowej
        NULLIF(LTRIM(RTRIM(stan)), '') AS StockRaw,
        LTRIM(RTRIM(jm)) AS UnitOfMeasure,
        TRY_CONVERT(decimal(5,2), REPLACE(REPLACE(NULLIF(LTRIM(RTRIM(vat)), ''), '%', ''), ',', '.')) AS VatRate,
        cennik_kartuzy_n_pln AS NetPrice,
        cennik_kartuzy_b_pln AS GrossPrice,
        cennik_kartuzy_n_pln_alt AS NetPriceAlt,
        cennik_kartuzy_b_pln_alt AS GrossPriceAlt,
        data_utworzenia AS CreatedAt
    FROM dbo.Oferta
)
SELECT
    id,
    lp,
    ProductName,
    StockQty,
    UnitOfMeasure,
    VatRate,
    NetPrice,
    GrossPrice,
    NetPriceAlt,
    GrossPriceAlt,
    CreatedAt,
    -- ZMIANA: nowe statusy stanu
    CASE
        WHEN StockRaw IS NULL THEN 'No stock data'
        WHEN StockQty IS NULL THEN 'Invalid stock'   -- niepusty, ale nieliczbowy
        WHEN StockQty <= 0 THEN 'Out of stock'
        WHEN StockQty < 10 THEN 'Low stock'
        ELSE 'In stock'
    END AS StockStatus,
    CASE
        WHEN GrossPrice IS NULL OR GrossPrice = 0 THEN 'Missing price'
        WHEN GrossPrice < 0 THEN 'Invalid price'
        ELSE 'Valid price'
    END AS PriceStatus,
    CASE
        WHEN VatRate IS NULL THEN 'Invalid VAT'
        WHEN VatRate IN (0, 5, 8, 23) THEN 'Valid VAT'
        ELSE 'Unusual VAT'
    END AS VatStatus,
    CASE
        WHEN GrossPriceAlt IS NOT NULL
         AND GrossPriceAlt > 0
         AND GrossPriceAlt <> GrossPrice THEN 1
        ELSE 0
    END AS HasAlternativeGrossPrice,
    CASE
        WHEN NetPriceAlt IS NOT NULL
         AND NetPriceAlt > 0
         AND NetPriceAlt <> NetPrice THEN 1
        ELSE 0
    END AS HasAlternativeNetPrice,
    ROUND(NetPrice * (1 + VatRate / 100.0), 2) AS ExpectedGrossPrice,
    ROUND(GrossPrice - ROUND(NetPrice * (1 + VatRate / 100.0), 2), 2) AS GrossPriceDifference,
    CASE
        WHEN ABS(ROUND(GrossPrice - ROUND(NetPrice * (1 + VatRate / 100.0), 2), 2)) > 0.01 THEN 1
        ELSE 0
    END AS HasVatPriceMismatch,
    ROUND(GrossPriceAlt - GrossPrice, 2) AS AlternativeGrossPriceDifference,
    CASE
        WHEN GrossPrice IS NULL OR GrossPrice <= 0 THEN 'Missing or zero'
        WHEN GrossPrice < 5 THEN '0.01-4.99'
        WHEN GrossPrice < 10 THEN '5.00-9.99'
        WHEN GrossPrice < 25 THEN '10.00-24.99'
        WHEN GrossPrice < 50 THEN '25.00-49.99'
        ELSE '50.00+'
    END AS GrossPriceBand,
    CASE
        WHEN GrossPrice IS NULL OR GrossPrice <= 0 THEN 0
        WHEN GrossPrice < 5 THEN 1
        WHEN GrossPrice < 10 THEN 2
        WHEN GrossPrice < 25 THEN 3
        WHEN GrossPrice < 50 THEN 4
        ELSE 5
    END AS GrossPriceBandSort,
    CASE
        WHEN ProductName LIKE 'PIWO%' THEN 'Beer'
        WHEN ProductName LIKE 'WODA%' THEN 'Water'
        WHEN ProductName LIKE 'BAT.%' OR ProductName LIKE 'BAT %' THEN 'Bars and sweets'
        WHEN ProductName LIKE 'BOM.%' THEN 'Chocolate and gifts'
        WHEN ProductName LIKE 'CHR.%' OR ProductName LIKE 'CHI.%' THEN 'Snacks'
        WHEN ProductName LIKE 'KNOR%' OR ProductName LIKE 'AMINO%' OR ProductName LIKE 'W.%' OR ProductName LIKE 'Z.%' THEN 'Instant and canned food'
        WHEN ProductName LIKE 'SER%' THEN 'Cheese'
        WHEN ProductName LIKE '%SYROP%' THEN 'Syrups'
        WHEN ProductName LIKE '%MIOD%' OR ProductName LIKE '%DZEM%' THEN 'Breakfast and preserves'
        ELSE 'Other'
    END AS InferredProductGroup,
    -- ZMIANA: nowe kolumny dopisane na koncu, by nie zmieniac kolejnosci istniejacych
    CAST(StockQty * NetPrice AS decimal(18,2)) AS StockValueNet,
    CAST(StockQty * GrossPrice AS decimal(18,2)) AS StockValueGross
FROM Cleaned;
GO

-- 2. Data quality ----------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Oferta_DataQualityIssues AS
WITH Base AS (
    SELECT
        a.*,
        -- ZMIANA: duplikat = ta sama nazwa, cena i stan (np. id 967-971 vs 1058-1062)
        COUNT(*) OVER (PARTITION BY a.ProductName, a.NetPrice, a.GrossPrice, a.StockQty) AS SameRecordCount
    FROM dbo.vw_Oferta_Analytics AS a
)
SELECT
    id,
    ProductName,
    StockQty,
    UnitOfMeasure,
    VatRate,
    NetPrice,
    GrossPrice,
    StockStatus,
    PriceStatus,
    VatStatus,
    GrossPriceDifference,
    HasVatPriceMismatch,
    CASE
        WHEN ProductName IS NULL OR ProductName = '' THEN 'Missing product name'
        WHEN PriceStatus IN ('Missing price', 'Invalid price') THEN PriceStatus
        WHEN VatStatus <> 'Valid VAT' THEN VatStatus
        WHEN HasVatPriceMismatch = 1 THEN 'Gross price differs from net price + VAT'
        WHEN StockStatus IN ('No stock data', 'Out of stock', 'Invalid stock') THEN StockStatus  -- ZMIANA
        WHEN SameRecordCount > 1 THEN 'Duplicate name'                                           -- ZMIANA
        ELSE 'No issue'
    END AS DataQualityIssue,
    CASE
        WHEN ProductName IS NULL OR ProductName = '' THEN 'Product'
        WHEN PriceStatus IN ('Missing price', 'Invalid price') THEN 'Price'
        WHEN VatStatus <> 'Valid VAT' THEN 'VAT'
        WHEN HasVatPriceMismatch = 1 THEN 'VAT'
        WHEN StockStatus IN ('No stock data', 'Out of stock', 'Invalid stock') THEN 'Stock'
        WHEN SameRecordCount > 1 THEN 'Product'
        ELSE 'No issue'
    END AS DataQualityArea,
    CASE
        WHEN ProductName IS NULL OR ProductName = '' THEN 1
        WHEN PriceStatus IN ('Missing price', 'Invalid price') THEN 2
        WHEN VatStatus <> 'Valid VAT' THEN 3
        WHEN HasVatPriceMismatch = 1 THEN 4
        WHEN StockStatus IN ('No stock data', 'Out of stock', 'Invalid stock') THEN 5
        WHEN SameRecordCount > 1 THEN 6
        ELSE 99
    END AS DataQualityPriority
FROM Base
WHERE ProductName IS NULL
   OR ProductName = ''
   OR StockStatus IN ('No stock data', 'Out of stock', 'Invalid stock')
   OR PriceStatus IN ('Missing price', 'Invalid price')
   OR VatStatus <> 'Valid VAT'
   OR HasVatPriceMismatch = 1
   OR SameRecordCount > 1;
GO

-- 3. Agregacja stanow ------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Oferta_StanyMagazynowe AS
SELECT
    UnitOfMeasure,
    InferredProductGroup,
    COUNT(*) AS ItemCount,
    SUM(StockQty) AS TotalStockQty,
    SUM(StockValueGross) AS TotalStockValueGross,
    SUM(CASE WHEN StockStatus = 'No stock data' THEN 1 ELSE 0 END) AS ItemsWithoutStock
FROM dbo.vw_Oferta_Analytics
GROUP BY UnitOfMeasure, InferredProductGroup;
GO

-- 4. Zapytania kontrolne ---------------------------------------------------
SELECT TOP 100 * FROM dbo.vw_Oferta_Analytics ORDER BY id;
GO
SELECT TOP 100 * FROM dbo.vw_Oferta_DataQualityIssues ORDER BY DataQualityPriority, id;
GO
SELECT TOP 100 * FROM dbo.vw_Oferta_StanyMagazynowe ORDER BY UnitOfMeasure, InferredProductGroup;
GO

-- Kontrola oczekiwanych liczb: 2910 pozycji, 1948 ze stanem dodatnim, 962 bez stanu
SELECT
    COUNT(*) AS Total,
    SUM(CASE WHEN StockQty > 0 THEN 1 ELSE 0 END) AS PositiveStock,
    SUM(CASE WHEN StockStatus = 'No stock data' THEN 1 ELSE 0 END) AS NoStockData
FROM dbo.vw_Oferta_Analytics;
GO
