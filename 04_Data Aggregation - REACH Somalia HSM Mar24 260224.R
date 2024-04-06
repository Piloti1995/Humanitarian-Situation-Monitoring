# REACH Somalia HSM Dec23 - Aggregation Script

###########################################################
########################## Setup ##########################
###########################################################

setwd('D:/15_Others/Muse/')

rm(list = ls())
source("_code/support_functions/04_Data Aggregation - Support Functions.R")
library(readxl)
library(openxlsx)
library(dplyr)

# write the aggregation file with a timestamp to more easily keep track of different versions
date_time_now <- format(Sys.time(), "%a_%b_%d_%Y_%H%M%S")

##############################################################################
########################## Load the Data and Survey ##########################
##############################################################################

# read in the kobo tool survey and choices sheets
kobo_tool_name <- "03_kobo_tool/SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx"
questions <- read_excel(kobo_tool_name, "survey")
# choices <- read_excel(kobo_tool_name, "choices")

# not actually clean data right now, I'm just testing
cleaned_data_name <- 'clean_data_with_clogs_Mar_19_2024_152711.xlsx'
cleaned_data <- read_excel(cleaned_data_name, 'Clean_Data')

##############################################################################
############################# Do the aggregation #############################
##############################################################################

# get the name, aggregation type, and response type for each question to feed into the aggregation functions
agg_method <- questions %>%
                select(c('name','aggregation','type')) %>%
                dplyr::rename(variable = name) %>%
                na.omit()

# make a new row to give settlement_combined aggregation logic
combined_settlement_agg_row <- c('settlement_combined','aok_mode','select_one placeholder_ignore')

# add and reorganize
agg_method <- agg_method %>%
                rbind(combined_settlement_agg_row) %>%
                arrange(match(variable, c("region", "district", "settlement_combined", "*")))

# remove all of the house hold level data from the aggregation - this will be processed separately
hh_variables <- agg_method %>%
                    filter(aggregation == "hh_level") %>%
                    pull(variable)

cleaned_data_no_hh <- cleaned_data %>%
                            select(-all_of(hh_variables))

# get rid of the hh_level variables in agg method so they don't show up in the results table
agg_method_no_hh <- agg_method %>%
                        filter(aggregation != "hh_level")
                        
# identify the multiple choice questions, as for each of the multiple choice responses we'll need to make a column for True/False
q_smult <- questions$name[grep("select_multiple", questions$type)]

# split the data by settlement, 
data_split <- split.data.frame(cleaned_data_no_hh, cleaned_data_no_hh$settlement_combined)
data_agg <- lapply(data_split, apply_aok, question_name = agg_method_no_hh$variable, q_smult = q_smult, agg_method = agg_method_no_hh) %>% do.call(rbind,.)

###############################################################################
############################# Calculate # Surveys #############################
###############################################################################

# we want to know how many surveys we had by settlment. We will exclude any settlements with only 1 interview
num_surveys <- cleaned_data_no_hh %>%
                    group_by(settlement_combined) %>%
                    dplyr::summarise(surveys = n())

#################################################################################
############################# Prep Output and Write #############################
#################################################################################

# include the number of surveys
aggregation_data_output <- data_agg %>%
                                left_join(num_surveys, by = c("settlement_combined")) %>%
                                relocate(surveys, .after = settlement_combined)

# only include settlements with at least 2 interviews!
aggregation_data_output <- aggregation_data_output %>%
                                filter(surveys >= 2)

# note: numbers are formatted as text because they appear alongside "NC" and empties ("")
aggregation_file_output_path <- paste0("07_aggregation/hsm_mar24_aggregation_", date_time_now, ".xlsx")
aggregation_data_output %>% write.xlsx(aggregation_file_output_path, sheetName = "HSM Mar 24 Aggregated Data")

aggregation_file_output_path_csv <- paste0("07_aggregation/hsm_mar24_aggregation_", date_time_now, ".csv")
aggregation_data_output %>% write.csv(aggregation_file_output_path_csv)

