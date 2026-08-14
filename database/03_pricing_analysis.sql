USE [tomawebp_oferta];
GO

-- Overall pricing summary.
SELECT
    COUNT(*) AS ProductCount,
    AVG(cennik_kartuzy_n_pln) AS AverageNetPrice,
    AVG(cennik_kartuzy_b_pln) AS AverageGrossPrice,
    MIN(NULLIF(cennik_kartuzy_b_pln, 0)) AS LowestPositiveGrossPrice,
    MAX(cennik_kartuzy_b_pln) AS HighestGrossPrice
FROM dbo.Oferta;

-- Top 20 most expensive products by gross price.
SELECT TOP 20
    id,
    nazwa,
    stan,
    jm,
    vat,
    cennik_kartuzy_b_pln AS GrossPrice
FROM dbo.Oferta
WHERE cennik_kartuzy_b_pln IS NOT NULL
ORDER BY cennik_kartuzy_b_pln DESC;

-- Top 20 cheapest products by gross price, excluding zero prices.
SELECT TOP 20
    id,
    nazwa,
    stan,
    jm,
    vat,
    cennik_kartuzy_b_pln AS GrossPrice
FROM dbo.Oferta
WHERE cennik_kartuzy_b_pln IS NOT NULL
  AND cennik_kartuzy_b_pln > 0
ORDER BY cennik_kartuzy_b_pln ASC;

-- Products with alternative gross prices.
SELECT
    COUNT(*) AS ProductsWithAlternativeGrossPrice
FROM dbo.Oferta
WHERE cennik_kartuzy_b_pln_alt IS NOT NULL
  AND cennik_kartuzy_b_pln_alt > 0
  AND cennik_kartuzy_b_pln_alt <> cennik_kartuzy_b_pln;

-- Largest differences between standard and alternative gross prices.
SELECT TOP 50
    id,
    nazwa,
    cennik_kartuzy_b_pln AS GrossPrice,
    cennik_kartuzy_b_pln_alt AS GrossPriceAlt,
    ROUND(cennik_kartuzy_b_pln_alt - cennik_kartuzy_b_pln, 2) AS GrossPriceDiff,
    CASE
        WHEN cennik_kartuzy_b_pln > 0
        THEN ROUND((cennik_kartuzy_b_pln_alt - cennik_kartuzy_b_pln) / cennik_kartuzy_b_pln * 100, 2)
    END AS GrossPriceDiffPct
FROM dbo.Oferta
WHERE cennik_kartuzy_b_pln_alt IS NOT NULL
  AND cennik_kartuzy_b_pln_alt > 0
  AND cennik_kartuzy_b_pln IS NOT NULL
  AND cennik_kartuzy_b_pln > 0
ORDER BY ABS(cennik_kartuzy_b_pln_alt - cennik_kartuzy_b_pln) DESC;

-- Price bands for reporting.
SELECT
    CASE
        WHEN cennik_kartuzy_b_pln IS NULL OR cennik_kartuzy_b_pln = 0 THEN 'Missing or zero'
        WHEN cennik_kartuzy_b_pln < 5 THEN '0.01-4.99'
        WHEN cennik_kartuzy_b_pln < 10 THEN '5.00-9.99'
        WHEN cennik_kartuzy_b_pln < 25 THEN '10.00-24.99'
        WHEN cennik_kartuzy_b_pln < 50 THEN '25.00-49.99'
        ELSE '50.00+'
    END AS GrossPriceBand,
    COUNT(*) AS ProductCount
FROM dbo.Oferta
GROUP BY
    CASE
        WHEN cennik_kartuzy_b_pln IS NULL OR cennik_kartuzy_b_pln = 0 THEN 'Missing or zero'
        WHEN cennik_kartuzy_b_pln < 5 THEN '0.01-4.99'
        WHEN cennik_kartuzy_b_pln < 10 THEN '5.00-9.99'
        WHEN cennik_kartuzy_b_pln < 25 THEN '10.00-24.99'
        WHEN cennik_kartuzy_b_pln < 50 THEN '25.00-49.99'
        ELSE '50.00+'
    END
ORDER BY ProductCount DESC;

