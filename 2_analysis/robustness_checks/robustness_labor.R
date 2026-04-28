#########################################################################################/
# Overview####
#title: "robustness_labor.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. LFP - consistency across survey waves & surveys & alignment with ILO####
#########################################################################################/
#reload data
outcome_type = "cs"
source(paste0(path_code, "/2_analysis/2.0_data_import.R"))
outcome_type = "cohort"

#Household surveys (HHS)
data_lfp_hhs <- data_hhs %>%
  filter(sample_iop_labor == 1) %>% #sample restriction
  filter(age >= 15 & age <= 64) %>% #age restriction
  mutate(empstat = ifelse(country == "Sri Lanka" & year == 2002, NA, empstat)) %>% #non-fully comparable question
  mutate(wt_hh = 1) %>%   #disregard weights
  mutate(lfp = ifelse(is.na(lstatus) != 1, ifelse(lstatus != 3, 1, 0), NA))

#Labor force surveys (LFS)
data_lfp_lfs <- data_lfs %>%
  filter(age >= 15 & age <= 64) %>% #age restriction
  mutate_at(vars(female, urban, demo, geo_level_1), ~factor(.)) %>%
  filter(!(cohort_5 == 7 & country == "Sri Lanka")) %>% #small sample size
  mutate(wt_hh = 1) %>% #disregard weights
  mutate(lfp = ifelse(is.na(lstatus) != 1, ifelse(lstatus != 3, 1, 0), NA))

summary_lfp_hhs <- data_lfp_hhs %>%
  filter(is.na(lfp) != 1) %>%
  group_by(country, year, lfp) %>%
  summarise(count = n()) %>%
  group_by(country, year) %>%
  mutate(share = count / sum(count), n_obs = sum(count)) %>%
  ungroup()

summary_lfp_lfs <- data_lfp_lfs %>%
  filter(is.na(lfp) != 1) %>%
  group_by(country, year, lfp) %>%
  summarise(count = n()) %>%
  group_by(country, year) %>%
  mutate(share = count / sum(count), n_obs = sum(count)) %>%
  ungroup()

#ILO estimates (model based) "WDI - SL.TLF.ACTI.ZS"
summary_lfp_ilo <- read_csv(paste0(path_data, "/raw/auxiliary/ILO_lfp_model.csv"), skip = 3) %>%
  pivot_longer(cols = matches("^(19|2).*"), names_to = "year", values_to = "share") %>%
  dplyr::rename(country = "Country Name") %>%
  select(country, year, share) %>%
  right_join(summary_lfp_hhs%>%select(country), by = c("country"))

#ILO estimates (survey based) "original file name EAP_DWAP_SEX_AGE_RT_A-20260122T0941.csv"
summary_lfp_ilo_lfs <- read_csv(paste0(path_data, "/raw/auxiliary/ILO_lfp_lfs.csv")) %>%
  filter(sex.label == "Sex: Total" & classif1.label == "Age (Youth, adults): 15-64") %>%
  dplyr::rename(country = "ref_area.label", year = "time", share = "obs_value") %>%
  select(country, year, share) %>%
  right_join(summary_lfp_hhs %>% select(country), by = c("country"))

summary_lfp <- rbind(summary_lfp_hhs %>% mutate(source = 1) %>% filter(lfp == 1) %>% select(country, year, share, source),
                     summary_lfp_lfs %>% mutate(source = 2) %>% filter(lfp == 1) %>% select(country, year, share, source) %>% filter(country != "Pakistan"),
                     summary_lfp_ilo %>% mutate(source = 3) %>% distinct() %>% mutate(share = share/100),
                     summary_lfp_ilo_lfs %>% mutate(source = 4) %>% distinct() %>% mutate(share = share/100)) %>%
  group_by(country) %>% filter(year  >=  min(year[source %in% c(1, 2)])) %>% ungroup() %>%
  mutate(source = factor(source, labels = c("1" = "Household Survey", "2" = "Labor Force Survey (LFS)", "3" = "ILO - Model", "4" = "ILO - LFS"))) %>% 
  mutate(year = as.numeric(year)) %>%
  mutate(non_comparable = ifelse(
    (year == 2008&country == "Afghanistan")|((year == 2020|year == 2007)&country == "Bhutan")|(country == "Bangladesh"&year == 2022)|(country == "Nepal"&(year == 2017))|(country == "Pakistan"&(year == 2013|year == 2022)), 
    1, 0))

