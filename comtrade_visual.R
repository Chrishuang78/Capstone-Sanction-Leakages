# Theses visualizes the Comtrade data (for Figure. 6)

# --------------------------
# Initialization
# --------------------------
library(readr) 
library(dplyr)  
library(ggplot2)
library(tidyr)
install.packages("purrr") 
library(purrr)
library(openxlsx)

# Set Directory
setwd("/Users/huangjinyang/Documents/NYUAD/Fall 24/Capstone'")

trade_data <- read_csv("data/TradeData_2_26_2025_14_50_13.csv")

filtered_data <- trade_data %>%
  group_by(reporterISO) %>%
  filter(n_distinct(refYear) > 1) %>%
  ungroup()

# Create a list of data frames split by HS code
split_data <- split(filtered_data, filtered_data$cmdCode)

# Assign each data frame to a separate variable with a dynamic name
for (hs_code in names(split_data)) {
  assign(paste0("filtered_data_", hs_code), split_data[[hs_code]])
}

# Get all objects in the environment with names starting with "filtered_data_"
filtered_datasets <- ls(pattern = "^filtered_data_\\d+")

# Loop over each dataset and save it as a CSV
for (dataset_name in filtered_datasets) {
  data <- get(dataset_name)  # Get the dataset by its name
  write.csv(data, paste0(dataset_name, ".csv"), row.names = FALSE)
}

trade_tables <- filtered_data %>%
  group_split(cmdCode) %>%
  set_names(map_chr(., ~ unique(.x$cmdCode))) %>%
  map(~ .x %>%
        select(reporterISO, refYear, primaryValue) %>%
        pivot_wider(names_from = refYear, values_from = primaryValue, values_fill = 0)
  )


# Create a new workbook
wb <- createWorkbook()

# Add each dataset as a new sheet
walk2(names(trade_tables), trade_tables, ~ {
  addWorksheet(wb, .x)
  writeData(wb, sheet = .x, .y)
})

# Save the workbook
saveWorkbook(wb, "Trade_Tables.xlsx", overwrite = TRUE)
