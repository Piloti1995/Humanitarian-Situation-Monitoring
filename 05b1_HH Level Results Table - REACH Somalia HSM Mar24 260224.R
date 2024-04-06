# REACH Somalia HSM Dec23 - HH Level "Aggregation" / Results Script

###########################################################
########################## Setup ##########################
###########################################################

rm(list = ls())

options(scipen = 999)

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, hypegrammaR, rio, readxl, openxlsx)

setwd('C:/Users/reid.jackson/ACTED/IMPACT SOM - 01_REACH/Unit 1 - Intersectoral/SOM1901_HSM/03_Data/2024/01_March Round')
source("_code/support_functions/05_Results Table - Support Functions.R")

# write the aggregation file with a timestamp to more easily keep track of different versions
date_time_now <- format(Sys.time(), "%a_%b_%d_%Y_%H%M%S")

##############################################################################
########################## Load the Data and Survey ##########################
##############################################################################

# read in the kobo tool survey and choices sheets
kobo_tool_name <- "03_kobo_tool/SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx"
questions <- read_excel(kobo_tool_name, "survey")
# choices <- read_excel(kobo_tool_name, "choices")

# clean data
cleaned_data_name <- '06_combining_clean_data/combined_clean_data_and_clogs/clean_data_with_clogs_Mar_19_2024_152711.xlsx'
cleaned_data <- read_excel(cleaned_data_name, 'Clean_Data')

################################################################################
############################# Narrow our data down #############################
################################################################################

# get the name, aggregation type, and response type for each question to feed into the aggregation functions
hh_level_variables <- questions %>%
                        filter(aggregation == "hh_level") %>%
                        pull(name)

# we only ask these hh_level questions on phone interviews with people currently living in the H2R settlement
hh_level_data_subset <- cleaned_data %>%
                                filter(ki_interview == "phone_interview") %>%
                                select(district, all_of(hh_level_variables))

##############################################################################
############################# Compute FCS Score ##############################
##############################################################################

hh_level_data_subset_with_fcs_calcs <- hh_level_data_subset %>%
                                          mutate(fcs_total = cereals_tubers * 2 +
                                                             lentils_beans * 3 +
                                                             vegetables * 1 +
                                                             fruits * 1 +
                                                             sugar_honey * 0.5 +
                                                             oils_fats * 0.5 +
                                                             milk_yogurt * 4 +
                                                             beef_eggs_fish * 4
                                                 ) %>%
                                          relocate(fcs_total, .after = beef_eggs_fish) %>%
                                          mutate(fcs_score = case_when(fcs_total <= 28 ~ "poor",
                                                                       fcs_total > 28 & fcs_total <= 42 ~ "borderline",
                                                                       fcs_total > 42 ~ "acceptable"))

##############################################################################
################################ HHS Scoring #################################
##############################################################################

hh_level_data_subset_with_hhs_calcs <- hh_level_data_subset_with_fcs_calcs %>%
                                            mutate(hhs_1_score = case_when(no_resources == "no"~ 0,
                                                                           days_no_resources == 0 ~ 0,
                                                                           days_no_resources >= 1 & days_no_resources <= 10 ~ 1,
                                                                           days_no_resources > 10 ~ 2),
                                                   hhs_2_score = case_when(sleep_hungry == "no"~ 0,
                                                                           days_sleep_hungry == 0 ~ 0,
                                                                           days_sleep_hungry >= 1 & days_sleep_hungry <= 10 ~ 1,
                                                                           days_sleep_hungry > 10 ~ 2),
                                                   hhs_3_score = case_when(whole_day_no_eat == "no"~ 0,
                                                                           times_whole_day_noeat == 0 ~ 0,
                                                                           times_whole_day_noeat >= 1 & times_whole_day_noeat <= 10 ~ 1,
                                                                           times_whole_day_noeat > 10 ~ 2),
                                                   hhs_total_score = hhs_1_score + hhs_2_score + hhs_3_score,
                                                   hhs_classification = case_when(hhs_total_score == 0 ~ "none",
                                                                                  hhs_total_score == 1 ~ "slight",
                                                                                  hhs_total_score >= 2 & hhs_total_score <= 3 ~ "moderate",
                                                                                  hhs_total_score == 4 ~ "severe",
                                                                                  hhs_total_score >= 5 & hhs_total_score <= 6 ~"very severe",
                                                                                  is.na(hhs_total_score) ~ "no_score"))

#####################################################################################
################################ HWISE Calculations #################################
#####################################################################################

