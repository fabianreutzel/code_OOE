#########################################################################################/
# Overview####
#title: "2.8_joint_graphs"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#0. load results####
#########################################################################################/
load(paste0(path_results, "/educ_cs4.RData"))
load(paste0(path_results, "/prim_cs4.RData"))
load(paste0(path_results, "/uppsec_cs4.RData"))
load(paste0(path_results, "/lfp_cs4.RData"))
load(paste0(path_results, "/cons_cs3.RData"))
load(paste0(path_results, "/lfp_cs4.RData"))
load(paste0(path_results, "/paidwage_cs4.RData"))
load(paste0(path_results, "/wage_cs4.RData"))
#########################################################################################/
#1. Evolution IOp across outcome dimensions####
#########################################################################################/
#########################################################################################/
#1.1 IOp educ + cons ####
#########################################################################################/
educ_cons <- rbind(
  rbind(
    educ_cs4 %>% select(country, year, gini_u, gini_l, gini_p) %>% mutate(outcome = 1, measure = 0),
    cons_cs3 %>% select(country, year, gini_u, gini_l, gini_p) %>% mutate(outcome = 2, measure = 0)) %>% 
      rename_with(~str_replace(., "gini", "value"), contains("gini")
  ),
  rbind(
    educ_cs4 %>% select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>% mutate(outcome = 1, measure = 1),
    cons_cs3 %>% select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>% mutate(outcome = 2, measure = 1)) %>% 
      rename_with(~str_replace(., "rel_iop", "value"), contains("rel_iop")
  )) %>%
  mutate(outcome = factor(outcome, labels = c("1" = "Education", "2" = "Consumption"))) %>%
  mutate(measure = factor(measure, labels = c("0" = "Total Inequality", "1" = "Relative IOp"))) %>%
  mutate(line_type = as.factor(case_when(
    measure == "Total Inequality" ~ "solid",
    measure == "Relative IOp" ~ "dashed"
  )))

