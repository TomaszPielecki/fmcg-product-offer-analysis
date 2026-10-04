# Analiza oferty FMCG — interaktywny dashboard portfolio
# Uruchom z katalogu projektu: shiny::runApp("shiny")

required_packages <- c("shiny", "bslib", "DBI", "odbc", "plotly", "DT")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Brak pakietów R: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

load_offer_data <- function() {
  con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = Sys.getenv("MSSQL_DRIVER", "ODBC Driver 18 for SQL Server"),
    Server = Sys.getenv("MSSQL_SERVER", "localhost\\SQLEXPRESS"),
    Database = Sys.getenv("MSSQL_DATABASE", "tomawebp_oferta"),
    Trusted_Connection = "Yes", Encrypt = "Yes",
    TrustServerCertificate = "Yes", timeout = 10
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  offer <- DBI::dbGetQuery(con, paste(
    "SELECT id, ProductName, StockQty, UnitOfMeasure, VatRate, NetPrice,",
    "GrossPrice, StockStatus, PriceStatus, VatStatus, HasVatPriceMismatch,",
    "GrossPriceBand, GrossPriceBandSort, InferredProductGroup,",
    "StockValueNet, StockValueGross, CreatedAt",
    "FROM dbo.vw_Oferta_Analytics"
  ))
  issues <- DBI::dbGetQuery(con, paste(
    "SELECT id, ProductName, StockQty, UnitOfMeasure, VatRate, NetPrice,",
    "GrossPrice, StockStatus, PriceStatus, VatStatus, GrossPriceDifference,",
    "DataQualityIssue",
    "FROM dbo.vw_Oferta_DataQualityIssues"
  ))
  issue <- as.character(issues$DataQualityIssue)
  issues$DataQualityArea <- ifelse(
    issue %in% c("Missing product name", "Duplicate name"), "Product",
    ifelse(grepl("VAT", issue, ignore.case = TRUE), "VAT",
      ifelse(grepl("price", issue, ignore.case = TRUE), "Price", "Stock"))
  )
  if (!nrow(offer)) stop("Widok dbo.vw_Oferta_Analytics nie zawiera produktów.")
  list(offer = offer, issues = issues)
}

pln <- function(x) paste0(format(round(x, 2), big.mark = " ", decimal.mark = ",", nsmall = 2), " zł")
status_labels <- c(
  "In stock" = "Na stanie", "Low stock" = "Niski stan",
  "Out of stock" = "Brak na stanie", "No stock data" = "Brak danych",
  "Invalid stock" = "Nieprawidłowa wartość"
)
area_labels <- c(Product = "Produkt", Price = "Cena", VAT = "VAT", Stock = "Magazyn")
price_labels <- c("Missing price" = "Brak ceny", "Invalid price" = "Nieprawidłowa cena", "Valid price" = "Cena poprawna")
vat_labels <- c("Invalid VAT" = "Nieprawidłowy VAT", "Unusual VAT" = "Nietypowa stawka VAT", "Valid VAT" = "VAT poprawny")
group_labels <- c(
  "Beer"="Piwo", "Water"="Woda", "Bars and sweets"="Batoniki i słodycze",
  "Chocolate and gifts"="Czekolada i upominki", "Snacks"="Przekąski",
  "Instant and canned food"="Dania instant i konserwy", "Cheese"="Sery",
  "Syrups"="Syropy", "Breakfast and preserves"="Śniadaniowe i przetwory",
  "Other"="Inne"
)
display_group <- function(x) {
  translated <- unname(group_labels[as.character(x)])
  translated[is.na(translated)] <- as.character(x)[is.na(translated)]
  translated
}
issue_labels <- c(
  "Missing product name" = "Brak nazwy produktu", "Missing price" = "Brak ceny",
  "Invalid price" = "Nieprawidłowa cena", "Invalid VAT" = "Nieprawidłowy VAT",
  "Unusual VAT" = "Nietypowa stawka VAT",
  "Gross price differs from net price + VAT" = "Cena brutto różni się od netto + VAT",
  "No stock data" = "Brak danych o stanie", "Out of stock" = "Brak na stanie",
  "Invalid stock" = "Nieprawidłowy stan", "Duplicate name" = "Duplikat produktu"
)
dt_language <- list(
  search="Szukaj:", lengthMenu="Pokaż _MENU_ pozycji", info="Pozycje _START_–_END_ z _TOTAL_",
  infoEmpty="Brak danych", zeroRecords="Nie znaleziono pasujących pozycji",
  paginate=list(previous="Poprzednia", "next"="Następna")
)

