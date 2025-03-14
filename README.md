# dr_tourism_project
Data Project: Dominican Republic Tourism Trends Dashboard


##Goal

The primary objective of this project was to develop an interactive dashboard that visualizes general tourism trends to the Dominican Republic, categorized by the origin country of visitors. This dashboard aims to inform strategic decisions regarding advertising budget allocation and timing. Specifically, it focuses on displaying:
* Monthly tourism trends for each country within the dataset.
* Year-over-year changes in tourist visits.
* The country with the highest number of visits per region.
* The top three countries exhibiting the highest year-over-year growth.
* The bottom three countries exhibiting the lowest year-over-year growth.
* Tourist visit patterns based on various features, including lodging type, gender, age group, and reason for visit.
* A six-month forecast for future tourist arrivals.

##Methodology

This project was completed in approximately 25 hours, excluding the time spent on this report. A significant portion of the time was dedicated to learning and implementing time series forecasting models and constructing the interactive dashboard.
The data source for this project was an Excel report obtained from the Central Bank of the Dominican Republic: https://www.bancentral.gov.do/a/d/2537-sector-turismo.
The Excel file contained aggregated yearly and monthly airport arrival data for various countries of origin. However, the spreadsheet was not structured for direct analysis or database integration, necessitating extensive data cleaning and preprocessing. The fact that each year's data was contained in a separate file posed an additional challenge.

The project was divided into three main phases:
1.	Data Preparation: 
* File retrieval.
* Data cleaning and preprocessing.
* Data combination and file generation.
2.	Forecasting for the First Half of 2025: 
* Preparing data for time series analysis.
* Exploratory data analysis for model selection.
* Model training with rolling window cross-validation and tuning.
* Model testing and selection.
* Forecasting values for 2025.
* Generating CSV files for dashboard use.
  
3.	Dashboard Creation: 
* Data connection and dashboard construction.
* Integration of predicted values from the selected model.

  
##Detailed Methodology

R was used for data cleaning and preprocessing. The code is available on GitHub.

###Data Preparation:

* File Retrieval: A script was developed to automatically retrieve annual Excel files from the government website. Each file, containing monthly and yearly visitor data categorized by country of origin, age group, lodging type, gender, and reason for visit, was downloaded. Error handling was implemented to address download failures.
* Data Cleaning and Preprocessing: The complexity of the Excel files required multiple cleaning steps. The files were largely consistent across years, with minor adjustments needed for the 2025 file. Each monthly sheet was extracted into a data frame. Summary level data was kept, and airport specific data was discarded. Unnecessary header and separator rows and columns were removed. Columns were renamed to English. "Other" entries in the country column were renamed to their respective regions. A translation table, generated with the aid of LLMs (ChatGPT), was used to convert country names from Spanish to English. A region column was added based on a predefined list of English region names. Numerical values were rounded down. A date column was created by combining the year and month information.
* Data Combination and File Generation: A loop was implemented to automate the cleaning process for each monthly sheet. The script was adapted to handle variations in the 2025 file's sheet naming convention. A function was created to retrieve, clean, and combine monthly data for each year, outputting a CSV file. The code was refactored with the assistance of ChatGPT for efficiency and professionalism. Finally, all yearly data was merged into a single CSV file for use in the Power BI dashboard.
Forecasting for the First Half of 2025:
* Preparing Data for Time Series Analysis: A time series object was created using aggregated total tourist numbers. Unnecessary columns were removed, and the date column was formatted. The time series object covered the period from 2022 to 2024, with a monthly frequency. January 2025 data was excluded.
* Exploratory Data Analysis for Model Selection: Stationarity and seasonality were assessed using various plots and the Dickey-Fuller test. The data exhibited an upward trend and seasonality. Differencing was applied to achieve stationarity.
* Model Training with Rolling Window Cross-Validation and Tuning: SARIMA, ETS, and Prophet models were trained using rolling window cross-validation. The RMSE was used to evaluate model performance. A manual SARIMA model with specific parameters yielded the lowest RMSE.
* Model Testing and Selection: The manual SARIMA model was selected as the final model based on its performance on the first six months of 2025.
* Forecasting Values for 2025: A function was created to generate forecasts for each country. The function processed each country's data, created a time series object, fit the SARIMA model, and generated a data frame of predicted values for 2025.

###Dashboard Creation:

* Data Connection and Dashboard Construction: Data was loaded into Power BI. The "Month" column was renamed to "Date," and a calendar table was added. Filters were applied to exclude Dominican resident data. Slicers were created for year and region. Charts were generated to display total visitors, year-over-year changes, top countries, monthly trends, and demographic breakdowns. A separate page was created for country-specific data. A YoY detailed page was added to show the highest and lowest growth countries.
* Integration of Predicted Values from the Selected Model: A page was added to display forecasted values. The page includes a line chart of actual and predicted monthly visitors for the first six months of 2025 and a card showing the percentage difference.

##Shortcomings

* The aggregated nature of the data limited the depth of analysis. Access to individual-level data would have allowed for more robust correlation analysis and market segmentation.
* Further optimization of the code for automating yearly data merging is possible.
* I noticed in the forecast plots while using Power BI that my predictions for the total tourists’ numbers for the first month was very close to reality, but showed considerable differences with some countries. Ideally, separate forecasting models would have been used for each country, considering individual trend differences.
* The function that created the forecast for each country had issues with the country of Scotland, due to all of the values being zero.
* Confidence intervals are not displayed on the forecast graphs.

##Improvements

* Merge actual and predicted values into a single plot and add confidence intervals to the forecast page.
* Include model details and parameters directly in the Power BI report.
* Optimize code for automated CSV generation.
* Automate data retrieval, processing, and Power BI report refresh using R and Power Automate.

