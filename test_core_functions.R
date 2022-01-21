source("CoinView/global.R")

# Test FTX Data Pull From Global ----
base_currency = "ETH"
quote_currency = "USD"
resolution = "four_hour"
start_date = "2018-01-01"
end_date = as.character(Sys.Date())

ethusd <- get_ftx(base_currency = base_currency,
                        quote_currency = quote_currency,
                        resolution = resolution,
                        start_date = start_date,
                        end_date = end_date
                        )
# Test Add Fib ----

ethusd <- add_fib(ethusd)

# Test Candle Plot ----

ethusd_candle <- get_candle(ethusd, resolution = resolution)

# Test Add On of Fib Sequence ----
ethusd_fib <- get_candle(ethusd, resolution = resolution, add_fib = TRUE)
ethusd_fib

# Test RSI Calculation ----

get_RSI(ethusd)

# Test MACD Calculation ---- 

MACD(ethusd$close)

# Test FIB EMA Review Table ----

# Test FIB EMA Ratio Charts ---- 