ggplot(educ_cons,
       aes(x = year, y = value_p, color = outcome, linetype = measure)) +
  geom_point() +
  geom_line(data = educ_cons,
            aes(x = year, y = value_p, color = outcome, linetype = measure)) +
  geom_text(data = . %>% group_by(country, outcome) %>% filter(year == min(year)),
            aes(label = round(value_p, 2)), vjust = -1, check_overlap = TRUE, size = 3, show.legend = FALSE) +
  geom_text(data = . %>% group_by(country, outcome) %>% filter(year == max(year)),
            aes(label = round(value_p, 2)), vjust = 1, size = 3, show.legend = FALSE) +
  scale_y_continuous(limits = c(0, 1)) +
  facet_wrap(~country) +
  ylab("Total Inequality & Relative IOp") +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  scale_linetype_manual(
    values = c("Total Inequality" = "solid", "Relative IOp" = "dashed"),
    breaks = c("Total Inequality", "Relative IOp"),
    labels = c("Total Inequality", "Relative IOp")
  ) +
  scale_colour_manual("", values = c("Education" = "blue", "Consumption" = "red")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/main/educ_cons.png"), width = 8, height = 6)

#########################################################################################/
#1.2 Relative change IOp educ + lfp + cons ####
#########################################################################################/
change_educ_lfp_cons <- rbind(
  educ_cs4 %>% select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>% mutate(outcome = 1),
  lfp_cs4 %>%  select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>% mutate(outcome = 3) %>%
    rename_with(~paste0("rel", substr(., 4, nchar(.))), starts_with("abs")),
  cons_cs3 %>% select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>% mutate(outcome = 2)
  ) %>%
  mutate(outcome = factor(outcome, labels = c("1" = "Education", "2" = "Consumption", "3" = "LFP"))) %>%
  mutate(type_new = as.factor(ifelse((outcome == "LFP"&country == "India"&year >= 6), 1, 0))) %>%
  mutate(type_std = as.factor(ifelse(!(outcome == "LFP"&country == "India"&year>6), 1, 0))) %>%
  group_by(country) %>%
  mutate(max_min_year = max(aggregate(year ~ outcome, data = pick(everything()), FUN = min)$year)) %>% # Calculate highest min year
  ungroup() %>% group_by(country, outcome) %>%
  mutate(rel_iop_p_0 = case_when(year == max_min_year ~ rel_iop_p, TRUE ~ 0), rel_iop_p_0 = max(rel_iop_p_0),
         rel_iop_p = (rel_iop_p/rel_iop_p_0)*100, rel_iop_u = (rel_iop_u/rel_iop_p_0)*100, rel_iop_l = (rel_iop_l/rel_iop_p_0)*100)

ggplot(change_educ_lfp_cons,
       aes(x = year, y = rel_iop_p, color = outcome)) +
  geom_point() +
  geom_line(data = . %>% filter(type_std == "1"),
            aes(x = year, y = rel_iop_p, color = outcome), linetype = "solid") +
  geom_line(data = . %>% filter(type_new == "1"),
            aes(x = year, y = rel_iop_p, color = outcome), linetype = "dotted") +
  geom_text(data = . %>% filter(!((outcome == "LFP"&(country == "Afghanistan"|country == "India"))|(outcome == "Consumption"&country == "Pakistan"))) %>% group_by(country, outcome) %>% filter(year == max(year)), 
            aes(label = round(rel_iop_p, 0)), vjust = -1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
  geom_text(data = . %>% filter((outcome == "LFP"&(country == "Afghanistan"|country == "India"))|(outcome == "Consumption"&country == "Pakistan")) %>% group_by(country) %>% filter(year == max(year)), 
                               aes(label = round(rel_iop_p, 0)), vjust = 1, size = 4, show.legend = FALSE) +
  scale_y_continuous(limits = c(25, 130)) +
  facet_wrap(~country) +
  ylab("% Change in IOp") +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  guides(linetype = "none") +
  scale_colour_manual("", values = c("Education" = "blue", "LFP" = "violet", "Consumption" = "red")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/main/change_educ_lfp_cons.png"), width = 8, height = 6)

#########################################################################################/
#2. Multi-Outcome Profile Changes #####
#########################################################################################/
load(paste0(path_results, "/profiles_prim_cs4.RData"))
load(paste0(path_results, "/profiles_uppsec_cs4.RData"))
load(paste0(path_results, "/profiles_cons_cs3.RData"))
load(paste0(path_results, "/profiles_lfp_cs4.RData"))

#minimum type size
n_min = 20

#get type-definition based on consumption
prof_0_cons <- profiles_cons_cs3 %>% 
  group_by(country) %>%
  filter(year == min(year)) %>%
  filter(N >= n_min&is.na(y_hat_p) != 1) %>%  #apply restriction for min group size
  arrange(country, y_hat_p) %>% 
  mutate(type_id = row_number()) %>%
  mutate(type_id_cons = ((type_id-1)/max(type_id-1)*100)) %>%
  select(country, type_id_cons, demo, urban, geo_level_1)

#get type-definition based on primary education share for Afghanistan (no cons estimates)
prof_0_afg <- profiles_prim_cs4 %>%
  filter(country == "Afghanistan") %>%
  filter(female == 0) %>%
  filter(year == min(year)) %>%
  filter(N >= n_min&is.na(y_hat_p) != 1) %>%  #apply restriction for min group size
  arrange(country, y_hat_p) %>% 
  mutate(type_id = row_number()) %>%
  mutate(type_id_cons = ((type_id-1)/max(type_id-1)*100)) %>%
  select(country, type_id_cons, demo, urban, geo_level_1)

#combine type definitions
prof_0_cons <- rbind(prof_0_afg, prof_0_cons)

#combine uppsec & lfp (i.e., make sure to have both outcomes for each group)
profiles_lfp_cs4 <- profiles_lfp_cs4 %>% filter(N >= n_min & is.na(y_hat_p) != 1)
profiles_uppsec_cs4 <- profiles_uppsec_cs4 %>% filter(N >= n_min & is.na(y_hat_p) != 1)
profiles_uppsec_cs4_adj <- profiles_uppsec_cs4 %>%
  inner_join(profiles_lfp_cs4%>%select(country, type, year), by = c("country", "type", "year"))
profiles_lfp_cs4_adj <- profiles_lfp_cs4 %>%
  inner_join(profiles_uppsec_cs4%>%select(country, type, year), by = c("country", "type", "year"))
prof_uppsec_lfp <- rbind(profiles_uppsec_cs4_adj %>% mutate(outcome = "Secondary/Higher Education"),
                         profiles_lfp_cs4_adj %>% mutate(outcome = "LFP")) %>%
  left_join(prof_0_cons, by = c("country", "demo", "urban", "geo_level_1")) %>%
  filter(is.na(type_id_cons) != 1) %>%
  mutate(y_hat_u = ifelse(y_hat_u<1, y_hat_u, 1),
         y_hat_l = ifelse(y_hat_l>0, y_hat_l, 0))
prof_uppsec_lfp %>% filter(country == "Bhutan") %>% group_by(year) %>% summarise(N_types = n_distinct(type))

#combine first and last cohort
prof_0 <- prof_uppsec_lfp %>% filter((year == 2&country != "Bhutan"&country != "Afghanistan")|(year == 3&(country == "Bhutan"|country == "Afghanistan")))
prof_1 <- prof_uppsec_lfp %>% filter((year == 7&country != "Bhutan")|(year == 6&country == "Bhutan"))
prof_01 <- inner_join(prof_1, prof_0, by = c("country", "type", "outcome")) %>%
  dplyr::rename(type_id_cons = type_id_cons.x, female = female.x) %>%
  mutate(change_y_hat_p = y_hat_p.x-y_hat_p.y, change_y_hat_u = y_hat_u.x-y_hat_u.y, change_y_hat_l = y_hat_l.x-y_hat_l.y) %>%
  filter(is.na(change_y_hat_p) != 1)

ggplot(prof_01,
       aes(x = type_id_cons, y = change_y_hat_p, color = female, shape = outcome, weight = N.y, group = country)) +
  geom_point(size = 1, alpha = 0.3) +
  geom_hline(yintercept = 0, color = "black") +
  geom_smooth(aes(color = female, group = paste0(outcome, female), linetype = outcome), method = "loess", se = FALSE) +
  ylab("Change in Type-Average Share (1950s-1980s)") + xlab("Opportunity Groups (ordered by HH Consumption)") +
  scale_shape_manual(values = c(16, 17)) + 
  scale_color_manual(values = c("blue", "red"), labels = c("♂ Male", "♀ Female")) +
  scale_linetype_manual(values = c("solid", "dashed")) +
  facet_wrap(~country) +
  theme(axis.line = element_line(color = "black"),
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank()) +
  guides(linetype = guide_legend(override.aes = list(color = "black")))
ggsave(paste0(path_figures, "/main/change_uppsec_lfp.png"), width = 8, height = 6)