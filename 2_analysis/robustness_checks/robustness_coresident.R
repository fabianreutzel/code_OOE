#########################################################################################/
# Overview####
#title: "robustness_coresident"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Coresident analysis####
#########################################################################################/
if (restimation == TRUE){
  educ_full_cores_cs4 <- iop_ex_ante(data_hhs, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_age_cs4 <- iop_ex_ante(data_educ_age, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_cores_cs4 <- iop_ex_ante(data_educ_cores, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_iop_cs4 <- iop_ex_ante(data_educ_iop, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_perf_cs4 <- iop_ex_ante(data_educ_perf, circumstances = circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores_perf", boot_n)
  educ_age_co4 <- iop_ex_ante(data_educ_age, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_cores_co4 <- iop_ex_ante(data_educ_cores, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_iop_co4 <- iop_ex_ante(data_educ_iop, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_perf_co4 <- iop_ex_ante(data_educ_perf, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores_perf", boot_n)
  educ_perf_age_cs4 <- iop_ex_ante(data_educ_perf_age, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores_perf", boot_n)
  educ_perf_age_co4 <- iop_ex_ante(data_educ_perf_age, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores_perf", boot_n)
  educ_iop_ptrunc_cs4 <- iop_ex_ante(data_educ_iop_ptrunc, circumstances_cs4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)
  educ_iop_ptrunc_co4 <- iop_ex_ante(data_educ_iop_ptrunc, circumstances_co4, outcome = "educ", estimation, type = "cohort_cores", boot_n, cohort_cores)

  save(educ_full_cores_cs4, file = paste0(path_results, "/educ_full_cores_cs4.RData")) 
  save(educ_age_cs4, file = paste0(path_results, "/educ_age_cs4.RData"))
  save(educ_cores_cs4, file = paste0(path_results, "/educ_cores_cs4.RData"))
  save(educ_iop_cs4, file = paste0(path_results, "/educ_iop_cs4.RData"))
  save(educ_perf_cs4, file = paste0(path_results, "/educ_perf_cs4.RData"))
  save(educ_age_co4, file = paste0(path_results, "/educ_age_co4.RData"))
  save(educ_cores_co4, file = paste0(path_results, "/educ_cores_co4.RData"))
  save(educ_iop_co4, file = paste0(path_results, "/educ_iop_co4.RData"))
  save(educ_perf_co4, file = paste0(path_results, "/educ_perf_co4.RData"))
  save(educ_perf_age_cs4, file = paste0(path_results, "/educ_perf_age_cs4.RData"))
  save(educ_perf_age_co4, file = paste0(path_results, "/educ_perf_age_co4.RData"))
  save(educ_iop_ptrunc_cs4, file = paste0(path_results, "/educ_iop_ptrunc_cs4.RData"))
  save(educ_iop_ptrunc_co4, file = paste0(path_results, "/educ_iop_ptrunc_co4.RData"))
}
load(paste0(path_results, "/educ_full_cores_cs4.RData"))
load(paste0(path_results, "/educ_age_cs4.RData"))
load(paste0(path_results, "/educ_cores_cs4.RData"))
load(paste0(path_results, "/educ_iop_cs4.RData"))
load(paste0(path_results, "/educ_perf_cs4.RData"))
load(paste0(path_results, "/educ_age_co4.RData"))
load(paste0(path_results, "/educ_cores_co4.RData"))
load(paste0(path_results, "/educ_iop_co4.RData"))
load(paste0(path_results, "/educ_perf_co4.RData"))
load(paste0(path_results, "/educ_perf_age_cs4.RData"))
load(paste0(path_results, "/educ_perf_age_co4.RData"))
load(paste0(path_results, "/educ_iop_ptrunc_cs4.RData"))
load(paste0(path_results, "/educ_iop_ptrunc_co4.RData"))

#########################################################################################/
#2. Co-residence Bias  ####
#########################################################################################/
#input
d_full_cs <- educ_full_cores_cs4
d_age_cs <- educ_age_cs4
d_iop_cs <- educ_iop_cs4
d_iop_co <- educ_iop_co4
d_perf_cs <- educ_perf_cs4
d_perf_co <- educ_perf_co4
d_perf_age_cs <- educ_perf_age_cs4
d_perf_age_co <- educ_perf_age_co4

#change Gini IOp for restricting to coresident
full_cores_r <- left_join(d_full_cs, d_iop_cs, by = "country_year")
full_cores_gini <- (full_cores_r$gini_p.y - full_cores_r$gini_p.x) / full_cores_r$gini_p.x
full_cores_iop <- (full_cores_r$rel_iop_p.y - full_cores_r$rel_iop_p.x) / full_cores_r$rel_iop_p.x
full_cores <- cbind.data.frame(country_year = full_cores_r$country_year, full_cores_gini, full_cores_iop)

#change Gini for restricting age
full_age_r <- left_join(d_full_cs, d_age_cs, by = "country_year")
full_age_gini <- (full_age_r$gini_p.y - full_age_r$gini_p.x) / full_age_r$gini_p.x
full_age <- cbind.data.frame(country_year = full_age_r$country_year, full_age_gini)

#change Gini age vs. coresident
cores_age_r <- left_join(d_age_cs, d_iop_cs, by = "country_year")
cores_age_p <- (cores_age_r$gini_p.y - cores_age_r$gini_p.x) / cores_age_r$gini_p.x
cores_age <- cbind.data.frame(country_year = cores_age_r$country_year, cores_age_p)

#change IOp for inclusion of parents_educ (coresident sample)
cores_parent_r <- left_join(d_iop_cs, d_iop_co, by = "country_year")
cores_parent_p <- (cores_parent_r$rel_iop_p.y - cores_parent_r$rel_iop_p.x) / cores_parent_r$rel_iop_p.x
cores_parent <- cbind.data.frame(country_year = cores_parent_r$country_year, cores_parent_p)

#change IOp for inclusion of parents_educ (full-cores)
naive_r <- left_join(d_full_cs, d_iop_co, by = "country_year")
naive_p <- (naive_r$rel_iop_p.y - naive_r$rel_iop_p.x) / naive_r$rel_iop_p.x
naive <- cbind.data.frame(country_year = naive_r$country_year, naive_p)

#bias IOp (difference IOp co-res vs. full sample for good data countries IOp with parental background)
bias_r <- left_join(d_perf_cs, d_perf_co, by = "country_year")
bias_p <- (bias_r$rel_iop_p.y - bias_r$rel_iop_p.x) / bias_r$rel_iop_p.x
bias <- cbind.data.frame(country_year = bias_r$country_year, bias_p)
bias_age_r <- left_join(d_perf_age_cs, d_perf_age_co, by = "country_year")
bias_age_p <- (bias_age_r$rel_iop_p.y - bias_age_r$rel_iop_p.x) / bias_age_r$rel_iop_p.x
bias_age <- cbind.data.frame(country_year = bias_age_r$country_year, bias_age_p)

tab_distortion <- left_join(full_cores[, -3], full_age, by = "country_year") %>% 
  left_join(cores_age, by = "country_year") %>%
  left_join(full_cores[, -2], by = "country_year") %>% left_join(naive, by = "country_year") %>% 
  left_join(cores_parent, by = "country_year") %>% left_join(bias_age, by = "country_year") %>%
  left_join(bias, by = "country_year") %>%
  left_join(d_full_cs[, c(1, 2, 3)], by = "country_year") %>% filter(is.na(full_cores_gini) != 1) %>%
  select(-c("country", "year"))
tab_distortion <- cbind(tab_distortion[, 1], round((tab_distortion[, -1]*100), 1))
addtorow <- list()
addtorow$pos <- list(0, 0)
addtorow$command <- c("& \\multicolumn{3}{c}{Total Inequality} & \\multicolumn{5}{c}{Relative IOp} \\\\\n",
                      " \\cmidrule(lr){2-4} \\cmidrule(lr){5-9}  Country \\& Cohort & Cores-Full & Age-Full & Cores-Age & limited C & naive & proxy & trunc & true \\\\\n")
print(xtable(tab_distortion), digits = c(1, 1, 1, 1, 1), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow,
      floating = FALSE, auto = TRUE, file = paste0(path_tables, "/annex/distortion_educ.tex"))

#########################################################################################/
#3. Sampling Frame####
#########################################################################################/
if (restimation == TRUE){
  count_age_gender <- data_hhs %>% dplyr::count(country, age, female, wt = wt_hh) 
  count_age_gender_cores <- data_hhs %>% filter(coresident == 1)%>% dplyr::count(country, age, female, wt = wt_hh) %>% dplyr::rename(n_cores = n)
  cores_age_gender <- left_join(count_age_gender, count_age_gender_cores) %>% mutate(share_cores = n_cores/n) 
  save(cores_age_gender, file = paste0(path_results, "/cores_age_gender.RData"))
} else {
  load(paste0(path_results, "/cores_age_gender.RData"))
}

ggplot(cores_age_gender %>% mutate(female = factor(female, label = c("male", "female"))), 
       aes(x = age, y = share_cores, linetype = female, shape = female, color = country)) +
  geom_point() +
  geom_line() +
  geom_vline(xintercept = 15, color = "black") +
  geom_vline(xintercept = 18, color = "black") +
  facet_wrap(~country) +
  xlab("Age")+ylab("Share of Coresident Individuals") +
  scale_shape_manual("", values = c(19, 4), labels = c("♂ Male", "♀ Female")) +
  scale_linetype_manual("", values = c(1, 2), labels = c("♂ Male", "♀ Female")) +
  scale_y_continuous(limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(13, 24, 1), limits = c(13, 24)) +
  scale_color_discrete("", guide = "none") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/coresident_share_gender.png"), width = 8, height = 6)

#########################################################################################/
#4. Importance Parental Background####
#########################################################################################/
if(restimation == TRUE){
  circ_imp_educ_coresident_co4 <- circ_imp_para(data_educ_iop, circumstances_co4, outcome = "educ", type = "cohort_cores", boot_n, cohort_cores)
  circ_imp_educ_perf_co4 <- circ_imp_para(data_educ_perf, circumstances_co4, outcome = "educ", type = "cohort_5", boot_n)
  save(circ_imp_educ_coresident_co4, file = paste0(path_results, "/circ_imp_educ_coresident_co4.RData"))
  save(circ_imp_educ_perf_co4, file = paste0(path_results, "/circ_imp_educ_perf_co4.RData"))
} else {
  load(paste0(path_results, "/circ_imp_educ_coresident_co4.RData"))
  load(paste0(path_results, "/circ_imp_educ_perf_co4.RData"))
}

#coresident data (relative importance)
circ_imp <- circ_imp_educ_coresident_co4 %>% select(-c("sum_marg", "full", "rel_iop"))
circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
circ_imp <- circ_imp %>% 
  mutate(value = factor(value, levels = c("parents_educ", "female", "demo", "urban", "geo_level_1"), 
                      labels = c("Parental Education", "Gender", "Demographic Group", "Urban", "Region")))
ggplot(circ_imp,
        aes(x = year, fill = value, y = value.1)) +
  geom_bar(position = "stack", stat = "identity")+ facet_wrap(~ country, nrow = 3) +
  scale_fill_manual(values = c("purple", "red", "lightgreen", "orange", "blue")) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1975, 2000, 5)) +
  ylab("Relative Contribution to Education IOp") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/circ_imp_educ_coresident.png"), width = 8, height = 6)

#perfect data (relative importance), i.e., directly question parental background
circ_imp <- circ_imp_educ_perf_co4 %>% select(-c("sum_marg", "full", "rel_iop"))
circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
circ_imp <- circ_imp %>%
  mutate(value = factor(value, levels = c("parents_educ", "female", "demo", "urban", "geo_level_1"), 
                      labels = c("Parental Education", "Gender", "Demographic Group", "Urban", "Region")))
ggplot(circ_imp,
        aes(x = year, fill = value, y = value.1)) +
  geom_bar(position = "stack", stat = "identity")+ facet_wrap(~ country, nrow = 3) +
  scale_fill_manual(values = c("purple", "red", "lightgreen", "orange", "blue")) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  ylab("Relative Contribution to Education IOp") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position =  "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/circ_imp_educ_perfect.png"), width = 8, height = 6)