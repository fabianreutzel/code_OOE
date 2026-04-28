#########################################################################################/
# Overview####
#title: "2_main_analysis.R"
#author: "Fabian Reutzel"
#########################################################################################/
rm(list = ls())

#DEFINE ROOT DIRECTORY
setwd ("XXX")

#define file paths
path_figures = paste0(getwd(), "/outputs/figures")
path_tables = paste0(getwd(), "/outputs/tables")
path_results = paste0(getwd(), "/outputs/files")
path_code = paste0(getwd(), "/code")
path_data = paste0(getwd(), "/data")

#create output directories
if(!dir.exists(paste0(path_results))){dir.create(paste0(path_results), recursive = TRUE)}
if(!dir.exists(paste0(path_figures))){dir.create(paste0(path_figures), recursive = TRUE)}
if(!dir.exists(paste0(path_figures, "/main"))){dir.create(paste0(path_figures, "/main"), recursive = TRUE)}
if(!dir.exists(paste0(path_figures, "/annex"))){dir.create(paste0(path_figures, "/annex"), recursive = TRUE)}
if(!dir.exists(paste0(path_tables))){dir.create(paste0(path_tables), recursive = TRUE)}
if(!dir.exists(paste0(path_tables, "/main"))){dir.create(paste0(path_tables, "/main"), recursive = TRUE)}
if(!dir.exists(paste0(path_tables, "/annex"))){dir.create(paste0(path_tables, "/annex"), recursive = TRUE)}

#load packages
list.of.packages <- c("tidyverse", "sandwich", "rlang","haven", "xtable", "data.table", "DescTools", "broom", "matrixStats",
                      "survey", "margins", "dineq", "boot", "party", "partykit", "latex2exp", "labelled", "car")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if(length(new.packages) != 0){install.packages(new.packages, repos = "http://cran.us.r-project.org")}
lapply(list.of.packages, library, character.only = TRUE)

#define cohort labels
cohort_5_lab <- c("1" = "1950-54", "2" = "1955-59", "3" = "1960-64", "4" = "1965-69", "5" = "1970-74",
                  "6" = "1975-79", "7" = "1980-84", "8" = "1985-89", "9" = "1990-94", "10" = "1995-00")

#define circumstance sets
circumstances_cs3 <- c("age", "demo", "urban", "geo_level_1")
circumstances_cs4 <- c("age", "female", "demo", "urban", "geo_level_1")
circumstances_cs5 <- c("age", "female", "demo", "urban", "geo_level_1", "geo_level_2")
circumstances_cs4hh <- c("age", "demo", "urban", "geo_level_1", "geo_level_2")
circumstances_co4 <- c("age", "female", "parents_educ", "demo", "urban", "geo_level_1")

#########################################################################################/
#1. Cross-sectional results ####
#########################################################################################/
outcome_dim = "all" #options: "all", "educ", "coresident", "cons", "labor"
outcome_type = "cs" #options: "cs", "cohort"
boot_n = 2 #number of bootstrap replications (not used in paper for brevity)
estimation = "para" #options: "para", "forest" => only "para" used in main part of paper
restimation = TRUE

#load data
if(restimation == TRUE){source(paste0(path_code, "/2_analysis/2.0_data_import.R"))}

#load functions
source(paste0(path_code, "/2_analysis/iop_ex_ante.R"))

#run estimations AND create tables
source(paste0(path_code, "/2_analysis/2.1_IOp_cross-section_intro.R"))

#########################################################################################/
# 2. Cohort results ####
#########################################################################################/
outcome_dim = "labor" #options: "all", "educ", "coresident", "cons", "labor"
outcome_type = "cohort" #options: "cs", "cohort"
boot_n = 2 #number of bootstrap replications (not used in paper for brevity)
estimation = "para" #options: "para", "forest" => only "para" used in main part of paper
restimation = TRUE
robustness_checks = TRUE
robustness_forest = FALSE

#load data
if(restimation == TRUE){source(paste0(path_code, "/2_analysis/2.0_data_import.R"))}

#load functions
source(paste0(path_code, "/2_analysis/iop_ex_ante.R"))
source(paste0(path_code, "/2_analysis/profiles.R"))
source(paste0(path_code, "/2_analysis/circ_imp_para.R"))

#run estimations AND create tables and figures with single outcome dimension
source(paste0(path_code, "/2_analysis/2.2_IOp_cohort.R"))
if(outcome_dim == "all" | outcome_dim == "labor"){source(paste0(path_code, "/2_analysis/2.3_regression_analyses.R"))}
source(paste0(path_code, "/2_analysis/2.4_opportunity_profiles.R"))
source(paste0(path_code, "/2_analysis/2.5_circ_importance.R"))

#mandatory robustness checks for consumption (incl. adjustment factor for India)
if(outcome_dim == "all" | outcome_dim == "cons"){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_consumption.R"))}

#run other robustness checks
if(robustness_checks == TRUE){
  if(robustness_forest == TRUE){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_forest.R"))}
  if(outcome_dim == "all" | outcome_dim == "educ"){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_education.R"))}
  if(outcome_dim == "all" | outcome_dim == "coresident"){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_coresident.R"))}
  if(outcome_dim == "all" | outcome_dim == "labor"){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_labor.R"))}
  if(outcome_dim == "all"){source(paste0(path_code, "/2_analysis/robustness_checks/robustness_migration.R"))}
}

#create tables and figures with multiple outcome dimension
if(outcome_dim == "all" & outcome_type == "cohort"){
  source(paste0(path_code, "/2_analysis/2.6_joint_tables.R"))
  source(paste0(path_code, "/2_analysis/2.7_joint_graphs.R"))
}