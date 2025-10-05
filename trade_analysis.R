# These codes provides visualization to trade substitution from Comtrade data (for figure 4 & 5)

# --------------------------
# Initialization
# --------------------------\
library(tidyverse)
library(readr)
library(janitor)
library(ggplot2)


setwd("/Users/huangjinyang/Documents/NYUAD/Fall 24/Capstone")

data2 <- read_csv("top7sectors_trade.csv") %>%
  clean_names()  # optional: makes column names consistent (snake_case)

# View the first few rows
head(data2)

str(data2)
colnames(data2)

library(dplyr)

# Revised product code lists - make them mutually exclusive
product_codes <- list(
  "Naphtha_and_Petroleum_Coke" = c(270120, 270799),  # Moved FIRST with unique codes
  "Heavy_Fuel_Oil_and_Non_specified_Petroleum_Products" = c(151920, 271000, 271011, 271012, 271019, 271020, 271091, 271099, 271210, 271220, 271290, 271311, 271312, 271320, 271390, 290220, 290230, 290244, 381900),  # Removed the overlapping codes
  "Other_Bituminous_Coal" = c(270111),
  "Copper_Products" = c(741991, 741999, 848180),
  "Peat" = c(250490, 251200, 251310, 251311, 251320, 251321, 252010, 252400, 252410, 252490, 252510, 252610, 252700, 253010, 253020, 253090, 270300, 271410, 271490)
)

# Revised filtering with proper order
filtered_data <- data2 %>%
  filter(
    partner_iso == "RUS",
    ref_year %in% 2021:2023,
    cmd_code %in% unlist(product_codes)
  ) %>%
  mutate(
    product = case_when(
      cmd_code %in% product_codes$Naphtha_and_Petroleum_Coke ~ "Naphtha_and_Petroleum_Coke",
      cmd_code %in% product_codes$Heavy_Fuel_Oil_and_Non_specified_Petroleum_Products ~ "Heavy_Fuel_Oil_and_Non_specified_Petroleum_Products",
      cmd_code %in% product_codes$Other_Bituminous_Coal ~ "Other_Bituminous_Coal",
      cmd_code %in% product_codes$Copper_Products ~ "Copper_Products",
      cmd_code %in% product_codes$Peat ~ "Peat",
      TRUE ~ "Other"
    )
  )


# Step 2: Summarize trade values (now with duplicates for overlaps)
trade_summary <- filtered_data %>%
  group_by(product, reporter_iso, reporter_desc, ref_year) %>%
  summarize(
    total_value = sum(primary_value, na.rm = TRUE),
    total_volume_kg = sum(net_wgt, na.rm = TRUE)
  ) %>%
  arrange(product, ref_year, desc(total_value))

top_exporters <- trade_summary %>%
  group_by(product, ref_year) %>%
  slice_max(order_by = total_value, n = 10)  # Top 10 per product/year

print(top_exporters, n = 200)

# Calculate each exporter's % share of Russia's total imports PER PRODUCT/YEAR
proportional_rank <- trade_summary %>%
  group_by(product, ref_year) %>%
  mutate(
    total_product_year = sum(total_value, na.rm = TRUE),
    prop_value = (total_value / total_product_year) * 100
  ) %>%
  arrange(product, ref_year, desc(prop_value))

# Top 10 exporters by proportion
top_prop_exporters <- proportional_rank %>%
  slice_max(order_by = prop_value, n = 10)

print(top_prop_exporters, n = 200)  # Disables scientific notation globally)


# First, identify top 5 exporters per product-year
top5_exporters <- top_prop_exporters %>%
  group_by(product, ref_year) %>%
  slice_max(order_by = prop_value, n = 5) %>%
  ungroup()

top5_exporters <- top5_exporters %>%
  mutate(ref_year = factor(ref_year, levels = c(2021, 2022, 2023)))

#Create Product Labels
product_labels <- c(
  "Naphtha_and_Petroleum_Coke" = "Naphtha, Petroleum Coke & Oven Coke",
  "Heavy_Fuel_Oil_and_Non_specified_Petroleum_Products" = "Heavy Fuel Oil, Gas/Diesel & Non-Specific",
  "Other_Bituminous_Coal" = "Coking Coal & Other Bituminous Coal",
  "Copper_Products" = "Copper Products",
  "Peat" = "Peat"
)


