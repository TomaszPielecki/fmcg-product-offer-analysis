# Data Dictionary

Source database: `tomawebp_oferta`  
Source table: `dbo.Oferta`

| Column | Description | Notes |
|---|---|---|
| `id` | Technical product record identifier | SQL Server identity column |
| `lp` | Original line/product number | Stored as text |
| `nazwa` | Product name | Cleaned with `LTRIM/RTRIM` in reporting view |
| `stan` | Stock quantity | Stored as text, converted to decimal in reporting view |
| `jm` | Unit of measure | Examples: `szt`, `kg`, `op` |
| `vat` | VAT rate | Stored as text with `%`, converted to numeric rate |
| `cennik_kartuzy_n_pln` | Standard net price in PLN | Decimal |
| `cennik_kartuzy_b_pln` | Standard gross price in PLN | Decimal |
| `cennik_kartuzy_n_pln_alt` | Alternative net price in PLN | Decimal, often zero when not used |
| `cennik_kartuzy_b_pln_alt` | Alternative gross price in PLN | Decimal, often zero when not used |
| `data_utworzenia` | Record creation timestamp | Used for data freshness checks |

## Reporting View Fields

View: `dbo.vw_Oferta_Analytics`

| Field | Description |
|---|---|
| `ProductName` | Trimmed product name |
| `StockQty` | Numeric stock quantity |
| `UnitOfMeasure` | Trimmed unit of measure |
| `VatRate` | Numeric VAT rate |
| `NetPrice` | Standard net price |
| `GrossPrice` | Standard gross price |
| `NetPriceAlt` | Alternative net price |
| `GrossPriceAlt` | Alternative gross price |
| `StockStatus` | `In stock`, `Out of stock`, `Missing stock`, `Invalid stock` |
| `PriceStatus` | `Valid price`, `Missing price`, `Invalid price` |
| `VatStatus` | `Valid VAT`, `Invalid VAT`, `Unusual VAT` |
| `ExpectedGrossPrice` | Gross price calculated from net price and VAT |
| `GrossPriceDifference` | Difference between actual and expected gross price |
| `HasVatPriceMismatch` | Flag for products where gross price differs from calculated gross price by more than 0.01 PLN |
| `AlternativeGrossPriceDifference` | Difference between alternative and standard gross price |
| `GrossPriceBand` | Gross price range used for Power BI charts |
| `GrossPriceBandSort` | Numeric sort order for `GrossPriceBand` |
| `HasAlternativeGrossPrice` | Flag for products with alternative gross price different from standard gross price |
| `HasAlternativeNetPrice` | Flag for products with alternative net price different from standard net price |
| `InferredProductGroup` | Simple product group inferred from product name |

View: `dbo.vw_Oferta_DataQualityIssues`

| Field | Description |
|---|---|
| `DataQualityIssue` | Main detected issue for the product record |
| `DataQualityArea` | Issue area: product, stock, price or VAT |
| `DataQualityPriority` | Numeric priority used for sorting issue tables in Power BI |

## Data Limitations

- Product groups are inferred from product names, not from a master category table.
- The dataset does not contain sales quantities, revenue, margin or customer data.
- The dataset does not contain suppliers or purchase prices.
- The dataset represents a product offer snapshot, not a full price history.
- Stock values and VAT rates come from text fields and require conversion in the reporting view.
