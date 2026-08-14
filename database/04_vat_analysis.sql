USE [tomawebp_oferta];
GO

WITH Cleaned AS (
    SELECT
        id,
        nazwa,
        vat,
        TRY_CONVERT(decimal(5,2), REPLACE(REPLACE(NULLIF(LTRIM(RTRIM(vat)), ''), '%', ''), ',', '.')) AS VatRate,
        cennik_kartuzy_n_pln AS NetPrice,
        cennik_kartuzy_b_pln AS GrossPrice
    FROM dbo.Oferta
)
SELECT
    VatRate,
    COUNT(*) AS ProductCount,
    AVG(NetPrice) AS AverageNetPrice,
    AVG(GrossPrice) AS AverageGrossPrice
FROM Cleaned
GROUP BY VatRate
ORDER BY ProductCount DESC;

-- Gross price validation against net price and VAT.
WITH Cleaned AS (
    SELECT
        id,
        nazwa,
        vat,
        TRY_CONVERT(decimal(5,2), REPLACE(REPLACE(NULLIF(LTRIM(RTRIM(vat)), ''), '%', ''), ',', '.')) AS VatRate,
        cennik_kartuzy_n_pln AS NetPrice,
        cennik_kartuzy_b_pln AS GrossPrice
    FROM dbo.Oferta
),
Validation AS (
    SELECT
        id,
        nazwa,
        vat,
        VatRate,
        NetPrice,
        GrossPrice,
        ROUND(NetPrice * (1 + VatRate / 100.0), 2) AS ExpectedGrossPrice,
        ROUND(GrossPrice - ROUND(NetPrice * (1 + VatRate / 100.0), 2), 2) AS GrossPriceDifference
    FROM Cleaned
    WHERE NetPrice IS NOT NULL
      AND GrossPrice IS NOT NULL
      AND VatRate IS NOT NULL
)
SELECT TOP 100
    id,
    nazwa,
    vat,
    NetPrice,
    GrossPrice,
    ExpectedGrossPrice,
    GrossPriceDifference
FROM Validation
ORDER BY ABS(GrossPriceDifference) DESC, id;

-- Count of records with gross price differences above one grosz.
WITH Cleaned AS (
    SELECT
        TRY_CONVERT(decimal(5,2), REPLACE(REPLACE(NULLIF(LTRIM(RTRIM(vat)), ''), '%', ''), ',', '.')) AS VatRate,
        cennik_kartuzy_n_pln AS NetPrice,
        cennik_kartuzy_b_pln AS GrossPrice
    FROM dbo.Oferta
),
Validation AS (
    SELECT
        ROUND(GrossPrice - ROUND(NetPrice * (1 + VatRate / 100.0), 2), 2) AS GrossPriceDifference
    FROM Cleaned
    WHERE NetPrice IS NOT NULL
      AND GrossPrice IS NOT NULL
      AND VatRate IS NOT NULL
)
SELECT
    COUNT(*) AS ProductsChecked,
    SUM(CASE WHEN ABS(GrossPriceDifference) > 0.01 THEN 1 ELSE 0 END) AS ProductsWithVatPriceMismatch
FROM Validation;

