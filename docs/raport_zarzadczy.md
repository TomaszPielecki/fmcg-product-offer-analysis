# Braki w ewidencji zapasu ograniczają kontrolę nad ofertą i rentownością produktów

## Wniosek dla zarządu

Obecny zbiór daje obraz katalogu i części stanów, ale nie daje firmie wiarygodnej kontroli nad całą ofertą. W bazie znajduje się 2 910 produktów, z czego 962 (33,1%) nie mają zapisanej ilości. To nie jest drobny brak w raporcie: bez poprawnego stanu magazynowego trudno odróżnić pozycję dostępną od takiej, której nie ma, a bez danych o sprzedaży i kosztach nie można ustalić, które produkty naprawdę zarabiają.

Dane wskazują na poważną lukę w ewidencji i widoczności operacyjnej. Mogą uzasadniać obawy o nadmierne zakupy, braki na półce, zalegający zapas i utraconą sprzedaż. **Nie pozwalają jednak ustalić, czy te straty rzeczywiście wystąpiły ani oszacować ich kwoty.** Do tego potrzebne są wiarygodne stany, sprzedaż oraz koszty zakupu.

## Najważniejsze wyniki

| Obszar | Wynik | Co można z niego wywnioskować |
|---|---:|---|
| Produkty w katalogu | 2 910 | Tyle pozycji obejmuje analizowany widok oferty. |
| Produkty z podaną ilością | 1 948 (66,9%) | Ilość jest znana dla około dwóch trzecich katalogu. |
| Produkty bez ilości | 962 (33,1%) | Dla jednej trzeciej pozycji dostępność jest nieznana; brak nie oznacza zera. |
| Status „Na stanie” | 1 729 (59,4% katalogu) | Tyle produktów ma zapisany dodatni stan powyżej progu niskiego stanu. |
| Niski stan | 219 (7,5% katalogu) | Tyle pozycji ma dodatni stan poniżej progu 10 jednostek zastosowanego w widoku. |
| Jawnie zapisany stan zerowy | 0 | W analizowanym widoku nie ma pozycji oznaczonych jako „Brak na stanie”. Przy 962 brakach nie oznacza to, że wszystkie produkty są dostępne. |
| Szacowana wartość brutto znanych stanów | 3 095 717,07 zł | To ilość pomnożona przez cenę brutto z oferty, a nie koszt magazynowy, przychód ani zysk. |
| Niezgodności ceny brutto z wyliczeniem VAT | 7 | Wymagają sprawdzenia cennika lub reguł podatkowych. |
| Historia stanów / sprzedaż | 0 / 0 rekordów | Nie można odtworzyć zmian zapasu ani sprawdzić, jak zapas przekładał się na sprzedaż. |

Podział statusów sumuje się do 2 910 produktów: 1 729 „Na stanie”, 219 „Niski stan” i 962 „Brak danych”. Udziały procentowe odnoszą się do całego katalogu. Nie należy traktować braku wpisu jako potwierdzonego stanu zerowego.

## Co mówi podział ilości

Zarejestrowane ilości obejmują różne jednostki. Każdą trzeba czytać osobno:

| Jednostka | Produkty z ilością | Suma ilości w tej jednostce |
|---|---:|---:|
| kg | 48 | 25 603,8 kg |
| op | 26 | 1 829 opakowań |
| szt | 1 874 | 878 877,6 szt. |

Nie wolno dodawać kilogramów, opakowań i sztuk do jednego łącznego „stanu”. Te sumy pokazują tylko skalę zapisów w każdej jednostce; nie informują same w sobie o rotacji ani o tym, czy poziom zapasu jest właściwy dla danego produktu.

Widok SQL klasyfikuje dodatnie stany poniżej 10 jako niski stan niezależnie od jednostki produktu. Próg 10 kg, 10 opakowań i 10 sztuk może mieć zupełnie inne znaczenie operacyjne. Liczbę 219 należy więc traktować jako techniczny sygnał do przeglądu, nie jako gotową listę produktów wymagających zamówienia. Docelowe progi powinny być określone per produkt lub grupa, z uwzględnieniem czasu dostawy i tempa sprzedaży.

