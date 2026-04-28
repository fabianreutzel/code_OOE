#########################################################################################/
# Overview####
#title: "robustness_forest"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
# 1. Forest IOp estimation by outcome####
#########################################################################################/
estimation = "forest"
if(restimation == TRUE & outcome_type == "cohort"){
  if(outcome_dim == "all" | outcome_dim == "educ"){
    educ_cs4_forest <- iop_ex_ante(data_educ, circumstances_cs4, outcome = "educ", estimation, type = "cohort_5", boot_n)
    save(educ_cs4_forest, file = paste0(path_results, "/educ_cs4_forest.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "cons"){
    cons_cs3_forest <- iop_ex_ante(data_cons, circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cohort_5", boot_n)
    save(cons_cs3_forest, file = paste0(path_results, "/cons_cs3_forest.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "labor"){
    lfp_cs4_forest <- iop_ex_ante(data_labor, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    save(lfp_cs4_forest, file = paste0(path_results, "/lfp_cs4_forest.RData"))
  }
}else{
  load(paste0(path_results, "/educ_cs4_forest.RData"))
  load(paste0(path_results, "/cons_cs3_forest.RData"))
  load(paste0(path_results, "/lfp_cs4_forest.RData"))
}
#########################################################################################/
#1.2 Parametric vs. Forest ####
#########################################################################################/
load(paste0(path_results, "/educ_cs4.RData"))
load(paste0(path_results, "/lfp_cs4.RData"))
load(paste0(path_results, "/cons_cs3.RData"))
load(paste0(path_results, "/rescale_india.RData"))

para_forest <- rbind(
  educ_cs4 %>% dplyr::select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>%
    mutate(estimation = 1, outcome = 1),
  educ_cs4_forest %>% dplyr::select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>%
    mutate(estimation = 2, outcome = 1),
  cons_cs3 %>% dplyr::select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>%
    mutate(rel_iop_p = ifelse(country == "India" & year >= 5, rel_iop_p*rescale_india$rescale_rel_iop_last, rel_iop_p),
          rel_iop_l = ifelse(country == "India" & year >= 5, rel_iop_l*rescale_india$rescale_rel_iop_last, rel_iop_l),
          rel_iop_u = ifelse(country == "India" & year >= 5, rel_iop_u*rescale_india$rescale_rel_iop_last, rel_iop_u)) %>%
    mutate(estimation = 1, outcome = 2),
  cons_cs3_forest %>% dplyr::select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>%
    mutate(rel_iop_p = ifelse(country == "India" & year >= 5, rel_iop_p*rescale_india$rescale_rel_iop_last, rel_iop_p),
          rel_iop_l = ifelse(country == "India" & year >= 5, rel_iop_l*rescale_india$rescale_rel_iop_last, rel_iop_l),
          rel_iop_u = ifelse(country == "India" & year >= 5, rel_iop_u*rescale_india$rescale_rel_iop_last, rel_iop_u)) %>%
    filter(country != "Nepal") %>% 
    mutate(rel_iop_u = NA, rel_iop_l = NA, estimation = 2, outcome = 2),
  lfp_cs4 %>%  select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>%
        rename_with(~paste0("rel", substr(., 4, nchar(.))), starts_with("abs")) %>% mutate(estimation = 1, outcome = 3),
  lfp_cs4_forest %>%  select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>%
    rename_with(~paste0("rel", substr(., 4, nchar(.))), starts_with("abs")) %>% mutate(estimation = 2, outcome = 3)
  ) %>%
  mutate(estimation = factor(estimation, labels = c("1" = "Parametric", "2" = "Forest"))) %>%
  mutate(outcome = factor(outcome, labels = c("1" = "Education", "2" = "Consumption", "3" = "LFP"))) %>%
  group_by(country, estimation, outcome) %>%
  mutate(rel_iop_p_0 = ifelse(year == min(year), rel_iop_p, 0), rel_iop_p_0 = max(rel_iop_p_0), rel_iop_p = (rel_iop_p/rel_iop_p_0)*100) %>%
  mutate(rel_iop_u = (rel_iop_u/rel_iop_p_0)*100, rel_iop_l = (rel_iop_l/rel_iop_p_0)*100)

ggplot(para_forest,
      aes(x = year, y = rel_iop_p, linetype = estimation, shape = estimation, color = outcome)) +
  geom_point() +
  geom_line() +
  geom_text(data = . %>% filter(year == max(year), estimation == "Parametric"), aes(label = round(rel_iop_p, 0)), vjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  geom_text(data = . %>% filter(year == max(year), estimation == "Forest"), aes(label = round(rel_iop_p, 0)), vjust = -1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  facet_wrap(~country) +
  ylab("% Change in Relative IOp") +
  scale_y_continuous(limits = c(25, 125)) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  scale_linetype_discrete("") +
  scale_color_manual("", values = c("Education" = "blue", "Consumption" = "red", "LFP" = "violet")) +
  scale_shape_discrete("") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/comp_para_forest.png"), width = 8, height = 6)