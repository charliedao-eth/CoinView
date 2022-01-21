source("CoinView/global.R")

# Test FTX Data Pull From Global ----
base_currency = "ETH"
quote_currency = "USD"
resolution = "four_hour"
start_date = "2020-01-01"
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

get_MACD(ethusd)

# Get FIB Status ----

ethusd <- add_fib_status(ethusd)

# Test FIB Status-Sequence ---- 

ethusd_sequence <- get_fib_sequences(ethusd)

# Test All Market History Plot ----
get_history(ethusd_sequence)

# Test Singular Market History ----
get_single_history(ethusd_sequence,
                   ethusd_sequence$cl$current_status,
                   ethusd_sequence$cl$current_length)
