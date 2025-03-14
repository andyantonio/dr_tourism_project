# Dominican Republic Tourism Trends Dashboard

## Description:

The primary objective of this project was to develop an interactive dashboard that visualizes general tourism trends to the Dominican Republic, categorized by the origin country of visitors. This dashboard aims to inform strategic decisions regarding advertising budget allocation and timing.

[Download the Power BI report]( https://github.com/andyantonio/dr_tourism_project/raw/refs/heads/main/Dashboard/DRDashboard.pbix )

## Key Features:

•	Interactive dashboard displaying monthly tourism trends for each country.
•	Visualization of year-over-year changes in tourist visits.
•	Identification of the top countries per region and demographic breakdowns.
•	Six-month forecast of tourist arrivals using SARIMA time series models.

## Methodology:

•	Data cleaning and preprocessing performed in R, automating the handling of yearly Excel files.
•	Time series forecasting implemented using SARIMA models, with model selection based on RMSE.
•	Dashboard created in Power BI, presenting key insights through interactive visualizations.

## Data Source:

•	Data obtained from the Central Bank of the Dominican Republic: https://www.bancentral.gov.do/a/d/2537-sector-turismo

## Key Technologies:
•	R (for data processing and time series analysis)
•	Power BI (for dashboard creation)

## Shortcomings and Improvements:

•	Limitations due to aggregated data; individual-level data would enable more robust analysis.
•	Potential improvements include adding confidence intervals to forecasts and implementing individual models for each country.
•	Automated data refresh.

## Full Documentation:
•	A [full documentation] (https://github.com/andyantonio/dr_tourism_project/blob/main/docs/documentation.md) of this project is available in the docs folder of this repository.


