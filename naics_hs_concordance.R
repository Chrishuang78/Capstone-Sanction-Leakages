# These codes converts the EXIOBASE product-level classification to NAICS
# We found 27 NAICS products from the original EXIOBASE 20 products

# --------------------------
# Initialization
# --------------------------
library(concordance)
library(readxl)
library(tidyverse)

setwd('/Users/huangjinyang/Documents/NYUAD/Fall 24/Capstone')

list = c("870323",'300490','870829','848180','847989','901890','870333','870899','330210','880240',
  '903289','870840','870324','841989','271000','853710','870332','843680','901819','940190')

concd=concord(sourcevar = c("870323",'300490','870829','848180','847989','901890','870333','870899','330210','880240',
                      '903289','870840','870324','841989','271000','853710','870332','843680','901819','940190'),
        origin = "HS", destination = "NAICS",
        dest.digit = 6, all = TRUE)

naics=c()

for (i in 1:20){
  matches=concd[[i]]$match
  naics=c(naics, matches)
}
naics=unique(naics)

naics

naics_exio=read_xlsx('data/transposed_filtered_file.xlsx')

naics_exio_selected <- naics_exio[, colnames(naics_exio) %in% naics]

non_na_list <- lapply(naics_exio_selected, function(column) na.omit(column))

# If you want all non-NA values in a single list rather than a list of lists:
exio <- unique(unlist(non_na_list))
exio

test = hs_naics[hs_naics$NAICS_6d == '213113', ]