## Wartość zapasu nie pokazuje rentowności

Widok szacuje brutto wartość znanego zapasu jako `ilość × cena brutto z oferty`. Wynik wynosi 3,10 mln zł. Największą część tej wartości przypisano grupie „Inne” — 2,25 mln zł (72,7%); grupa „Woda” odpowiada za 764,9 tys. zł (24,7%). Pozostałe grupy łącznie stanowią około 2,6% szacowanej wartości.

Ta koncentracja wymaga ostrożności. Grupy są wywnioskowane z początku lub fragmentu nazwy produktu, a nie pobrane ze sprawdzonego słownika kategorii. „Inne” obejmuje prawie trzy czwarte wyliczonej wartości, więc obecny podział asortymentu jest za mało precyzyjny, by dobrze wspierać decyzje kategorii.

Kwota 3,10 mln zł nie jest wartością księgową zapasu. Baza zawiera ceny ofertowe, ale nie zawiera kosztów zakupu, rabatów, kosztów dostawy, korekt ani danych o sprzedanej ilości. Cena brutto nie mówi, ile firma zarobiła. Do rentowności produktu potrzebne są co najmniej przychód netto ze sprzedaży i koszt sprzedanych towarów w tym samym okresie.

## Ceny i kontrola VAT

Mediana zapisanej ceny brutto wynosi 4,91 zł. Połowa zarejestrowanych cen leży poniżej tej wartości, a połowa powyżej. Kwartyl dolny wynosi 2,78 zł, górny 8,61 zł, a 90. percentyl 18,38 zł. Histogram w Shiny pokazuje kształt rozkładu; sama cena nie mówi jednak, czy produkt jest rentowny.

Widok kontroli wskazuje 7 pozycji, w których cena brutto różni się od kwoty wynikającej z ceny netto i stawki VAT zapisanej w bazie. To około 0,24% katalogu. Niezgodność może wynikać z błędnej ceny, stawki, zaokrąglenia lub wyjątku handlowego. Każdą pozycję należy sprawdzić z cennikiem źródłowym; nie należy automatycznie uznawać różnicy za stratę.

## Dlaczego to jest problem zarządczy

W FMCG decyzje dotyczące zakupów i dostępności powtarzają się szybko, a asortyment obejmuje wiele pozycji o różnych jednostkach, cenach i tempie sprzedaży. Gdy ilość jest znana tylko dla części katalogu, kierownictwo nie może z tego zbioru rzetelnie odpowiedzieć na podstawowe pytania:

- Których produktów faktycznie nie ma, a dla których tylko nie uzupełniono ewidencji?
- Które produkty sprzedają się szybko, a które zalegają?
- Ile gotówki jest zamrożone w zapasie i jaki jest jego koszt zakupu?
- Które SKU przynoszą dodatnią marżę po uwzględnieniu kosztu zakupu i rabatów?
- Czy brak produktu na półce powoduje utraconą sprzedaż, czy popyt przechodzi na substytut?
- Czy zapasy są regularnie korygowane po dostawach, sprzedaży, zwrotach i ubytkach?

Na dziś odpowiedzialna odpowiedź brzmi: ta baza na te pytania nie odpowiada. To **ograniczenie systemu informacji i ewidencji**, które utrudnia zarządzanie wynikiem. Jest zgodne z obawą, że firma może podejmować decyzje bez wiedzy, co przynosi dochód, ale nie stanowi dowodu konkretnych strat ani zaniedbań poszczególnych osób.