# Create the plot
plot_top5 <- ggplot(top5_exporters, 
                    aes(x = ref_year, y = prop_value, fill = reporter_iso)) +
  geom_col(position = "stack", color = "white", linewidth = 0.3, width = 0.7) +
  # Add text labels - adjust size and position as needed
  geom_text(aes(label = ifelse(prop_value > 3, reporter_iso, "")),  # Only label segments >3%
            position = position_stack(vjust = 0.5),
            size = 3, color = "white") +  # White text for better contrast
  facet_wrap(~factor(product, levels = names(product_labels), 
                     labels = product_labels)) +
  scale_y_continuous(limits = c(0, 100),
                     breaks = seq(0, 100, by = 20)) +
  labs(title = "Top 5 Exporters to Russia by Product Category (2021-2023)",
       x = "Year", 
       y = "Share of Russian Imports (%)",
       caption = "Data Source: UN Comtrade | Analysis: Grouped by HS-6 codes, aggregated by product category, %shares computed within product-year") +
  theme_minimal() +
  theme(legend.position = "none",  # Remove legend
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_discrete(guide = "none")  # Suppress legend while keeping colors

plot_top5


data <- read_csv("next7sectors_trade.csv") %>%
  clean_names()  # optional: makes column names consistent (snake_case)

# View the first few rows
head(data)

str(data)
colnames(data)

# Revised product code lists 
product_codes <- list(
  "Precious_Metals_Lead_Zinc_and_Tin" = c(262011,262019,262021,262029,262030,262040,262060,262099,280450,280461,280469,280490,710691,710812,711011,711021,711031,711041,740100,740200,740311,740312,740313,740319,740321,740322,740329,740500,740610,740620,750110,750120,750210,750220,780110,780191,780199,790111,790112,790120,790310,800110,800120,810194,810294,810320,810411,810419,810520,810720,810730,810820,810920,811010,811090,811100,811212,811221,811229,811251,811292,811299,710692,710700,710813,710900,711019,711029,711039,711049,711100,711590,750511,750512,750521,750522,750610,750620,750711,750712,750800,750810,750890,780300,780411,780419,780500,780600,790400,790500,790600,790700,800300,800400,800600,800700,810192,810193,810195,810196,810199,810292,810293,810295,810296,810299,810390,810490,810510,810520,810530,810590,810600,810790,810890,810990,811100,811219,811230,811259,811292,811299,831130,854411,854419, 710610,710811,750400,780420,790390,800500,800520,800700,810110,810210,810310,810320,810430,810810,810820), 
  "Other_non_ferrous_metal_products" = c(848110, 848120,	848190, 262011,262019,262021,262029,262030,262040,262060,262099,280450,280461,280469,280490,710691,710812,711011,711021,711031,711041,740100,740200,740311,740312,740313,740319,740321,740322,740329,740500,740610,740620,750110,750120,750210,750220,780110,780191,780199,790111,790112,790120,790310,800110,800120,810194,810294,810320,810411,810419,810520,810720,810730,810820,810920,811010,811090,811100,811212,811221,811229,811251,811292,811299,710692,710700,710813,710900,711019,711029,711039,711049,711100,711590,750511,750512,750521,750522,750610,750620,750711,750712,750800,750810,750890,780300,780411,780419,780500,780600,790400,790500,790600,790700,800300,800400,800600,800700,810192,810193,810195,810196,810199,810292,810293,810295,810296,810299,810390,810490,810510,810520,810530,810590,810600,810790,810890,810990,811100,811219,811230,811259,811292,811299,831130,854411,854419, 710610,710811,750400,780420,790390,800500,800520,800700,810110,810210,810310,810320,810430,810810,810820),  
  "Aluminium_and_aluminium_products" = c(281820,760110,	760120, 760310,	760320,760611, 760612,	760691,	760692,	760711, 731210,760410,760421,760429,760511,760519,760521,760529,760810,760820,761410,761490,854419),
  "Bitumen" = c(251720, 251730, 271500, 680710, 680790),
  "Aluminium_ores_and_concentrates" = c(260200,260500,260600,260900,261000,261100,261220,261310,261390,261400,261510,261590,261710,261790
  )
)

# Revised filtering with proper order
filtered_data <- data %>%
  filter(
    partner_iso == "RUS",
    ref_year %in% 2021:2023,
    cmd_code %in% unlist(product_codes)
  ) %>%
  mutate(
    product = case_when(
      cmd_code %in% product_codes$Precious_Metals_Lead_Zinc_and_Tin ~ "Precious_Metals_Lead_Zinc_and_Tin",
      cmd_code %in% product_codes$Other_non_ferrous_metal_products ~ "Other_non_ferrous_metal_products",
      cmd_code %in% product_codes$Aluminium_and_aluminium_products ~ "Aluminium_and_aluminium_products",
      cmd_code %in% product_codes$Bitumen ~ "Bitumen",
      cmd_code %in% product_codes$Aluminium_ores_and_concentrates ~ "Aluminium_ores_and_concentrates",
      TRUE ~ "Other"
    )
  )


# Step 2: Summarize trade values (now with duplicates for overlaps)
trade_summary <- filtered_data %>%
  group_by(product, reporter_iso, reporter_desc, ref_year) %>%
  summarize(
    total_value = sum(primary_value, na.rm = TRUE),
    total_volume_kg = sum(net_wgt, na.rm = TRUE)
  ) %>%
  arrange(product, ref_year, desc(total_value))

print(trade_summary, n = 500)

top_exporters <- trade_summary %>%
  group_by(product, ref_year) %>%
  slice_max(order_by = total_value, n = 10)  # Top 10 per product/year

print(top_exporters, n = 200)

# Calculate each exporter's % share of Russia's total imports PER PRODUCT/YEAR
proportional_rank <- trade_summary %>%
  group_by(product, ref_year) %>%
  mutate(
    total_product_year = sum(total_value, na.rm = TRUE),
    prop_value = (total_value / total_product_year) * 100
  ) %>%
  arrange(product, ref_year, desc(prop_value))

# Top 10 exporters by proportion
top_prop_exporters <- proportional_rank %>%
  slice_max(order_by = prop_value, n = 10)

print(top_prop_exporters, n = 200)

top5_exporters <- top_prop_exporters %>%
  group_by(product, ref_year) %>%
  slice_max(order_by = prop_value, n = 5) %>%
  ungroup()

top5_exporters <- top5_exporters %>%
  mutate(ref_year = factor(ref_year, levels = c(2021, 2022, 2023)))

product_labels <- c(
  "Precious_Metals_Lead_Zinc_and_Tin" = "Precious Metals, Lead, Zinc & Tin",
  "Other_non_ferrous_metal_products" = "Other Non-Ferrous Metal Products",
  "Aluminium_and_aluminium_products" = "Aluminium & Aluminium Products",
  "Bitumen" = "Bitumen",
  "Aluminium_ores_and_concentrates" = "Aluminium Ores & Concentrates"
)

# Create the plot
plot_nexttop5 <- ggplot(top5_exporters, 
                    aes(x = ref_year, y = prop_value, fill = reporter_iso)) +
  geom_col(position = "stack", color = "white", linewidth = 0.3, width = 0.7) +
  # Add text labels - adjust size and position as needed
  geom_text(aes(label = ifelse(prop_value > 3, reporter_iso, "")),  # Only label segments >3%
            position = position_stack(vjust = 0.5),
            size = 3, color = "white") +  # White text for better contrast
  facet_wrap(~factor(product, levels = names(product_labels), 
                     labels = product_labels)) +
  scale_y_continuous(limits = c(0, 100),
                     breaks = seq(0, 100, by = 20)) +
  labs(title = "Top 5 Exporters to Russia by Product Category (2021-2023)",
       x = "Year", 
       y = "Share of Russian Imports (%)",
       caption = "Data Source: UN Comtrade | Analysis: Grouped by HS-6 codes, aggregated by product category, %shares computed within product-year") +
  theme_minimal() +
  theme(legend.position = "none",  # Remove legend
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_discrete(guide = "none")  # Suppress legend while keeping colors

plot_nexttop5