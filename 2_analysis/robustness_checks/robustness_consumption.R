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

#########################################################################################/
#2. India ####
#########################################################################################/
#load data
data_cons_india_raw <- read_stata(paste0(path_data, "/clean/IND_cons.dta"))

##methodology-specific estimates
data_cons_india <- data_cons_india_raw %>%
  mutate_at(vars(female, urban, demo, geo_level_1, geo_level_2, religion, language, caste), ~factor(.)) %>%
  mutate(age = as.numeric(age),
         year_birth = year - age) %>%
  select(-c(country, hh_cons_wb)) %>%
  filter(age >= 35 & age <= 54) %>%
  pivot_longer(
    cols = c(hh_cons_wb_old, hh_cons_wb_new),
    names_to = "country",
    values_to = "hh_cons_wb"
  ) %>%
  mutate(country = gsub("hh_cons_wb_", "", country)) %>%
  filter(!is.na(hh_cons_wb))
#check & exclude cohort that are not fully covered (<4 of 5 years)
hh_cons_cohort_full_india <- data_cons_india %>%
  filter(is.na(cohort_5) != 1) %>%
  group_by(country, cohort_5) %>%
  summarise(
    max_y = max(year_birth, na.rm = TRUE),
    min_y = min(year_birth, na.rm = TRUE),
    n_obs = n(),
    n_years = length(unique(year)),
    years = toString(unique(year)),
    .groups = "drop"
  ) %>%
  mutate(sample_hh_cons_cohort = ifelse((max_y-min_y>= 3) & n_years>1, 1, 0)) %>% #pseudo panel restriction satisfied
  mutate(sample_hh_cons_cohort = ifelse(country == "new" & cohort_5 == 7, 1, sample_hh_cons_cohort)) %>% #keep despite no pseudo panel 
  select(country, cohort_5, sample_hh_cons_cohort)
data_cons_india <- data_cons_india %>% left_join(hh_cons_cohort_full_india, by = c("country", "cohort_5")) %>%
  filter(sample_hh_cons_cohort == 1)

cons_india_cs3 <- iop_ex_ante(data_cons_india, circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cohort_5", boot_n)
save(cons_india_cs3, file = paste0(path_results, "/cons_india_cs3.RData"))
load(paste0(path_results, "/cons_india_cs3.RData"))

#rescaling factors (to be used in joined graphs)
rescale_rel_iop = (cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 4, "rel_iop_p"] +
                     cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "rel_iop_p"]) /
  (cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 4, "rel_iop_p"] +
     cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "rel_iop_p"])
rescale_abs_iop = (cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 4, "abs_iop_p"] +
                     cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "abs_iop_p"]) /
  (cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 4, "abs_iop_p"] +
     cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "abs_iop_p"])
rescale_gini = (cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 4, "gini_p"] +
                  cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "gini_p"]) /
  (cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 4, "gini_p"] +
     cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "gini_p"])

rescale_rel_iop_last = cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "rel_iop_p"] / 
  cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "rel_iop_p"]
rescale_abs_iop_last = cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "abs_iop_p"] / 
  cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "abs_iop_p"]
rescale_gini_last = cons_india_cs3[cons_india_cs3["country"] == "old"&cons_india_cs3["year"] == 5, "gini_p"] / 
  cons_india_cs3[cons_india_cs3["country"] == "new"&cons_india_cs3["year"] == 5, "gini_p"]

rescale_india <- as.data.frame(cbind(
  rescale_rel_iop, rescale_rel_iop_last,
  rescale_abs_iop, rescale_abs_iop_last,
  rescale_gini, rescale_gini_last
))
save(rescale_india, file = paste0(path_results, "/rescale_india.RData"))

#harmonized estimates (disregarded as non-convincing due too flat total inequality trend)
cons_india_harm_cs3 <- iop_ex_ante(data_cons_india_raw %>%filter(cohort_5<= 8), circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cohort_5", boot_n)
save(cons_india_harm_cs3, file = paste0(path_results, "/cons_india_harm_cs3.RData"))
load(paste0(path_results, "/cons_india_harm_cs3.RData"))

#compare estimates
india_cons <- rbind(
  cons_india_cs3,
  cons_india_harm_cs3 %>% mutate(country = "harmonized")
) %>% select(year, country, gini_p, rel_iop_p) %>%
  pivot_wider(names_from = country, values_from = c(gini_p, rel_iop_p)) %>%
  arrange(year) %>%
  mutate(year = cohort_5_lab[year])
india_cons <- india_cons[, c("year",
                          "gini_p_old", "gini_p_new", "gini_p_harmonized",
                          "rel_iop_p_old", "rel_iop_p_new", "rel_iop_p_harmonized")]

addtorow <- list()
addtorow$pos <- list(0, 0)
addtorow$command <- c("& \\multicolumn{3}{c}{Gini} & \\multicolumn{3}{c}{Relative IOp} \\\\\n", 
                      " \\cmidrule(lr){2-4} \\cmidrule(lr){5-7}  Cohort & Old & New & Harm. & Old & New & Harm. \\\\\n")
print(xtable(india_cons), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow, 
      floating = FALSE, file = paste0(path_tables, "/annex/india_cons.tex"))