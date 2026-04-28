#########################################################################################/
# Overview####
#title: "2.6_circ_importance"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#########################################################################################/
#1. Parametric circumstance importance####
#########################################################################################/
#########################################################################################/
##1.1 Education ####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "educ"){
  if(restimation == TRUE){
    circ_imp_educ_cs4 <- circ_imp_para(data_educ, circumstances_cs4, outcome = "educ", type = "cohort_5", boot_n)
    save(circ_imp_educ_cs4, file = paste0(path_results, "/circ_imp_educ_cs4.RData"))
  } else {
    load(paste0(path_results, "/circ_imp_educ_cs4.RData"))
  }

  #full sample (absolute importance wrt relative IOp)
  circ_imp <- circ_imp_educ_cs4 %>%
    mutate(female = female*rel_iop, demo = demo*rel_iop, urban = urban*rel_iop, geo_level_1 = geo_level_1*rel_iop) %>% 
    select(-c("sum_marg", "full", "rel_iop"))
  circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
  circ_imp <- circ_imp %>%
    mutate(value = factor(value, labels = c("Gender", "Demographic Group", "Urban", "Region")))
  ggplot(circ_imp, 
         aes(x = year, fill = value, y = value.1)) +
    geom_bar(position = "stack", stat = "identity") + facet_wrap(~ country, nrow = 3) +
    scale_fill_manual(values = c("red", "lightgreen", "orange", "blue")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    ylab("Decomposition Education IOp") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position =  c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/circ_imp_educ.png"), width = 8, height = 6)
}

#########################################################################################/
##1.2 Consumption ####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "cons"){
  if(restimation == TRUE){
    circ_imp_cons_cs3 <- circ_imp_para(data_cons, circumstances_cs3, outcome = "hh_cons_wb", type = "cohort_5", boot_n)
    save(circ_imp_cons_cs3, file = paste0(path_results, "/circ_imp_cons_cs3.RData"))
  } else {
    load(paste0(path_results, "/circ_imp_cons_cs3.RData"))
  }

  #absolute importance wrt relative IOp
  circ_imp <- circ_imp_cons_cs3 %>%
    mutate(demo = demo*rel_iop, urban = urban*rel_iop, geo_level_1 = geo_level_1*rel_iop) %>% 
    select(-c("sum_marg", "full", "rel_iop"))
  circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
  circ_imp <- circ_imp %>% 
    mutate(value = factor(value, labels = c("Demographic Group", "Urban", "Region")), 
           year = factor(year, labels = cohort_5_lab[1:length(unique(circ_imp$year))]))
  ggplot(circ_imp,
         aes(x = year, fill = value, y = value.1)) +
    geom_bar(position = "stack", stat = "identity") + facet_wrap(~ country, nrow = 2) +
    ylab("Decomposition of Consumption IOp") + xlab("Birth Cohort") +
    scale_fill_manual(values = c("lightgreen", "orange", "blue")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/annex/circ_imp_cons.png"), width = 8, height = 6)
}

#########################################################################################/
##1.3 Labor Market ####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "labor"){
  if(restimation == TRUE){
    circ_imp_lfp_cs4 <- circ_imp_para(data_labor, circumstances_cs4, outcome = "lfp", type = "cohort_5", boot_n)
    circ_imp_paidwage_cs4 <- circ_imp_para(data_labor%>%filter(!is.na(paidwage)), circumstances_cs4, outcome = "paidwage", type = "cohort_5", boot_n)
    circ_imp_wage_cs4 <- circ_imp_para(data_labor, circumstances_cs4, outcome = "wage", type = "cohort_5", boot_n)
    save(circ_imp_lfp_cs4, file = paste0(path_results, "/circ_imp_lfp_cs4.RData"))
    save(circ_imp_paidwage_cs4, file = paste0(path_results, "/circ_imp_paidwage_cs4.RData"))
    save(circ_imp_wage_cs4, file = paste0(path_results, "/circ_imp_wage_cs4.RData"))
  } else {
    load(paste0(path_results, "/circ_imp_lfp_cs4.RData"))
    load(paste0(path_results, "/circ_imp_paidwage_cs4.RData"))
    load(paste0(path_results, "/circ_imp_wage_cs4.RData"))
  }

  #LFP
  circ_imp <- circ_imp_lfp_cs4 %>%
    mutate(female = female*full, demo = demo*full, urban = urban*full, geo_level_1 = geo_level_1*full) %>% 
    select(-c("sum_marg", "full", "rel_iop"))
  circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
  circ_imp <- circ_imp %>% 
    mutate(value = factor(value, labels = c("Gender", "Demographic Group", "Urban", "Region")))
  ggplot(circ_imp, 
         aes(x = year, fill = value, y = value.1)) + 
    geom_bar(position = "stack", stat = "identity") + facet_wrap(~ country) +
    scale_fill_manual(values = c("red", "lightgreen", "orange", "blue")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    ylab("Decomposition LFP IOp") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = "bottom",
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/main/circ_imp_lfp.png"), width = 8, height = 6)
  
  #Wage-Employment
  circ_imp <- circ_imp_paidwage_cs4 %>%
    mutate(female = female*full, demo = demo*full, urban = urban*full, geo_level_1 = geo_level_1*full) %>% 
    select(-c("sum_marg", "full", "rel_iop"))
  circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
  circ_imp <- circ_imp %>%
    mutate(value = factor(value, labels = c("Gender", "Demographic Group", "Urban", "Region")))
  ggplot(circ_imp,
         aes(x = year, fill = value, y = value.1)) +
    geom_bar(position = "stack", stat = "identity") + facet_wrap(~ country, nrow = 3) +
    scale_fill_manual(values = c("red", "lightgreen", "orange", "blue")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    ylab("Decomposition Wage-Employment IOp") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position =  c(.8, .1),
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/annex/circ_imp_paidwage.png"), width = 8, height = 6)
  
  #Wage
  circ_imp <- circ_imp_wage_cs4 %>%
    mutate(female = female*rel_iop, demo = demo*rel_iop, urban = urban*rel_iop, geo_level_1 = geo_level_1*rel_iop) %>%
    select(-c("sum_marg", "full", "rel_iop"))
  circ_imp <- melt(setDT(circ_imp), id.vars = c("country", "year", "country_year"), variable.name = "value")
  circ_imp <- circ_imp %>% mutate(value = factor(value, labels = c("Gender", "Demographic Group", "Urban", "Region")))
  ggplot(circ_imp,
         aes(x = year, fill = value, y = value.1)) +
    geom_bar(position = "stack", stat = "identity") + facet_wrap(~ country, nrow = 3) +
    scale_fill_manual(values = c("red", "lightgreen", "orange", "blue")) +
    scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
    ylab("Decomposition Wage IOp") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.line = element_line(color = "black"),
          legend.position = "bottom",
          legend.title = element_blank(),
          legend.text = element_text(size = 11),
          panel.background = element_blank())
  ggsave(paste0(path_figures, "/annex/circ_imp_wage.png"), width = 8, height = 6)
}