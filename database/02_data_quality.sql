USE [tomawebp_oferta];
GO

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
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN ProductName IS NULL OR ProductName = '' THEN 1 ELSE 0 END) AS MissingProductNames,
    SUM(CASE WHEN StockQty IS NULL THEN 1 ELSE 0 END) AS MissingOrInvalidStock,
    SUM(CASE WHEN StockQty < 0 THEN 1 ELSE 0 END) AS NegativeStock,
    SUM(CASE WHEN VatRate IS NULL THEN 1 ELSE 0 END) AS MissingOrInvalidVat,
    SUM(CASE WHEN NetPrice IS NULL OR GrossPrice IS NULL THEN 1 ELSE 0 END) AS MissingPrices,
    SUM(CASE WHEN NetPrice = 0 OR GrossPrice = 0 THEN 1 ELSE 0 END) AS ZeroPrices,
    SUM(CASE WHEN NetPrice < 0 OR GrossPrice < 0 THEN 1 ELSE 0 END) AS NegativePrices
FROM Cleaned;

-- Products with missing or invalid prices.
SELECT
    id,
    nazwa,
    stan,
    jm,
    vat,
    cennik_kartuzy_n_pln AS NetPrice,
    cennik_kartuzy_b_pln AS GrossPrice
FROM dbo.Oferta
WHERE cennik_kartuzy_n_pln IS NULL
   OR cennik_kartuzy_b_pln IS NULL
   OR cennik_kartuzy_n_pln <= 0
   OR cennik_kartuzy_b_pln <= 0
ORDER BY id;

-- Duplicate product names.
SELECT
    LTRIM(RTRIM(nazwa)) AS ProductName,
    COUNT(*) AS DuplicateCount
FROM dbo.Oferta
WHERE NULLIF(LTRIM(RTRIM(nazwa)), '') IS NOT NULL
GROUP BY LTRIM(RTRIM(nazwa))
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC, ProductName;

-- Records with stock values that cannot be converted to numbers.
SELECT
    id,
    nazwa,
    stan
FROM dbo.Oferta
WHERE NULLIF(LTRIM(RTRIM(stan)), '') IS NOT NULL
  AND TRY_CONVERT(decimal(18,2), REPLACE(LTRIM(RTRIM(stan)), ',', '.')) IS NULL
ORDER BY id;

-- Records with unusual VAT values.
WITH VatCleaned AS (
    SELECT
        id,
        nazwa,
        vat,
        TRY_CONVERT(decimal(5,2), REPLACE(REPLACE(NULLIF(LTRIM(RTRIM(vat)), ''), '%', ''), ',', '.')) AS VatRate
    FROM dbo.Oferta
)
SELECT
    id,
    nazwa,
    vat,
    VatRate
FROM VatCleaned
WHERE VatRate IS NULL
   OR VatRate NOT IN (0, 5, 8, 23)
ORDER BY id;

