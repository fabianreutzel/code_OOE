#########################################################################################/
# Overview####
#title: "2.0_data_import"
#author: "Fabian Reutzel"
#########################################################################################/

#########################################################################################/
#1.0 load raw HHS data
#########################################################################################/
data_hhs <- read_stata(paste0(path_data, "/clean/HHS_dataset.dta"))
#factorize variables
demo_lab <- val_labels(data_hhs$demo)
geo_level_1_lab <- val_labels(data_hhs$geo_level_1)
data_hhs <- data_hhs %>%
  mutate_at(vars(female, urban, demo, geo_level_1, geo_level_2, religion, language, caste), ~factor(.))

#########################################################################################/
# 1.1 Cross-sectional data####
#########################################################################################/
if(outcome_dim == "all"|outcome_dim == "cons"){
  data_cons_cs_all <- data_hhs %>%
    filter(sample_iop_cons == 1) %>%
    #excl. new harmonized consumption measure for India as not reliable (see "robustness_india.R")
    mutate(hh_cons_wb = ifelse(country != "India", hh_cons_wb, ifelse(year>2011, hh_cons_wb_new, hh_cons_wb_old)))
  data_cons_cs <- data_cons_cs_all %>%
    filter(age >= 18) #GEOM sample restriction
  if(outcome_type != "cs"){
    rm(data_cons_cs_all)
  }
}

if(outcome_dim == "all"|outcome_dim == "labor"){
  #Household Surveys
  data_hhs_cs <- data_hhs %>%
    filter(sample_iop_labor == 1) %>% #sample restriction
    filter(age >= 15 & age <= 64) %>% #age restriction labor force
    filter(age >= 35 & age <= 54) %>% #age restriction comparable cohort analysis
    filter(!(year == 2008 & country == "Afghanistan")) %>% #quite different
    filter(!(year == 2007 & country == "Bhutan")) %>% #spike in LFP
    mutate(empstat = ifelse(country == "Bangladesh" & year == 2000, NA, empstat)) %>% #overall wage-employment share comparable BUT <50% of wage-employees receive a wage
    mutate(wage = ifelse(country == "Bangladesh" & year == 2000, NA, wage)) %>% #overall wage-employment share comparable BUT <50% of wage-employees receive a wage
    filter(!(country == "Bangladesh" & year == 2022)) %>% #exclude Bangladesh 2022 because of spike in paidwage & LFP 
    mutate(empstat = ifelse(country == "Pakistan" & year == 2013, NA, empstat)) %>% # dip in paidwage
    mutate(lstatus = ifelse(country == "Pakistan" & year == 2013, NA, lstatus)) %>% #spike in lfp
    mutate(empstat = ifelse(country == "Sri Lanka" & year == 2002, NA, empstat)) %>% #non-fully comparable question
    #dichotomize labor outcomes
    mutate(lfp = ifelse(is.na(lstatus) != 1, ifelse(lstatus != 3, 1, 0), NA),
           paidwage_all = ifelse(is.na(lfp), NA, ifelse(is.na(empstat), 0, ifelse(empstat == 1, 1, 0))),
           paidwage = ifelse(is.na(lfp), NA, ifelse(lfp == 1, ifelse(is.na(empstat), NA, ifelse(empstat == 1, 1, 0)), NA)),
           paidwage_wage = ifelse(is.na(lfp), NA, ifelse(lfp == 1, ifelse(wage>0, 1, 0), NA)),
           wage = ifelse(empstat == 1 & wage > 0, wage, NA)) %>%
    mutate(educ_cat = ifelse(is.na(educ_cat_harm), NA,
                        ifelse(educ_cat_harm < 2, 0,
                          ifelse(educ_cat_harm  ==  2 | educ_cat_harm  ==  3| educ_cat_harm  ==  4, 1, 2)))) %>%
    mutate_at(vars(female, urban, demo, geo_level_1), ~factor(.))

  #Labor Force Surveys
  data_lfs <- read_stata(paste0(path_data, "/clean/LFS_dataset.dta"))
  data_lfs_cs <- data_lfs %>%
    filter(age >= 15 & age <= 64) %>% #age restriction labor force
    filter(age >= 35 & age <= 54) %>% #age restriction comparable cohort analysis
    mutate(lfp = ifelse(is.na(lstatus), NA, ifelse(lstatus != 3, 1, 0)),
           paidwage_all = ifelse(is.na(lfp), NA, ifelse(is.na(empstat), 0, ifelse(empstat == 1, 1, 0))),
           paidwage = ifelse(is.na(lfp), NA, ifelse(lfp == 1, ifelse(is.na(empstat), NA, ifelse(empstat == 1, 1, 0)), NA)),
           wage = ifelse(empstat == 1 & wage > 0, wage, NA)) %>%
    mutate(educ_cat = ifelse(is.na(educ_cat_harm), NA,
                        ifelse(educ_cat_harm < 2, 0,
                          ifelse(educ_cat_harm  ==  2 | educ_cat_harm  ==  3| educ_cat_harm  ==  4, 1, 2)))) %>%
    mutate_at(vars(female, urban, demo, geo_level_1), ~factor(.))
  
  #combine HH & LFS datasets (all cross-sections of selected data sources)
  data_labor_cs <- rbind(data_hhs_cs %>% filter(country == "Afghanistan"|country == "Bhutan"|country == "Pakistan") %>%
                          select(country, id, cohort_5, wt_hh, year, lfp, paidwage, paidwage_all, wage, age, age_2, female, demo, urban, geo_level_1),
                         data_lfs_cs %>%
                          select(country, id, cohort_5, wt_hh, year, lfp, paidwage, paidwage_all, wage, age, age_2, female, demo, urban, geo_level_1)) %>%
                          filter(is.na(wt_hh) != 1) #exclude missing weights (mostly LFS)
}

