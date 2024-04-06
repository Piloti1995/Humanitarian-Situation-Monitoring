# REACH Somalia HSM Dec23 - Results Table Formatting Script, HH Level Only!

###################################################################################
###################################### Setup ######################################
###################################################################################

rm(list = ls())

setwd('C:/Users/reid.jackson/ACTED/IMPACT SOM - 01_REACH/Unit 1 - Intersectoral/SOM1901_HSM/03_Data/2024/01_March Round')
library(readxl)
library(openxlsx)
library(dplyr)
library(tidyr)

date_time_now <- format(Sys.time(), "%a_%b_%d_%Y_%H%M%S")

######################################################################################
########################## Read in KI, HH Level & Kobo Tool ##########################
######################################################################################

hh_level_results <- read_excel("08_results_table/hh_level/results_table_Tue_Mar_19_2024_155352.xlsx")

kobo_tool_name <- "03_kobo_tool/SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx"
survey <- read_excel(kobo_tool_name, "survey")
choices <- read_excel(kobo_tool_name, "choices")

######################################################################################
################################ Relabel and Transpose ###############################
######################################################################################

# get out list of choices
choice_list <- survey %>%
                    select(name, choice_list, question_type, order) %>%
                    na.omit()

# rbind, sub "." for "/"
# all drag down values to replace NAs
hh_level_formatted <- hh_level_results %>%

                        dplyr::rename(question_choice_lookup = `Question.xml`) %>%
                        
                        # split the question_choice_lookup into question name and choice (only if its a multiple choice question)
                        mutate(survey_question_name_for_lookup = sub("\\..*", "", question_choice_lookup)) %>%
                        
                        # join to get the choice_list name, question_type, and question order        
                        left_join(choice_list, by = c("survey_question_name_for_lookup" = "name")) %>%
                        
                        # choice: if the question is multiple choice, we split off the choice after the period
                        # choice_list_choice_lookup: fill in the items without choice_lists with the question_choice_lookup
                        mutate(survey_question_name = ifelse(question_type == "select_multiple",
                                                             sub("\\..*", "", question_choice_lookup),
                                                             question_choice_lookup),
                               choice = ifelse(question_type == "select_multiple",
                                               sub(".*\\.", "", question_choice_lookup),
                                               NA),
                               choice_list_choice_lookup = ifelse((is.na(choice_list) | is.na(choice)),
                                                                  question_choice_lookup,
                                                                  paste0(choice_list,".", choice)),
                               row_num = row_number())


# create a column with the English label that was shown to the enumerator when conducting the survey
hh_level_formatted$question_label <- survey$`label::English`[match(hh_level_formatted$survey_question_name_for_lookup, survey$name)]

# update the clean label - if there is a match with a name in the choices list, update to the "label::English" that would appear in the kobo tool, if not just keep the label from the original output
hh_level_formatted$choice_label <- ifelse(!match(hh_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name)) | is.na(match(hh_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name))),
                                        hh_level_formatted$Question.label,
                                        choices$`label::English`[match(hh_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name))])

# make it neater
hh_level_formatted <- hh_level_formatted %>%
                            relocate(row_num, survey_question_name, question_type, choice_list, choice, choice_list_choice_lookup, question_choice_lookup, question_label, choice_label, .before = `Question.label`)


# now we want to split the data into select_one and calcuated HH variables

# this is the cutoff for calculated fields in the HH level script
fcs_score_row <- match("fcs_score",hh_level_formatted$choice_list_choice_lookup)

hh_level_no_score_fields <- hh_level_formatted %>%
                                        filter(row_num < fcs_score_row) %>%
                                        fill(choice_list, question_type, survey_question_name)

hh_level_formatted_select_one <- hh_level_no_score_fields %>%
                                        filter(question_type != "select_multiple" | is.na(question_type)) %>% # include the num surveys by including NA
                                        fill(question_label) %>% 
                                        # be careful with this below statement, I'm just using it to fill in NAs for survey count but make sure its not overwriting anything on accident!
                                        mutate(question_label = replace_na(question_label, "Number of Surveys")) %>%
                                        
                                        # list for HH Level - you'll need to update this with the correct districts every time!
                                        fill("All","buur_hakaba","qansax_dheere","diinsoor","xudur","tiyeglow","afmadow","buloburto","jalalaqsi","kurtunwaarey","qandala","adanyabaal","rab_dhuure","waajid","xarardhere","buaale","balcad","saakow","ceelwaaq","ceeldheer","laasqoray","dhuusomareb","sablaale","ceelbuur",
                                            .direction = "up") %>%
                                        
                                        filter(choice_label != "Average") %>%
                                        # not sure why its not working doing both of these in one filter, but oh well
                                        filter(question_label != choice_label)                                   

hh_level_formatted_calculated_fields <- hh_level_formatted %>%
                                            filter(row_num >= fcs_score_row) %>%
                                            mutate(question_label = ifelse(is.na(All),
                                                                           Question.label,
                                                                           NA)) %>%
                                            fill(question_label) %>%
                                            filter(!is.na(All))

hh_level_formatted_to_output <- hh_level_formatted_select_one %>%
                                        rbind(hh_level_formatted_calculated_fields) %>% 
                                        arrange(row_num) %>%
                                        select(-one_of(c("Question.label", "row_num","order","survey_question_name_for_lookup")))

# transpose to match previous formats
transposed_hh_level_formatted <- as.data.frame(t(hh_level_formatted_to_output))

# add more_than_1_settlement if needed
hh_level_formatted_file_output_path <- paste0("08_results_table/hh_level/hh_level_transposed_hsm_mar_24_results_table_", date_time_now, ".xlsx")
transposed_hh_level_formatted %>% write.xlsx(hh_level_formatted_file_output_path, 
                                           sheetName = "HSM Mar24 HH Results Table",
                                           rowNames = TRUE,
                                           colNames = FALSE)
