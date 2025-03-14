## Preprocess function



#Loading libraries
library(tidyverse)
library(readxl)
library(dplyr)
library(httr2)
library(tidyr)
library(purrr)
library(stringr)

# Define constants
BASE_URL <- "https://cdn.bancentral.gov.do/documents/estadisticas/sector-turismo/documents"


#Creating lookup table for spanish months (usually the sheet names) and assign month numbers to each, will be used in the dates
MONTH_LOOKUP <- data.frame(
  Spanish = c("ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
              "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"),
  MonthNumber = sprintf("%02d", 1:12)
)


#Creating a lookup table to translate spanish country names to english
COUNTRY_LOOKUP <- data.frame(
  Spanish = c("Dom. Residentes.", "Ext. Residentes.", "Dom. No Residentes.", 
              "Canadá", "Estados Unidos", "México", "Aruba", "Caicos y Turcas, Islas", 
              "Costa Rica", "Cuba", "Curazao", "El Salvador", "Guadalupe", 
              "Guatemala", "Haití", "Honduras", "Jamaica", "Martinica", 
              "Panamá", "Puerto  Rico", "San Martin", "Trinidad y Tobago", 
              "Vírgenes Americanas, Islas", "OtherAmerica", "Argentina", "Bolivia", 
              "Brasil", "Chile", "Colombia", "Ecuador", "Perú", "Uruguay", 
              "Venezuela", "OtherSouthAmerica", "China", "Corea del Sur", "India", 
              "Israel", "Japon", "Taiwán", "OtherAsia", "Alemania", "Austria", 
              "Bélgica", "Bulgaria", "Dinamarca", "Escocia", "España", "Finlandia", 
              "Francia", "Grecia", "Holanda", "Hungría", "Reino Unido", 
              "Irlanda", "Italia", "Luxemburgo", "Noruega", "Polonia", "Portugal", 
              "República Checa", "Rumania", "Rusia", "Suecia", "Suiza", 
              "Ucrania", "OtherEurope", "Australia", "OtherRestoftheWorld"),
  English = c("Dom. Residents", "Ext. Residents", "Dom. Non-Residents", 
              "Canada", "United States", "Mexico", "Aruba", "Turk and Caicos Islands", 
              "Costa Rica", "Cuba", "Curaçao", "El Salvador", "Guadeloupe", 
              "Guatemala", "Haiti", "Honduras", "Jamaica", "Martinique", 
              "Panama", "Puerto Rico", "Saint Martin", "Trinidad and Tobago", 
              "U.S. Virgin Islands", "Other America", "Argentina", "Bolivia", 
              "Brazil", "Chile", "Colombia", "Ecuador", "Peru", "Uruguay", 
              "Venezuela", "Other South America", "China", "South Korea", "India", 
              "Israel", "Japan", "Taiwan", "Other Asia", "Germany", "Austria", 
              "Belgium", "Bulgaria", "Denmark", "Scotland", "Spain", "Finland", 
              "France", "Greece", "Netherlands", "Hungary", "United Kingdom", 
              "Ireland", "Italy", "Luxembourg", "Norway", "Poland", "Portugal", 
              "Czech Republic", "Romania", "Russia", "Sweden", "Switzerland", 
              "Ukraine", "Other Europe", "Australia", "Other Rest of the World")
)

#Created a region list, will be used to assign a region to each of the countries
REGION_LISTS <- list(
  north_america = c("Canada", "United States", "Mexico", "Other America"),
  central_america = c("Costa Rica", "El Salvador", "Guatemala", "Honduras", "Panama"),
  caribbean = c("Aruba", "Turk and Caicos Islands", "Cuba", "Curaçao", "Guadeloupe", 
                "Haiti", "Jamaica", "Martinique", "Puerto Rico", "Saint Martin", 
                "Trinidad and Tobago", "U.S. Virgin Islands"),
  south_america = c("Argentina", "Bolivia", "Brazil", "Chile", "Colombia", "Ecuador", 
                    "Peru", "Uruguay", "Venezuela", "Other South America"),
  asia = c("China", "South Korea", "India", "Israel", "Japan", "Taiwan", "Other Asia"),
  europe = c("Germany", "Austria", "Belgium", "Bulgaria", "Denmark", "Scotland", "Spain", 
             "Finland", "France", "Greece", "Netherlands", "Hungary", "United Kingdom", 
             "Ireland", "Italy", "Luxembourg", "Norway", "Poland", "Portugal", 
             "Czech Republic", "Romania", "Russia", "Sweden", "Switzerland", "Ukraine", "Other Europe"),
  australia = c("Australia"),
  other_rest_of_world = c("Other Rest of the World")
)

# Function to download file from the URL
download_file <- function(url, output_filename) {
  response <- GET(url)
  if (status_code(response) != 200) {
    stop(paste("File not found:", url))
  }
  writeBin(content(response, "raw"), output_filename)
  message(paste0("File downloaded to: ", output_filename))
}

# Function to process sheet data. 
#Keeping the 95 first rows (csv is always structured the same way, now keeping the airport data to simplify analysis)
#filtering out rows where first column has null values and unwanted rows and columns
#Renaming columns
#Removing rows with region titles

