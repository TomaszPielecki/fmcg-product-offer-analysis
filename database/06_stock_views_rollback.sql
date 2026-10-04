/*
    06_stock_views_rollback.sql
    Wycofanie 06_stock_views.sql: usuwa dbo.vw_Oferta_StanyMagazynowe i przywraca
    oryginalne definicje widokow z 05_views_for_powerbi.sql.
    Uwaga: jesli zywa definicja roznila sie od repo, przywroc ja z kopii zapisanej
    przed wdrozeniem (OBJECT_DEFINITION).
*/
GO

DROP VIEW IF EXISTS dbo.vw_Oferta_StanyMagazynowe;
GO

CREATE OR ALTER VIEW dbo.vw_Oferta_Analytics AS
WITH Cleaned AS (
    SELECT
        id,
        lp,
        LTRIM(RTRIM(nazwa)) AS ProductName,
        TRY_CONVERT(decimal(18,2), REPLACE(NULLIF(LTRIM(RTRIM(stan)), ''), ',', '.')) AS StockQty,
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
    CASE
        WHEN StockQty IS NULL THEN 'Missing stock'
        WHEN StockQty = 0 THEN 'Out of stock'
        WHEN StockQty > 0 THEN 'In stock'
        ELSE 'Invalid stock'
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
    END AS InferredProductGroup
FROM Cleaned;
GO

CREATE OR ALTER VIEW dbo.vw_Oferta_DataQualityIssues AS
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
        WHEN StockStatus IN ('Missing stock', 'Invalid stock') THEN StockStatus
        ELSE 'No issue'
    END AS DataQualityIssue,
    CASE
        WHEN ProductName IS NULL OR ProductName = '' THEN 'Product'
        WHEN PriceStatus IN ('Missing price', 'Invalid price') THEN 'Price'
        WHEN VatStatus <> 'Valid VAT' THEN 'VAT'
        WHEN HasVatPriceMismatch = 1 THEN 'VAT'
        WHEN StockStatus IN ('Missing stock', 'Invalid stock') THEN 'Stock'
        ELSE 'No issue'
    END AS DataQualityArea,
    CASE
        WHEN ProductName IS NULL OR ProductName = '' THEN 1
        WHEN PriceStatus IN ('Missing price', 'Invalid price') THEN 2
        WHEN VatStatus <> 'Valid VAT' THEN 3
        WHEN HasVatPriceMismatch = 1 THEN 4
        WHEN StockStatus IN ('Missing stock', 'Invalid stock') THEN 5
        ELSE 99
    END AS DataQualityPriority
FROM dbo.vw_Oferta_Analytics
WHERE ProductName IS NULL
   OR ProductName = ''
   OR StockStatus IN ('Missing stock', 'Invalid stock')
   OR PriceStatus IN ('Missing price', 'Invalid price')
   OR VatStatus <> 'Valid VAT'
   OR HasVatPriceMismatch = 1;
GO
