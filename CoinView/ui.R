
library(shiny)
library(plotly)
library(quantmod)
library(DT)
source("global.R")

# Define UI for application
shinyUI(ui = fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
  
  div(class = 'main-app',
      div(class = "button-bar",
          fluidRow(
            column(2, 
                   selectInput(inputId = "base_currency",
                               label = "Base Currency",
                               choices = readLines("available_options/BASECURRENCY.txt"),
                               selected = "ETH",
                               multiple = FALSE,
                               selectize = TRUE)),
            column(2, 
                   selectInput(inputId = "quote_currency",
                               label = "Quote Currency",
                               choices = readLines("available_options/QUOTECURRENCY.txt"),
                               selected = "ETH",
                               multiple = FALSE,
                               selectize = TRUE)),
            column(2, selectInput(inputId = "resolution",
                                 label = "Resolution",
                                 choices = list(
                                   "15 Seconds" = "segment",
                                   "1 Minute" = "minute",
                                   "5 Minutes" = "five_minute",
                                   "15 Minutes" = "fifteen_minute",
                                   "1 Hour" = "hour",
                                   "4 Hours" = "four_hour",
                                   "1 Day" = "day",
                                   "1 Week" = "week"),
                                 selected = "ETH",
                                 multiple = FALSE,
                                 selectize = TRUE)),
            column(2, dateInput(inputId = "start_date",
                                label = "Start Date",
                                value = "2021-01-01",
                                min = "2019-09-13",
                                max = Sys.Date())),
            column(2,dateInput(inputId = "end_date",
                             label = "End Date",
                             value = Sys.Date(),
                             min = "2019-09-14",
                             max = Sys.Date())),
            column(2, 
                   br(),
                   div(class = "center-button",
                   actionButton(inputId = "begin",
                                label = "Launch", width = "80%"))
            )
          )),
      div(class = "current-market",
          fluidRow(
            column(6, 
                   div(class = "current-market-table",
                       DT::dataTableOutput("cycle_trend")
                   )),
            column(6, div(class = "current-market-boxplot",
                       plotlyOutput("cycle_single", height = 150)
                   ))
          )),
      div(class = "graphs-section",
          div(class = "candle chart",
              plotlyOutput("candle", width = "100%", height = 300)
              ),
          div(class = "rsi chart",
              plotlyOutput("rsi", width = "100%", height = 300)
              ),
          div(class = "macd chart",
              hr()
              ),
          div(class = "historic chart",
              hr()
              )
          )
  ),
  div(class = "footer", 
      hr()
      )
))
