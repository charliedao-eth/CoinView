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
 
 ggplotly(g) %>% 
   layout(title ="Relative Strength Index")
 
  }

#  MACD Calculation ---- 

get_MACD <- function(ftx,
                     ob_color = "#bedf8e", 
                     os_color = "#c19bff"){ 
  macd <- data.frame( Date = ftx$startTime, MACD(ftx$close))
  macd$vs_baseline <- macd$macd - macd$signal
  
  ymin = floor(min(macd$vs_baseline,na.rm = TRUE))
  ymax = ceiling(max(macd$vs_baseline,na.rm = TRUE))
  
  g <- ggplot(macd, aes(x = Date, y = vs_baseline)) + 
    annotate("rect", 
             xmin = min(macd$Date),
             xmax = max(macd$Date), 
             ymin = 0, 
             ymax = ymax + 1,
             alpha = 0.5, 
             fill = ob_color) + 
    annotate("text", 
             x = median(macd$Date),
             y = ymax, 
             label = "Bullish") + 
    annotate("rect", 
             xmin = min(macd$Date), 
             xmax = max(macd$Date),
             ymin = ymin - 1, 
             ymax = 0,
             alpha = 0.5, 
             fill = os_color) + 
    annotate("text",
             x = median(macd$Date),
             y = ymin,
             label = "Bearish") + 
    geom_line() + theme_classic()
  
  ggplotly(g) %>% 
    layout(title ="MACD (Signal Adjusted)")
  
  }

#  Get Fib Status ----

add_fib_status <- function(ftx){ 
  df <- ftx
  df$c8d55 <- df$close_8/df$close_55 - 1
  df$c13d55 <- df$close_13/df$close_55 - 1
  df$c21d55 <- df$close_21/df$close_55 - 1
  
  df$status <- NA
  
  for(i in 1:nrow(df)){ 
    if( is.na(df$close_55[i]) ){
      df$status[i] <- NA
    } else if( df$c8d55[i] > 0 & df$c13d55[i] > 0 & df$c21d55[i] > 0) { 
      df$status[i] <- "BULL"
    } else if(  df$c8d55[i] < 0 & df$c13d55[i] < 0 & df$c21d55[i] < 0){ 
        df$status[i] <- "BEAR"
    } else { 
      df$status[i] <- "CRAB"  
      }
  }
  
  df$sequence <- NA
  for(i in 1:nrow(df)){ 
    if( is.na(df$close_55[i]) ){
      df$status[i] <- NA
    } else if(!is.na(df$status[i - 1]) & df$status[i] == df$status[i-1]){
        df$sequence[i] <- TRUE
      } else { 
        df$sequence[i] <- FALSE
        }
  }
  
  return(df)
  }

#  FIB Status-Sequence ---- 

get_fib_sequences <- function(ftx){ 

  current_status <- ftx[nrow(ftx), "status"]
  break_index <- which(!ftx$sequence)
  current_length <- nrow(ftx) - max(break_index)
  
  current_list <- list(
    current_status = current_status,
    current_length = current_length,
    break_index = break_index)
  
  status_splits <- split(ftx, ftx$status)
  
  sequence_lengths <- function(status_split){ 
    
    x <- status_split$sequence
    
    # if the final sequence is TRUE
    # add a fake false to count ongoing trend (then adjust for it)
    if(tail(x, 1) == TRUE){ 
      trend_lengths <- diff( which(!c(x,FALSE)) )
      trend_lengths[length(trend_lengths)] <- trend_lengths[length(trend_lengths)] - 1
    } else { 
      trend_lengths <- diff( which(!x) )
      }
    return(trend_lengths)
  }
  
  historic_lengths <- lapply(status_splits, sequence_lengths)

  sequence_list <- list(
    cl = current_list, 
    hl = historic_lengths
  )
  
  return(sequence_list)
  }

# Sequence History Plots ---- 

get_history <- function(ftx_sequence){ 
  
  plot_ly(type = "box") %>% 
    add_boxplot(x = ftx_sequence$hl$BEAR, boxpoints = "all", pointpos = 0, 
                marker = list(color = "black"),
                line = list(color = "black"),
                name = "Bear") %>% 
    add_boxplot(x = ftx_sequence$hl$CRAB, boxpoints = "all", pointpos = 0, 
                marker = list(color = "black"),
                line = list(color = "black"),
                name = "Crab") %>%
    add_boxplot(x = ftx_sequence$hl$BULL, boxpoints = "all", pointpos = 0, 
                marker = list(color = "black"),
                line = list(color = "black"),
                name = "Bull") %>% 
    add_boxplot(x = as.numeric(unlist(ftx_sequence$hl)), boxpoints = "all", pointpos = 0, 
                marker = list(color = "black"),
                line = list(color = "black"),
                name = "All Markets") %>% 
    layout(title = "Historical Market Lengths (# Resolutions)", 
           xaxis = list(categoryorder = "array",
                        categoryarray = c("All Markets","Bull","Crab","Bear")),
           legend = list(traceorder = "reversed")
           )

  }

get_single_history <- function(ftx_sequence, market, current){ 
  plot_ly(type = "box") %>% 
    add_boxplot(x = ftx_sequence$hl[[market]], boxpoints = "all", pointpos = 0, 
                marker = list(color = "black"),
                line = list(color = "black"),
                name = market) %>%
    layout(title = paste0("Historical ", market, " Cycle Length"), 
           showlegend = FALSE,
           xaxis = list(title = "Cycle Length (# Resolutions)"),
           yaxis = list(title = ""))
}
