#########################################################################################/
#Overview####
#title: "2.0_IOp_cross-section_intro"
#author: "Fabian Reutzel"
#########################################################################################/

#########################################################################################/
#1. Survey Overview####
#########################################################################################/
if (restimation == TRUE & outcome_dim == "all"){
  #########################################################################################/
  #1.1 Overview overall####
  #########################################################################################/
  dataset_overview_cs <- data_hhs %>% group_by(country, survey, survey_name, year, survey_coresident) %>% dplyr::summarise(n_all = n()) %>% 
    mutate(coresident = ifelse(survey_coresident == "yes", "", "X")) %>%
    filter(!(survey == "BLFS")) %>% #exclude BLFS as reported in LFS dataset
    mutate(survey = ifelse(survey == "NSS - Employment", "NSS", survey)) #Year of NSS - Employment == Year of NSS - Consumption
  lfs_overview_cs <- data_lfs %>% group_by(country, survey, year) %>% dplyr::summarise(n_all = n()) %>%
    mutate(coresident = "") %>% 
    mutate(survey_name = ifelse(survey == "LFS", "Labor Force Survey", ifelse(survey == "EUS", "Employment and Unemployment Survey", "Periodic Labor Force Survey")))

  #number of surveys used
  nrow(dataset_overview_cs)
  nrow(lfs_overview_cs)

  #number of observations used
  sum(dataset_overview_cs$n_all) + sum(lfs_overview_cs$n_all)

  #survey overview - general
  country_survey <- rbind(
    dataset_overview_cs %>%
      group_by(country, survey, survey_name) %>%
      summarise(n = n(), .groups = "drop") %>%
      select(country, survey, survey_name),
    lfs_overview_cs %>%
      group_by(country, survey, survey_name) %>%
      summarise(n = n(), .groups = "drop") %>%
      select(country, survey, survey_name)
  ) %>% arrange(country, survey)

  country_survey_adj <- rbind(
    dataset_overview_cs %>%
      mutate(year = ifelse(coresident == "X", paste0(year, "*"), as.character(year))),
    lfs_overview_cs %>%
      mutate(year = as.character(year))
  ) %>% arrange(country, survey)

  countries <- country_survey$country
  surveys <- country_survey$survey
  survey_names <- country_survey$survey_name
  years <- character(length(countries))
  for (i in 1:length(countries)) {
    years[i] <- paste(unique(country_survey_adj$year[
      country_survey_adj$country == countries[i] &
      country_survey_adj$survey == surveys[i]
    ]), collapse = ", ")
  }

  survey_overview_raw <- data.frame(countries, surveys, survey_names, years)
  survey_overview <- survey_overview_raw

  #custom sorting order based on country, survey type (HH vs. LF), and survey years
  survey_order <- data.frame(
    countries = c("Afghanistan", "Afghanistan", "Afghanistan",
                  "Bangladesh", "Bangladesh",
                  "Bhutan", "Bhutan",
                  "India", "India", "India", "India", "India",
                  "Nepal", "Nepal", "Nepal",
                  "Pakistan", "Pakistan", "Pakistan",
                  "Sri Lanka", "Sri Lanka"),
    surveys = c("NRVA", "ALCS", "IELFS",
                "HIES", "LFS",
                "BLSS", "LFS",
                "IHDS", "NSS", "HCES", "EUS", "PLFS",
                "NLSS", "NPHC", "LFS",
                "HIES", "PIHS", "PSLM",
                "HIES", "LFS"),
    sort_order = 1:20
  )
  survey_overview <- survey_overview %>%
    left_join(survey_order, by = c("countries", "surveys")) %>%
    arrange(sort_order) %>%
    select(-sort_order) %>%
    mutate(years = ifelse(countries == "Sri Lanka" & surveys == "LFS", "1992-2021 bi-/annual", years)) # limit granularity of info for LKA

  colnames(survey_overview) <- c("Country", "Survey", "Full Survey Name", "Survey Years used in Analysis")
  print(xtable(survey_overview, digits = 0), include.rownames = FALSE, include.colnames = TRUE,
        floating = FALSE, file = paste0(path_tables, "/main/survey_overview.tex"))

  #########################################################################################/
  #1.2 Overview across Outcomes####
  #########################################################################################/
  out <- c("educ", "cons", "lfp", "lfp_lfs", "wage", "wage_lfs")
  #re: lfp == paidwage for survey selection
  survey_overview_outcome <- survey_overview_raw[, -c(3, 4)]
  for (o in 1:length(out)){
    outcome <- sapply(strsplit(out[o], "_"), "[", 1)
    if(out[o] == "educ"){df_raw <- data_hhs %>% filter(is.na(educ)!=1,age>=21,!(survey == "NLSS"&cohort_5<= 8))} #use only NPHC for older cohorts
    if(out[o] == "cons"){df_raw <- data_cons_cs %>% filter(!(country == "Afghanistan" & year!=2017))} #exclude non-used cs
    if(out[o] == "lfp" | out[o] == "wage"){df_raw <- data_hhs_cs %>% filter_at(vars(outcome), all_vars(!is.na(.))) %>% 
      mutate(survey = ifelse(survey == "NSS - Employment", "NSS", survey))} #combine NSSs as Year of NSS - Employment == Year of NSS - Consumption
    if(out[o] == "wage"){df_raw <- df_raw %>% filter(!(country == "Afghanistan" & year != 2020),!(country == "Nepal"))} #exclude non-used cs
    if(out[o] == "lfp_lfs" | out[o] == "wage_lfs"){df_raw <- data_lfs_cs %>% filter_at(vars(outcome), all_vars(!is.na(.)))}
    if(out[o] == "wage_lfs"){df_raw <- df_raw %>% filter(!(country == "Nepal" & year != 2017))} #exclude non-used cs
    df_overview_o <- df_raw %>% group_by(country, survey, year) %>% dplyr::summarise(n_all = n())
    country_survey <- df_overview_o %>%
      group_by(country, survey) %>%
      summarise(n = n(), .groups = "drop") %>%
      select(country, survey)
    country_survey_adj <- df_overview_o %>%
      mutate(year = as.character(year))
    countries <- country_survey$country
    surveys <- country_survey$survey
    years <- character(length(countries))
    for (i in 1:length(countries)) {
      years[i] <- paste(unique(country_survey_adj$year[
        country_survey_adj$country == countries[i] & country_survey_adj$survey == surveys[i]
      ]), collapse = ", ")
      if(countries[i] == "Bangladesh" & out[o] == "lfp_lfs"){ #adjust for differing employment definition BGD 2000
        years[i] <- "2000*, 2005, 2010, 2016, 2022"}
    }
    survey_overview_outcome <- left_join(survey_overview_outcome, as.data.frame(cbind(countries, surveys, years)), by = c("countries", "surveys"))
  }
  survey_overview_outcome <- survey_overview_outcome %>% mutate(years.x.x = coalesce(years.y.y, years.x.x),
                                                                years.x.x.x = coalesce(years.y.y.y, years.x.x.x)) %>% 
    select(-contains("y.y"))

  survey_overview_outcome <- survey_overview_outcome %>%
    left_join(survey_order, by = c("countries", "surveys")) %>%
    arrange(sort_order) %>%
    select(-sort_order)

  addtorow <- list()
  addtorow$pos <- list(0)
  addtorow$command <- c("Country & Survey & Education & Consumption & LFP \\& Wage-Employment & Wages \\\\\n")
  print(xtable(survey_overview_outcome), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow,
        floating = FALSE, file = paste0(path_tables, "/annex/survey_overview_outcome_raw.tex"))
}
#re:brackets and bold formatting to be added manually (see Section A1 for comparability of defintion across survey waves)
#re:Definition comparability visualized in "/annex/lfp_cs_overview.png" and "/annex/gini_pip.png" for reference)

