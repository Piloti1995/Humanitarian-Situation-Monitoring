# REACH Somalia HSM Dec23 - ki_level aggregation script

###########################################################
########################## Setup ##########################
###########################################################

rm(list = ls())

options(scipen = 999)

if (!require("pacman")) install.packages("pacman")

pacman::p_load(tidyverse,
               hypegrammaR,
               rio,
               readxl,
               openxlsx)

setwd('D:/15_Others/Muse/')
source("_code/support_functions/05_Results Table - Support Functions.R")

#########################################################################
########################## read in needed data ##########################
#########################################################################

data <- read.csv("muse.csv", stringsAsFactors = F, na.strings = c("n/a","#N/A","NA",""))
koboToolPath <- "SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx"

# not sure why this has to be factor, but not messing with it
data  <- to_factor(data)

questions <- read_xlsx(koboToolPath,
                       guess_max = 50000,
                       na = c("NA","#N/A",""," "),
                       sheet = 1) %>% filter(!is.na(name)) %>% 
                          mutate(q.type=as.character(lapply(type, function(x) str_split(x, " ")[[1]][1])),
                                 list_name=as.character(lapply(type, function(x) str_split(x, " ")[[1]][2])),
                                 list_name=ifelse(str_starts(type, "select_"), list_name, NA))

choices <- read_xlsx(koboToolPath,
                       guess_max = 50000,
                       na = c("NA","#N/A",""," "),
                       sheet = 2)

############################################################################
########################## make the results table ##########################
############################################################################

res <- generate_results_table(data = data,
                              questions = questions,
                              choices = choices,
                              weights.column = NULL,
                              use_labels = T,
                              labels_column = "label::English",
                              "district" # can add displacement status here (ki_displacement_status)
                              )

export_table(res,"08_results_table/ki_level/")

