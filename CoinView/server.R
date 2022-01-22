
library(shiny)
library(plotly)
library(quantmod)
library(DT)
source("global.R")

# Define server logic 
shinyServer(function(input, output, session) {
  # Generate Data Transforms 
  
  ftx <- reactive({ 
    df <- template
    df$startTime <- as.POSIXct(df$startTime)
    df <- add_fib(df)
    df <- add_fib_status(df)
    df
  })
  
  ftx_sequence <- reactive({ 
    get_fib_sequences(ftx())
    })
  
  observe({ 
    ff <<- ftx_sequence()
    })
  
  # Cycle Trend ----
  output$cycle_trend <- DT::renderDataTable({
    cycle_table(ftx_sequence())
  })
  
  # Single Cycle Length ----
  output$cycle_single <- renderPlotly({
    get_single_history(ftx_sequence(),
                       ftx_sequence()$cl$current_status,
                       ftx_sequence()$cl$current_length)
  })
  
  # Fib Candle ----
  output$candle <- renderPlotly({
    get_candle(ftx(), resolution = input$resolution, add_fib = TRUE)
  })
  
  # RSI ----
  output$rsi <- renderPlotly({ 
    get_RSI(ftx())
    })
  
  # MACD ----
  
  # Historical ---- 
  
  
  
  
  # Error Prevention ----
   # Only allow USD as Quote Currency on certain Base Currencies
   # To conform to available FTX Markets 
  
  observeEvent(input$base_currency, {
    
    if(input$base_currency %in% c("AAVE","BAT","DAI","GRT","MKR","SHIB")){ 
      updateSelectInput(session = session,
                        inputId = "quote_currency",
                        label = "Quote Currency",
                        choices = "USD")
    } else { 
      updateSelectInput(session = session,
                        inputId = "quote_currency",
                        label = "Quote Currency",
                        choices = readLines("available_options/QUOTECURRENCY.txt"))
      }
  })

})
