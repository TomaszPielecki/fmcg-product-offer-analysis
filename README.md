# FMCG | Analiza oferty i widoczności zapasu

Projekt analityczny dla branży FMCG: łączy bazę SQL Server, dashboard w R Shiny i raport Quarto, aby pokazać stan katalogu, dostępność produktów, ceny oraz jakość danych.

> **Wynik analizy:** w badanym zbiorze jest 2 910 produktów, a dla 962 (33,1%) nie zapisano ilości. Brak ilości oznacza stan nieznany, a nie zero. Baza nie zawiera historii sprzedaży ani kosztów zakupu, dlatego nie pozwala policzyć marży, rotacji ani rzeczywistego zysku.

## Co znajdziesz w projekcie

- **Dashboard Shiny** — osiem wskaźników, wykres dostępności, rozkład cen, szacowana wartość zapasu według grup, wyszukiwany katalog i kontrola jakości danych.
- **Raport Quarto** — źródło raportu z analizą cen, zapasu, jakości ewidencji i ograniczeń danych: [otwórz plik Quarto](oferta_dashboard.qmd). Wyrenderowany plik HTML pozostaje lokalny, ponieważ zawiera szczegółowe dane oferty.
- **Raport zarządczy** — interpretacja wyników i zalecane kolejne kroki: [przejdź do raportu](docs/raport_zarzadczy.md).
- **SQL** — skrypty schematu, widoków analitycznych, kontroli jakości i rozszerzonego modelu danych w katalogu [`database/`](database/).

## KPI w dashboardzie

Dashboard pokazuje bieżący obraz dostępnego wyciągu:

| Obszar | Wskaźniki |
|---|---|
| Katalog i stany | Liczba produktów, pokrycie stanów, produkty na stanie, niski lub zerowy stan, pozycje bez danych o stanie |
| Ceny i wycena orientacyjna | Mediana ceny brutto, szacowana wartość znanego zapasu |
| Klasyfikacja | Udział grupy „Inne” w szacowanej wartości zapasu |
| Jakość | Niezgodności ceny brutto z wyliczeniem na podstawie ceny netto i VAT oraz lista innych wykrytych problemów |

### Jakich KPI brakuje do oceny wyniku firmy?

Marża brutto według produktu, rotacja i dni zapasu oraz dostępność w dniach z popytem wymagają danych, których obecnie nie ma: transakcji sprzedaży, kosztów zakupu i historii stanów z datami. Nie zastępujemy ich ceną brutto ani wartością zapasu — te miary nie mówią, ile firma zarobiła. Priorytety uzupełnienia danych i definicje KPI opisuje [raport zarządczy](docs/raport_zarzadczy.md).

## Uruchomienie aplikacji

Wymagania: R, sterownik ODBC Driver 18 for SQL Server, lokalna baza `tomawebp_oferta` z widokami analitycznymi oraz pakiety R: `shiny`, `bslib`, `DBI`, `odbc`, `plotly` i `DT`.

Z głównego katalogu projektu:

```r
install.packages(c("shiny", "bslib", "DBI", "odbc", "plotly", "DT"))
shiny::runApp("shiny")
```

Domyślnie aplikacja łączy się z `localhost\\SQLEXPRESS`, używając uwierzytelniania Windows. Połączenie można skonfigurować zmiennymi środowiskowymi `MSSQL_SERVER`, `MSSQL_DATABASE` i `MSSQL_DRIVER`.

## Renderowanie raportu

Wymagane są Quarto, R oraz pakiety `knitr`, `DBI`, `odbc`, `plotly` i `DT`.

```sh
quarto render oferta_dashboard.qmd
```

Raport i aplikacja odczytują widok `dbo.vw_Oferta_Analytics`; kontrola jakości korzysta z `dbo.vw_Oferta_DataQualityIssues`.

## Dane i ograniczenia interpretacji

- Ilość pochodzi z `dbo.Oferta.stan`. Pusta wartość oznacza **brak danych**, nie potwierdzony stan zerowy.
- Jednostki `kg`, `op` i `szt` należy analizować osobno.
- Wartość zapasu to szacunek `ilość × cena brutto z oferty`; nie jest kosztem magazynowym, przychodem ani zyskiem.
- Grupy produktów są wnioskowane z nazw. Duży udział „Inne” wskazuje na potrzebę poprawy klasyfikacji.
- Historia stanów i sprzedaż są obecnie puste. Historia prezentowana w raporcie Quarto jest wyłącznie symulacją i nie opisuje działalności firmy.
- Próg niskiego stanu 10 jednostek jest wspólny dla różnych miar i powinien być traktowany jako sygnał do przeglądu, nie gotowa rekomendacja zamówienia.

> **Uwaga:** `database/00_create_database_and_load_data.sql` usuwa i odtwarza tabelę `dbo.Oferta`. Nie uruchamiaj go na bazie z danymi, które chcesz zachować.

## Publikacja i prywatność danych

Repozytorium zawiera kod i opis analizy, ale nie pełny zestaw źródłowy. Skrypt z 2 910 wierszami nazw produktów, cen i stanów (`database/00_create_database_and_load_data.sql`) oraz wyrenderowany raport HTML pozostają lokalne. Nie publikuj ich w publicznym repozytorium. Dashboard łączy się z lokalną bazą; przed uruchomieniem przygotuj własny, autoryzowany zbiór danych.
