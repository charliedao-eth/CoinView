
library(shiny)
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
                                 selected = "day",
                                 multiple = FALSE,
                                 selectize = TRUE)),
            column(2, dateInput(inputId = "start_date",
                                label = "Start Date",
                                value = "2021-01-01",
                                min = "2019-09-13",
                                max = Sys.Date()+1)),
            column(2,dateInput(inputId = "end_date",
                             label = "End Date",
                             value = Sys.Date()+1,
                             min = "2019-09-14",
                             max = Sys.Date()+2)),
            column(2, 
                   br(),
                   div(class = "center-button",
                   actionButton(inputId = "begin",
                                label = "Launch", width = "80%"))
            )
          )),
      div(class = "current-market",
          div(class = "fib-explain",
          fluidRow(
             br(),
             HTML('Using Fibonnaci EMAs (8, 13, 21, and 55) at the 
             desired resolution, a "cycle" is identified based on the following
             criteria: <br>
             <li>If the EMA-8, EMA-13, AND EMA-21 are all ABOVE the EMA-55,
             the current cycle is "BULL".</li>
             <li>If the EMA-8, EMA-13, and EMA-21 are all BELOW the 
             EMA-55, the currency cycle is "BEAR".</li>
             <li>If there is a mix of some above and some below, the current
             cycle is "CRAB".</li><br>
             Example: <br> 
             If Resolution = 1 Hour, Cycle = BEAR, and Cycle Length = 25.<br>
             Then the 1-HOUR EMA-8, EMA-13, and EMA-21 are currently below the EMA-55 and
             have been under for 25 hours (so far). <br> The Avg and Median length for 
             BEAR cycles are provided given all available data (see note).<br>
             note: Only 1500 units (Resolution) <em>max</em> are returned by FTX API.
             <br>
                  ')
            )),
          hr(),
          fluidRow(
            column(6, 
                   div(class = "current-market-table",
                       DT::dataTableOutput("cycle_trend")
                   )),
            column(6, div(class = "current-market-boxplot",
                       plotlyOutput("cycle_single", height = 150)
                   ))
          )),
      hr(),
      br(),
      div(class = "graphs-section",
          div(class = "candle-chart",
              plotlyOutput("candle", width = "100%", height = 300)
              ),
          hr(),br(),
          div(class = "rsi-chart",
              plotlyOutput("rsi", width = "100%", height = 300)
              ),
          hr(),br(),
          div(class = "macd-chart",
              plotlyOutput("macd", width = "100%", height = 300)
              ),
          hr(),br(),
          div(class = "historic-chart",
              plotlyOutput("history", width = "100%", height = 300)
              )
          )
  ),hr(),
  div(class = "footer", 
      HTML("Not financial advice, this is for entertainment and informational
      purposes only. <br> 
           If you like applications like these, requests & donations 
           can be made to the creator charliemarketplace.eth on 
           Mainnet, Polygon, Arbitrum, Fantom, or Avalanche.<br> If you'd like to 
           join CharlieDAO and learn/share/collaborate on your writings, 
           applications, and analyses, DM <a href = \"https://twitter.com/charliedao_eth\">
           charliedao_eth</a> on twitter! <br>
           ")
      )
))
