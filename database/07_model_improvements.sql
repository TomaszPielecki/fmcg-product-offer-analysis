-- 07_model_improvements.sql : dodatkowy model (slowniki, typowane dane, widoki ilosciowe). Nie modyfikuje dbo.Oferta.
IF OBJECT_ID('dbo.Kategoria') IS NULL
CREATE TABLE dbo.Kategoria(KategoriaId int IDENTITY PRIMARY KEY, Nazwa nvarchar(60) NOT NULL UNIQUE);
IF OBJECT_ID('dbo.PrefiksKategorii') IS NULL
CREATE TABLE dbo.PrefiksKategorii(Prefiks nvarchar(20) NOT NULL PRIMARY KEY, KategoriaId int NOT NULL REFERENCES dbo.Kategoria(KategoriaId));
GO
DELETE FROM dbo.PrefiksKategorii;
DELETE FROM dbo.Kategoria;
INSERT dbo.Kategoria(Nazwa) VALUES
(N'Słodycze'),(N'Napoje'),(N'Kawa i herbata'),(N'Nabiał'),(N'Konserwy i przetwory'),
(N'Przyprawy i zupy'),(N'Produkty sypkie i makarony'),(N'Przekąski'),(N'Śniadaniowe'),
(N'Chemia i higiena'),(N'Karma dla zwierząt'),(N'Piwo i alkohol'),(N'Inne');
GO
INSERT dbo.PrefiksKategorii(Prefiks,KategoriaId)
SELECT p.Prefiks,k.KategoriaId FROM (VALUES
(N'C',N'Słodycze'),(N'CU',N'Słodycze'),(N'CZ',N'Słodycze'),(N'WAF',N'Słodycze'),(N'G',N'Słodycze'),(N'Y',N'Słodycze'),
(N'ŚW',N'Słodycze'),(N'LIZAK',N'Słodycze'),(N'ŻELKI',N'Słodycze'),(N'ŻEL',N'Słodycze'),(N'DRA',N'Słodycze'),(N'W',N'Słodycze'),
(N'BAT',N'Słodycze'),(N'BOM',N'Słodycze'),(N'KISIEL',N'Słodycze'),(N'BUDYŃ',N'Słodycze'),(N'DESER',N'Słodycze'),
(N'N',N'Napoje'),(N'WODA',N'Napoje'),(N'SOK',N'Napoje'),(N'NAP',N'Napoje'),(N'KUBUŚ',N'Napoje'),
(N'KAW',N'Kawa i herbata'),(N'KAWA',N'Kawa i herbata'),(N'H',N'Kawa i herbata'),(N'KAKAO',N'Kawa i herbata'),
(N'JOG',N'Nabiał'),(N'SER',N'Nabiał'),(N'SEREK',N'Nabiał'),(N'MLEKO',N'Nabiał'),(N'MARG',N'Nabiał'),
(N'KON',N'Konserwy i przetwory'),(N'KONC',N'Konserwy i przetwory'),(N'FIL',N'Konserwy i przetwory'),(N'SAŁ',N'Konserwy i przetwory'),
(N'Z',N'Konserwy i przetwory'),(N'FASOLA',N'Konserwy i przetwory'),(N'KUKUR',N'Konserwy i przetwory'),(N'BURACZKI',N'Konserwy i przetwory'),
(N'OGÓRKI',N'Konserwy i przetwory'),(N'KOMPOT',N'Konserwy i przetwory'),(N'DZEM',N'Konserwy i przetwory'),
(N'AMINO',N'Przyprawy i zupy'),(N'KNORR',N'Przyprawy i zupy'),(N'KET',N'Przyprawy i zupy'),(N'SOS',N'Przyprawy i zupy'),
(N'PAPRYKA',N'Przyprawy i zupy'),(N'PIEPRZ',N'Przyprawy i zupy'),(N'SÓL',N'Przyprawy i zupy'),(N'MAJERANEK',N'Przyprawy i zupy'),
(N'CZOSNEK',N'Przyprawy i zupy'),(N'PRZY',N'Przyprawy i zupy'),(N'POM',N'Przyprawy i zupy'),(N'KWAS',N'Przyprawy i zupy'),
(N'M',N'Produkty sypkie i makarony'),(N'KASZA',N'Produkty sypkie i makarony'),(N'RYŻ',N'Produkty sypkie i makarony'),
(N'MĄKA',N'Produkty sypkie i makarony'),(N'CUKIER',N'Produkty sypkie i makarony'),(N'OLEJ',N'Produkty sypkie i makarony'),
(N'CHR',N'Przekąski'),(N'CHI',N'Przekąski'),(N'PAL',N'Przekąski'),(N'POPCORN',N'Przekąski'),(N'ORZ',N'Przekąski'),
(N'PL',N'Śniadaniowe'),(N'PŁATKI',N'Śniadaniowe'),
(N'PŁ',N'Chemia i higiena'),(N'PR',N'Chemia i higiena'),(N'PAP',N'Chemia i higiena'),(N'BROS',N'Chemia i higiena'),
(N'MYD',N'Chemia i higiena'),(N'KREM',N'Chemia i higiena'),
(N'MK',N'Karma dla zwierząt'),(N'PIWO',N'Piwo i alkohol')
) p(Prefiks,Kat) JOIN dbo.Kategoria k ON k.Nazwa=p.Kat;
GO
INSERT dbo.PrefiksKategorii(Prefiks,KategoriaId)
SELECT p.Prefiks,k.KategoriaId FROM (VALUES
(N'LAJK',N'Przekąski'),(N'HOCH',N'Nabiał'),(N'HOCHL',N'Nabiał'),(N'KEFIR',N'Nabiał'),(N'LODY',N'Nabiał'),
(N'TEO',N'Karma dla zwierząt'),(N'PREVITAL',N'Karma dla zwierząt'),(N'TURNA',N'Karma dla zwierząt'),
(N'GAL',N'Konserwy i przetwory'),(N'VEGETA',N'Przyprawy i zupy'),(N'CURRY',N'Przyprawy i zupy'),(N'OREGANO',N'Przyprawy i zupy'),
(N'KOLENDRA',N'Przyprawy i zupy'),(N'ESTRAGON',N'Przyprawy i zupy'),(N'SZAFRAN',N'Przyprawy i zupy'),(N'MUSZT',N'Przyprawy i zupy'),
(N'MIÓD',N'Konserwy i przetwory'),(N'NUTELLA',N'Słodycze'),(N'DROPS',N'Słodycze'),(N'SĘKACZ',N'Słodycze'),(N'PUDDING',N'Słodycze')
) p(Prefiks,Kat) JOIN dbo.Kategoria k ON k.Nazwa=p.Kat
WHERE NOT EXISTS(SELECT 1 FROM dbo.PrefiksKategorii x WHERE x.Prefiks=p.Prefiks);
GO-- Typowana, uporzadkowana dimension produktu
CREATE OR ALTER VIEW dbo.vw_Oferta_Produkt AS
SELECT a.id, a.ProductName, a.UnitOfMeasure,
  a.StockQty, a.VatRate, a.NetPrice, a.GrossPrice, a.StockStatus, a.StockValueNet, a.StockValueGross,
  p.Prefiks,
  COALESCE(k.Nazwa, CASE WHEN LEFT(a.ProductName,1)=N'.' THEN N'Chemia i higiena' ELSE N'Inne' END) AS Kategoria
