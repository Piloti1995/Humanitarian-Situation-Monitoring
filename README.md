# Humanitarian-Situation-Monitoring
Below is a more detailed walkthrough of the code and folder structure to facilitate internal review:

•	The R-files referenced below are stored in the folder called “_code”.
•	01_Data Cleaning - REACH Somalia HSM Mar24 140324.
o	Relevant folders
	Inputs
•	_raw_data_download: Raw data is downloaded from the kobo server and saved to / read form here
•	03_kobo_tool: The kobo tool is saved here (“SOM_REACH_H2R_Mar_2024_Tool - 290224.xlsx”)
	Outputs
•	04_data_cleaning: Each Field Officer has a folder to store clogs they are responsible for. Finished clogs are moved to the “finished_clogs” subfolder. For ease of review, all clean clogs are also stored in this sub-folder: “__all_clean_clogs_for_HQ_review”
o	Surveys deleted prior to clog creation for either KI consent, interview duration, etc are stored in the “_deleted_prior_to_cleaning” folder and consolidated at the end of the cycle (found in the Deletions tab of the deliverable)
•	05_contact_information_dec_cycle: Each Field Officer has a folder to store possible future contacts
o	Process
	Download the latest data directly from Kobo into R
	Remove any surveys below 20min or greater than 80min (to save FOs’ time) and save them in a dedicated folder
	Run similarity checks to flag any issues to FOs so they can contact enumerators 
	Run all logic checks to create clogs
•	02_Clog Duplicate Parent Column Alignment & Binary Updates - REACH Somalia HSM Mar24 260224.R
o	Relevant folders
	Input
•	04_data_cleaning: The finished clogs from each enumerator are read in here
	Output
•	06_combining_clean_data: Processed clogs are consolidated by enumerator and stored in the sub-folder “fo_level_corrected_clogs_inputs”
o	All the updates for each uuid/variable combo are stored within text files here: 06_combining_clean_data/fo_level_corrected_clogs_inputs /output_text
o	Process
	This code is run for each enumerator after all their clogs have been filled out and verified by the data team
	The code 1) consolidates multiple changes for a given uuid/question combination and 2) updates binaries automatically
•	1) If a particular variable is flagged for multiple logic checks, there may be a conflict in between the resulting “new_value” fields. See below for an example
o	 
•	Note: For a given UUID/question/issue combination, the update provided by the Field Officers during the clogs review is stored under the “orig_new_value” column. After this code is run and parent columns are aligned, the final value will be stored in the “new_value” column 
o	“shocks” initially contains “drought_prolonged_lack_rain” and “insecurity”
o	Logic Check 1: After reviewing the first row, the Field Officer leaves “shocks” unchanged
o	Logic Check 2: After reviewing the second row, the Field Officer adds “flooding” to “shocks”
o	This code will recognize that these two rows belong to the same UUID/question combination and that they need to match. Based on the FO’s updates, in this case adding “flooding”, the “new_value” of “drought_prolonged_lack_rain”, “insecurity”, and “flooding” will apply to both rows
•	The code also updates the change_type to “change_response” for both rows 
•	2) Any updates because of filling out the clogs will automatically have an entry in the clog created
o	These are labeled “generated from reid's clog review code”
o	This removes the process of having to manually updating, saving time, and reducing errors
•	03_Create Clean Data & Align Clogs - REACH Somalia HSM Mar24 260224.R
o	Relevant Folders
	Input
•	06_combining_clean_data: The processed and clogs are read in from “fo_level_corrected_clogs_inputs”
	Output
•	06_combining_clean_data: The raw data, clean data, clog, and deletion file is stored within “combined_clean_data_and_clogs”
o	Process
	Once the previous step has been run for all enumerators, this code will consolidate all files into a single, combined file
	The combined file will then be checked for any issues with clogs (no issues found)
	Clean data will then be created and compared against the clogs to ensure nothing is missing (nothing was missing)
•	04_Data Aggregation - REACH Somalia HSM Mar24 260224.R
o	Relevant Folders: 07_aggregation
	Input
•	06_combining_clean_data: The clean data is read in from the folder “combined_clean_data_and_clogs”
	Output
•	07_aggregation: The KI-level aggregated data is stored here
o	Process
	We aggregate only the KI-level variables from the clean data (household level data is removed from the clean data)
	Settlement names that were manually input into the field “settlement_other” are combined with “settlements” selected through the multiple-choice options to create a “master” settlement name list called “settlement_combined”
•	We also use the file “mar24_hsm_settlement_dup_correct_names 031024.xlsx” in the folder “_FO_assignments_and_locations” to correct any misspellings spotted during the cycle
	The aggregation is run and the number of surveys per settlement is calculated
•	05a1_KI Level Results Table - REACH Somalia HSM Mar24 260224.R
o	Relevant Folders: 08_results_table
	Input
•	07_aggregation: The KI-Level aggregated data is read from here
	Output
•	08_results_table: The KI-level results data is stored in the “ki_level” subfolder
o	Process
	The results table is calculated for KI-level variables
•	05a2_HSM Analysis Reformatting KI Level_2003024.R
o	Relevant Folders: 08_results_table
	Input
•	08_results_table/ki_level: The KI-Level results table is read from here
	Output
•	08_results_table: The KI-level formatted results data is stored in the “ki_level” subfolder
o	Process
	The formatted results table is created for KI-level variables
•	05b1_HH Level Results Table - REACH Somalia HSM Mar24 260224.R
o	Relevant Folders: 08_results_table
	Input
•	06_combining_clean_data: The clean HH-level data is read in from the “combined_clean_data_and_clogs” folder
	Output
•	08_results_table: The HH-level results data is stored in the “hh_level” subfolder
	
o	Process
	Several calculations are done to create FCS Score, HHS Scores, etc.
	The results table is calculated for HH-level variables
	NOTE: No settlements are removed for the calculation of these variables (i.e. we do not include the “2 survey per settlement” limit like we do for calculating KI-level variables)
•	05b2_HSM Analysis Reformatting HH Level_2003024.R
o	Relevant Folders: 08_results_table
	Input
•	08_results_table/hh_level: The HH-Level results table is read from here
	Output
•	08_results_table: The HH-level formatted results data is stored in the “ki_level” subfolder
o	Process
	The formatted results table is created for KI-level variables