Najbardziej prawdopodobne obszary ryzyka to nadmierne zamówienia pozycji, których sprzedaży nie porównuje się ze stanem; utrata sprzedaży przy niezauważonym braku produktu; zamrożenie kapitału w wolno rotujących pozycjach; oraz brak możliwości szybkiego wykrycia rozbieżności między stanem systemowym a fizycznym. Są to ryzyka wynikające z braków w ewidencji — ich skali nie da się policzyć z obecnego zbioru.

## KPI, które warto prowadzić na stałe

Dashboard pokazuje teraz wskaźniki opisujące aktualny wyciąg — m.in. pokrycie ilościami (66,9%), 219 pozycji o niskim stanie, 962 pozycje bez ilości, medianę ceny oraz udział grupy „Inne” w szacowanej wartości (72,7%). To dobry punkt startowy do ujawnienia luki, ale nie zastępuje systemu KPI sprzedaży i rentowności.

| KPI | Definicja | Stan obecny i zastosowanie |
|---|---|---|
| **Pokrycie aktualnym stanem** | Aktywne SKU z poprawną ilością potwierdzoną w bieżącym cyklu spisu ÷ wszystkie aktywne SKU. | Obecny wskaźnik 66,9% liczy niepuste ilości, ale brak daty potwierdzonego pomiaru. Traktuj go jako wstępne pokrycie, nie dowód świeżości. Docelowo każdy aktywny produkt powinien mieć stan albo jawnie potwierdzone zero w każdym cyklu spisu. |
| **Marża brutto według SKU** | (Przychód netto ze sprzedanych sztuk − koszt sprzedanych towarów) ÷ przychód netto. Raportować dla okresu i według SKU oraz grupy. | KPI wyniku: pokaże, które produkty faktycznie zarabiają. Obecnie niepoliczalny, bo brak transakcji sprzedaży i kosztu zakupu. Nie zastępuj marży ceną brutto ani wartością zapasu. |
| **Dostępność przy popycie** | Dni/SKU z dodatnim, potwierdzonym stanem w dniach, w których wystąpił popyt ÷ wszystkie dni/SKU z popytem. | KPI ochronny: pozwala sprawdzać, czy ograniczanie zapasu nie powoduje braków i utraty sprzedaży. Wymaga datowanych stanów i sprzedaży; obecnie nie ma wiarygodnej bazy. |
| **Dni zapasu** | Średni zapas wyceniony kosztem zakupu ÷ koszt sprzedanych towarów w okresie × liczba dni okresu. | Wskaźnik kapitału i rotacji. Trzeba czytać go razem z dostępnością: niski zapas może uwalniać środki, ale przy częstych brakach szkodzi sprzedaży. Wymaga kosztów i historii stanów. |
| **Udział wartości w grupie „Inne”** | Szacowana wartość zapasu w grupie „Inne” ÷ szacowana wartość całego znanego zapasu. | Obecnie 72,7%. To wskaźnik jakości klasyfikacji, nie rentowności. Spadek jest wartościowy tylko wtedy, gdy produkty trafiają do poprawnych kategorii, a nie tylko do innych etykiet. |

Spośród tych KPI tylko pokrycie ewidencji i udział grupy „Inne” można dziś obliczyć z dostępnego wyciągu — i oba mają ograniczenia. Marża, dostępność przy popycie oraz dni zapasu powinny zostać uruchomione dopiero po zasileniu historii sprzedaży, kosztów i datowanych stanów. Ich wartości docelowe należy ustalić po zebraniu wiarygodnego punktu odniesienia; jedynym proponowanym celem procesowym na start jest pełne, datowane pokrycie aktywnego asortymentu.

## Aktualność i ograniczenia

Wszystkie 2 910 rekordów ma w polu `data_utworzenia` datę 1 czerwca 2025 r. To wspólna data utworzenia lub załadowania rekordów w bazie. Nie ma jednak niezależnego znacznika potwierdzającego, że ilości zostały fizycznie przeliczone właśnie tego dnia ani że od tego czasu są aktualizowane. Na dzień sporządzenia raportu (3 października 2026 r.) świeżość stanów pozostaje więc niepotwierdzona.

