# REACH Somalia HSM Dec23 - Results Table Formatting Script, KI-Level Only

###################################################################################
###################################### Setup ######################################
###################################################################################

rm(list = ls())

setwd('D:/15_Others/Muse')
library(readxl)
library(openxlsx)
library(dplyr)
library(tidyr)

date_time_now <- format(Sys.time(), "%a_%b_%d_%Y_%H%M%S")

######################################################################################
########################## Read in KI, HH Level & Kobo Tool ##########################
######################################################################################

ki_level_results <- read_excel("_code/results_table_Sun_Mar_31_2024_103107.xlsx")

kobo_tool_name <- "SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx"
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
ki_level_formatted <- ki_level_results %>%
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
ki_level_formatted$question_label <- survey$`label::English`[match(ki_level_formatted$survey_question_name_for_lookup, survey$name)]

# update the clean label - if there is a match with a name in the choices list, update to the "label::English" that would appear in the kobo tool, if not just keep the label from the original output
ki_level_formatted$choice_label <- ifelse(!match(ki_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name)) | is.na(match(ki_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name))),
                                          ki_level_formatted$Question.label,
                                          choices$`label::English`[match(ki_level_formatted$choice_list_choice_lookup, paste0(choices$list_name, ".", choices$name))])

# make it neater - just reordering some columsn
ki_level_formatted <- ki_level_formatted %>%
                            relocate(row_num, survey_question_name, question_type, choice_list, choice, choice_list_choice_lookup, question_choice_lookup, question_label, choice_label, .before = `Question.label`)

# fill down columns so the appropriate choice_list, question_type, and survey question_name are populated
select_one_and_multiple_fields <- ki_level_formatted %>%
                                        fill(choice_list, question_type, survey_question_name)

ki_level_formatted_select_multiple <- select_one_and_multiple_fields %>%
                                            filter(question_type == "select_multiple") %>%
                                            fill(question_label, choice) %>%
                                            group_by(question_label, choice) %>%
                                            arrange(match(choice_label, c("NC", "0", "Average", "1")), .by_group = TRUE) %>%
                                            filter(!(choice_label %in% c("0", "NC"))) %>%
                                            
                                            # there's probably a cleaner way to do this than just entering all the districts, but for now it works
                                            # list for KI-Level
                                            fill("All","buur_hakaba","xudur","tiyeglow","afmadow","buloburto","diinsoor","jalalaqsi","kurtunwaarey","dhuusomareb","adanyabaal","qandala","rab_dhuure","waajid",
                                                 "xarardhere","jilib","buaale","balcad","jamaame","saakow","ceelwaaq","ceeldheer","qansax_dheere","laasqoray","sablaale","ceelbuur") %>%
            
                                            filter(!(choice_label %in% c("1", "Average")))

ki_level_formatted_select_one <- select_one_and_multiple_fields %>%
                                        filter(question_type != "select_multiple" | is.na(question_type)) %>% # include the num surveys by including NA
                                        fill(question_label) %>% 
                                        # be careful with this below statement, I'm just using it to fill in NAs for survey count but make sure its not overwriting anything on accident!
                                        mutate(question_label = replace_na(question_label, "Number of Surveys")) %>%
                                        
                                        # list for KI Level
                                        fill("All","buur_hakaba","xudur","tiyeglow","afmadow","buloburto","diinsoor","jalalaqsi","kurtunwaarey","dhuusomareb","adanyabaal",
                                             "qandala","rab_dhuure","waajid","xarardhere","jilib","buaale","balcad","jamaame","saakow","ceelwaaq","ceeldheer","qansax_dheere","laasqoray","sablaale","ceelbuur",
                                            .direction = "up") %>%
                                        
                                        filter(choice_label != "Average") %>%
                                        # not sure why its not working doing both of these in one filter, but oh well
                                        filter(question_label != choice_label)                                   

ki_level_formatted_to_output <- ki_level_formatted_select_multiple %>%
                                        rbind(ki_level_formatted_select_one) %>%
                                        arrange(row_num) %>%
                                        select(-one_of(c("Question.label", "row_num","order","survey_question_name_for_lookup")))

# transpose to match previous formats
transposed_ki_level_formatted <- as.data.frame(t(ki_level_formatted_to_output))

# add more_than_1_settlement if needed
ki_level_formatted_file_output_path <- paste0("08_results_table/ki_level/ki_level_transposed_hsm_mar_24_results_table_", date_time_now, ".xlsx")
transposed_ki_level_formatted %>% write.xlsx(ki_level_formatted_file_output_path, 
                                           sheetName = "HSM Mar 24 KI Results Table",
                                           rowNames = TRUE,
                                           colNames = FALSE)

