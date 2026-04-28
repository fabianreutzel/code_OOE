#########################################################################################/
# Overview####
#title: "2.7_joint_tables"
#author: "Fabian Reutzel"
#########################################################################################/

#########################################################################################/
#1. Tables sample size & total inequality & relative IOp ####
#########################################################################################/
load(paste0(path_results, "/educ_cs4.RData"))
load(paste0(path_results, "/cons_cs3.RData"))
load(paste0(path_results, "/lfp_cs4_hhs.RData"))
load(paste0(path_results, "/lfp_cs4_lfs.RData"))
load(paste0(path_results, "/lfp_cs4.RData"))
load(paste0(path_results, "/paidwage_cs4_hhs.RData"))
load(paste0(path_results, "/paidwage_cs4_lfs.RData"))
load(paste0(path_results, "/paidwage_cs4.RData"))
load(paste0(path_results, "/wage_cs4_hhs.RData"))
load(paste0(path_results, "/wage_cs4_lfs.RData"))
load(paste0(path_results, "/wage_cs4.RData"))

##estimates for both sources
educ_cons_labor_all <- educ_cs4 %>% select(country, year, gini_p, rel_iop_p, N) %>% dplyr::rename(gini_educ  =  gini_p, iop_educ  =  rel_iop_p, n_educ  =  N) %>%
  left_join(cons_cs3 %>% select(country, year, gini_p, rel_iop_p, N) %>% dplyr::rename(gini_cons  =  gini_p, iop_cons  =  rel_iop_p, n_cons  =  N), by = c("country", "year")) %>% 
  left_join(lfp_cs4_hhs %>% filter(country != "Nepal") %>% select(country, year, share_p, abs_iop_p, N) %>% dplyr::rename(share_lfp  =  share_p, iop_lfp  =  abs_iop_p, n_lfp  =  N), by = c("country", "year")) %>%
  left_join(lfp_cs4_lfs %>% filter(country != "Nepal") %>%select(country, year, share_p, abs_iop_p, N) %>% dplyr::rename(share_lfp_lfs  =  share_p, iop_lfp_lfs  =  abs_iop_p, n_lfp_lfs  =  N), by = c("country", "year")) %>%
  left_join(paidwage_cs4_hhs %>%select(country, year, share_p, abs_iop_p, N) %>% dplyr::rename(share_paidwage  =  share_p, iop_paidwage  =  abs_iop_p, n_paidwage  =  N), by = c("country", "year")) %>%
  left_join(paidwage_cs4_lfs %>% filter(country != "Nepal") %>%select(country, year, share_p, abs_iop_p, N) %>% dplyr::rename(share_paidwage_lfs  =  share_p, iop_paidwage_lfs  =  abs_iop_p, n_paidwage_lfs  =  N), by = c("country", "year")) %>%
  left_join(wage_cs4_hhs %>% filter(country != "Nepal") %>%select(country, year, gini_p, rel_iop_p, N) %>% dplyr::rename(gini_wage  =  gini_p, iop_wage  =  rel_iop_p, n_wage  =  N), by = c("country", "year")) %>%
  left_join(wage_cs4_lfs %>% filter(country != "Nepal") %>% select(country, year, gini_p, rel_iop_p, N) %>% dplyr::rename(gini_wage_lfs  =  gini_p, iop_wage_lfs  =  rel_iop_p, n_wage_lfs  =  N), by = c("country", "year")) %>%
  mutate(year  =  dplyr::recode(year, !!!cohort_5_lab)) %>%
  group_by(country) %>% mutate(country = ifelse(year == min(year), country, "")) %>% ungroup()

#Total Ineq. & IOp
non_empty_indices <- which(educ_cons_labor_all$country != "")[-1]
addtorow_hlines <- list()
addtorow_hlines$pos <- as.list(non_empty_indices - 1)
addtorow_hlines$command <- rep("\\hline ", length(non_empty_indices))
header_rows <- list()
header_rows$pos <- list(0, 0, 0)
header_rows$command <- c(
  "\\multicolumn{2}{c}{} & \\multicolumn{2}{c}{Education} & \\multicolumn{2}{c}{Consumption} & \\multicolumn{4}{c}{LFP} & \\multicolumn{4}{c}{Wage Employment} & \\multicolumn{4}{c}{Wages}\\\\\n", 
  " \\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-10} \\cmidrule(lr){11-14} \\cmidrule(lr){15-18} \\multicolumn{6}{c}{} & \\multicolumn{2}{c}{HH Survey} & \\multicolumn{2}{c}{LF Survey} & \\multicolumn{2}{c}{HH Survey} & \\multicolumn{2}{c}{LF Survey} & \\multicolumn{2}{c}{HH Survey} & \\multicolumn{2}{c}{LF Survey}\\\\\n", 
  " \\cmidrule(lr){7-8} \\cmidrule(lr){9-10} \\cmidrule(lr){11-12} \\cmidrule(lr){13-14} \\cmidrule(lr){15-16} \\cmidrule(lr){17-18} Country & Cohort & Gini & IOp & Gini & IOp & Share & IOp & Share & IOp & Share & IOp & Share & IOp & Gini & IOp & Gini & IOp \\\\\n"
)
combined_addtorow <- list(pos  =  c(header_rows$pos, addtorow_hlines$pos), 
                         command  =  c(header_rows$command, addtorow_hlines$command))
output_raw <- print(xtable(educ_cons_labor_all %>%select(-contains("n_"))), include.rownames = FALSE, include.colnames = FALSE, 
          add.to.row = combined_addtorow, booktabs  =  TRUE, sanitize.text.function  =  function(x){ x }, floating = FALSE, file = "")
output <- sub("(\\\\begin\\{tabular\\})\\{(.*?)\\}", "\\1{ll|rr|rr|rrrr|rrrr|rrrr}", output_raw)
cat(output, file = paste0(path_tables, "/annex/educ_cons_labor.tex"), sep  =  "\n")

#Sample Size
non_empty_indices <- which(educ_cons_labor_all$country != "")[-1]
addtorow_hlines <- list()
addtorow_hlines$pos <- as.list(non_empty_indices - 1)
addtorow_hlines$command <- rep("\\hline ", length(non_empty_indices))
header_rows <- list()
header_rows$pos <- list(0, 0)
header_rows$command <- c("\\multicolumn{2}{c}{} & \\multicolumn{1}{c}{Education} & \\multicolumn{1}{c}{Consumption} & \\multicolumn{2}{c}{LFP} & \\multicolumn{2}{c}{Wage Employment} & \\multicolumn{2}{c}{Wages}\\\\\n", 
                         " \\cmidrule(lr){3-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8} \\cmidrule(lr){9-10} Country & Cohort & HH Survey & HH Survey & HH Survey & LF Survey & HH Survey & LF Survey & HH Survey & LF Survey \\\\\n")
combined_addtorow <- list(pos  =  c(header_rows$pos, addtorow_hlines$pos), 
                          command  =  c(header_rows$command, addtorow_hlines$command))
sample_size_cohort_all <- educ_cons_labor_all%>% select(-c(contains("iop"), contains("share"), contains("gini")))
output_raw <- print(xtable(sample_size_cohort_all), include.rownames = FALSE, include.colnames = FALSE, 
          add.to.row = combined_addtorow, booktabs  =  TRUE, sanitize.text.function  =  function(x){ x }, floating = FALSE, file = "")
output <- sub("(\\\\begin\\{tabular\\})\\{(.*?)\\}", "\\1{ll|r|r|rr|rr|rr}", output_raw)
cat(output, file = paste0(path_tables, "/annex/sample_size_cohort.tex"), sep  =  "\n")