Tabela `dbo.StanMagazynowyHistoria` istnieje, ale nie zawiera zapisów. Tabela `dbo.Sprzedaz` również nie zawiera rekordów. Strona „Historia” w raporcie portfolio pokazuje syntetyczną symulację do prezentacji wykresu — nie jest to historia firmy i nie wolno używać jej do wniosków operacyjnych.

Pozostałe istotne ograniczenia:

- Ilość w `dbo.Oferta.stan` jest przechowywana jako tekst, a dopiero widok próbuje zamienić ją na liczbę.
- Wartość zapasu używa ceny brutto z oferty, nie kosztu zakupu.
- Klasyfikacja grupy wynika z nazw i wymaga słownika produktowego.
- Próg „niski stan” równy 10 jest wspólny dla różnych jednostek i nie uwzględnia rotacji ani czasu dostawy.
- Brakuje danych o sprzedaży, kosztach, marży, dostawach, zwrotach, ubytkach i terminach ważności.
- Wynik opisuje zawartość lokalnej bazy, nie całą działalność firmy ani jej pełne sprawozdanie finansowe.

## Co warto uporządkować w pierwszej kolejności

1. **Wykonać i datować rzeczywisty spis.** Dla każdego SKU zapisać ilość, jednostkę, datę oraz osobę lub źródło pomiaru. Potwierdzone zero zapisywać jako `0`; stan nieznany powinien pozostać osobno oznaczony.
2. **Uzupełnić rejestr ruchów.** Rejestrować przyjęcia, sprzedaż, zwroty, korekty i ubytki z datą i identyfikatorem produktu. Bieżący stan powinien wynikać z tych zdarzeń albo być okresowo uzgadniany z fizycznym spisem.
3. **Wprowadzić sprzedaż i koszt zakupu per SKU.** Dopiero połączenie wolumenu sprzedaży, ceny netto i kosztu towaru pozwoli policzyć marżę oraz wskazać produkty zarabiające i nierentowne.
4. **Naprawić kartotekę i klasyfikację produktów.** Zastąpić zgadywanie grup z nazwy stabilnym kodem produktu, jednostką, marką i kategorią ze słownika.
5. **Ustawić sensowne progi operacyjne.** Progi minimalne i alarmowe definiować per SKU lub na podstawie rotacji i czasu dostawy, zamiast stosować jeden próg 10 dla każdej jednostki.
6. **Monitorować jakość i świeżość danych.** Raport powinien pokazywać datę ostatniego spisu/importu, procent produktów z potwierdzoną ilością, nieuzgodnione różnice oraz pozycje bez kosztu lub sprzedaży.

## Dane i sposób obliczeń

Analiza wykorzystuje lokalną bazę SQL Server `tomawebp_oferta`, przede wszystkim widok `dbo.vw_Oferta_Analytics`. Liczebności statusów, grupy, jednostki, kwantyle cen oraz wartość znanych stanów zostały obliczone z rekordów dostępnych w bazie. Status „Niski stan” odpowiada regule widoku `0 < StockQty < 10`; „Na stanie” odpowiada dodatniej ilości co najmniej 10; puste ilości pozostają „Brak danych”.

Wartość brutto znanego zapasu to suma `StockQty × GrossPrice` dla pozycji z rozpoznaną ilością i ceną. Grupy produktowe są etykietami wywnioskowanymi przez reguły SQL z nazwy. Kwantyle odnoszą się do dodatnich, skończonych cen brutto. Braki, udziały, grupy i statusy opisują wyłącznie rekordy z tego widoku i nie są porównaniem w czasie.

**Wnioski o ryzyku są interpretacją biznesową braków w danych. Kwoty rzeczywistych strat, przychodów i zysku nie zostały wyliczone, ponieważ źródło nie zawiera niezbędnych danych transakcyjnych i kosztowych.**