app_css <- "
  :root { --ink:#14243b; --muted:#68778d; --line:#e4eaf2; --blue:#2864b4; --teal:#15877d; --canvas:#f3f6fa; }
  html { scroll-behavior:smooth; }
  body { background:var(--canvas); color:var(--ink); font-family:Inter,'Segoe UI',system-ui,sans-serif; }
  .navbar { min-height:68px; background:#fff!important; border-bottom:1px solid var(--line); box-shadow:0 4px 18px #14243b08; }
  .navbar-brand { color:var(--ink)!important; font-size:1.02rem; font-weight:800; letter-spacing:-.035em; }
  .navbar-nav { gap:.2rem; }
  .navbar-nav .nav-link { margin:.5rem .1rem; padding:.58rem .9rem; border-radius:10px; color:#63728a; font-weight:650; transition:all .18s ease; }
  .navbar-nav .nav-link:hover { background:#f1f5fa; color:var(--blue); }
  .navbar-nav .nav-link.active { background:#eaf1fb; color:#1e5399; }
  .bslib-page-fill { padding:1.35rem clamp(1rem,3.2vw,2.8rem) 2.5rem; }
  .page-intro { position:relative; overflow:hidden; padding:1.65rem 1.8rem; margin:0 0 1.25rem; color:white;
    border-radius:20px; background:linear-gradient(112deg,#142b4b 0%,#1b426d 58%,#256b83 100%);
    box-shadow:0 14px 34px #18355d20; }
  .page-intro:after { content:''; position:absolute; right:-58px; top:-100px; width:270px; height:270px; border:1px solid #ffffff20; border-radius:50%; box-shadow:0 0 0 32px #ffffff08,0 0 0 66px #ffffff06; pointer-events:none; }
  .intro-kicker { position:relative; z-index:1; margin-bottom:.5rem; color:#a9d5e2; font-size:.7rem; font-weight:800; letter-spacing:.15em; text-transform:uppercase; }
  .page-intro h1 { position:relative; z-index:1; margin:0 0 .35rem; font-weight:780; letter-spacing:-.04em; font-size:clamp(1.5rem,2.3vw,2rem); }
  .page-intro p { position:relative; z-index:1; margin:0; max-width:760px; color:#e1ebf4; }
  .snapshot-note { position:relative; z-index:1; display:inline-flex; gap:.55rem; align-items:center; margin-top:1rem; padding:.62rem .8rem; border:1px solid #ffffff24; border-radius:10px;
    background:#ffffff12; color:#e6eff8; font-size:.84rem; }
  .section-label { color:#78879b; font-size:.7rem; font-weight:800; letter-spacing:.12em; text-transform:uppercase; margin:.35rem 0 .72rem; }
  .section-intro { margin:.25rem 0 1rem; }
  .section-intro h2 { margin:0 0 .25rem; color:var(--ink); font-size:1.35rem; font-weight:780; letter-spacing:-.035em; }
  .section-intro p { margin:0; color:var(--muted); }
  .card { border:1px solid var(--line); border-radius:17px; background:#fff; box-shadow:0 5px 22px #14243b08; transition:box-shadow .2s ease,transform .2s ease; }
  .card:hover { box-shadow:0 9px 28px #14243b0d; }
  .card-header { background:transparent; border:0; padding:1.15rem 1.3rem .25rem; color:var(--ink); font-size:.96rem; font-weight:750; letter-spacing:-.015em; }
  .card-body { padding:1rem 1.3rem 1.25rem; }
  .card-body > .text-secondary { max-width:62ch; color:var(--muted)!important; line-height:1.5; }
  .bslib-value-box { min-height:136px; border:0; border-radius:17px; box-shadow:0 7px 22px #14243b10; transition:transform .18s ease,box-shadow .18s ease; }
  .bslib-value-box:hover { transform:translateY(-2px); box-shadow:0 12px 28px #14243b16; }
  .value-box-title { font-size:.82rem!important; font-weight:650!important; opacity:.9; }
  .value-box-value { font-size:clamp(1.5rem,2vw,2rem)!important; font-weight:780!important; letter-spacing:-.045em; }
  .value-box-showcase .bi { opacity:.78; }
  .refresh-meta { color:#6c7b90; font-size:.8rem; }
  #refresh { border-radius:9px; padding:.45rem .75rem; font-weight:650; box-shadow:0 3px 9px #2457a71c; }
  .insight-card { display:grid; grid-template-columns:minmax(175px,.7fr) 2fr; gap:1.25rem; align-items:center; padding:1.15rem 1.35rem; border:1px solid #f0d9ad; border-left:5px solid #d9972b; border-radius:16px; background:linear-gradient(110deg,#fffaf0,#fff); }
  .insight-heading { color:#92601a; font-size:.73rem; font-weight:800; letter-spacing:.1em; text-transform:uppercase; }
  .insight-copy { margin:0; color:#43536a; line-height:1.6; }
  .insight-copy p { margin:0; }
  .insight-copy p + p { margin-top:.45rem; }
  .insight-copy strong { color:var(--ink); }
  .form-control,.form-select,.selectize-input { min-height:40px; border-color:#dce4ee!important; border-radius:10px!important; box-shadow:none!important; }
  .form-control:focus,.form-select:focus,.selectize-input.focus { border-color:#7da6d8!important; box-shadow:0 0 0 .2rem #2864b41a!important; }
  table.dataTable { border-collapse:separate!important; border-spacing:0; }
  table.dataTable thead th { padding:.8rem .7rem!important; color:#61718a; background:#f5f8fc; border-bottom:1px solid var(--line)!important; font-size:.7rem; font-weight:800; letter-spacing:.045em; text-transform:uppercase; }
  table.dataTable tbody td { padding:.68rem .7rem!important; border-bottom:1px solid #edf1f6!important; color:#35455b; vertical-align:middle; }
  table.dataTable tbody tr:hover { background:#f5f9ff!important; }
  .dataTables_wrapper .dataTables_filter input,.dataTables_wrapper .dataTables_length select { margin-left:.4rem; border:1px solid #dce4ee; border-radius:8px; padding:.35rem .55rem; }
  .dt-buttons .dt-button { border:1px solid #dce4ee!important; border-radius:8px!important; background:#fff!important; color:#315a8a!important; font-weight:650!important; }
  .plotly .modebar { opacity:.35; }
  .plotly:hover .modebar { opacity:.9; }
  @media (max-width: 760px) { .page-intro { padding:1.25rem; border-radius:15px; } .navbar-nav .nav-link { margin:.15rem 0; } .bslib-value-box { min-height:112px; } .insight-card { grid-template-columns:1fr; gap:.45rem; } }
"

ui <- bslib::page_navbar(
  title = "FMCG / ANALITYKA", id = "main_navigation", fillable = FALSE,
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly", primary = "#2457a7"),
  header = shiny::tagList(
    shiny::tags$head(shiny::tags$style(shiny::HTML(app_css))),
    shiny::div(class = "d-flex justify-content-end align-items-center gap-3 px-3 py-2",
      shiny::uiOutput("load_status"),
      shiny::actionButton("refresh", "Odśwież dane", icon = shiny::icon("rotate"), class = "btn-primary btn-sm")
    )
  ),
  bslib::nav_panel("Przegląd",
    shiny::div(class = "page-intro",
      shiny::div(class = "intro-kicker", "Panel analityczny · oferta i zapas"),
      shiny::h1("Oferta produktowa pod kontrolą"),
      shiny::p("Ceny, dostępność i jakość danych w jednym czytelnym widoku."),
      shiny::div(class = "snapshot-note",
        shiny::icon("circle-info"), "  Dane pokazują pojedynczy zapis oferty. Nie zawierają historii zmian stanów magazynowych."
      )
    ),
    shiny::div(class = "section-label", "Najważniejsze wskaźniki"),
    bslib::layout_columns(col_widths = c(3, 3, 3, 3, 3, 3, 3, 3),
      bslib::value_box("Produkty w ofercie", shiny::textOutput("product_count", inline = TRUE), showcase = shiny::icon("boxes-stacked"), theme = "primary"),
      bslib::value_box("Pokrycie stanów", shiny::textOutput("stock_coverage", inline = TRUE), showcase = shiny::icon("chart-pie"), theme = "info"),
      bslib::value_box("Na stanie", shiny::textOutput("in_stock_count", inline = TRUE), showcase = shiny::icon("warehouse"), theme = "success"),
      bslib::value_box("Niski lub zerowy stan", shiny::textOutput("attention_stock_count", inline = TRUE), showcase = shiny::icon("triangle-exclamation"), theme = "warning"),
      bslib::value_box("Brak danych o stanie", shiny::textOutput("missing_stock_count", inline = TRUE), showcase = shiny::icon("circle-question"), theme = "secondary"),
      bslib::value_box("Wartość znanego zapasu", shiny::textOutput("stock_value", inline = TRUE), showcase = shiny::icon("coins"), theme = "primary"),
      bslib::value_box("Mediana ceny brutto", shiny::textOutput("median_price", inline = TRUE), showcase = shiny::icon("tag"), theme = "secondary"),
      bslib::value_box("Udział wartości „Inne”", shiny::textOutput("other_value_share", inline = TRUE), showcase = shiny::icon("layer-group"), theme = "warning")
    ),
    bslib::layout_columns(col_widths = c(6, 6),
      bslib::card(bslib::card_header("Dostępność produktów"), shiny::p(class="text-secondary small mb-0", "Liczba pozycji według statusu zapisanego w ofercie."), plotly::plotlyOutput("stock_chart", height="310px")),
      bslib::card(bslib::card_header("Histogram cen brutto"), shiny::p(class="text-secondary small mb-0", "Każdy słupek pokazuje liczbę produktów w koszyku 5 zł; przerywana linia oznacza medianę."), plotly::plotlyOutput("price_chart", height="310px"))
    ),
    bslib::layout_columns(col_widths = c(8, 4),
      bslib::card(bslib::card_header("Wartość znanego stanu według grup"), shiny::p(class="text-secondary small mb-0", "Wartość brutto obliczona jako ilość × cena brutto; grupy są wnioskowane z nazwy produktu."), plotly::plotlyOutput("group_chart", height="350px")),
      bslib::card(bslib::card_header("Kontrola cen i VAT"), shiny::p(class="text-secondary small", "Liczba produktów, których cena brutto różni się od wyliczenia na podstawie VAT."), shiny::uiOutput("vat_mismatch_count"), shiny::hr(), shiny::p(class="text-secondary small mb-0", "Wartość stanu jest szacunkiem opartym na danych z pliku oferty, nie wyceną księgową."))
    ),
    shiny::div(class="insight-card",
      shiny::div(class="insight-heading", "Ryzyko dla wyniku firmy"),
      shiny::uiOutput("insight_text")
    )
  ),
  bslib::nav_panel("Produkty",
    shiny::div(class="section-intro", shiny::h2("Katalog produktów"), shiny::p("Wyszukuj po nazwie, filtruj grupy i porównuj ceny oraz dostępność.")),
    bslib::card(bslib::card_header("Przegląd produktów"),
      bslib::layout_columns(col_widths=c(8,4), shiny::textInput("product_search", "Szukaj produktu", placeholder="Nazwa produktu…"), shiny::selectInput("product_group", "Grupa", choices="Wszystkie")),
      DT::DTOutput("products_table")
    )
  ),
  bslib::nav_panel("Jakość danych",
    shiny::div(class="section-intro", shiny::h2("Jakość danych"), shiny::p("Sprawdź pozycje z brakami i niespójnościami wymagającymi weryfikacji.")),
    bslib::card(bslib::card_header("Pozycje wymagające uwagi"), shiny::p(class="text-secondary small", "Lista pochodzi z widoku kontroli jakości w bazie."), DT::DTOutput("issues_table")),
    bslib::card(bslib::card_header("Brak danych o stanie"), DT::DTOutput("missing_stock_table"))
  )
)

server <- function(input, output, session) {
  snapshot <- shiny::reactiveVal(NULL)
  refreshed_at <- shiny::reactiveVal(NULL)
  refresh_snapshot <- function() {
    tryCatch({ snapshot(load_offer_data()); refreshed_at(Sys.time()) }, error = function(e) {
      snapshot(NULL)
      shiny::showNotification(paste("Nie udało się pobrać danych:", conditionMessage(e)), type="error", duration=NULL)
    })
  }
  session$onFlushed(refresh_snapshot, once=TRUE)
  shiny::observeEvent(input$refresh, refresh_snapshot(), ignoreInit=TRUE)

  output$load_status <- shiny::renderUI({
    t <- refreshed_at()
    shiny::span(class="refresh-meta", if (is.null(t)) "Oczekiwanie na połączenie" else paste("Odświeżono", format(t, "%d.%m.%Y, %H:%M")))
  })
  output$product_count <- shiny::renderText({ shiny::req(snapshot()); format(nrow(snapshot()$offer), big.mark=" ") })
  output$stock_coverage <- shiny::renderText({
    shiny::req(snapshot()); o <- snapshot()$offer
    paste0(format(round(100 * sum(!is.na(o$StockQty)) / nrow(o), 1), decimal.mark=",", nsmall=1), "%")
  })
  output$in_stock_count <- shiny::renderText({ shiny::req(snapshot()); format(sum(snapshot()$offer$StockStatus == "In stock", na.rm=TRUE), big.mark=" ") })
  output$attention_stock_count <- shiny::renderText({
    shiny::req(snapshot()); format(sum(snapshot()$offer$StockStatus %in% c("Low stock", "Out of stock"), na.rm=TRUE), big.mark=" ")
  })
  output$missing_stock_count <- shiny::renderText({ shiny::req(snapshot()); format(sum(snapshot()$offer$StockStatus == "No stock data", na.rm=TRUE), big.mark=" ") })
  output$stock_value <- shiny::renderText({ shiny::req(snapshot()); pln(sum(snapshot()$offer$StockValueGross, na.rm=TRUE)) })
  output$median_price <- shiny::renderText({
    shiny::req(snapshot()); prices <- snapshot()$offer$GrossPrice
    prices <- prices[is.finite(prices) & prices > 0]
    if (length(prices)) pln(stats::median(prices)) else "—"
  })
  output$other_value_share <- shiny::renderText({
    shiny::req(snapshot()); o <- snapshot()$offer
    total <- sum(o$StockValueGross, na.rm=TRUE)
    other <- sum(o$StockValueGross[o$InferredProductGroup == "Other"], na.rm=TRUE)
    if (total > 0) paste0(format(round(100 * other / total, 1), decimal.mark=",", nsmall=1), "%") else "—"
  })
  output$vat_mismatch_count <- shiny::renderUI({
    shiny::req(snapshot()); n <- sum(snapshot()$offer$HasVatPriceMismatch, na.rm=TRUE)
    bslib::value_box("Niezgodność brutto / VAT", format(n, big.mark=" "), theme=if(n) "warning" else "success")
  })
  output$insight_text <- shiny::renderUI({
    shiny::req(snapshot())
    o <- snapshot()$offer
    known <- sum(!is.na(o$StockQty))
    missing <- sum(o$StockStatus == "No stock data", na.rm=TRUE)
    missing_share <- if (nrow(o)) 100 * missing / nrow(o) else 0
    groups <- o$InferredProductGroup
    groups[is.na(groups) | groups == ""] <- "Nieznana grupa"
    by_group <- stats::aggregate(o$StockValueGross, list(grupa=groups), function(x) sum(x, na.rm=TRUE))
    names(by_group)[2] <- "wartosc"
    by_group <- by_group[order(by_group$wartosc, decreasing=TRUE), , drop=FALSE]
    leader <- if (nrow(by_group) && by_group$wartosc[1] > 0) {
      top_share <- 100 * by_group$wartosc[1] / sum(by_group$wartosc, na.rm=TRUE)
      paste0(" Największą część szacowanej wartości zapasu ma grupa „", display_group(by_group$grupa[1]), "” (", pln(by_group$wartosc[1]), "; ", format(round(top_share, 1), decimal.mark=",", nsmall=1), "%); podział kategorii jest wnioskowany z nazw.")
    } else " Wartości zapasu nie można porównać, bo brakuje ilości lub cen."
    shiny::div(class="insight-copy",
      shiny::tags$p(
        shiny::tags$strong(paste0(format(missing, big.mark=" "), " produktów (", format(round(missing_share, 1), decimal.mark=",", nsmall=1), "%) nie ma zarejestrowanej ilości.")),
        " To sygnał luki w ewidencji stanów, który utrudnia kontrolę zakupów i dostępności. Brak danych może zwiększać ryzyko nadmiernych zakupów, braków na półce i utraconej sprzedaży."
      ),
      shiny::tags$p(
        "W tej bazie nie ma historii sprzedaży ani kosztów zakupu, więc nie da się rzetelnie wskazać produktów z zyskiem lub stratą ani policzyć kwoty strat.",
        leader
      )
    )
  })

  output$stock_chart <- plotly::renderPlotly({
    shiny::req(snapshot()); d <- as.data.frame(table(factor(snapshot()$offer$StockStatus,
      levels=c("In stock","Low stock","Out of stock","No stock data","Invalid stock"))))
    names(d) <- c("status","liczba"); d$etykieta <- unname(status_labels[as.character(d$status)]); d <- d[d$liczba > 0,]
    status_colors <- c("In stock"="#168575", "Low stock"="#d99a27", "Out of stock"="#d85b64", "No stock data"="#8b98a9", "Invalid stock"="#8260b4")
    bar_colors <- unname(status_colors[as.character(d$status)])
    plotly::plot_ly(d, x=~liczba, y=~factor(etykieta, levels=rev(etykieta)), type="bar", orientation="h",
      marker=list(color=bar_colors), text=~liczba, textposition="outside", hovertemplate="%{y}: %{x} produktów<extra></extra>") |>
      plotly::layout(xaxis=list(title="Liczba produktów", rangemode="tozero", showgrid=TRUE, gridcolor="#edf1f6"),
        yaxis=list(title=""), margin=list(l=125,r=35,t=10,b=45), paper_bgcolor="transparent", plot_bgcolor="transparent",
        font=list(family="Inter, Segoe UI, sans-serif", color="#506078")) |>
      plotly::config(displaylogo=FALSE, displayModeBar="hover", responsive=TRUE)
  })
  output$price_chart <- plotly::renderPlotly({
    shiny::req(snapshot()); prices <- snapshot()$offer$GrossPrice
    prices <- prices[is.finite(prices) & prices > 0]
    shiny::validate(shiny::need(length(prices) > 0, "Brak poprawnych cen do narysowania histogramu."))
    median_price <- stats::median(prices)
    plotly::plot_ly(x=prices, type="histogram", xbins=list(size=5),
      marker=list(color="#55a99b", line=list(color="#ffffff", width=1)),
      hovertemplate="Cena brutto: %{x:.2f} zł<br>Produktów: %{y}<extra></extra>") |>
      plotly::layout(xaxis=list(title="Cena brutto (zł)", tickprefix="zł ", tickformat=",.0f", gridcolor="#edf1f6"),
        yaxis=list(title="Liczba produktów", rangemode="tozero", gridcolor="#edf1f6"),
        shapes=list(list(type="line", xref="x", yref="paper", x0=median_price, x1=median_price, y0=0, y1=1,
          line=list(color="#e28b35", width=2, dash="dash"))),
        margin=list(l=65,r=20,t=15,b=55), paper_bgcolor="transparent", plot_bgcolor="transparent", showlegend=FALSE,
        bargap=.08, font=list(family="Inter, Segoe UI, sans-serif", color="#506078")) |>
      plotly::config(displaylogo=FALSE, displayModeBar="hover", responsive=TRUE)
  })
  output$group_chart <- plotly::renderPlotly({
    shiny::req(snapshot()); o <- snapshot()$offer; group <- o$InferredProductGroup
    group[is.na(group)|group==""] <- "Nieznana grupa"
    d <- stats::aggregate(o$StockValueGross, list(grupa=group), function(x) sum(x,na.rm=TRUE)); names(d)[2] <- "wartosc"
    d <- d[order(d$wartosc),]; d <- utils::tail(d,12)
    d$grupa <- display_group(d$grupa)
    plotly::plot_ly(d, x=~wartosc, y=~factor(grupa,levels=grupa), type="bar", orientation="h",
      marker=list(color="#2457a7"), hovertemplate="%{y}<br>%{x:,.2f} zł<extra></extra>") |>
      plotly::layout(xaxis=list(title="Wartość brutto (zł)", tickformat=",.0f", gridcolor="#edf1f6"), yaxis=list(title=""),
        margin=list(l=155,r=25,t=10,b=50), paper_bgcolor="transparent", plot_bgcolor="transparent",
        font=list(family="Inter, Segoe UI, sans-serif", color="#506078")) |>
      plotly::config(displaylogo=FALSE, displayModeBar="hover", responsive=TRUE)
  })

  groups <- shiny::reactive({ shiny::req(snapshot()); sort(unique(stats::na.omit(snapshot()$offer$InferredProductGroup))) })
  shiny::observeEvent(groups(), {
    g <- groups()
    choices <- c("Wszystkie", stats::setNames(g, display_group(g)))
    shiny::updateSelectInput(session,"product_group",choices=choices)
  })
  filtered_products <- shiny::reactive({
    shiny::req(snapshot()); d <- snapshot()$offer
    term <- trimws(if (is.null(input$product_search)) "" else input$product_search)
    if (nzchar(term)) d <- d[grepl(term,d$ProductName,ignore.case=TRUE),,drop=FALSE]
    if (!is.null(input$product_group) && input$product_group!="Wszystkie") d <- d[d$InferredProductGroup==input$product_group,,drop=FALSE]
    d
  })
  output$products_table <- DT::renderDT({
    d <- filtered_products()[,c("ProductName","InferredProductGroup","StockQty","UnitOfMeasure","NetPrice","GrossPrice","StockStatus")]
    names(d) <- c("Produkt","Grupa","Stan","Jednostka","Netto (zł)","Brutto (zł)","Dostępność")
    d[["Dostępność"]] <- unname(status_labels[as.character(d[["Dostępność"]])])
    d[["Grupa"]] <- display_group(d[["Grupa"]])
    DT::datatable(d, rownames=FALSE, filter="top", extensions="Buttons", options=list(pageLength=15,scrollX=TRUE,dom="Bfrtip",
      buttons=list(list(extend="copy",text="Kopiuj"),list(extend="csv",text="Pobierz CSV")),language=dt_language)) |>
      DT::formatRound(c("Stan","Netto (zł)","Brutto (zł)"),2,mark=" ",dec.mark=",")
  }, server=TRUE)
  output$issues_table <- DT::renderDT({
    shiny::req(snapshot()); d <- snapshot()$issues
    if (!nrow(d)) return(DT::datatable(data.frame(Informacja="Nie znaleziono pozycji wymagających uwagi."),rownames=FALSE,options=list(dom="t")))
    d$StockStatus <- unname(status_labels[as.character(d$StockStatus)])
    d$PriceStatus <- unname(price_labels[as.character(d$PriceStatus)])
    d$VatStatus <- unname(vat_labels[as.character(d$VatStatus)])
    d$DataQualityIssue <- unname(issue_labels[as.character(d$DataQualityIssue)])
    d$DataQualityArea <- unname(area_labels[as.character(d$DataQualityArea)])
    names(d) <- c("ID","Produkt","Stan","Jednostka","VAT (%)","Netto (zł)","Brutto (zł)","Status stanu","Status ceny","Status VAT","Różnica brutto (zł)","Problem","Obszar")
    DT::datatable(d,rownames=FALSE,filter="top",options=list(pageLength=15,scrollX=TRUE,language=dt_language))
  })
  output$missing_stock_table <- DT::renderDT({
    shiny::req(snapshot()); d <- snapshot()$offer; d <- d[d$StockStatus=="No stock data",c("ProductName","InferredProductGroup","UnitOfMeasure","NetPrice","GrossPrice"),drop=FALSE]
    names(d) <- c("Produkt","Grupa","Jednostka","Netto (zł)","Brutto (zł)")
    DT::datatable(d,rownames=FALSE,filter="top",options=list(pageLength=15,scrollX=TRUE,language=dt_language))
  })
}

app <- shiny::shinyApp(ui=ui, server=server)