hh_level_data_subset_with_hwise_calcs <- hh_level_data_subset_with_hhs_calcs %>%
                                              mutate(worry_water_score = case_when(worry_water == "always" | worry_water == "often_11_20times" ~ 3,
                                                                                   worry_water == "sometimes_3_2times" ~ 2,
                                                                                   worry_water == "rarely_1_2times" ~ 1,
                                                                                   worry_water == "never" ~ 0),
                                                     change_plans_score = case_when(change_plans == "always" | change_plans == "often_11_20times" ~ 3,
                                                                                    change_plans == "sometimes_3_2times" ~ 2,
                                                                                    change_plans == "rarely_1_2times" ~ 1,
                                                                                    change_plans == "never" ~ 0),
                                                     without_washing_hands_score = case_when(without_washing_hands == "always" | without_washing_hands == "often_11_20times" ~ 3,
                                                                                             without_washing_hands == "sometimes_3_2times" ~ 2,
                                                                                             without_washing_hands == "rarely_1_2times" ~ 1,
                                                                                             without_washing_hands == "never" ~ 0),
                                                     no_drink_score = case_when(no_drink == "always" | no_drink == "often_11_20times" ~ 3,
                                                                                no_drink == "sometimes_3_2times" ~ 2,
                                                                                no_drink == "rarely_1_2times" ~ 1,
                                                                                no_drink == "never" ~ 0),
                                                     wise_score =  worry_water_score + change_plans_score + without_washing_hands_score + no_drink_score,
                                                     hwise_score = ifelse(wise_score >= 4, "insecure", "secure")
                                                     )


#####################################################################################
################################ LCSI Calculations #################################
#####################################################################################

hh_level_data_subset_with_lsci_calcs <- hh_level_data_subset_with_hwise_calcs %>%
                                              mutate(borrow_money_score = ifelse(borrow_money == "yes" | borrow_money == "no_exhaust", 1, 0),
                                                     send_members_eat_score = ifelse(send_members_eat == "yes" | send_members_eat == "no_exhaust", 1, 0),
                                                     sell_non_food_items_score = ifelse(sell_non_food_items == "yes" | sell_non_food_items == "no_exhaust", 1, 0),
                                                     prioritize_food_consumption_score = ifelse(prioritize_food_consumption == "yes" | prioritize_food_consumption == "no_exhaust", 1, 0),
                                                     sell_productive_items_score = ifelse(sell_productive_items == "yes" | sell_productive_items == "no_exhaust", 1, 0),
                                                     reduce_expense_health_score = ifelse(reduce_expense_health == "yes" | reduce_expense_health == "no_exhaust", 1, 0),
                                                     children_work_score = ifelse(children_work == "yes" | children_work == "no_exhaust", 1, 0),
                                                     sell_female_animal_score = ifelse(sell_female_animal == "yes" | sell_female_animal == "no_exhaust", 1, 0),
                                                     beg_food_score = ifelse(beg_food == "yes" | beg_food == "no_exhaust", 1, 0),
                                                     socially_degrading_act_score = ifelse(socially_degrading_act == "yes" | socially_degrading_act == "no_exhaust", 1, 0),
                                                     
                                                     stress = ifelse((borrow_money_score + send_members_eat_score + sell_non_food_items_score + prioritize_food_consumption_score) > 0, 1, 0),
                                                     crisis = ifelse((sell_productive_items_score + reduce_expense_health_score + children_work_score) > 0, 1, 0),
                                                     emergency = ifelse((sell_female_animal_score + beg_food_score + socially_degrading_act_score) > 0, 1, 0),
                                                     
                                                     emergency_category = ifelse(emergency == 1, 4,
                                                                          ifelse(crisis == 1, 3,
                                                                          ifelse(stress == 1, 2, 1))),
                                                     
                                                     lsci_category_name = ifelse(emergency == 1, "Emergency",
                                                                          ifelse(crisis == 1, "Crisis",
                                                                          ifelse(stress == 1, "Stress", "Neutral")))
                                              )


# this breaks the results table script and was excluded last cycle
hh_level_data_subset_with_lsci_calcs <- hh_level_data_subset_with_lsci_calcs %>%
                                            select(-one_of("other_reasons"))
                                                     
###############################################################################################
################################ Prepare and Write the Output #################################
###############################################################################################

questions <- read_xlsx(kobo_tool_name,
                       guess_max = 50000,
                       na = c("NA","#N/A",""," "),
                       sheet = 1) %>% 
                       filter(!is.na(name)) %>% 
                       mutate(q.type = as.character(lapply(type, function(x) str_split(x, " ")[[1]][1])),
                              list_name = as.character(lapply(type, function(x) str_split(x, " ")[[1]][2])),
                              list_name = ifelse(str_starts(type, "select_"), list_name, NA))

choices <- read_xlsx(kobo_tool_name,
                     guess_max = 50000,
                     na = c("NA","#N/A",""," "),
                     sheet = 2)

res <- generate_results_table(data = hh_level_data_subset_with_lsci_calcs,
                              questions = questions,
                              choices = choices,
                              weights.column = NULL,
                              use_labels = T,
                              labels_column = "label::English",
                              "district")

# add this to the path if you're running >= 2 surveys: more_than_1_settlement
export_table(res, "C:/Users/reid.jackson/ACTED/IMPACT SOM - 01_REACH/Unit 1 - Intersectoral/SOM1901_HSM/03_Data/2024/01_March Round/08_results_table/hh_level/")

