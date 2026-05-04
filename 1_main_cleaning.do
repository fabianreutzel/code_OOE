/******************************************************************************\
#title: "1_main_cleaning.do"
#author: "Fabian Reutzel"
#structure: 1.1-1.8 Country-specific household survey data cleaning
			1.9 Household survey (HHS) dataset creation
			1.10 Country-specific labor force survey data cleaning
			1.11 Labor force survey (LFS) dataset creation
\******************************************************************************/
clear all
set more off

*DEFINE ROOT DIRECTORY
gl root "C:/Users/fabia/OneDrive - Université Paris 1 Panthéon-Sorbonne/World Bank"

*define file paths
gl code "$root/code_iop_south_asia"
gl interim "$root/data/interim"
gl raw "$root/data/raw"
gl clean "$root/data/clean"
gl GLD_WB "Y:" //World Bank Global Labor Database drive

*load required program
do "$code/1_cleaning/parent_merge.do"

*define variables of interest
gl var_main "survey survey_name year country coresident hh_id child_id wt* psu *geo_level* hh_rel hh_size child_coresident"
gl var_cores "father_home mother_home *_educ* *literate"
gl var_indiv "female age *_emp_*"
gl var_labor "lstatus empstat* wage unitwage"

********************************************************************************
**#1.1-1.8 Country-specific household survey data cleaning
********************************************************************************
do "$code/1_cleaning/1.1_HHS_AFG_dataset.do"
do "$code/1_cleaning/1.2_HHS_BGD_dataset.do"
do "$code/1_cleaning/1.3_HHS_BTN_dataset.do"
do "$code/1_cleaning/1.4_HHS_IND_dataset.do"
*do "$code/1_cleaning/1.5_HHS_MDV_dataset.do" //not used due to no circumstance data
do "$code/1_cleaning/1.6_HHS_NPL_dataset.do"
do "$code/1_cleaning/1.7_HHS_PAK_dataset.do"
do "$code/1_cleaning/1.8_HHS_LKA_dataset.do"

*delete all working files
local all_files: dir "$interim" files "*.dta"
di `"`all_files'"'
foreach file of local all_files {
	di `"`file'"'
    erase "$interim/`file'"
}
********************************************************************************
**#1.9 Household survey (HHS) dataset creation
********************************************************************************
do "$code/1_cleaning/1.9_HHS_dataset.do"
********************************************************************************
**#1.10 Country-specific labor force survey data cleaning
********************************************************************************
*set source of GLD data (local or WB drive)
gl GLD_local "yes"
do "$code/1_cleaning/1.10_LFS_country_datasets.do"

*delete all interim files
local all_files: dir "$interim" files "*.dta"
di `"`all_files'"'
foreach file of local all_files {
	di `"`file'"'
	erase "$interim/`file'"
}
********************************************************************************
**#1.11 Labor force survey (LFS) dataset creation
********************************************************************************
do "$code/1_cleaning/1.11_LFS_dataset.do"