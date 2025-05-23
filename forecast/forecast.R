## Forecast function


library(dplyr)
library(lubridate)
library(tsibble)
library(forecast)
library(fable)
library(zoo)

country_forecast <- function(df) {
  unique_countries <- unique(df$Country)
  final_results <- list()  # Store results
  failed_countries <- c()  # Store failed country names
  
  for (c in unique_countries) {
    tryCatch({
      #__________________________________________________________________________________
      # Prepare file for forecast
      ts_table <- df %>%
        filter(Country == c) %>%
        select(Country, Month, Male, Female) %>%
        rename(date = Month) %>%
        mutate(tourists = Male + Female) %>%
        select(-Male, -Female) %>%
        filter(as.Date(date) < as.Date("2025-01-01")) %>%
        select(-Country)
      
      # Group by date and sum the tourists column
      ts_table <- ts_table %>%
        group_by(date) %>%
        summarise(tourists = sum(tourists, na_rm = TRUE))
      
      #Convert the date column to year month and assign it as index for modeling
      ts_table <- ts_table %>%
        mutate(date = yearmonth(date)) %>%
        as_tsibble(index = date)
      
      # Create time series object which is the input for the models
      time_series <- ts(ts_table$tourists, start = c(2022, 1), frequency = 12)
      
      # Ensure time_series has enough data
      if (length(time_series) < 12) {
        stop("Not enough data for forecasting")
      }
      
      #____________________________________________________________________________
      # Cross-validation window : 
      window_size <- 30
      forecast_horizon <- 6
      step_size <- 6
      
      # SARIMA parameters
      #p, P for stationarity and seasonality auto regressive order. Uses the previous point or the same point previous period. This model uses the previous point or the same month previous year
      #d, D for stationarity and seasonality differencing orders. Like p but uses the difference between observations. This model performed better without differencing to capture the underlying pattern
      #q, Q for moving average order. Like the other two but uses the previous points forecast error. The model performed better by using the error from the same point the previous year
      p <- 1; d <- 0; q <- 0
      P <- 1; D <- 0; Q <- 1
      seasonality <- 12
      
      # Rolling Window Cross-Validation
      model <- NULL  # Ensure model is defined
      
      #Training and fitting the rolling window cross validation witht the specified parameters  
      for (i in seq(window_size, length(time_series) - forecast_horizon, by = step_size)) {
        train <- window(time_series, start = time(time_series)[1], end = time(time_series)[i])
        test <- window(time_series, start = time(time_series)[i + 1], end = time(time_series)[i + forecast_horizon])
        
        model <- Arima(train,
                       order = c(p, d, q),
                       seasonal = list(order = c(P, D, Q), period = seasonality),
                       method = "ML")
      }
      
      # IF the model was not trained display this message
      if (is.null(model)) {
        stop("Model training failed.")
      }
      
      #_____________________________________________________________________________
      # Run the forecast
      start_year <- as.numeric(floor(time(time_series)[1]))
      start_month <- as.numeric(round((time(time_series)[1] - start_year + 1/12) * 12))
      last_date <- ymd(paste(start_year, start_month, "01")) + months(length(time_series) - 1)
      first_forecast_date <- last_date + months(1)
      
      forecast_dates <- seq(from = first_forecast_date, by = "month", length.out = forecast_horizon)
      
      #Extract the following information
      final_forecast_result <- forecast(model, h = forecast_horizon)
      final_forecasts <- final_forecast_result$mean
      lower_ci_80 <- final_forecast_result$lower[, 1]
      upper_ci_95 <- final_forecast_result$upper[, 2]
      
      # Create the forecast dataframe
      forecast_df <- data.frame(
        Date = forecast_dates,
        Predicted = final_forecasts,
        Lower_CI_80 = lower_ci_80,
        Upper_CI_95 = upper_ci_95
      )
      
      #_____________________________________________________________________________
      # Prep file : Adding country, renaming columns, removing confidence intervals for the moment, will be used in a later improvement of the project.
      forecast_df$Country <- c
      forecast_df <- forecast_df %>%
        select(Country, everything())
      
      total_forecast <- forecast_df %>%
        mutate(Date = Date) %>%
        mutate(TotalVisitors = Predicted) %>%
        select(1:3)  # Keep only Country, Date, TotalVisitors
      
      # Store result in the list
      final_results[[c]] <- total_forecast
      
    }, error = function(e) {
      message(paste("Failed for country:", c, " - ", e$message))
      failed_countries <<- c(failed_countries, c)  # Store failed country
    })
  }
  
  # Combine all successful forecasts into one dataframe
  all_forecasts <- bind_rows(final_results)
  
  # Return combined dataframe and failed countries
  return(list(all_forecasts = all_forecasts, failed = failed_countries))
}


#Run the function to create the list
all_forecasts <- country_forecast(DRtourism_data)



#Retrieve the forecasts that succeeded from the list
all_forecasts <- all_forecasts$all_forecasts



#Rounds down to have similar values to the yearly data set
all_forecasts <- all_forecasts %>% 
  mutate(across(where(is.numeric), floor))


#Export to csv for use in the dashboard
write.csv(all_forecasts, file = "data/all_forecasts2025.csv", row.names = FALSE)




