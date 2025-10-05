# These codes cleans and aggregates the Comtrade data

# --------------------------
# Initialization
# --------------------------
library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(openxlsx)

# Set Directory
setwd("/Users/huangjinyang/Documents/NYUAD/Fall 24/Capstone'")

# --------------------------
# Data Processing
# --------------------------
# Raw Data
trade_data <- read_csv(
  "data/TradeData_2_26_2025_14_50_13.csv",
  col_types = cols(cmdCode = col_character())
)

# Filter the data and extract the HS-2 Code
filtered_data <- trade_data %>%
  filter(refYear != 2024) %>%                
  mutate(hs2 = substr(cmdCode, 1, 2)) %>%    
  group_by(reporterISO, hs2, refYear) %>%    
  summarise(total_value = sum(primaryValue)) %>%
  ungroup()

# --------------------------
# Rank, 2013 as basis
# --------------------------
top_countries_2013 <- filtered_data %>%
  filter(refYear == 2013) %>%               
  group_by(hs2) %>%                         
  arrange(desc(total_value), .by_group = TRUE) %>%  
  slice_head(n = 10) %>%                  
  select(hs2, reporterISO) %>%              
  ungroup()

top_countries_data <- filtered_data %>%
  inner_join(top_countries_2013, by = c("hs2", "reporterISO"))

# --------------------------
# Reshape to wide data
# --------------------------
hs2_wide_list <- top_countries_data %>%
  group_split(hs2) %>%                      #
  map(~ {
    hs2_code <- unique(.x$hs2)              
    
    sorted_data <- .x %>%
      group_by(reporterISO) %>%
      mutate(base_2013 = total_value[refYear == 2013]) %>%  
      ungroup() %>%
      arrange(desc(base_2013)) %>%          
      select(-base_2013)                    
    
    pivot_wider(
      sorted_data,
      names_from = refYear,
      values_from = total_value,
      values_fill = 0                       
    )
  }) %>%
  setNames(unique(top_countries_data$hs2))  

# --------------------------
# Export Excel
# --------------------------
write.xlsx(
  hs2_wide_list,
  file = "HS2_Sorted_By_2013.xlsx",
  asTable = FALSE,                          
  firstRow = TRUE,                          
  overwrite = TRUE                          
)

