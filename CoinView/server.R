
library(shiny)
library(plotly)
library(quantmod)
library(DT)
source("global.R")

# Define server logic 
shinyServer(function(input, output, session) {
  # Generate Data Transforms 
  
  ftx <- eventReactive(input$begin, {
    
    withProgress(message = "Pulling Data", expr = { 
      
      incProgress(amount = 0.1, message = "Pulling Data")
      df <- get_ftx(base_currency = input$base_currency,
                    quote_currency = input$quote_currency,
                    resolution = input$resolution,
                    start_date = input$start_date,
                    end_date = input$end_date
      )
      incProgress(amount = 0.9, message = "Calculating Fib EMA")
      df <- add_fib(df)
      df <- add_fib_status(df)
      df
      }
      
    )
  })
  
  observe({
    ff <<- ftx()
  })
  
  ftx_sequence <- reactive({ 
    get_fib_sequences(ftx())
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
    get_candle(ftx(), resolution = input$resolution, add_fib = TRUE) %>% 
      config(scrollZoom = TRUE, 
             toImageButtonOptions = list(
               format = 'svg', 
               filename = paste0("candle_fib_",input$resolution,".svg")
             ))
  })
  
  # RSI ----
  output$rsi <- renderPlotly({ 
    get_RSI(ftx())
    })
  
  # MACD ----
  output$macd <- renderPlotly({
    get_MACD(ftx())
  })
  
  # Historical ---- 
  
  output$history <- renderPlotly({ 
    get_history(ftx_sequence())
    })
  
  
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