#########################################################################################/
# 1.2 Cohort data####
#########################################################################################/
if(outcome_type != "cs"){
  if(outcome_dim == "educ"| outcome_dim == "coresident" | outcome_dim == "all"){
    data_educ <- data_hhs %>%
      filter(is.na(educ) != 1, is.na(cohort_5) != 1) %>%
      filter(age>21) %>%
      filter(!(survey == "NLSS"&cohort_5<= 8)) %>% #use only NPHC for older cohorts (NLSS only when not covered by NPHC)
      mutate(prim = ifelse(educ_cat_harm>= 2&is.na(educ_cat_harm) != 1, 1, 0),
             lowsec = ifelse(educ_cat_harm>= 4&is.na(educ_cat_harm) != 1, 1, 0),
             uppsec = ifelse(educ_cat_harm>= 5&is.na(educ_cat_harm) != 1, 1, 0),
             tert = ifelse(educ_cat_harm == 6&is.na(educ_cat_harm) != 1, 1, 0)) %>%
      mutate(educ_cat = ifelse(is.na(educ_cat_harm), NA,
                            ifelse(educ_cat_harm < 2, 0,
                              ifelse(educ_cat_harm  ==  2 | educ_cat_harm  ==  3| educ_cat_harm  ==  4, 1, 2))))

    #check & exclude cohort that are not fully covered (<4of5 years)  = > done
    educ_cohort_full <- data_educ %>%
      group_by(country, cohort_5) %>%
      summarise(
        max_y = max(year_birth, na.rm = TRUE), 
        min_y = min(year_birth, na.rm = TRUE), 
        n_obs = n(),
        .groups = "drop"
      ) %>%
      mutate(sample_educ_cohort = ifelse(max_y-min_y>= 3, 1, 0)) %>%
      select(country, cohort_5, sample_educ_cohort) %>%
      dplyr::rename(year = cohort_5)
  }
  
  if(outcome_dim == "coresident" | outcome_dim == "all"){
    data_educ_age <- data_hhs %>% filter(is.na(educ) != 1, age>= 15&age<= 18) %>%
      mutate(prim = ifelse(educ_cat_harm>= 2&is.na(educ_cat_harm) != 1, 1, 0), 
             uppsec = ifelse(educ_cat_harm>= 5&is.na(educ_cat_harm) != 1, 1, 0))
    data_educ_cores <- data_educ_age %>% filter(coresident == 1) 
    data_educ_iop <- data_educ_cores %>% filter(is.na(parents_educ) != 1) #re: issue extracting parental education NLSS 2022
    data_educ_perf <- data_hhs %>% filter(is.na(educ) != 1&age>= 21) %>% filter(survey_coresident == "no")
    data_educ_perf_age <- data_hhs %>% filter(is.na(educ) != 1) %>% filter(survey_coresident == "no")
    #topcode education for coresident analysis
    data_educ_adj <- data_educ %>% mutate(educ = ifelse((educ<= 10 & educ != is.na(educ)), educ, 10))
    data_educ_age <- data_educ_age %>% mutate(educ = ifelse((educ<= 10 & educ != is.na(educ)), educ, 10))
    data_educ_iop <- data_educ_iop %>% mutate(educ = ifelse((educ<= 10 & educ != is.na(educ)), educ, 10))
    data_educ_perf_age <- data_educ_perf_age %>% mutate(educ = ifelse((educ<= 10 & educ != is.na(educ)), educ, 10))
    data_educ_iop_ptrunc <-  data_educ_iop %>% mutate(parents_educ = ifelse((parents_educ<= 10 & parents_educ != is.na(parents_educ)), parents_educ, 10))
    
    #generate country-specific cohorts for coresident comparison
    cohort_cores <- data_educ_iop %>% 
      dplyr::rename(year_survey = year) %>%
      group_by(country, year_survey) %>% 
      summarise(year = min(year_birth), .groups = "drop_last")
  }

  if(outcome_dim == "cons" | outcome_dim == "all"){
    data_cons <- data_cons_cs %>%
      filter(!(country == "India" & year == 2022)) %>% #non-comparable sampling to 2011 (Reviewer request)
      filter(!(country == "Afghanistan")) %>% #NRVA not comparable across waves
      filter(!(country == "Bangladesh" & year == 2022)) %>% #non-comparable welfare aggregate (PIP)
      filter(!(country == "Bhutan" & year == 2022)) %>% #non-comparable welfare aggregate (PIP)
      filter(!(country == "Nepal")) %>% #only 3 cohorts covered and issue of weights
      mutate(hh_cons_wb = ifelse(country != "India", hh_cons_wb, hh_cons_wb_old)) %>%  #use old measure for all cohorts (Reviewer request)
      filter(age >= 35 & age <= 54)

  #check & exclude cohort that are not fully covered (<4of5 years)
    hh_cons_cohort_full <- data_cons %>%
      filter(is.na(cohort_5) != 1) %>%
      group_by(country, cohort_5) %>%
      summarise(
        max_y = max(year_birth, na.rm = TRUE), 
        min_y = min(year_birth, na.rm = TRUE), 
        n_obs = n(),
        n_years = length(unique(year)), #pseudo panel restriction satisfied 
        .groups = "drop"
      ) %>%
      mutate(sample_hh_cons_cohort = ifelse((max_y - min_y >= 3) & n_years>1, 1, 0)) %>%
      select(country, cohort_5, sample_hh_cons_cohort)

    data_cons <- data_cons %>% left_join(hh_cons_cohort_full, by = c("country", "cohort_5")) %>%
      filter(sample_hh_cons_cohort == 1)
  }

  if(outcome_dim == "labor" | outcome_dim == "all"){
    ##Household Surveys
    rm(data_labor_cs)
    data_hhs_full <- data_hhs_cs %>%
      filter(!((country == "Nepal"|country == "Bhutan") & year == 2022)) %>% # LFP not comparable to previous waves
      #different survey for Bhutan (estimates are influenced by spike in LFP for young cohorts)
      filter(age >= 35 & age <= 54) #age restriction
    rm(data_hhs_cs)
    #check & exclude cohorts that are not fully covered (<4 of 5 years)
    lm_full <- data_hhs_full %>% filter(is.na(cohort_5) != 1) %>%
      mutate(year_birth = year-age)%>%
      group_by(country, cohort_5) %>%
      summarise(
        max_y = max(year_birth, na.rm = TRUE),
        min_y = min(year_birth, na.rm = TRUE),
        n_obs = n(),
        n_years = length(unique(year)), #pseudo panel restriction satisfied
        .groups = "drop"
      ) %>%
      mutate(sample_hh_cons_cohort = ifelse((max_y - min_y >= 3) & n_years>1, 1, 0)) %>%
      mutate(sample_lm = ifelse((max_y -min_y >= 3)&n_years>1, 1, 0)) %>%
      select(country, cohort_5, sample_lm) %>%
      filter(!(cohort_5 <= 1 & (country == "Bangladesh")) & !(cohort_5 <= 2 & (country == "Bhutan"))) #excl. small sample wrt other birth cohorts

    data_hhs_full <- data_hhs_full %>% left_join(lm_full, by = c("country", "cohort_5")) %>%
      mutate(wage = ifelse(country == "Nepal"|country == "Afghanistan", NA, wage)) %>% #too small sample size 
      filter(sample_lm == 1)
    #sample restriction for graphs with non-restricted data
    lm_full <- lm_full %>% dplyr::rename(year = cohort_5)
    #check true pseudo panel
    lm_test_pseudo <- data_hhs_full %>% 
      group_by(country, cohort_5) %>% 
      summarise(n_years = length(unique(year)), .groups = "drop")

    ##LFS
    data_lfs_full <- data_lfs_cs %>%
      filter(age >= 35 & age <= 54) %>% #age restriction cohort
      mutate(educ = ifelse(country == "Bangladesh" & year == 2013, NA, educ),
            educ_cat = ifelse(country == "Bangladesh" & year == 2013, NA, educ_cat)) %>% # share no primary to divergent to other waves
      mutate(wage = ifelse(country == "Bangladesh" & year == 2022, NA, wage)) %>% # change in methodology (mean 2016 1794 vs 2022 1064)
      filter(!(cohort_5<6&country == "India" & year>2015)) %>% #excl. new waves for old cohorts due to differing definitions 
      filter(!(year>2016&country == "Nepal")) %>% # keep first waves but only for paidwage for comparison
      mutate(wage = ifelse(country == "Nepal", NA, wage)) %>% # weird estimates
      mutate(lfp = ifelse(country == "Nepal", NA, lfp)) #too high LFP

    rm(data_lfs_cs)
    #check & exclude cohort that are not fully covered (<4 of 5 years)
    lfs_full <- data_lfs_full %>% filter(is.na(cohort_5) != 1) %>%
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
      filter(!(cohort_5 == 1&(country == "Nepal"))) %>% #excl. small sample wrt other birth cohorts (BGD 1950-54 excl. due to missing pseudo)
      select(country, cohort_5, sample_lfs)
    data_lfs_full <- data_lfs_full %>% left_join(lfs_full, by = c("country", "cohort_5")) %>%
      filter(sample_lfs == 1)
    #check true pseudo panel
    lm_test_pseudo <- data_lfs_full %>%
      group_by(country, cohort_5) %>%
      summarise(n_years = length(unique(year)), .groups = "drop")
    
    ##combine both datasets
    data_labor <- rbind(data_hhs_full %>% filter(country == "Afghanistan"|country == "Bhutan"|country == "Nepal"|country == "Pakistan") %>%
                           select(country, id, cohort_5, cohort_age_5, educ_cat, educ, age, age_2, wt_hh, year, lfp, paidwage, paidwage_all, wage, female, demo, urban, geo_level_1) %>%
                           mutate(lfp = ifelse(country == "Nepal", NA, lfp), # exclude due to overstated LFP & too positive development
                                  paidwage = ifelse(country == "Nepal", paidwage_all, paidwage)), #adjust paidwage for Nepal 
                        data_lfs_full %>% filter(country != "Nepal", country != "Bhutan") %>% #larger coverage NLSS than LFS; BLSS preferred b/c longer panel
                           select(country, id, cohort_5, cohort_age_5, educ_cat, educ, age, age_2, wt_hh, year, lfp, paidwage, paidwage_all, wage, female, demo, urban, geo_level_1)
    )

    ##education x labor dataset
    data_labor_educ_cat <- data_labor %>%
      filter(is.na(educ_cat) != 1) %>%
      mutate(lfp = ifelse(country == "Nepal", NA, lfp), # exclude due to overstated LFP & too positive development
             paidwage = ifelse(country == "Nepal", paidwage_all, paidwage)) %>% #adjust paidwage for Nepal
      mutate(country = paste(country, "_", educ_cat, sep = ""))
  }
  if(robustness_checks == FALSE){rm(data_hhs)}
}