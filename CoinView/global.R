# Read from FTX API
library(httr)
library(jsonlite)
library(ggplot2)
library(plotly)
library(quantmod)


# FTX Data Pull From Global ----
get_ftx <- function(base_currency, quote_currency, 
                    resolution,
                    start_date, end_date = Sys.Date()){
  
  endpoint_url = 'https://ftx.com/api/markets'
  
  res = list(
    segment = 15,
    minute = 60,
    five_minute = 300,
    fifteen_minute = 900,
    hour = 3600,
    four_hour = 14400,
    day = 86400,
    week = 86400 * 7
  )
  
  if( !(resolution %in% names(res)) ){ 
    stop("Resolution must be be one of: 
    segment, minute, five_minute, fifteen_minute, hour, four_hour, day, week.")
  }
  
  final_resolution = res[[resolution]]
  
  request_url <- paste(endpoint_url, base_currency, quote_currency, sep = "/")
  
  final_request <- paste(request_url,
                         "/candles?resolution=",
                         final_resolution,
                         "&start_time=",
                         as.numeric(as.POSIXct(as.Date(start_date))),
                         "&end_time=",
                         as.numeric(as.POSIXct(as.Date(end_date))),
                         sep = "")
  
  response <- VERB("GET", final_request, accept_json())
  raw <- content(response, "text", encoding = "UTF-8")
  raw_content <- jsonlite::fromJSON(raw)
  
  tbl <- raw_content$result
  tbl$startTime <- as.POSIXct.numeric(tbl$time/1000, origin = as.Date("1970-01-01"))
  
  return(tbl)

  }

# Add FIB 8,13,21,55 ----

add_fib <- function(ftx){ 
  df <- ftx
  df$close_8 <- EMA(df$close, n = 8)
  df$close_13 <- EMA(df$close, n = 13)
  df$close_21 <- EMA(df$close, n = 21)
  df$close_55 <- EMA(df$close, n = 55)
  return(df)
  }

#  Candle Plot ----

get_candle <- function(ftx, 
                       increase_color = "#bedf8e", 
                       decrease_color = "#c19bff", 
                       c8 = "#febd3f",
                       c13 = "#dd5730",
                       c21 = "#d3264e",
                       c55 = "#000000",
                       add_fib = FALSE, resolution){

   df <- data.frame(Date = index(ftx), coredata(ftx))
   
   # custom_colors
   i <- list(line = list(color = increase_color))
   d <- list(line = list(color = decrease_color))
   
  fig <- df %>% plot_ly(x = ~startTime, type="candlestick",
                 open = ~open, close = ~close,
                 high = ~high, low = ~low,
                 increasing = i, 
                 decreasing = d, 
                 name = "candle") 
  
  if(add_fib == TRUE){ 
    fig <- fig %>% 
      add_lines(x = ~startTime, y = ~close_8,
                line = list(color = c8, width = 0.75), 
                name = "EMA 8",
                inherit = FALSE) %>% 
      add_lines(x = ~startTime, y = ~close_13,
                line = list(color = c13, width = 0.75), 
                name = "EMA 13",
                inherit = FALSE) %>% 
      add_lines(x = ~startTime, y = ~close_21,
                line = list(color = c21, width = 0.75), 
                name = "EMA 21",
                inherit = FALSE) %>% 
      add_lines(x = ~startTime, y = ~close_55,
                line = list(color = c55, width = 0.75), 
                name = "EMA 55",
                inherit = FALSE) 
    }
  
  fig <- fig %>%
    layout(title = paste0("Candle & Fib EMA at ",resolution," level"),
           xaxis = list(rangeslider = list(visible = F),
                        title = "Date"),
           yaxis = list(title = "Price"),
           showlegend = TRUE)
  
  return(fig)
  
  }

#  RSI Calculation ----

get_RSI <- function(ftx,
                    ob_color = "#bedf8e", 
                    os_color = "#c19bff"){ 
 rsi <- data.frame( Date = ftx$startTime, RSI = RSI(ftx$close))

 g <- ggplot(rsi, aes(x = Date, y = RSI)) + 
   annotate("rect", xmin = min(rsi$Date), xmax = max(rsi$Date), ymin = 70, 
            ymax = 100, alpha = 0.5, fill = ob_color) + 
   annotate("text", x = median(rsi$Date), y = 90, label = "Over-Bought") + 
   annotate("rect", xmin = min(rsi$Date), xmax = max(rsi$Date), ymin = 0, 
            ymax = 30, alpha = 0.5, fill = os_color) + 
   annotate("text", x = median(rsi$Date), y = 10, label = "Over-Sold") + 
   geom_line() + 
   geom_abline(slope = 0, intercept = 30) + 
   geom_abline(slope = 0, intercept = 70) + theme_classic()
 
 ggplotly(g)
 
  }

#  MACD Calculation ---- 

#  FIB EMA Review Table ----

#  FIB EMA Ratio Charts ---- 