FROM dbo.vw_Oferta_Analytics a
CROSS APPLY (SELECT LTRIM(CASE WHEN LEFT(a.ProductName,1)=N'.' THEN SUBSTRING(a.ProductName,2,500) ELSE a.ProductName END) AS Nm) n
CROSS APPLY (SELECT UPPER(LEFT(n.Nm, NULLIF(PATINDEX(N'%[. ]%', n.Nm+N' ')-1,0))) AS Prefiks) p
LEFT JOIN dbo.PrefiksKategorii pk ON pk.Prefiks = p.Prefiks
LEFT JOIN dbo.Kategoria k ON k.KategoriaId = pk.KategoriaId;
GO
CREATE OR ALTER VIEW dbo.vw_Oferta_Kategorie AS
SELECT Kategoria,
  COUNT(*) AS LiczbaProduktow,
  SUM(CASE WHEN StockQty IS NOT NULL THEN 1 ELSE 0 END) AS ProduktyZeStanem,
  SUM(CASE WHEN UnitOfMeasure=N'szt' THEN StockQty END) AS StanSztuk,
  SUM(StockValueNet) AS WartoscStanuNetto,
  SUM(StockValueGross) AS WartoscStanuBrutto,
  AVG(NetPrice) AS SredniaCenaNetto,
  SUM(CASE WHEN StockStatus=N'Low stock' THEN 1 ELSE 0 END) AS NiskiStan,
  SUM(CASE WHEN StockStatus=N'No stock data' THEN 1 ELSE 0 END) AS BrakDanychStan
FROM dbo.vw_Oferta_Produkt GROUP BY Kategoria;
GO
-- Tabele pod prawdziwe dane (puste - do zasilenia z ERP/kasy)
IF OBJECT_ID('dbo.Sprzedaz') IS NULL
CREATE TABLE dbo.Sprzedaz(SprzedazId bigint IDENTITY PRIMARY KEY, OfertaId int NOT NULL REFERENCES dbo.Oferta(id),
  DataSprzedazy date NOT NULL, Ilosc decimal(18,3) NOT NULL CHECK(Ilosc>=0), WartoscNetto decimal(18,2) NULL);
IF OBJECT_ID('dbo.StanMagazynowyHistoria') IS NULL
CREATE TABLE dbo.StanMagazynowyHistoria(OfertaId int NOT NULL REFERENCES dbo.Oferta(id), DataStanu date NOT NULL,
  Ilosc decimal(18,3) NOT NULL CHECK(Ilosc>=0), PRIMARY KEY(OfertaId,DataStanu));
GO
