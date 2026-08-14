# Power BI Dashboard Guide

This guide describes how to build the final Power BI dashboard for the FMCG Product Offer & Pricing Analysis project.

## 1. Data Source

Connect Power BI Desktop to SQL Server and select:

- Database: `tomawebp_oferta`
- Mode: `Import`
- Views:
  - `dbo.vw_Oferta_Analytics`
  - `dbo.vw_Oferta_DataQualityIssues`

Run `database/00_create_database_schema.sql`, load an authorized dataset and then run `database/05_views_for_powerbi.sql` before connecting Power BI.

The full source dataset and the `.pbix` working file are intentionally kept outside the public repository. DAX measures remain documented in `docs/kpi_definitions.md`, while exported report screenshots provide the portfolio preview.

## 2. Model Setup

After loading the views:

1. Check data types:
   - `id`: Whole number
   - `StockQty`: Decimal number
   - `VatRate`: Decimal number
   - `NetPrice`, `GrossPrice`, `ExpectedGrossPrice`, `GrossPriceDifference`: Decimal number
   - `CreatedAt`: Date/Time
2. Format price fields as PLN.
3. Sort `GrossPriceBand` by `GrossPriceBandSort`.
4. Create a separate `Measures` table.
5. Add the DAX measures from `docs/kpi_definitions.md`.

Recommended slicers:

- `InferredProductGroup`
- `UnitOfMeasure`
- `VatRate`
- `StockStatus`
- `PriceStatus`

## 3. Page 1: Overview

Purpose: show the overall size, availability and structure of the offer.

Cards:

- Total Products
- Products In Stock
- Products Out Of Stock
- Products With Missing Price
- Average Gross Price

Visuals:

- Donut chart: products by `StockStatus`
- Column chart: products by `VatRate`
- Bar chart: products by `UnitOfMeasure`
- Bar chart or table: top 20 products by `GrossPrice`
- Bar chart: products by `InferredProductGroup`

Recommended table fields:

- `ProductName`
- `StockQty`
- `UnitOfMeasure`
- `VatRate`
- `GrossPrice`
- `InferredProductGroup`

## 4. Page 2: Pricing Analysis

Purpose: analyze standard prices, alternative prices and VAT-based price differences.

Cards:

- Average Net Price
- Average Gross Price
- Products With Alternative Gross Price
- Average Alternative Gross Price Difference
- Products With VAT Mismatch

Visuals:

- Scatter plot: `NetPrice` vs `GrossPrice`
- Column chart: products by `GrossPriceBand`
- Bar chart: top products by `AlternativeGrossPriceDifference`
- Bar chart: top products by absolute `GrossPriceDifference`
- Matrix or table: pricing validation details

Recommended table fields:

- `ProductName`
- `NetPrice`
- `GrossPrice`
- `ExpectedGrossPrice`
- `GrossPriceDifference`
- `GrossPriceAlt`
- `AlternativeGrossPriceDifference`
- `PriceStatus`
- `HasVatPriceMismatch`

## 5. Page 3: Data Quality

Purpose: identify records that need correction before the offer can be trusted operationally.

Cards:

- Data Quality Issues
- Data Quality Issue Rate
- Products With Missing Price
- Products With Missing Stock
- Products With VAT Mismatch

Visuals:

- Bar chart: issues by `DataQualityIssue`
- Bar chart: issues by `DataQualityArea`
- Donut chart: products by `PriceStatus`
- Donut chart: products by `VatStatus`
- Bar chart: products by `StockStatus`

Recommended table fields from `vw_Oferta_DataQualityIssues`:

- `DataQualityPriority`
- `DataQualityArea`
- `DataQualityIssue`
- `id`
- `ProductName`
- `StockQty`
- `UnitOfMeasure`
- `VatRate`
- `GrossPrice`
- `GrossPriceDifference`

Sort the issue table by `DataQualityPriority` ascending.

## 6. Design Notes

- Keep KPI cards at the top of each page.
- Use simple colors: green for valid/available, amber for warnings, red for issues.
- Avoid too many visuals on one page; the dashboard should be easy to scan.
- Use descriptive chart titles such as `Products by stock status`, not generic names.
- Put detail tables at the bottom of each page.
- Add page-level filters only when they help the analysis.

## 7. Validation Checklist

Before saving the final dashboard:

- Confirm row count equals 2,910 products.
- Confirm all cards react to slicers.
- Confirm `GrossPriceBand` sorts using `GrossPriceBandSort`.
- Confirm PLN formatting is applied to price fields.
- Confirm the data quality page uses `vw_Oferta_DataQualityIssues`.
- Confirm issue table sorting starts with the highest-priority problems.
- Confirm no chart shows blank categories unless the blank is analytically useful.

## 8. Export And Portfolio Handoff

Save the Power BI file as:

`powerbi/fmcg_product_offer_analysis.pbix`

Save screenshots as:

- `powerbi/screenshots/01_overview.png`
- `powerbi/screenshots/02_pricing.png`
- `powerbi/screenshots/03_data_quality.png`

After exporting screenshots, update:

- `docs/final_insights.md`
- root `README.md`
