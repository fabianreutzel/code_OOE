#########################################################################################/
# Overview####
#title: "robustness_education.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Assortative mating ####
#########################################################################################/
if(restimation == TRUE){
  gap_educ_age <- data_educ %>%
    filter(age >= 35&age <= 54) %>%
    filter(hh_rel == 0|hh_rel == 1) %>%
    group_by(country, year,  hh_id) %>%
    summarise(min_educ_hh  =  min(educ),
              max_educ_hh  =  max(educ),
              n_hh = n()) %>%
    filter(n_hh >= 2 & n_hh < 3) %>%
    ungroup() 
  gap_educ_age_raw <-right_join(data_educ %>%
                                  filter(age >= 35 & age <= 54) %>%
                                  filter(hh_rel == 0 | hh_rel == 1),
                                gap_educ_age)
  gap_educ_age_all <- gap_educ_age_raw %>%
    group_by(country,  cohort_5) %>%
    filter(is.na(min_educ_hh) != 1,  is.na(max_educ_hh) != 1) %>%
    summarise(corr_educ = cor(max_educ_hh, min_educ_hh, use = "complete.obs",  method = "spearman"),
              corr_educ_p = cor(max_educ_hh, min_educ_hh, use = "complete.obs",  method = "pearson"),
              n_obs = n())
  save(gap_educ_age_all, file = paste0(path_results, "/gap_educ_age_all.RData"))
} else {
   load(paste0(path_results, "/gap_educ_age_all.RData"))
}

ggplot(gap_educ_age_all,
       aes(x = cohort_5, y = corr_educ, color = country)) +
  geom_point() +
  geom_line() +
  geom_text(data = . %>% filter(cohort_5 == max(cohort_5)), aes(label = round(corr_educ, 2)), vjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  geom_text(data = . %>% filter(cohort_5 == min(cohort_5)), aes(label = round(corr_educ, 2)), vjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  facet_wrap(~country) +
  ylab("Rank Correlation between Years of Education HH Head and Spouse") +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  scale_color_discrete("", guide = "none") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line  =  element_line(color  =  "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text  =  element_text(size  =  11),
        panel.background  =  element_blank())
ggsave(paste0(path_figures, "/annex/corr_educ.png"), width = 8, height = 6)