#########################################################################################/
#2. Cross-sectional IOp estimates####
#re: latest available cross-section only to limit runtime
#########################################################################################/
if(restimation == TRUE){
  if(outcome_dim == "all" | outcome_dim == "educ"){
    educ_cs_cs4 <- iop_ex_ante(data_hhs %>% filter(is.na(educ) != 1, age>21), circumstances_cs4, outcome = "educ", estimation, type = "cs", boot_n)
    save(educ_cs_cs4, file = paste0(path_results, "/educ_cs_cs4.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "cons"){
    cons_cs_cs3_all <- iop_ex_ante(data_cons_cs_all, circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cs", boot_n)
    cons_cs_cs3 <- iop_ex_ante(data_cons_cs, circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cs", boot_n)
    save(cons_cs_cs3_all, file = paste0(path_results, "/cons_cs_cs3_all.RData"))
    save(cons_cs_cs3, file = paste0(path_results, "/cons_cs_cs3.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "labor"){
    lfp_cs_cs4 <- iop_ex_ante(data_labor_cs, circumstances_cs4, outcome = "lfp", estimation, type = "cs", boot_n)
    paidwage_cs_cs4 <- iop_ex_ante(data_labor_cs, circumstances_cs4, outcome = "paidwage", estimation, type = "cs", boot_n)
    wage_cs_cs4 <- iop_ex_ante(data_labor_cs, circumstances_cs4, outcome = "wage", estimation, type = "cs", boot_n)
    save(lfp_cs_cs4, file = paste0(path_results, "/lfp_cs_cs4.RData"))
    save(paidwage_cs_cs4, file = paste0(path_results, "/paidwage_cs_cs4.RData"))
    save(wage_cs_cs4, file = paste0(path_results, "/wage_cs_cs4.RData"))
  }
}
#load all results
load(paste0(path_results, "/educ_cs_cs4.RData"))
load(paste0(path_results, "/cons_cs_cs3_all.RData"))
load(paste0(path_results, "/cons_cs_cs3.RData"))
load(paste0(path_results, "/lfp_cs_cs4.RData"))
load(paste0(path_results, "/paidwage_cs_cs4.RData"))
load(paste0(path_results, "/wage_cs_cs4.RData"))

educ_cons_labor_cs_last <- educ_cs_cs4 %>% group_by(country) %>% filter(year == max(year)) %>% select(country, gini_p, rel_iop_p) %>% dplyr::rename(gini_educ = gini_p, iop_educ = rel_iop_p) %>%
  left_join(cons_cs_cs3 %>% group_by(country) %>% filter(year == max(year)) %>% select(country, gini_p, rel_iop_p) %>% dplyr::rename(gini_hh_cons = gini_p, iop_hh_cons = rel_iop_p), by = c("country")) %>% 
  left_join(lfp_cs_cs4 %>% group_by(country) %>% filter(year == max(year)) %>% select(country, share_p, abs_iop_p) %>% dplyr::rename(share_lfp = share_p, iop_lfp = abs_iop_p), by = c("country")) %>%
  left_join(paidwage_cs_cs4 %>% group_by(country) %>% filter(year == max(year)) %>% select(country, share_p, abs_iop_p) %>% dplyr::rename(share_paidwage = share_p, iop_paidwage = abs_iop_p), by = c("country")) %>%
  left_join(wage_cs_cs4 %>% group_by(country) %>% filter(year == max(year)) %>% select(country, gini_p, rel_iop_p) %>% dplyr::rename(gini_wage = gini_p, iop_wage = rel_iop_p), by = c("country"))

addtorow <- list()
addtorow$pos <- list(0, 0)
addtorow$command <- c("&  \\multicolumn{2}{c}{Education} & \\multicolumn{2}{c}{Consumption} & \\multicolumn{2}{c}{LFP} & \\multicolumn{2}{c}{Wage Emp.} & \\multicolumn{2}{c}{Wages}\\\\\n",
                      " \\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9} \\cmidrule(lr){10-11} Country & Gini & IOp & Gini & IOp & Share & IOp & Share & IOp & Gini & IOp \\\\\n")
print(xtable(educ_cons_labor_cs_last), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow,
      floating = FALSE, auto = TRUE, file = paste0(path_tables, "/main/educ_cons_labor_cs_last.tex"))

##########################################################################################/
##3. IOp SAR vs World####
##########################################################################################/
#country to region mapping WB
cont_wb <- read.csv(paste0(path_data, "/raw/auxiliary/WB_region_mapping.csv"))
cont_wb <- cont_wb %>% mutate(sar = ifelse((country == "Afghanistan" | country == "Bangladesh" | country == "Bhutan" | country == "India" | country == "Nepal" | country == "Pakistan" | country == "Sri Lanka"), 1, 0))

#population
#source: https://data.worldbank.org/indicator/SP.POP.TOTL
pop <- read.csv(paste0(path_data, "/raw/auxiliary/population.csv"), skip = 3, header = TRUE, stringsAsFactors = FALSE) %>%
  dplyr::rename(country = Country.Name, code = Country.Code) %>%
  pivot_longer(cols = starts_with("X"), names_to = "year", values_to = "pop") %>%
  mutate(year = as.numeric(gsub("X", "", year))) %>%
  select(country, year, pop)

pop_cont_wb <- inner_join(pop, cont_wb, by = "country")

#HH cons IOp with gender as circ in line with external estimates
load(paste0(path_results, "/cons_cs_cs3.RData"))
iop_sar <- cons_cs_cs3 %>%
  group_by(country) %>% filter(year == max(year))

#GEOM IOp
iop_geom <- read.csv(paste0(path_data, "/raw/auxiliary/GEOM.csv"), sep = ";")
iop_geom <- iop_geom %>% group_by(country) %>% filter(year == max(year)) %>%
  mutate(country = ifelse(country == "South Korea", "Korea, Rep.",
                    ifelse(country == "Gambia", "Gambia, The",
                      ifelse(country == "Guinea Bissau", "Guinea-Bissau",
                        ifelse(country == "Kyrgyzstan", "Kyrgyz Republic",
                          ifelse(country == "Ivory Coast", "Cote d'Ivoire",
                            ifelse(country == "Timor Leste", "Timor-Leste",
                              ifelse(country == "Czech Rep.", "Czech Republic",
                                ifelse(country == "Slovakia", "Slovak Republic",
                                  ifelse(country == "USA", "United States", country)))))))))) %>%
  mutate(measure = substr(year, 5, nchar(year)),
         year = as.numeric(substr(year, 1, 4)),
         rel_iop_p = rel_iop / 100,
         gini_p = gini) %>%
  select(country, rel_iop_p, gini_p, year)

iop_world_geom <- rbind(
  iop_sar %>%
    mutate(year = ifelse(year == 2022, 2021, year)) %>%
    select(country, rel_iop_p, gini_p, year) %>%
    left_join(pop_cont_wb, by = c("country", "year")),
  iop_geom %>% left_join(pop_cont_wb, by = c("country", "year"))) %>%
  mutate(cont_wb_code = ifelse(code == "USA", "NA", cont_wb_code))

##region averages
#simple average
region_agg_geom <- iop_world_geom %>% group_by(cont_wb_code) %>%
  summarise(geom_iop = mean(rel_iop_p), geom_gini = mean(gini_p))
#population-weighted
region_agg_geom_pop <- iop_world_geom %>% group_by(cont_wb_code) %>%
  mutate(pop_share = pop / sum(pop)) %>%
  summarise(geom_iop = weighted.mean(rel_iop_p, pop_share), geom_gini = weighted.mean(gini_p, pop_share))

#set color scheme
cont_color <- c("EAP" = "#F8766D", "ECA" = "#C49A00", "LAC" = "#53B400",
                "NA" = "#00C094", "MENA" = "#00B6EB", "SSA" = "#A58AFF", "SAR" = "#FB61D7")

#Great Gatsby - GEOM
ggplot(iop_world_geom %>% mutate(sar = ifelse(country %in% c("India", "Nepal") & year<2021, 0, sar)), aes(x = gini_p, y = rel_iop_p)) +
  geom_point(aes(color = cont_wb_code)) +
  geom_smooth(method = "lm", se = FALSE, color = "black", aes(weight = pop)) +
  geom_text(aes(label = code, alpha = as.factor(sar)), vjust = 1, hjust = c("middle")) +
  scale_alpha_manual(values = c("0" = 0.3, "1" = 1), guide = 'none') +
  scale_color_manual("",
         values = cont_color,
         labels = c("LAC" = "Latin America & Caribbean (LAC)", "SAR" = "South Asia (SAR)",
            "SSA" = "Sub-Saharan Africa (SSA)", "ECA" = "Europe & Central Asia (ECA)",
            "MENA" = "Middle East & North Africa (MENA)", "EAP" = "East Asia & Pacific (EAP)",
            "NA" = "North America (NA)")) +
  labs(x = "Total Inequality (Gini)", y = "Relative IOp") +
  theme(axis.line = element_line(color = "black"),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 9),
    legend.key = element_rect(fill = NA, colour = NA),
    panel.background = element_blank()) +
  guides(color = guide_legend(nrow = 2))
ggsave(paste0(path_figures, "/main/gini_iop_world.png"), width = 8, height = 6)

##########################################################################################/
##5.1 Intro: Regional Ginis (PIP data)####
#re: not displayed in the paper, but cited in section 1
##########################################################################################/
pip <- read.csv(paste0(path_data, "/raw/auxiliary/pip_20250930_2017_01_02_PROD.csv"))
pip_2020 <- pip %>%
  group_by(country_code) %>% filter(reporting_year == max(reporting_year)) %>% ungroup() %>%
  group_by(region_code, region_name) %>% summarise(cont_gini = mean(gini)) %>%
  select(region_name, region_code, cont_gini) %>%
  arrange(desc(cont_gini))
colnames(pip_2020) <- c("Region", "Code", "Gini")
print(xtable(pip_2020), include.rownames = FALSE, include.colnames = TRUE,
      floating = FALSE, auto = TRUE, file = paste0(path_tables, "/annex/gini_regions.tex"))

##########################################################################################/
##5.2 Appendix: Cross-section Gini comparison (PIP data)####
##########################################################################################/
pip_old <- read.csv(paste0(path_data, "/raw/auxiliary/pip_20240627_2017_01_02_PROD.csv"))
pip_new <- read.csv(paste0(path_data, "/raw/auxiliary/pip_20250930_2017_01_02_PROD.csv"))
pip <- rbind(pip_old %>% filter(country_name == "India"&reporting_year<2012), # keep old India estimates up to 2011 for methodological consistency
             pip_new %>% filter(!(country_name == "India"&reporting_year <= 2011)))
countries <- unique(cons_cs_cs3$country)
min_year <- min(cons_cs_cs3$year)
gini_pip <- rbind(
  pip %>% filter(country_name %in% countries) %>% filter(reporting_level == "national") %>%
    dplyr::rename(country = country_name, gini_p = gini, year = reporting_year)%>%
    select(country, year, gini_p) %>% mutate(source = 1),
  cons_cs_cs3 %>% select(country, year, gini_p) %>% mutate(source = 3),
  cons_cs_cs3_all %>% select(country, year, gini_p) %>% mutate(source = 2)
  ) %>%
  filter(year >= min_year) %>%
  mutate(non_comparable = ifelse(
    (country == "Afghanistan"&year == 2017) | (country == "Bangladesh"&year == 2022) | (country == "Bhutan"&(year == 2003 | year == 2022)) | (country == "India"& year == 2022) | (country == "Nepal"&(year == 2010 | year == 2022)) | (country == "Pakistan"&year == 2022), 
     1, 0)) %>%
  mutate(source = factor(source, labels = c("PIP Estimate", "Household Survey (0-99)", "Household Survey (>18)")))

ggplot(gini_pip,
       aes(x = year, y = gini_p, color = source)) +
  geom_point(data = gini_pip %>% filter(source == "PIP Estimate")) +
  geom_point(data = gini_pip %>% filter(source != "PIP Estimate"), alpha = 0.2) +
  geom_line(data = gini_pip %>% filter(non_comparable == 0)) +
  geom_text(data = .  %>% filter(non_comparable == 0) %>% group_by(country, source) %>% filter(year == max(year)), aes(label = round(gini_p, 2)), vjust = 1, hjust = 0, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  geom_text(data = .  %>% filter(non_comparable == 0) %>% group_by(country, source) %>% filter(year == min(year)), aes(label = round(gini_p, 2)), vjust = 1, hjust = 0, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  facet_wrap(~country) +
  ylab("Gini Estimate ") + labs(color = "Data Source") +
  scale_x_continuous(name = "Survey Year") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/gini_pip.png"), width = 8, height = 6)