ggplot(summary_lfp,
       aes(x = year, y = share, color = source)) +
  geom_point() +
  geom_line(data = summary_lfp %>% filter(non_comparable == 0)) +
  geom_text(data = . %>% filter(non_comparable == 0) %>% group_by(country, source) %>% filter(year == max(year)), aes(label = round(share, 2)), vjust = 0, hjust = 0.5, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  geom_text(data = . %>% filter(non_comparable == 0) %>% group_by(country, source) %>% filter(year == min(year)), aes(label = round(share, 2)), vjust = 0, hjust = 0.5, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  facet_wrap(~country) +
  ylab("Labor Force Participation") + labs(color = "Data Source") +
  scale_colour_manual(name = "", values = c("Household Survey" = "brown", "Labor Force Survey (LFS)" = "violet", "ILO - Model" = "blue", "ILO - LFS" = "lightblue")) +
  #scale_linetype_manual("", values = c("HHS" = "solid", "LFS" = "dashed", "ILO" = "dotted")) +
  scale_x_continuous(name = "Survey Year") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        axis.line = element_line(color = "black"), 
        legend.position = c(.8, .1), 
        legend.title = element_blank(),
        legend.text = element_text(size = 11), 
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/lfp_cs_overview.png"), width = 8, height = 6)

#########################################################################################/
#2. Profiles: Labor Force vs Household Survey Cross-sections #####
#re: limit circumstances (i.e., exclude geo_level_1) for visual comparability
#########################################################################################/
if(restimation == TRUE){
  cs_profiles_lfp_cs4           <- profiles(data_hhs_cs %>% filter(country == "Bangladesh"|country == "India"|country == "Sri Lanka"), circumstances_cs4[-c(1, 5)], outcome = "lfp", estimation = "para", type = "cs", boot_n)
  cs_profiles_paidwage_cs4      <- profiles(data_hhs_cs %>% filter(country == "Bangladesh"|country == "India"|country == "Sri Lanka"), circumstances_cs4[-c(1, 5)], outcome = "paidwage", estimation = "para", type = "cs", boot_n)
  cs_profiles_lfp_cs4_lfs       <- profiles(data_lfs_cs %>% filter(country == "Bangladesh"|country == "India"|country == "Sri Lanka"), circumstances_cs4[-c(1, 5)], outcome = "lfp", estimation = "para", type = "cs", boot_n)
  cs_profiles_paidwage_cs4_lfs  <- profiles(data_lfs_cs %>% filter(country == "Bangladesh"|country == "India"|country == "Sri Lanka"), circumstances_cs4[-c(1, 5)], outcome = "paidwage", estimation = "para", type = "cs", boot_n)
  save(cs_profiles_lfp_cs4, file = paste0(path_results, "/cs_profiles_lfp_cs4.RData"))
  save(cs_profiles_paidwage_cs4, file = paste0(path_results, "/cs_profiles_paidwage_cs4.RData"))
  save(cs_profiles_lfp_cs4_lfs, file = paste0(path_results, "/cs_profiles_lfp_cs4_lfs.RData"))
  save(cs_profiles_paidwage_cs4_lfs, file = paste0(path_results, "/cs_profiles_paidwage_cs4_lfs.RData"))
} else {
  load(paste0(path_results, "/cs_profiles_lfp_cs4.RData"))
  load(paste0(path_results, "/cs_profiles_paidwage_cs4.RData"))
  load(paste0(path_results, "/cs_profiles_lfp_cs4_lfs.RData"))
  load(paste0(path_results, "/cs_profiles_paidwage_cs4_lfs.RData"))
}

prof_paidwage_lfp_hhs <- rbind(
  cs_profiles_paidwage_cs4 %>% mutate(outcome = "Wage-Employment"),
  cs_profiles_lfp_cs4 %>% mutate(outcome = "LFP")
) %>% mutate(source = "Household Survey")

prof_paidwage_lfp_lfs <- rbind(
  cs_profiles_paidwage_cs4_lfs %>% mutate(outcome = "Wage-Employment"),
  cs_profiles_lfp_cs4_lfs %>% mutate(outcome = "LFP")
) %>% mutate(source = "Labor Force Survey")

n_min = 30
prof_0_lfp_id <- cs_profiles_lfp_cs4_lfs %>%
  group_by(country) %>%
  filter(year == min(year)) %>%
  filter(N >= n_min&is.na(y_hat_p) != 1) %>%  #apply restriction for min group size
  arrange(country, y_hat_p) %>%
  mutate(type_id = row_number()) %>%
  mutate(type_id_lfp = ((type_id-1)/max(type_id-1)*100)) %>%
  select(country, type_id_lfp, female, demo, urban)

prof_0_paidwage_id <- cs_profiles_paidwage_cs4_lfs %>%
  group_by(country) %>%
  filter(year == min(year)) %>%
  filter(N >= n_min&is.na(y_hat_p) != 1) %>%  #apply restriction for min group size
  arrange(country, y_hat_p) %>% 
  mutate(type_id = row_number()) %>%
  mutate(type_id_paidwage = ((type_id-1)/max(type_id-1)*100)) %>%
  select(country, type_id_paidwage, female, demo, urban)

prof_paidwage_lfp_hhs_lfs <- rbind(prof_paidwage_lfp_hhs, prof_paidwage_lfp_lfs) %>%
  left_join(prof_0_lfp_id, by = c("country", "female", "demo", "urban")) %>%
  left_join(prof_0_paidwage_id, by = c("country", "female", "demo", "urban")) %>%
  mutate(female_urban = factor(
    paste(female, urban, sep = "_"),
    levels = c("1_0", "1_1", "0_0", "0_1"),
    labels = c("♀-Rural", "♀-Urban", "♂-Rural", "♂-Urban")
  ))

##join years
prof_1 <- prof_paidwage_lfp_hhs_lfs %>% filter((country == "Bangladesh"&(year == 2016))|(country == "India"&year == 2011)|(country == "Sri Lanka"&(year == 2015|year == 2016)))
prof_0 <- prof_paidwage_lfp_hhs_lfs %>% filter((country == "Bangladesh"&(year == 2005))|(country == "India"&year == 1993)|(country == "Sri Lanka"&(year == 1995))) 
prof_01 <- prof_1 %>% left_join(prof_0, by = c("country", "type", "source", "outcome", "female_urban", "female", "urban")) %>%
  #apply restriction for min group size
  filter(N.y >= n_min&N.x >= n_min&is.na(y_hat_p.y) != 1&is.na(y_hat_p.x) != 1) %>%
  dplyr::rename(type_id_lfp = type_id_lfp.x) %>%
  #calculate growth rate & change
  mutate(change_y_hat_p = y_hat_p.x-y_hat_p.y, change_y_hat_u = y_hat_u.x-y_hat_u.y, change_y_hat_l = y_hat_l.x-y_hat_l.y, 
         growth_y_hat_p = (change_y_hat_p/y_hat_p.y)*100, growth_y_hat_u = (change_y_hat_u/y_hat_u.y)*100, growth_y_hat_l = (change_y_hat_l/y_hat_l.y)*100) %>%
  #keep only groups present in both years
  filter(is.na(change_y_hat_p) != 1)

mean_share <- prof_1 %>% group_by(country, source, outcome, female) %>% summarise(mean_share = sum(y_hat_p*N)/sum(N))

ggplot(prof_1 %>% filter(outcome == "LFP"), 
       aes(x = type_id_lfp, y = y_hat_p, color = source, shape = female_urban, group = country, weight = N)) +
  geom_point(size = 3) +
  geom_smooth(aes(color = source, group = paste0(source, female)), method = "loess", se = FALSE) +
  ylab("Type-Average LFP (2010s)") + xlab("Opportunity Groups") +
  scale_shape_manual(values = c(0, 15, 1, 16)) +
  scale_color_manual(values = c("brown", "violet"), name = "Source") +
  scale_linetype_manual(values = c("solid", "dashed")) +
  facet_wrap(~country) +
  theme(axis.line = element_line(color = "black"),
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank()) +
  guides(linetype = guide_legend(override.aes = list(color = "black")))
ggsave(paste0(path_figures, "/annex/prof_lfp_cs_last.png"), width = 8, height = 6)

ggplot(prof_1 %>% filter(outcome == "Wage-Employment"),
       aes(x = type_id_paidwage, y = y_hat_p, color = source, shape = female_urban, group = country, weight = N)) + 
  geom_point(size = 3) +
  geom_smooth(aes(color = source, group = paste0(source, female)), method = "loess", se = FALSE) +
  ylab("Type-Average Wage-Employment Share (2010s)") + xlab("Opportunity Groups") +
  scale_shape_manual(values = c(0, 15, 1, 16)) + 
  scale_color_manual(values = c("brown", "violet"), name = "Source") +
  scale_linetype_manual(values = c("solid", "dashed")) +
  facet_wrap(~country) +
  theme(axis.line = element_line(color = "black"),
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank()) +
  guides(linetype = guide_legend(override.aes = list(color = "black")))
ggsave(paste0(path_figures, "/annex/prof_paidwage_cs_last.png"), width = 8, height = 6)