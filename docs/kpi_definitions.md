# KPI Definitions

Recommended Power BI model:

- Load `dbo.vw_Oferta_Analytics`.
- Load `dbo.vw_Oferta_DataQualityIssues`.
- Create a separate table called `Measures` and store all measures there.
- Format price measures as PLN.
- Sort `GrossPriceBand` by `GrossPriceBandSort`.

## Product Availability

### Total Products

Number of product records in the offer.

```DAX
Total Products =
DISTINCTCOUNT(vw_Oferta_Analytics[id])
```

### Products In Stock

Number of products where stock is greater than zero.

```DAX
Products In Stock =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[StockStatus] = "In stock"
)
```

### Products Out Of Stock

Number of products where stock equals zero.

```DAX
Products Out Of Stock =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[StockStatus] = "Out of stock"
)
```

### Products With Missing Stock

Number of products where stock is blank or cannot be converted to a number.

```DAX
Products With Missing Stock =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[StockStatus] = "Missing stock"
)
```

### Total Stock Qty

Total quantity available in stock. Use carefully because products use different units of measure.

```DAX
Total Stock Qty =
SUM(vw_Oferta_Analytics[StockQty])
```

## Pricing

### Average Net Price

Average standard net product price.

```DAX
Average Net Price =
AVERAGE(vw_Oferta_Analytics[NetPrice])
```

### Average Gross Price

Average standard gross product price.

```DAX
Average Gross Price =
AVERAGE(vw_Oferta_Analytics[GrossPrice])
```

### Products With Valid Price

Number of products with valid gross price.

```DAX
Products With Valid Price =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[PriceStatus] = "Valid price"
)
```

### Products With Missing Price

Number of products with missing or zero gross price.

```DAX
Products With Missing Price =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[PriceStatus] = "Missing price"
)
```

### Products With Alternative Gross Price

Number of products where alternative gross price exists and differs from standard gross price.

```DAX
Products With Alternative Gross Price =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[HasAlternativeGrossPrice] = 1
)
```

### Products With Alternative Net Price

Number of products where alternative net price exists and differs from standard net price.

```DAX
Products With Alternative Net Price =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[HasAlternativeNetPrice] = 1
)
```

### Average Alternative Gross Price Difference

Average difference between alternative and standard gross price for products with alternative gross price.

```DAX
Average Alternative Gross Price Difference =
CALCULATE(
    AVERAGE(vw_Oferta_Analytics[AlternativeGrossPriceDifference]),
    vw_Oferta_Analytics[HasAlternativeGrossPrice] = 1
)
```

## VAT And Data Quality

### Average Gross Price Difference

Average difference between actual gross price and expected gross price calculated from net price and VAT.

```DAX
Average Gross Price Difference =
AVERAGE(vw_Oferta_Analytics[GrossPriceDifference])
```

### Products With VAT Mismatch

Number of products where actual gross price differs from calculated gross price by more than 0.01 PLN.

```DAX
Products With VAT Mismatch =
CALCULATE(
    [Total Products],
    vw_Oferta_Analytics[HasVatPriceMismatch] = 1
)
```

### Data Quality Issues

Number of records returned by `dbo.vw_Oferta_DataQualityIssues`.

```DAX
Data Quality Issues =
COUNTROWS(vw_Oferta_DataQualityIssues)
```

### Data Quality Issue Rate

Share of product records with at least one detected quality issue.

```DAX
Data Quality Issue Rate =
DIVIDE(
    [Data Quality Issues],
    [Total Products]
)
```
