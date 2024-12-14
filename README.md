# Cryptocurrency Investment Analysis using Dynamic Time Warping (DTW) and ARIMA

![1](https://github.com/user-attachments/assets/5b8ce5fd-bafa-4f47-a9a3-32fabdd70681)


This repository contains the implementation of a dynamic time series analysis for cryptocurrency investment using **Dynamic Time Warping (DTW)-based clustering** and **ARIMA forecasting**. The goal of the project is to identify buy/sell opportunities and provide actionable insights for cryptocurrency investors by analyzing historical price data.

## Table of Contents
- [Overview](#overview)
- [Business Problem](#business-problem)
- [Methodology](#methodology)
  - [Data Collection](#data-collection)
  - [Clustering with DTW](#clustering-with-dtw)
  - [Forecasting with ARIMA](#forecasting-with-arima)
- [Findings](#findings)
- [Installation](#installation)
- [Usage](#usage)
- [Dependencies](#dependencies)

## Overview
The cryptocurrency market is highly volatile, presenting challenges for investors looking for optimal strategies for buy, sell, or hold. This project employs **Dynamic Time Warping (DTW)** to cluster cryptocurrencies based on their price movement patterns and uses **ARIMA (AutoRegressive Integrated Moving Average)** for forecasting future prices. The findings and recommendations provide investors with insights into potential investment strategies.
![3](https://github.com/user-attachments/assets/34a86466-d238-4af5-8b3b-f4460b69a79b)

## Business Problem
The volatility and speculative nature of cryptocurrencies make it difficult to forecast their prices using traditional financial models. This project addresses this problem by:
- Segmenting cryptocurrencies into clusters based on similar time series behaviors.
- Using ARIMA to predict future performance of these clusters.
- Providing actionable investment recommendations based on the clustering and forecasting results.

## Methodology

### Data Collection
The dataset used in this project is sourced from **OpenML (ID: 43336)** and includes the following features:
- **Date**: Trading date.
- **Open, High, Low, Close**: Daily price metrics.
- **Volume**: Trading volume.
- **Market Cap**: Total market capitalization.

Additional features were engineered:
- **Daily_Return**: Percentage change in closing price.
- **Volatility**: Rolling standard deviation of daily returns.
- **MA_10, MA_30**: 10-day and 30-day moving averages.
- **High_Low_Range**: Difference between high and low prices.

### Clustering with DTW
**Dynamic Time Warping (DTW)** is used to group cryptocurrencies into clusters based on the similarity of their time series data. This method helps in capturing patterns in price movements that are not aligned in time, providing a more nuanced understanding of price dynamics than traditional clustering methods.

### Forecasting with ARIMA
**ARIMA** models were applied to forecast the future price performance of the clusters over a six-month horizon. The ARIMA model was chosen for its simplicity and effectiveness in short-term predictions for time series data.

## Findings

- **Cluster 1 (Stable Performers)**: These cryptocurrencies show low volatility and minimal fluctuations after an initial stabilization phase. Suitable for conservative investors.
- **Cluster 2 (High Initial Spikes)**: These assets show sharp price spikes early on, followed by stabilization. Suitable for short-term traders.
- **Cluster 3 (Volatile Growth)**: Cryptocurrencies in this cluster show high volatility and frequent price spikes, with strong upward trends. Ideal for aggressive investors.

**Forecasting Results**:
- **Cluster 1**: Projected 2% growth over six months.
- **Cluster 2**: Stabilized with negligible growth (0.5%).
- **Cluster 3**: Projected 20% growth with high volatility risks.
![9](https://github.com/user-attachments/assets/45a2e70c-90f4-40bc-8612-4b4668a4decd)


## Installation

To run this project on your local machine, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/cryptocurrency-investment-analysis.git
   ```

2. Install the necessary R packages (you can run this in your R console):
   ```R
   install.packages(c("dplyr", "ggplot2", "forecast", "dtw", "TTR", "tidyverse"))
   ```

3. Download the dataset from OpenML (ID: 43336).

## Usage

After setting up the environment and installing dependencies, run the R scripts sequentially:

1. **Data Preparation**: Preprocess the dataset by cleaning and transforming it (e.g., calculating daily returns, volatility, etc.).
2. **Clustering**: Apply DTW-based clustering on the preprocessed data to group cryptocurrencies.
3. **Forecasting**: Use ARIMA models to forecast the performance of the identified clusters.
4. **Analysis & Recommendations**: Generate and interpret the results for actionable investment insights.

You can find the main R scripts in the repository `Cluster Analysis for Crypto.Rmd` file.

## Dependencies

This project was developed using R and requires the following packages:
- `dplyr`: Data manipulation.
- `ggplot2`: Data visualization.
- `forecast`: Time series forecasting (for ARIMA).
- `dtw`: Dynamic Time Warping clustering.
- `TTR`: Technical trading rules for moving averages and other indicators.
- `tidyverse`: For data wrangling and visualization.