process_sheet <- function(sheet, year, monthNumber, monthUpper, output_filename) {
  data_raw <- read_excel(output_filename, sheet = sheet)
  
  data <- data_raw %>%
    head(95) %>% 
    filter(!is.na(.[[1]])) %>% 
    select(-2) %>%
    select(1:19) %>%
    select(-4, -7, -13) %>%
    rename(
      Country = 1, Female = 2, Male = 3, Hotelstay = 4, Otherstay = 5, 
      Age0to12 = 6, Age13to20 = 7, Age21to35 = 8, Age36to49 = 9, Age50over = 10, 
      Leisure = 11, Business = 12, Conf_Convention = 13, Education = 14, 
      Friend_Family = 15, Otherreason = 16
    ) %>%
    filter(!Country %in% c(paste0(monthUpper, " ", year), "RESIDENCIA", "TOTAL", "RESIDENTES", "NO RESIDENTES", 
                           "EXTRANJEROS", "AMERICA DEL NORTE", "AMERICA CENTRAL Y EL CARIBE",
                           "AMERICA DEL SUR", "ASIA", "EUROPA", "RESTO DEL MUNDO"))
  
  #Replacing country terms Other of each region with a more descriptive term
  replacement_terms <- c("OtherAmerica", "OtherSouthAmerica", "OtherAsia", "OtherEurope", "OtherRestoftheWorld")
  other_rows <- which(grepl("Otros", data$Country))
  for (i in seq_along(replacement_terms)) {
    if (i <= length(other_rows)) {
      data$Country[other_rows[i]] <- replacement_terms[i]
    }
  }
  
  # Translate country names
  data <- data %>%
    mutate(Country = ifelse(Country %in% COUNTRY_LOOKUP$Spanish, 
                            COUNTRY_LOOKUP$English[match(Country, COUNTRY_LOOKUP$Spanish)], 
                            Country))
  
  # Rounding down the numeric columns to get whole numbers and creating a Month column for the date
  data <- data %>%
    mutate(across(-Country, as.numeric)) %>%
    mutate(across(where(is.numeric), floor)) %>%
    mutate(Month = as.Date(paste0(year, "-", monthNumber, "-01"), format = "%Y-%m-%d")) %>%
    relocate(Month, .after = 1)
  
  # Assigning a region to the countries
  data <- data %>%
    mutate(Region = case_when(
      Country %in% REGION_LISTS$north_america ~ "North America",
      Country %in% REGION_LISTS$central_america ~ "Central America",
      Country %in% REGION_LISTS$caribbean ~ "Caribbean",
      Country %in% REGION_LISTS$south_america ~ "South America",
      Country %in% REGION_LISTS$asia ~ "Asia",
      Country %in% REGION_LISTS$europe ~ "Europe",
      Country %in% REGION_LISTS$australia ~ "Australia",
      Country %in% REGION_LISTS$other_rest_of_world ~ "Other",
      TRUE ~ NA_character_
    )) %>%
    #Moving the column closer to the Country column for readability
    relocate(Region, .after = "Country")
  
  return(data)
}

# Main function : Pass in the year as argument to obtain the correct file from the government site
process_DRdata <- function(year) {
  file_name <- paste0("lleg_caracteristicas_", year, ".xls")
  file_url <- paste0(BASE_URL, "/", file_name)
  
  download_file(file_url, file_name)
  
  #Filter out any sheet that has the same name of the year to skip the yearly aggregated sheet
  sheets <- excel_sheets(file_name) %>%
    discard(~ . == as.character(year)) %>%
    trimws()
  
  sheet_data <- data.frame(SheetName = sheets) %>%
    mutate(
      MonthUpper = map_chr(SheetName, ~ {
        matched_month <- MONTH_LOOKUP$Spanish[str_detect(.x, regex(MONTH_LOOKUP$Spanish, ignore_case = TRUE))]
        if (length(matched_month) > 0) toupper(matched_month[1]) else NA_character_
      }),
      MonthNumber = map_chr(MonthUpper, ~ {
        if (!is.na(.x)) MONTH_LOOKUP$MonthNumber[match(.x, MONTH_LOOKUP$Spanish)] else NA_character_
      })
    )
  
  # Process all sheets and combine into one dataframe
  combined_data <- map_dfr(1:nrow(sheet_data), ~ {
    sheet <- sheet_data$SheetName[.x]
    monthNumber <- sheet_data$MonthNumber[.x]
    monthUpper <- sheet_data$MonthUpper[.x]
    process_sheet(sheet, year, monthNumber, monthUpper, file_name)
  })
  
  # Save the combined dataframe to a single CSV file
  output_file <- paste0("dr_tourism_data_", year, ".csv")
  write.csv(combined_data, output_file, row.names = FALSE)
  message(paste0("Combined data saved to: ", output_file))
  
  return(combined_data)
}



dr_data2022 <- process_DRdata(2022)
dr_data2023 <- process_DRdata(2023)
dr_data2024 <- process_DRdata(2024)
dr_data2025 <- process_DRdata(2025)


# Using dplyr::bind_rows()
library(dplyr)
DRtourism_data <- bind_rows(dr_data2022,dr_data2023,dr_data2024,dr_data2025)
print(DRtourism_data)



write.csv(DRtourism_data, "DRtourism_data.csv", row.names = FALSE)

