# FMCG Product Offer & Pricing Analysis

SQL Server and Power BI portfolio project focused on product availability, pricing structure, VAT validation, alternative price lists and data quality in an FMCG offer.

## Project overview

The analysis was developed against a snapshot containing 2,910 product records. It demonstrates a complete BI workflow: source profiling, reusable SQL transformations, business KPI definitions and a three-page Power BI dashboard specification.

The public repository intentionally contains the database schema and analytical logic, but not the full source dataset or the Power BI working file. Detailed product prices and stock quantities remain local.

## Business questions

- How large is the product offer and how is it structured?
- Which products are in stock, out of stock or missing stock information?
- Which products have missing, zero or invalid prices?
- Are gross prices consistent with net prices and VAT rates?
- Which products use alternative price lists?
- What data quality issues should be fixed first?

## Tools and skills

- SQL Server and SSMS
- T-SQL data profiling and transformation
- Data quality checks
- DAX measure design
- Power BI dashboard design
- Git and GitHub documentation

## Repository structure

```text
fmcg-product-offer-analysis/
|-- database/
|   |-- 00_create_database_schema.sql
|   |-- 01_basic_checks.sql
|   |-- 02_data_quality.sql
|   |-- 03_pricing_analysis.sql
|   |-- 04_vat_analysis.sql
|   |-- 05_views_for_powerbi.sql
|-- docs/
|   |-- business_context.md
|   |-- data_dictionary.md
|   |-- kpi_definitions.md
|   |-- linkedin_post.md
|-- powerbi/
|   |-- README_POWERBI.md
|   |-- screenshots/
|       |-- README.md
|-- .gitignore
|-- README.md
```

## SQL workflow

1. Run [`database/00_create_database_schema.sql`](database/00_create_database_schema.sql) in SSMS.
2. Load an authorized dataset into `dbo.Oferta` using the schema documented in [`docs/data_dictionary.md`](docs/data_dictionary.md).
3. Run [`database/01_basic_checks.sql`](database/01_basic_checks.sql) to validate row counts and source fields.
4. Run [`database/02_data_quality.sql`](database/02_data_quality.sql) to identify missing, duplicated or invalid values.
5. Run [`database/03_pricing_analysis.sql`](database/03_pricing_analysis.sql) for standard and alternative price analysis.
6. Run [`database/04_vat_analysis.sql`](database/04_vat_analysis.sql) to compare stored gross prices with calculated VAT values.
7. Run [`database/05_views_for_powerbi.sql`](database/05_views_for_powerbi.sql) to create the reporting layer.

> The original loader is excluded from the public repository because it contains detailed product, stock and price data. Use only data you are authorized to publish or process.

## Reporting layer

Power BI uses two SQL views:

- `dbo.vw_Oferta_Analytics` — cleaned product offer with reporting statuses, VAT validation, price bands and inferred product groups.
- `dbo.vw_Oferta_DataQualityIssues` — prioritized records requiring data correction.

The DAX definitions are available in [`docs/kpi_definitions.md`](docs/kpi_definitions.md). Keeping the measures as text makes the analytical logic reviewable without distributing the `.pbix` file.

## Dashboard pages

### 1. Overview

Offer size, stock availability, VAT structure, units of measure, product groups and the most expensive products.

### 2. Pricing Analysis

Standard and alternative prices, price bands, VAT price differences and pricing outliers.

### 3. Data Quality

Missing prices, missing stock, invalid VAT values and prioritized records requiring correction.

Detailed build instructions are available in [`powerbi/README_POWERBI.md`](powerbi/README_POWERBI.md).

## Dashboard screenshots

The following exported report pages will be added after final Power BI validation:

- `powerbi/screenshots/01_overview.png`
- `powerbi/screenshots/02_pricing.png`
- `powerbi/screenshots/03_data_quality.png`

The `.pbix` file remains local; the screenshots and documented DAX provide the public portfolio preview.

## Data limitations

- The dataset is an offer snapshot rather than a sales fact table.
- It does not contain revenue, units sold, margin, customers or suppliers.
- Product groups are inferred from product names and are analytical approximations.
- Stock quantities use different units of measure and should not be aggregated without context.
- Stock and VAT source fields are stored as text and converted in the reporting view.

## Portfolio value

This project demonstrates practical SQL profiling, data quality design, price and VAT validation, reusable reporting views, KPI definition and the path from operational data to a Power BI dashboard.
