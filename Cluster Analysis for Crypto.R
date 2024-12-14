#' ---
#' title: "Dynamic Time Warping-Based Clustering for Cryptocurrency Investment"
#' author: "Esham Bin Rashid"
#' date: "`r Sys.Date()`"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE--------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

#' 
## ----Loading Libraries, message=FALSE, warning=FALSE-----------------------------------

library(tidyverse)     # Includes ggplot2, dplyr, tidyr, readr, purrr, etc.
library(OpenML)         # For OpenML API functions
library(farff)          # For ARFF file handling
library(zoo)            # For time series operations
library(gridExtra)      # For arranging grid-based plots
library(cluster)        # For clustering algorithms
library(dtwclust)       # For clustering algorithms
library(factoextra)     # For clustering visualization
library(lubridate)      # For date manipulation
library(forecast)       # For Forecasting


#' 
## ----Loading Dataset, message=FALSE, warning=FALSE-------------------------------------
setOMLConfig(apikey = Sys.getenv("OPENML_API_KEY"))

# Retrieving the dataset by ID
data <- getOMLDataSet(data.id = 43336)

# Extracting data frame from the dataset
crypto_data <- data$data

#' 
## ----Data Prep, message=FALSE, warning=FALSE-------------------------------------------

crypto_data <- crypto_data %>%
  # Selecting relevant columns and transform date
  select(-Unnamed._0) %>%
  mutate(
    Date = as.Date(Date, format = "%Y-%m-%d")
  ) %>%
  # Removing rows with missing values in critical columns
  filter(!is.na(Open), !is.na(Close), !is.na(Volume)) %>%
  arrange(Date) %>%
  # Calculating daily return, volatility, moving averages, high-low range, and normalized volume
  mutate(
    Daily_Return = (Close - lag(Close)) / lag(Close) * 100,
    Volatility = rollapply(Daily_Return, width = 10, FUN = sd, fill = NA, align = "right"),
    MA_10 = rollapply(Close, width = 10, FUN = mean, fill = NA, align = "right"),
    MA_30 = rollapply(Close, width = 30, FUN = mean, fill = NA, align = "right"),
    High_Low_Range = High - Low,
    Normalized_Volume = scale(Volume, center = TRUE, scale = TRUE)[, 1]
  ) %>%
  # Removing rows with NA values in calculated columns
  filter(!is.na(Daily_Return), !is.na(MA_10), !is.na(MA_30), !is.na(Volatility))


#' 
## ----PCA-------------------------------------------------------------------------------
# Selecting relevant numeric columns for PCA and remove rows with missing values
pca_data <- crypto_data %>%
  select(where(is.numeric), -Date) %>%
  na.omit()

# Performing and summarize PCA
pca_result <- prcomp(pca_data, scale. = TRUE)
summary(pca_result)

# Plotting PCA to visualize variance explained by each principal component
plot(pca_result, type = "l")

#' 
## --------------------------------------------------------------------------------------
# Filtering relevant columns and remove rows with missing values for both PCA and Symbol
pca_data <- crypto_data %>%
  select(Symbol, where(is.numeric), -Date) %>%
  na.omit()

# Performing PCA on numeric columns only (excluding Symbol)
pca_result <- prcomp(pca_data %>% select(-Symbol), scale. = TRUE)

# Extracting the first two principal components
pca_transformed_data <- as.data.frame(pca_result$x[, 1:2])

# Binding the Symbol column back to the PCA-transformed data
pca_transformed_data <- cbind(Symbol = pca_data$Symbol, pca_transformed_data)

# Splitting PCA-transformed data into a list of time series by each symbol
symbol_data <- split(pca_transformed_data[, -1], pca_transformed_data$Symbol)

# Setting seed for reproducibility
set.seed(2024)

# Performing DTW-based clustering with 3 clusters using the partitional method
dtw_clusters <- tsclust(
  symbol_data,
  type = "partitional",
  k = 3,
  distance = "dtw_basic",
  centroid = "pam"
)

# Plotting the clustering results
plot(dtw_clusters)



#' 
## --------------------------------------------------------------------------------------
# Getting symbols and clusters
symbols <- names(symbol_data)
clusters <- dtw_clusters@cluster

# Checking that symbols and clusters have matching lengths, then create cluster assignments
if (length(symbols) == length(clusters)) {
  cluster_assignments <- data.frame(Symbol = symbols, Cluster = clusters)
  
  # Merging with original crypto_data to add cluster information
  crypto_data_with_clusters <- merge(crypto_data, cluster_assignments, by = "Symbol", all.x = TRUE)
  
  # Removing rows with missing values
  crypto_data_with_clusters <- na.omit(crypto_data_with_clusters)
  
  # Displaying the first few rows to verify cluster assignments
  head(crypto_data_with_clusters)
} else {
  stop("Error: Symbols and clusters lengths do not match. Verify input data.")
}


#' 
## --------------------------------------------------------------------------------------
# Defining the recent time window (e.g., last 30 days from the latest date in the dataset)
recent_30_days <- as.Date(max(crypto_data_with_clusters$Date)) - 30

