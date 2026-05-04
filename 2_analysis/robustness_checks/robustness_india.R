#########################################################################################/
# Overview####
#title: "robustness_india.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Cohort-based estimates across different LFSs ####
#########################################################################################/
outcome_type = "cohort"
boot_n = 2
estimation = "para"

data_lfs <- read_stata(paste0(path_data, "/clean/LFS_dataset.dta"))
data_labor_india <- data_lfs %>%
    filter(country == "India") %>%
    mutate(country = ifelse(year > 2015, "PLFS", "EUS")) %>%
    filter(age >= 35 & age <= 54) %>% #age restriction comparable cohort analysis
    mutate_at(vars(female, urban, demo, geo_level_1), ~factor(.)) %>%
    mutate(lfp = ifelse(is.na(lstatus), NA, ifelse(lstatus != 3, 1, 0)),
            paidwage_all = ifelse(is.na(lfp), NA, ifelse(is.na(empstat), 0, ifelse(empstat == 1, 1, 0))),
            paidwage = ifelse(is.na(lfp), NA, ifelse(lfp == 1, ifelse(is.na(empstat), NA, ifelse(empstat == 1, 1, 0)), NA)),
            wage = ifelse(empstat == 1 & wage > 0, wage, NA)) %>%
    mutate(educ_cat = ifelse(is.na(educ_cat_harm), NA,
                        ifelse(educ_cat_harm < 2, 0,
                            ifelse(educ_cat_harm  ==  2 | educ_cat_harm  ==  3| educ_cat_harm  ==  4, 1, 2)))) %>%
    mutate_at(vars(female, urban, demo, geo_level_1), ~factor(.))

#check & exclude cohort that are not fully covered (<4 of 5 years)
lfs_full <- data_labor_india %>% filter(is.na(cohort_5) != 1) %>%
    mutate(year_birth = year-age) %>%
    group_by(country, cohort_5) %>%
    summarise(
    max_y = max(year_birth, na.rm = TRUE),
    min_y = min(year_birth, na.rm = TRUE),
    n_obs = n(),
    n_years = length(unique(year)), #pseudo panel restriction satisfied
    .groups = "drop"
    ) %>%
    mutate(sample_lfs = ifelse((max_y - min_y >= 3) & n_years > 1, 1, 0)) %>%
    select(country, cohort_5, sample_lfs)
data_labor_india <- data_labor_india %>% left_join(lfs_full, by = c("country", "cohort_5")) %>%
    filter(sample_lfs == 1)

#check true pseudo panel
lm_test_pseudo <- data_labor_india %>%
    group_by(country, cohort_5) %>%
    summarise(n_years = length(unique(year)),
     max_y = max(year_birth, na.rm = TRUE),
    min_y = min(year_birth, na.rm = TRUE),
    .groups = "drop")

if(restimation == TRUE){
    lfp_india_cs4 <- iop_ex_ante(data_labor_india, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    save(lfp_india_cs4, file = paste0(path_results, "/lfp_india_cs4.RData"))
    paidwage_india_cs4 <- iop_ex_ante(data_labor_india, circumstances_cs4, outcome = "paidwage", estimation, type = "cohort_5", boot_n)
    save(paidwage_india_cs4, file = paste0(path_results, "/paidwage_india_cs4.RData"))
    wage_india_cs4 <- iop_ex_ante(data_labor_india, circumstances_cs4, outcome = "wage", estimation, type = "cohort_5", boot_n)
    save(wage_india_cs4, file = paste0(path_results, "/wage_india_cs4.RData"))
} else {
    load(paste0(path_results, "/lfp_india_cs4.RData"))
    load(paste0(path_results, "/paidwage_india_cs4.RData"))
    load(paste0(path_results, "/wage_india_cs4.RData"))
}

robustness_india <- rbind(
    lfp_india_cs4 %>% select(country, year, abs_iop_p, share_p) %>% mutate(outcome = 1) %>%
        rename_with(~paste0("rel", substr(., 4, nchar(.))), starts_with("abs")) %>%
        rename_with(~paste0("gini", substr(., 6, nchar(.))), starts_with("share")),
    paidwage_india_cs4 %>%  select(country, year, abs_iop_p, share_p) %>% mutate(outcome = 2) %>%
        rename_with(~paste0("rel", substr(., 4, nchar(.))), starts_with("abs")) %>%
        rename_with(~paste0("gini", substr(., 6, nchar(.))), starts_with("share")),
    wage_india_cs4 %>%  select(country, year, rel_iop_p, gini_p) %>% mutate(outcome = 3)
    ) %>%
    select(year, country, outcome, gini_p, rel_iop_p) %>%
    pivot_wider(names_from = country, values_from = c(gini_p, rel_iop_p)) %>%
    pivot_wider(names_from = outcome, values_from = c(gini_p_EUS, gini_p_PLFS, rel_iop_p_EUS, rel_iop_p_PLFS)) %>%
    arrange(year) %>%
    mutate(year = cohort_5_lab[year]) %>%
    select(where(~ !all(is.na(.))))

#reorganize columns for better readability in table
robustness_india <- robustness_india[,
    c("year",
    "gini_p_EUS_1", "gini_p_PLFS_1", "rel_iop_p_EUS_1", "rel_iop_p_PLFS_1",
    "gini_p_EUS_2", "gini_p_PLFS_2", "rel_iop_p_EUS_2", "rel_iop_p_PLFS_2",
    "gini_p_EUS_3", "gini_p_PLFS_3", "rel_iop_p_EUS_3", "rel_iop_p_PLFS_3"
    )]

addtorow <- list()
addtorow$pos <- list(0, 0, 0)
addtorow$command <- c(
    "& \\multicolumn{4}{c}{LFP} & \\multicolumn{4}{c}{Wage-Employment} & \\multicolumn{4}{c}{Wages} \\\\\n", 
    " \\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13} & \\multicolumn{2}{c}{Share} & \\multicolumn{2}{c}{IOp} & \\multicolumn{2}{c}{Share} & \\multicolumn{2}{c}{IOp} & \\multicolumn{2}{c}{Gini} & \\multicolumn{2}{c}{IOp} \\\\\n", 
    " \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}  \\cmidrule(lr){6-7}  \\cmidrule(lr){8-9}  \\cmidrule(lr){10-11} \\cmidrule(lr){12-13} & EUS & PLFS & EUS & PLFS & EUS & PLFS & EUS & PLFS & EUS & PLFS & EUS & PLFS \\\\\n")
print(xtable(robustness_india), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow, 
      floating = FALSE, file = paste0(path_tables, "/annex/robustness_india.tex"))