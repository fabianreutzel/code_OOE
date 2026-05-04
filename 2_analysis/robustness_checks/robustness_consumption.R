#########################################################################################/
# Overview####
#title: "robustness_consumption.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Cohort age tables####
#########################################################################################/
if(restimation == TRUE){
  cons_cohort_age <- iop_ex_ante(data = data_cons %>% filter(cohort_age_5 != ""), circumstances = circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cohort_age_5", boot_n)
  save(cons_cohort_age, file = paste0(path_results, "/cons_cohort_age.RData"))
} else {
  load(paste0(path_results, "/cons_cohort_age.RData"))
}

load(paste0(path_results, "/cons_cs3.RData"))
country_hh_cons <- unique(cons_cs3$country)
for(c in country_hh_cons){
  tab_cohort_age_raw <- cons_cohort_age[[c]] %>% filter(row_number() <=  n()-1)
  iop_est <- t(cons_cs3 %>% filter(country == c) %>% select(rel_iop_p))
  #if(length(iop_est)<7){iop_est <- c(iop_est, NA)}
  mean_iop <- mean(iop_est, na.rm = TRUE)
  tab_cohort_age <- rbind(
    tab_cohort_age_raw,
    c("Est. IOp", round(c(iop_est, mean_iop), 3)),
    cons_cohort_age[[c]] %>% filter(row_number()  ==  n()))
  addtorow <- list()
  addtorow$pos <- list(0, 0)
  addtorow$command <- c("Age & \\multicolumn{7}{c}{Birth Cohort} & Avr. IOp / \\\\\n", 
                        "\\cmidrule(lr){2-8} Group & 1950-54 & 1955-59 &  1960-64 & 1965-69 & 1970-74 & 1975-79 & 1980-84 & Total Obs. \\\\\n")
  if(c == "Bangladesh"|c == "India"){
  addtorow$command <- c("Age& \\multicolumn{6}{c}{Birth Cohort} & Avr. IOp / \\\\\n",
                        "\\cmidrule(lr){2-7} Group & 1950-54 & 1955-59 &  1960-64 & 1965-69 & 1970-74 & 1975-79 & Total Obs. \\\\\n")}
  print(xtable(tab_cohort_age), add.to.row = addtorow, include.colnames = FALSE, include.rownames = FALSE,
        hline.after = c(-1, 0, nrow(tab_cohort_age_raw)-1, nrow(tab_cohort_age_raw)+1, nrow(tab_cohort_age_raw)+2),
        file = paste0(path_tables, "/annex/cons_cohort_age_", c, ".tex"), floating = FALSE)
}