# Calculating performance metrics for each cluster
cluster_performance <- crypto_data_with_clusters %>%
  filter(as.Date(Date) > recent_30_days, !is.na(Daily_Return)) %>%
  group_by(Cluster) %>%
  summarise(
    Cumulative_Return = prod(1 + Daily_Return/100) - 1,  # Cumulative return over the period
    Volatility = sd(Daily_Return, na.rm = TRUE),         # Volatility (std dev of returns)
    Recent_Momentum = mean(Daily_Return, na.rm = TRUE)   # Average daily return as momentum
  ) %>%
  ungroup()

# Ranking clusters based on each metric and assign scores
cluster_performance <- cluster_performance %>%
  mutate(
    Return_Score = ntile(Cumulative_Return, 3),   # Rank by cumulative return (higher is better)
    Volatility_Score = ntile(-Volatility, 3),     # Rank by volatility (lower is better, hence the negative sign)
    Momentum_Score = ntile(Recent_Momentum, 3)    # Rank by recent momentum (higher is better)
  )

# Calculating an overall score and classify recommendations
recommendations <- cluster_performance %>%
  mutate(
    Overall_Score = Return_Score + Volatility_Score + Momentum_Score,
    Recommendation = case_when(
      Overall_Score >= 7 ~ "Buy",        # High score, indicates strong performance
      Overall_Score <= 5 ~ "Sell",       # Low score, indicates weak performance
      TRUE ~ "Hold"                      # Medium score, indicates mixed performance
    )
  ) %>%
  select(Cluster, Recommendation)

# Merging recommendations back with the main dataset
crypto_data_with_tickers <- crypto_data_with_clusters %>%
  left_join(recommendations, by = "Cluster")


# Summary of the recommendations
table(crypto_data_with_tickers$Recommendation)


#' 
## --------------------------------------------------------------------------------------
# Filtering data to include only records from 2017-01-01 onward
crypto_data_for_forecast <- crypto_data_with_clusters %>%
  filter(as.Date(Date) >= as.Date("2017-01-01"))

# Aggregating daily closing prices for each cluster
cluster_time_series <- crypto_data_for_forecast %>%
  group_by(Date, Cluster) %>%
  summarize(Cluster_Close = mean(Close, na.rm = TRUE)) %>%
  ungroup()

# Finding the last date in the historical data
last_date <- max(as.Date(cluster_time_series$Date))

# Creating time series objects for each cluster from historical data
cluster_ts <- cluster_time_series %>%
  group_by(Cluster) %>%
  arrange(Date) %>%
  summarize(
    ts_data = list(ts(Cluster_Close, frequency = 365, start = c(lubridate::year(min(as.Date(Date))), 
                                                                lubridate::yday(min(as.Date(Date))))))
  ) %>%
  ungroup()

# Forecasting each cluster's time series for the next 6 months (180 days)
forecasts <- cluster_ts %>%
  mutate(
    forecast_model = map(ts_data, ~ auto.arima(.x)),
    forecast_values = map(forecast_model, ~ forecast(.x, h = 180))  # Forecast for the next 180 days
  )

# Extracting forecast data and add future dates
forecast_results <- forecasts %>%
  select(Cluster, forecast_values) %>%
  mutate(
    forecast_data = map(forecast_values, ~ as.data.frame(.x) %>% 
                          mutate(Date = seq.Date(from = last_date + 1, by = "day", length.out = 180)))
  ) %>%
  select(Cluster, forecast_data) %>%
  unnest(cols = c(forecast_data))

# Preparing data for individual plots by merging historical and forecasted data
forecast_with_history <- cluster_time_series %>%
  mutate(Date = as.Date(Date)) %>%
  rename(Historical_Close = Cluster_Close) %>%
  full_join(forecast_results, by = c("Cluster", "Date"))

# Generating separate plots for each cluster
plot_list <- list()

for (cluster_num in unique(forecast_with_history$Cluster)) {
  cluster_data <- forecast_with_history %>% filter(Cluster == cluster_num)
  
  plot <- ggplot(cluster_data, aes(x = Date)) +
    geom_line(aes(y = Historical_Close, color = "Actual"), size = 1) +  # Historical data
    geom_line(aes(y = `Point Forecast`, color = "Forecast"), linetype = "dashed", size = 1) +  # Forecast line
    geom_ribbon(aes(ymin = `Lo 80`, ymax = `Hi 80`), alpha = 0.2, fill = "blue") +  # 80% CI
    geom_ribbon(aes(ymin = `Lo 95`, ymax = `Hi 95`), alpha = 0.1, fill = "purple") +  # 95% CI
    labs(
      title = paste("6-Month Forecast of Cluster", cluster_num, "Performance"),
      y = "Cluster Close Price",
      x = "Date",
      color = "Legend"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  plot_list[[as.character(cluster_num)]] <- plot
}

# Display each plot individually
for (cluster_num in names(plot_list)) {
  print(plot_list[[cluster_num]])
}


