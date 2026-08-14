USE [tomawebp_oferta];
GO

-- Basic row count.
SELECT COUNT(*) AS TotalRows
FROM dbo.Oferta;

-- First 20 records.
SELECT TOP 20 *
FROM dbo.Oferta
ORDER BY id;

-- Table schema.
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Oferta'
ORDER BY ORDINAL_POSITION;

-- Basic profile of source fields.
SELECT
    COUNT(*) AS TotalProducts,
    COUNT(DISTINCT nazwa) AS DistinctProductNames,
    COUNT(DISTINCT jm) AS DistinctUnits,
    COUNT(DISTINCT vat) AS DistinctVatRates,
    MIN(data_utworzenia) AS FirstCreatedAt,
    MAX(data_utworzenia) AS LastCreatedAt
FROM dbo.Oferta;

-- Products by unit of measure.
SELECT
    jm,
    COUNT(*) AS ProductCount
FROM dbo.Oferta
GROUP BY jm
ORDER BY ProductCount DESC;

