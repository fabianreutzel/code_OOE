#########################################################################################/
# Overview####
#title: "2.2_IOp_cohort.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Education####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "educ"){
  #########################################################################################/
  ##1.1 Years of Education####
  #########################################################################################/
  if(restimation == TRUE){
    educ_cs4 <- iop_ex_ante(data_educ, circumstances_cs4, outcome = "educ", estimation, type = "cohort_5", boot_n)
    save(educ_cs4, file = paste0(path_results, "/educ_cs4.RData"))
  }else{
    load(paste0(path_results, "/educ_cs4.RData"))
  }
  #########################################################################################/
  ##1.2 Educational Degrees####
  #########################################################################################/
  if(restimation == TRUE){
    prim_cs4 <- iop_ex_ante(data_educ, circumstances_cs4, outcome = "prim", estimation, type = "cohort_5", boot_n)
    uppsec_cs4 <- iop_ex_ante(data_educ, circumstances_cs4, outcome = "uppsec", estimation, type = "cohort_5", boot_n)
    save(prim_cs4, file = paste0(path_results, "/prim_cs4.RData"))
    save(uppsec_cs4, file = paste0(path_results, "/uppsec_cs4.RData"))
  } else {
    load(paste0(path_results, "/prim_cs4.RData"))
    load(paste0(path_results, "/uppsec_cs4.RData"))
  }

  ###Primary education (IOp & Share) ####
  share_iop_prim <- rbind(prim_cs4 %>% select(country, year, share_u, share_l, share_p) %>% mutate(outcome = "1"),
                      prim_cs4 %>% select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>% mutate(outcome = "2") %>%
                        rename_with(~paste0("share", substr(., 8, nchar(.))), starts_with("abs_iop")))

  ggplot(share_iop_prim,
        aes(x = year, y = share_p, linetype = outcome)) +
    geom_point(color = "steelblue") +
    geom_line(color = "steelblue") +
    geom_text(data = . %>% group_by(country) %>% filter((year == max(year))&outcome == "1"), aes(label = round(share_p, 2)), vjust = -1, check_overlap = TRUE, size = 3, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country) %>% filter((year == max(year))&outcome == "2"), aes(label = round(share_p, 2)), vjust = 1.5, check_overlap = TRUE, size = 3, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country) %>% filter((year == min(year))&outcome == "1"), aes(label = round(share_p, 2)), vjust = -1, check_overlap = TRUE, size = 3, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country) %>% filter((year == min(year))&outcome == "2"), aes(label = round(share_p, 2)), vjust = 1.5, check_overlap = TRUE, size = 3, show.legend = FALSE) +
    scale_y_continuous(limits = c(0, 1)) +
    facet_wrap(~country) +
    ylab("D−index & Share in Population: Primary Education") +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    scale_linetype_manual("", values = c("1" = "solid", "2" = "dotted"), labels = c("1" = "Share", "2" = "D-Index")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/share_iop_prim.png"), width = 8, height = 6)

  ###Change IOp education across ####
  iop_uppsec_prim_educ <- rbind(educ_cs4 %>% select(country, year, rel_iop_u, rel_iop_l, rel_iop_p) %>% mutate(outcome = "1") %>%
                          rename_with(~paste0("abs_iop", substr(., 8, nchar(.))), starts_with("rel_iop")),
                        prim_cs4 %>% select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>% mutate(outcome = "2"),
                        uppsec_cs4 %>% select(country, year, abs_iop_u, abs_iop_l, abs_iop_p) %>% mutate(outcome = "3")) %>%
          group_by(country, outcome) %>%
          mutate(abs_iop_p_0 = ifelse(year == min(year), abs_iop_p, 0), abs_iop_p_0 = max(abs_iop_p_0),
                  abs_iop_p = (abs_iop_p/abs_iop_p_0)*100, abs_iop_u = (abs_iop_u/abs_iop_p_0)*100, abs_iop_l = (abs_iop_l/abs_iop_p_0)*100)
  ggplot(iop_uppsec_prim_educ,
        aes(x = year, y = abs_iop_p, color = outcome)) +
    geom_point() +
    geom_line() +
    geom_text(data = . %>% group_by(country, outcome) %>% filter(year == max(year)), aes(label = round(abs_iop_p, 0)), vjust = 1, hjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    scale_y_continuous(limits = c(0, 110), breaks = c(0, 25, 50, 75, 100)) +
    facet_wrap(~country) +
    ylab("% Change in IOp") +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    scale_color_manual("", values = c("1" = "blue", "2" = "steelblue", "3" = "lightblue"), labels = c("1" = "Years of Education", "2" = "Primary Education", "3" = "Upper Secondary Education")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/iop_uppsec_prim_educ.png"), width = 8, height = 6)

  #########################################################################################/
  #1.3 Evolution Education Categories ####
  #########################################################################################/
  if(restimation == TRUE){
    shares_educ_cat <- data_educ %>%
      filter(!is.na(educ_cat)) %>%
      group_by(country, cohort_5, educ_cat) %>%
      summarise(n = n(), .groups = "drop") %>%
      group_by(country, cohort_5) %>%
      mutate(share = n / sum(n)) %>%
      ungroup()
    save(shares_educ_cat, file = paste0(path_results, "/shares_educ_cat.RData"))
  } else {
    load(paste0(path_results, "/shares_educ_cat.RData"))
  }

  ggplot(shares_educ_cat %>%
    mutate(educ_cat = factor(as.character(educ_cat), levels = c("0", "1", "2"))),
    aes(x = cohort_5, y = share, fill = educ_cat)) +
    geom_col(position = position_stack(reverse = TRUE)) +
    facet_wrap(~country) +
    ylab("Population share") +
    xlab("Birth Cohort") +
    scale_x_continuous(breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    scale_fill_manual("",
      values = c("0" = "darkblue", "1" = "steelblue", "2" = "lightblue"),
      breaks = c("0", "1", "2"),
      labels = c("0" = "No/less than Primary",
        "1" = "Primary/Secondary non-completed",
        "2" = "Secondary/Higher Education")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
      axis.line = element_line(color = "black"),
      legend.position = c(0.8, 0.1),
      legend.title = element_blank(),
      panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/shares_educ_cat.png"), width = 10, height = 6)
}
#########################################################################################/
#2. Consumption ####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "cons"){
  if(restimation == TRUE){
    cons_cs3 <- iop_ex_ante(data_cons, circumstances_cs3, outcome = "hh_cons_wb", estimation, type = "cohort_5", boot_n)
    save(cons_cs3, file = paste0(path_results, "/cons_cs3.RData"))
  } else {
    load(paste0(path_results, "/cons_cs3.RData"))
  }
}
#########################################################################################/
#3. Labor Market Outcomes ####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "labor"){
  #########################################################################################/
  #3.1 Estimating/Loading IOp ####
  #########################################################################################/
  if(restimation == TRUE){
    #combined survey estimates
    lfp_cs4 <- iop_ex_ante(data_labor, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    paidwage_cs4 <- iop_ex_ante(data_labor, circumstances_cs4, outcome = "paidwage", estimation, type = "cohort_5", boot_n)
    wage_cs4 <- iop_ex_ante(data_labor, circumstances_cs4, outcome = "wage", estimation, type = "cohort_5", boot_n)
    save(lfp_cs4, file = paste0(path_results, "/lfp_cs4.RData"))
    save(paidwage_cs4, file = paste0(path_results, "/paidwage_cs4.RData"))
    save(wage_cs4, file = paste0(path_results, "/wage_cs4.RData"))
    
    #survey-specific estimates
    lfp_cs4_hhs <- iop_ex_ante(data_hhs_full, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    lfp_cs4_lfs <- iop_ex_ante(data_lfs_full, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    save(lfp_cs4_hhs, file = paste0(path_results, "/lfp_cs4_hhs.RData"))
    save(lfp_cs4_lfs, file = paste0(path_results, "/lfp_cs4_lfs.RData"))
    
    paidwage_cs4_hhs <- iop_ex_ante(data_hhs_full, circumstances_cs4, outcome = "paidwage", estimation, type = "cohort_5", boot_n)
    paidwage_cs4_lfs <- iop_ex_ante(data_lfs_full, circumstances_cs4, outcome = "paidwage", estimation, type = "cohort_5", boot_n)
    save(paidwage_cs4_hhs, file = paste0(path_results, "/paidwage_cs4_hhs.RData"))
    save(paidwage_cs4_lfs, file = paste0(path_results, "/paidwage_cs4_lfs.RData"))
    
    paidwage_all_cs4_hhs <- iop_ex_ante(data_hhs_full, circumstances_cs4, outcome = "paidwage_all", estimation, type = "cohort_5", boot_n)
    paidwage_all_cs4_lfs <- iop_ex_ante(data_lfs_full, circumstances_cs4, outcome = "paidwage_all", estimation, type = "cohort_5", boot_n)
    save(paidwage_all_cs4_hhs, file = paste0(path_results, "/paidwage_all_cs4_hhs.RData"))
    save(paidwage_all_cs4_lfs, file = paste0(path_results, "/paidwage_all_cs4_lfs.RData"))
    
    wage_cs4_hhs <- iop_ex_ante(data_hhs_full, circumstances_cs4, outcome = "wage", estimation, type = "cohort_5", boot_n)
    wage_cs4_lfs <- iop_ex_ante(data_lfs_full, circumstances_cs4, outcome = "wage", estimation, type = "cohort_5", boot_n)
    save(wage_cs4_hhs, file = paste0(path_results, "/wage_cs4_hhs.RData"))
    save(wage_cs4_lfs, file = paste0(path_results, "/wage_cs4_lfs.RData"))
    
    #education-group specific estimates
    lfp_educ_cat_cs4 <- iop_ex_ante(data_labor_educ_cat, circumstances_cs4, outcome = "lfp", estimation, type = "cohort_5", boot_n)
    paidwage_educ_cat_cs4 <- iop_ex_ante(data_labor_educ_cat, circumstances_cs4, outcome = "paidwage", estimation, type = "cohort_5", boot_n)
    save(lfp_educ_cat_cs4, file = paste0(path_results, "/lfp_educ_cat_cs4.RData"))
    save(paidwage_educ_cat_cs4, file = paste0(path_results, "/paidwage_educ_cat_cs4.RData"))
  } else {
    #combined survey estimates
    load(paste0(path_results, "/lfp_cs4.RData"))
    load(paste0(path_results, "/paidwage_cs4.RData"))
    load(paste0(path_results, "/wage_cs4.RData"))
    #survey-specific estimates
    load(paste0(path_results, "/lfp_cs4_hhs.RData"))
    load(paste0(path_results, "/lfp_cs4_lfs.RData"))
    load(paste0(path_results, "/paidwage_cs4_hhs.RData"))
    load(paste0(path_results, "/paidwage_cs4_lfs.RData"))
    load(paste0(path_results, "/paidwage_all_cs4_hhs.RData"))
    load(paste0(path_results, "/paidwage_all_cs4_lfs.RData"))
    load(paste0(path_results, "/wage_cs4_hhs.RData"))
    load(paste0(path_results, "/wage_cs4_lfs.RData"))
    #education-group specific estimates
    load(paste0(path_results, "/lfp_educ_cat_cs4.RData"))
    load(paste0(path_results, "/paidwage_educ_cat_cs4.RData"))
  }

  #########################################################################################/
  ##3.2 Graphs ####
  #########################################################################################/
  #########################################################################################/
  ###3.2.1 Wage-Employment across sample definitions & sources ####
  #########################################################################################/
  lfp_paidwage_paidwage_all_hhs_lfs <- rbind(lfp_cs4_hhs %>% mutate(outcome = "LFP", source = "Household Survey") %>% select(country, year, outcome, source, abs_iop_p, N),
                                    lfp_cs4_lfs %>% mutate(outcome = "LFP", source = "Labor Force Survey") %>% select(country, year, outcome, source, abs_iop_p, N),
                                    paidwage_cs4_hhs %>% mutate(outcome = "Wage-Emp.", source = "Household Survey") %>% select(country, year, outcome, source, abs_iop_p, N),
                                    paidwage_cs4_lfs %>% mutate(outcome = "Wage-Emp.", source = "Labor Force Survey") %>% select(country, year, outcome, source, abs_iop_p, N),
                                    paidwage_all_cs4_hhs %>% mutate(outcome = "Wage-Emp. (Full Pop.)", source = "Household Survey") %>% select(country, year, outcome, source, abs_iop_p, N),
                                    paidwage_all_cs4_lfs %>% mutate(outcome = "Wage-Emp. (Full Pop.)", source = "Labor Force Survey") %>% select(country, year, outcome, source, abs_iop_p, N)) %>%
    filter(!(country == "Nepal"&outcome == "LFP")) %>% # exclude Nepal LFP due to overreporting
    mutate(outcome = factor(outcome, levels = c("LFP", "Wage-Emp.", "Wage-Emp. (Full Pop.)")),
          source = factor(source, levels = c("Household Survey", "Labor Force Survey")))

  ggplot(lfp_paidwage_paidwage_all_hhs_lfs,
        aes(x = year, y = abs_iop_p, color = outcome)) +
    geom_point(aes(shape = source)) +
    geom_line(aes(linetype = source)) +
    geom_text(data = . %>% group_by(country, outcome, source) %>% filter(year == max(year)), aes(label = round(abs_iop_p, 2)), vjust = 1, hjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country, outcome, source) %>% filter(year == min(year)), aes(label = round(abs_iop_p, 2)), vjust = 0, hjust = 0, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    facet_wrap(~country) +
    scale_y_continuous(limits = c(0.0, 0.65)) +
    ylab("IOp in Labor Market Outcomes") +
    scale_color_manual("Data Source", values = c("LFP" = "violet", "Wage-Emp." = "orange", "Wage-Emp. (Full Pop.)" = "red")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    scale_linetype_manual(values = c("Household Survey" = "solid", "Labor Force Survey" = "dotted")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/annex/iop_lfp_paidwage_paidwage_all_hhs_lfs.png"), width = 8, height = 6)

  #########################################################################################/
  ###3.2.2 Combined sources (main text) ####
  #########################################################################################/
  lfp_paidwage_wage <- rbind(
      lfp_cs4 %>% mutate(outcome = "LFP", source = "Household Survey") %>% select(country, year, outcome, source, abs_iop_p, N), 
      paidwage_cs4 %>% mutate(outcome = "Wage-Employment", source = "Household Survey") %>% select(country, year, outcome, source, abs_iop_p, N), 
      wage_cs4 %>% mutate(outcome = "Wages", source = "Household Survey") %>% select(country, year, outcome, source, rel_iop_p, N) %>%
        dplyr::rename_with(~gsub("rel_iop", "abs_iop", .), starts_with("rel_iop"))
    ) %>%
    filter(!(country == "Nepal" & outcome != "Wage-Employment")) %>%
    mutate(outcome = factor(outcome, levels = c("LFP", "Wage-Employment", "Wages"))) %>%
    mutate(type_new = as.factor(ifelse((country == "India"&year >= 6), 1, 0))) %>%
    mutate(type_std = as.factor(ifelse(!(country == "India"&year>6), 1, 0)))

  ggplot(lfp_paidwage_wage, 
        aes(x = year, y = abs_iop_p, color = outcome)) +
    geom_point() +
    geom_line(data = . %>% filter(type_std == "1"),
              aes(x = year, y = abs_iop_p, color = outcome), linetype = "solid") +
    geom_line(data = . %>% filter(type_new == "1"),
              aes(x = year, y = abs_iop_p, color = outcome), linetype = "dotted") +
    geom_text(data = . %>% group_by(country, outcome, source) %>% filter(year == max(year)), aes(label = round(abs_iop_p, 2)), vjust = 1, hjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country, outcome, source) %>% filter(year == min(year)), aes(label = round(abs_iop_p, 2)), vjust = 0, hjust = 0, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    facet_wrap(~country) +
    ylab("IOp in Labor Market Outcomes") +
    scale_y_continuous(limits = c(0.0, 0.65)) +
    scale_color_manual("Data Source", values = c("LFP" = "violet", "Wage-Employment" = "orange", "Wages" = "gold")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    guides(linetype = "none") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/iop_lfp_paidwage_wage.png"), width = 8, height = 6)

  #########################################################################################/
  ###3.2.3 IOp by education groups####
  #########################################################################################/
  lfp_educ_cat <- lfp_educ_cat_cs4 %>%
    mutate(educ_cat = factor(substr(country, nchar(country)-1, nchar(country)), labels = c("0" = "No/less than Primary", "1" = "Primary/Secondary non-completed", "2" = "Secondary/Higher Education")), 
          country = substr(country, 1, nchar(country)-2))
  paidwage_educ_cat <- paidwage_educ_cat_cs4 %>%
    mutate(educ_cat = factor(substr(country, nchar(country)-1, nchar(country)), labels = c("0" = "No/less than Primary", "1" = "Primary/Secondary non-completed", "2" = "Secondary/Higher Education")), 
          country = substr(country, 1, nchar(country)-2))

  #LFP & Wage-Employment IOp in top vs. full pop.
  ggplot(rbind(
        lfp_educ_cat %>% filter(educ_cat == "Secondary/Higher Education") %>% mutate(sample = 2, outcome = 1) %>% select(country, year, abs_iop_p, sample, outcome), 
        lfp_cs4 %>% mutate(sample = 1, outcome = 1) %>% select(country, year, abs_iop_p, sample, outcome), 
        paidwage_educ_cat %>% filter(educ_cat == "Secondary/Higher Education") %>% mutate(sample = 2, outcome = 2) %>% select(country, year, abs_iop_p, sample, outcome), 
        paidwage_cs4 %>% mutate(sample = 1, outcome = 2) %>% select(country, year, abs_iop_p, sample, outcome)
      ) %>%
      mutate(sample = factor(sample, labels = c("1" = "Full Population", "2" = "Only Secondary/Higher Education"))) %>% 
      mutate(outcome = factor(outcome, labels = c("1" = "LFP", "2" = "Wage-Employment"))), 
      aes(x = year, y = abs_iop_p, linetype = sample, shape = sample, color = outcome)) +
    geom_point() +
    geom_line() +
    geom_text(data = . %>% group_by(country, sample) %>% filter(year == max(year)), aes(label = round(abs_iop_p, 2)), vjust = 1, hjust = 1, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    geom_text(data = . %>% group_by(country, sample) %>% filter(year == min(year)), aes(label = round(abs_iop_p, 2)), vjust = 0, hjust = 0, check_overlap = TRUE, size = 4, show.legend = FALSE) +
    facet_wrap(~country) +
    ylab("IOp in LFP/Wage-Employment") +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    scale_color_manual("", values = c("violet", "orange")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/iop_lfp_paidwage_educ_cat_sample.png"), width = 8, height = 6)
}