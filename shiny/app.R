# Standardowy punkt wejścia dla shiny::runApp("shiny") i wdrożeń.
app_env <- new.env(parent = globalenv())
source("shiny.R", local = app_env, encoding = "UTF-8")
app_env$app
