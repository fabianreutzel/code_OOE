#########################################################################################/
# Overview####
#title: "2.3_regression_analyses.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Convex Returns####
#########################################################################################/
#########################################################################################/
##1.1 Model & Function Definition####
#########################################################################################/
lm_returns <- function(data, outcome) {
  # joint regresson
  if (any(is.na(data$demo))) {
    model_formula <- paste0(outcome, "~ age + age_2 + cohort_5*educ + cohort_5*educ_2 + cohort_5*female + cohort_5*urban + cohort_5*geo_level_1")
  } else {
    model_formula <- paste0(outcome, "~ age + age_2 + cohort_5*educ + cohort_5*educ_2 + cohort_5*female + cohort_5*urban + cohort_5*geo_level_1 + demo")
  }
  model <- lm(model_formula, data = data, weights = data$wt_hh)
  model_summary <- summary(model) # N & R2
  # heteroskedasticity-consistent (robust) SEs
  vcov_robust <- sandwich::vcovHC(model, type = "HC3")
  ct <- lmtest::coeftest(model, vcov. = vcov_robust)
  coef <- ct[, "Estimate"]
  se <- ct[, "Std. Error"]
  prob_coef <- ct[, "Pr(>|t|)"]
  n_r2 <- data.frame(rbind(
    c("Mean Outcome", mean(data[[outcome]]), NA, NA),
    c("N", length(model_summary$residuals), NA, NA),
    c("adj. R$^2$", model_summary$adj.r.squared, NA, NA)))
  colnames(n_r2) = c("term", "coef", "se", "prob_coef")
  return(
    rbind(
      tibble(
        term = names(coef),
        coef = coef,
        se = se,
        prob_coef = prob_coef),
        n_r2
      )
    )
}

lm_returns_year <- function(data, outcome) {
  if (any(is.na(data$demo))) {
    model_formula <- paste0(outcome, "~ age + age_2 + educ + educ_2 + female + urban + geo_level_1")
  } else {
    model_formula <- paste0(outcome, "~ age + age_2 + educ + educ_2 + female + urban + geo_level_1 + demo")
  }
  model <- lm(model_formula, data = data, weights = data$wt_hh)
  model_summary <- summary(model) # N & R2
  # heteroskedasticity-consistent (robust) SEs
  vcov_robust <- sandwich::vcovHC(model, type = "HC3")
  ct <- lmtest::coeftest(model, vcov. = vcov_robust)
  coef <- ct[, "Estimate"]
  se <- ct[, "Std. Error"]
  prob_coef <- ct[, "Pr(>|t|)"]
  n_r2 <- data.frame(rbind(
    c("N", length(model_summary$residuals), NA, NA),
    c("adj. R$^2$", model_summary$adj.r.squared, NA, NA)))
  colnames(n_r2) = c("term", "coef", "se", "prob_coef")
  return(
    rbind(
      tibble(
        term = names(coef),
        coef = coef,
        se = se,
        prob_coef = prob_coef),
        n_r2
      )
    )
}

calc_returns <- function(data, outcome, type = "", female = FALSE) {
  if (type  ==  "year") lm_reg <- lm_returns_year else lm_reg <- lm_returns
  data <- data %>%
    filter(!is.na(educ), !is.na(.data[[outcome]])) %>%
    mutate(educ_2 = educ^2)
  if (outcome  ==  "wage") {data <- data %>% mutate(wage = log(wage))}
  if (outcome  ==  "wage" & type != "year") {
    data <- data %>% # adjust cohorts (sample size) and log wages
      filter(!(cohort_5 <=   2 & (country  ==  "Pakistan"))) # excl. due to small sample size
  }
  group_vars <- c("country", type)
  if (female == TRUE){group_vars <- c("country", type, "female")}
  results <- data %>%
    mutate(across(c(cohort_5, female, urban, demo, geo_level_1), ~factor(.))) %>%
    group_by(!!!rlang::syms(group_vars)) %>%
    nest() %>% 
    mutate(model_results = purrr::map(data, .f = ~lm_reg(.x, outcome = outcome))) %>%
    unnest(model_results) %>% 
    select(-data) %>% 
    mutate(across(-1, as.numeric)) %>%
    ungroup()
  if (type  !=  "year"){results <- results %>% 
    mutate(cohort = as.numeric(str_replace(str_extract(term, "cohort_5\\d+"), "cohort_5", ""))) %>%
    group_by(country) %>%
    mutate(cohort = ifelse(is.na(cohort), min(cohort, na.rm = TRUE)-1, cohort)) %>%
    mutate(max_cohort = max(cohort, na.rm = TRUE), min_cohort = min(cohort, na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(cohort = factor(cohort, levels = names(cohort_5_lab), labels = cohort_5_lab))
  }
  return(results)
}

#########################################################################################/
##1.2 Estimation ####
#########################################################################################/
if(restimation == TRUE){
  lm_paidwage_educ_cat_convex <- calc_returns(data_labor, "paidwage")
  lm_lfp_educ_cat_convex <- calc_returns(data_labor, "lfp")
  lm_wage_educ_cat_convex <- calc_returns(data_labor, "wage")
  save(lm_paidwage_educ_cat_convex, file = paste0(path_results, "/lm_paidwage_educ_cat_convex.RData"))
  save(lm_lfp_educ_cat_convex, file = paste0(path_results, "/lm_lfp_educ_cat_convex.RData"))
  save(lm_wage_educ_cat_convex, file = paste0(path_results, "/lm_wage_educ_cat_convex.RData"))
  median_wage <- data_labor %>%
    filter(is.na(educ) != 1, is.na(wage) != 1) %>%
    mutate(wage = log(wage)) %>%
    group_by(country, cohort_5) %>%
    summarise(median_wage = median(wage, na.rm = TRUE), .groups = "drop") %>%
    ungroup()
  save(median_wage, file = paste0(path_results, "/median_wage.RData"))
}else{
  load(paste0(path_results, "/lm_paidwage_educ_cat_convex.RData"))
  load(paste0(path_results, "/lm_lfp_educ_cat_convex.RData"))
  load(paste0(path_results, "/lm_wage_educ_cat_convex.RData"))
  load(paste0(path_results, "/median_wage.RData"))
}

#########################################################################################/
##1.3 Graphs####
#########################################################################################/
returns_educ <- rbind(
  lm_lfp_educ_cat_convex %>% mutate(outcome = 1),
  lm_paidwage_educ_cat_convex %>% mutate(outcome = 2),
  lm_wage_educ_cat_convex %>% mutate(outcome = 3)
  ) %>%
  mutate(outcome = factor(outcome, levels = c(1, 2, 3), labels = c("LFP", "Wage-Employment", "Wage"))) %>%
  group_by(country, outcome) %>%
  mutate(cohort_5 = as.numeric(cohort)) %>%
  filter(cohort_5 == min(cohort_5)|cohort_5 == max(cohort_5)) %>%
  filter(grepl("educ", term) | term  ==  paste0("cohort_5", max(cohort_5, na.rm = TRUE), ":")) %>%
  mutate(cohort = as.factor(ifelse(cohort_5 == min(cohort_5), "1950s", "1980s"))) %>%
  mutate(coef_raw = as.numeric(coef)) %>%
  mutate(term = gsub("cohort_5\\d+:", "", term)) %>%
  mutate(
    base1 = { idx1 <- which(term  ==  "educ"); if (length(idx1) > 0) as.numeric(coef[idx1[1]]) else 0 }, 
    base2 = { idx2 <- which(term  ==  "educ_2"); if (length(idx2) > 0) as.numeric(coef[idx2[1]]) else 0 }, 
    coef_adj = case_when( 
      cohort == "1980s" & term == "educ" ~ (base1 + coef),
      cohort == "1980s" & term == "educ_2" ~ (base2 + coef),
      cohort == "1950s" ~ coef,
      TRUE ~ NA_real_)
  ) %>%
  ungroup() %>%
  left_join(median_wage, by = c("country", "cohort_5")) %>%
  select(country, cohort, outcome, term, coef_adj, median_wage) %>%
  pivot_wider(names_from = term, values_from = coef_adj) %>%
  dplyr::cross_join(data.frame(year = 1:16)) %>%
  mutate(pred = (educ * year) + (educ_2 * (year^2)),
         marginal_return = educ + (2 * educ_2 * year)) %>%
  select(country, cohort, outcome, year, pred, marginal_return, median_wage) %>%
  arrange(country, cohort, year) %>%
  mutate(pred = ifelse(outcome == "Wage", pred / median_wage, pred))

ggplot(returns_educ,
       aes(x = year, y = pred, color = outcome, linetype = cohort, shape = cohort)) +
  geom_point() +
  geom_line() +
  geom_hline(yintercept = 0) +
  scale_linetype_manual(values = c("1950s" = "solid", "1980s" = "dashed")) +
  scale_shape_manual(values = c(16, 17)) +
  scale_color_manual("", values = c("LFP" = "violet", "Wage-Employment" = "orange", "Wage" = "gold")) + 
  facet_wrap(~country) +
  scale_x_continuous(name = "Years of Education", breaks = seq(1, 16, by = 1)) +
  ylab(expression(paste("Predicted ", Delta, " in (i) Prob. for LFP/Wage-Employment / (ii) Log(Wage)"))) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/main/returns_educ.png"), width = 8, height = 6)

#########################################################################################/
#2. Circumstance Return Differentials ####
#########################################################################################/
#########################################################################################/
##2.1 Model & Function Definition####
#########################################################################################/
lm_educ_cat_int_cohort <- function(data, outcome) {# for fully interacted model need also interact age polynomial
  if (any(is.na(data$demo))) {
    model_formula <- paste0(outcome, "~ age + age_2 + cohort_5*educ_cat*female + cohort_5*educ_cat*urban + cohort_5*educ_cat*geo_level_1")
  } else {
    model_formula <- paste0(outcome, "~ age + age_2 + cohort_5*educ_cat*female + cohort_5*educ_cat*urban + cohort_5*educ_cat*demo + cohort_5*educ_cat*geo_level_1")
  }
  max_cohort <- max(as.numeric(data$cohort_5), na.rm = TRUE)
  model <- lm(model_formula, data = data, weights = data$wt_hh)
  # heteroskedasticity-consistent (robust) SEs
  vcov_robust <- sandwich::vcovHC(model, type = "HC3")
  ct <- lmtest::coeftest(model, vcov. = vcov_robust)
  #use HC1 if HC3 fails to compute SEs (e.g. due to small sample size in some cohorts)
  while (is.na(ct["educ_cat1", "Std. Error"])) {
    vcov_robust <- sandwich::vcovHC(model, type = "HC1")
    ct <- lmtest::coeftest(model, vcov. = vcov_robust)
  }
  model_summary <- summary(model) # N & R2
  # heteroskedasticity-consistent (robust) SEs
  model_summary <- summary(model)
  coef <- ct[, "Estimate"]
  se <- ct[, "Std. Error"]
  prob_coef <- ct[, "Pr(>|t|)"]
  #margins_educ_cat <- summary(margins(model, variables = c("educ_cat")))[, 1:3] %>%  dplyr::rename(term = factor)
  prob_equal_educ_cat <- linearHypothesis(model, "educ_cat1 = educ_cat2", singular.ok = TRUE)
  prob_equal_female <- linearHypothesis(model, "educ_cat1:female1 = educ_cat2:female1", singular.ok = TRUE)
  prob_equal_urban <- linearHypothesis(model, "educ_cat1:urban1 = educ_cat2:urban1", singular.ok = TRUE)
  prob_equal_cohort_educ_cat <- linearHypothesis(model, 
    paste0("cohort_5", max_cohort, ":educ_cat1 = cohort_5", max_cohort, ":educ_cat2"),
    singular.ok = TRUE)
  prob_equal_cohort_female <- linearHypothesis(model,
    paste0("cohort_5", max_cohort, ":educ_cat1:female1 = cohort_5", max_cohort, ":educ_cat2:female1"),
    singular.ok = TRUE)
  prob_equal_cohort_urban <- linearHypothesis(model,
    paste0("cohort_5", max_cohort, ":educ_cat1:urban1 = cohort_5", max_cohort, ":educ_cat2:urban1"),
    singular.ok = TRUE)
  prob_equal <- data.frame(rbind(
    c("Mean Outcome", mean(data[[outcome]]), NA, NA),
    c("N", length(model_summary$residuals), NA, NA),
    c("educ_cat1 = educ_cat2", prob_equal_educ_cat$"Pr(>F)"[2], NA, NA),
    c("educ_cat1:female1 = educ_cat2:female1", prob_equal_female$"Pr(>F)"[2], NA, NA),
    c("educ_cat1:urban1 = educ_cat2:urban1", prob_equal_urban$"Pr(>F)"[2], NA, NA),
    c(paste0("cohort_5", max_cohort, ":educ_cat1 = educ_cat2"), prob_equal_cohort_educ_cat$"Pr(>F)"[2], NA, NA),
    c(paste0("cohort_5", max_cohort, ":educ_cat1:female1 = educ_cat2:female1"), prob_equal_cohort_female$"Pr(>F)"[2], NA, NA),
    c(paste0("cohort_5", max_cohort, ":educ_cat1:urban1 = educ_cat2:urban1"), prob_equal_cohort_urban$"Pr(>F)"[2], NA, NA)
  ))

  colnames(prob_equal) = c("term", "coef", "se", "prob_coef")
  return(
    rbind(
      tibble(
        term = names(coef),
        coef = coef,
        se = se,
        prob_coef = prob_coef),
      prob_equal
    )
  )
}

run_lm <- function(data, outcome, lm_type) {
  lm_reg <-  lm_type
  data <- data %>% filter(!is.na(educ_cat), !is.na(.data[[outcome]]), !is.na(cohort_5))
  if (outcome  ==  "wage") {
    data <- data %>% mutate(wage = log(wage)) %>% 
      # adjust cohorts (sample size) and log wages
      filter(!(cohort_5 <=   2 & (country  ==  "Bangladesh" | country  ==  "Pakistan"))) %>%
      filter(!(cohort_5 >=   7 & (country  ==  "Sri Lanka"))) 
  }
  data <- data %>%
  mutate_at(vars(educ_cat, cohort_5, female, urban, demo, geo_level_1), ~factor(.)) %>%
  group_by(country) %>%
  nest() %>% 
  mutate(model_results = purrr::map(data, .f = ~lm_reg(.x, outcome = outcome))) %>%
  unnest(model_results) %>% select(-data) %>%
  mutate(across(-1, as.numeric)) %>%
  mutate(educ_cat = as.numeric(str_replace(str_extract(term, "educ_cat\\d+"), "educ_cat", ""))) %>%
  mutate(cohort = as.numeric(str_replace(str_extract(term, "cohort_5\\d+"), "cohort_5", ""))) %>%
  group_by(country) %>%
  mutate(cohort = ifelse(is.na(cohort), min(cohort, na.rm = TRUE)-1, cohort)) %>%
  mutate(max_cohort = max(cohort, na.rm = TRUE), min_cohort = min(cohort, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(educ_cat = factor(educ_cat, levels = c(1, 2), labels = c("Primary Education", "Secondary/Higher Education")),
         cohort = factor(cohort, levels = names(cohort_5_lab), labels = cohort_5_lab),
         circ = case_when(
          grepl("female", term) ~ "female",
          grepl("demo", term) ~ "demo",
          grepl("urban", term) ~ "urban",
          grepl("geo_level", term) ~ "geo_level",
          TRUE ~ "base")
  )
}

adj_coef <- function(data) {
  data <- data %>%
    filter((term  ==  "educ_cat1" | term  ==  "educ_cat2") | (grepl("educ_cat", term))) %>%
    group_by(country) %>%
    mutate(
      base1 = { idx1 <- which(term  ==  "educ_cat1"); if (length(idx1) > 0) as.numeric(coef[idx1[1]]) else 0 },
      base2 = { idx2 <- which(term  ==  "educ_cat2"); if (length(idx2) > 0) as.numeric(coef[idx2[1]]) else 0 },
      female1 = { idx1 <- which(term  ==  "educ_cat1:female1"); if (length(idx1) > 0) as.numeric(coef[idx1[1]]) else 0 },
      female2 = { idx2 <- which(term  ==  "educ_cat2:female1"); if (length(idx2) > 0) as.numeric(coef[idx2[1]]) else 0 },
      urban1 = { idx1 <- which(term  ==  "educ_cat1:urban1"); if (length(idx1) > 0) as.numeric(coef[idx1[1]]) else 0 },
      urban2 = { idx2 <- which(term  ==  "educ_cat2:urban1"); if (length(idx2) > 0) as.numeric(coef[idx2[1]]) else 0 },
      coef_adj = case_when(
        grepl(":educ_cat1", term) ~ (base1 + coef),
        grepl(":educ_cat2", term) ~ (base2 + coef),
        grepl(":educ_cat1:female1", term) ~ (female1 + coef),
        grepl(":educ_cat2:female1", term) ~ (female2 + coef),
        grepl(":educ_cat1:urban1", term) ~ (urban1 + coef),
        grepl(":educ_cat2:urban1", term) ~ (urban2 + coef),
        term %in% c("educ_cat1", "educ_cat2",
          "educ_cat1:female1", "educ_cat2:female1",
          "educ_cat1:urban1", "educ_cat2:urban1") ~ coef,
        TRUE ~ NA_real_ )
    ) %>%
    ungroup() %>%
    select(country, cohort, term, educ_cat, circ, coef, coef_adj, se)
  return(data)
}

#########################################################################################/
##2.2 Estimation ####
#########################################################################################/
if(restimation == TRUE){
  lm_paidwage_educ_cat_cohort <- run_lm(data_labor, "paidwage", lm_educ_cat_int_cohort)
  lm_lfp_educ_cat_cohort <- run_lm(data_labor, "lfp", lm_educ_cat_int_cohort)
  lm_wage_educ_cat_cohort <- run_lm(data_labor, "wage", lm_educ_cat_int_cohort)
  save(lm_paidwage_educ_cat_cohort, file = paste0(path_results, "/lm_paidwage_educ_cat_cohort.RData"))
  save(lm_lfp_educ_cat_cohort, file = paste0(path_results, "/lm_lfp_educ_cat_cohort.RData"))
  save(lm_wage_educ_cat_cohort, file = paste0(path_results, "/lm_wage_educ_cat_cohort.RData"))
} else {
  load(paste0(path_results, "/lm_paidwage_educ_cat_cohort.RData"))
  load(paste0(path_results, "/lm_lfp_educ_cat_cohort.RData"))
  load(paste0(path_results, "/lm_wage_educ_cat_cohort.RData"))
}

#########################################################################################/
##2.3 Graphs####
#########################################################################################/
#LFP vs. Wage-Employment
ggplot(rbind(
      adj_coef(lm_lfp_educ_cat_cohort) %>% mutate(outcome = "LFP"),
      adj_coef(lm_paidwage_educ_cat_cohort) %>% mutate(outcome = "Wage-Employment")
      ) %>% filter(circ == "base", !grepl(" = ", term)), 
    aes(x = as.numeric(cohort), y = coef_adj, color = outcome, linetype = educ_cat, shape = educ_cat)) +
  geom_point() +
  geom_errorbar(
    aes(ymin = coef_adj - se, ymax = coef_adj + se, linetype = educ_cat),
    width = 0.2
  ) +
  geom_line(aes(color = outcome, linetype = educ_cat)) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("LFP" = "violet", "Wage-Employment" = "orange")) + 
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  facet_wrap(~country) +
  scale_y_continuous(limits = c(-0.3, 1), breaks = c(-0.3, 0, 0.3, 0.6, 0.9)) +
  ylab(expression(paste(beta, "'s for LFP / Wage-Employment")))+ xlab("Birth Cohorts") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/main/lm_lfp_paidwage_educ_cat.png"), width = 8, height = 6)

#LFP vs. Wage-Employment - female
ggplot(rbind(
      adj_coef(lm_lfp_educ_cat_cohort) %>% mutate(outcome = "LFP"),
      adj_coef(lm_paidwage_educ_cat_cohort) %>% mutate(outcome = "Wage-Employment")
      ) %>% filter(circ == "female", !grepl(" = ", term)), 
    aes(x = as.numeric(cohort), y = coef_adj, color = outcome, linetype = educ_cat, shape = educ_cat)) +
  geom_point() +
  geom_errorbar(
    aes(ymin = coef_adj - se, ymax = coef_adj + se, linetype = educ_cat),
    width = 0.2
  ) +
  geom_line(aes(color = outcome, linetype = educ_cat)) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("LFP" = "violet", "Wage-Employment" = "orange")) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  facet_wrap(~country) +
  scale_y_continuous(limits = c(-0.3, 1), breaks = c(-0.3, 0, 0.3, 0.6, 0.9)) +
  ylab(expression(paste(pi[1], "'s & ", rho[1], "'s for LFP/ Wage-Employment"))) +
  xlab("Birth Cohorts") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/main/lm_lfp_paidwage_female.png"), width = 8, height = 6)

#LFP vs. Wage-Employment - urban
ggplot(rbind(
      adj_coef(lm_lfp_educ_cat_cohort) %>% mutate(outcome = "LFP"),
      adj_coef(lm_paidwage_educ_cat_cohort) %>% mutate(outcome = "Wage-Employment")
      ) %>% filter(circ == "urban", !grepl(" = ", term)),
    aes(x = as.numeric(cohort), y = coef_adj, color = outcome, linetype = educ_cat, shape = educ_cat)) +
  geom_point() +
  geom_errorbar(
    aes(ymin = coef_adj - se, ymax = coef_adj + se, linetype = educ_cat),
    width = 0.2
  ) +
  geom_line(aes(color = outcome, linetype = educ_cat)) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("LFP" = "violet", "Wage-Employment" = "orange")) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  facet_wrap(~country) +
  scale_y_continuous(limits = c(-0.3, 1), breaks = c(-0.3, 0, 0.3, 0.6, 0.9)) +
  ylab(expression(paste(pi[2], "'s & ", rho[2], "'s for LFP/ Wage-Employment"))) +
  xlab("Birth Cohorts") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/lm_lfp_paidwage_urban.png"), width = 8, height = 6)

#########################################################################################/
#3. Output Tables ####
#########################################################################################/
output_reg_tex <- function(reg_type, outcome) {
  lm_raw <- get(paste0("lm_", outcome, "_educ_cat_", reg_type))
  # add significance stars and format coefficients
  lm_raw <- lm_raw %>%
    mutate(
      stars = cut(prob_coef, breaks = c(-Inf, 0.01, 0.05, 0.1, Inf), labels = c("***", "**", "*", ""), right = FALSE),
      coef_raw = coef,
      coef = case_when(
        term  ==  "Mean Outcome" ~ sprintf("%.3f", coef),
        term  ==  "N" ~ paste0("\\text{", round(coef), "}"),
        term  ==  "adj. R$^2$" ~ sprintf("%.3f", coef),
        grepl(" = ", term) ~ sprintf("%.3f", coef),
        is.na(coef) ~ NA_character_,
        prob_coef > 0.1 ~ paste0(sprintf("%.3f", coef)),
        TRUE ~ paste0(sprintf("%.3f", coef), "\\sym{", stars, "}")
      ),
      prob_coef = ifelse(is.na(prob_coef), NA_character_, sprintf("%.3f", prob_coef)))

  # build output table with first and last cohort
  countries <- sort(unique(lm_raw$country))
  for (i in seq_along(countries)) {
    country_i <- countries[i]
    t0 <- lm_raw %>% 
      filter(country  ==  country_i) %>% ungroup() %>%
      filter(as.numeric(cohort)  ==  min_cohort) %>% ungroup() %>%
      select(term, coef, prob_coef) %>%
      rename_with(~ paste0(i, ., "_t0"), .cols = -c(term))
    t1 <- lm_raw %>% 
      filter(country  ==  country_i) %>% ungroup() %>%
      filter(as.numeric(cohort)  ==  max_cohort) %>% ungroup() %>%
      mutate(term = gsub(paste0("cohort_5", max_cohort, ":"), "", term), 
            term = ifelse(term == paste0("cohort_5", max_cohort), "(Intercept)", term)) %>%
      select(term, coef, prob_coef) %>%
      rename_with(~ paste0(i, ., "_t1"), .cols = c("coef", "prob_coef"))
    empty_rows <- as.data.frame(matrix(NA, nrow = 3, ncol = ncol(t1)))
    colnames(empty_rows) <- colnames(t1)
    t1_adj <- dplyr::bind_rows(empty_rows, t1)
    t01 <- left_join(t0, t1_adj) %>% mutate(term = case_when(
      grepl("demo\\d", term) ~ sub("(demo)\\d", "\\1", term), 
      grepl("geo_level_1\\d", term) ~ sub("(geo_level_1)\\d", "\\1", term),
      TRUE ~ term ))
    if (i  ==  1) {
      tab_t01 <- t01
    } else {
      tab_t01 <- full_join(tab_t01, t01, by = "term")
    }
  }

  # adjust demo omission and keep row with fewest NAs when terms duplicate
  if (all(c("demo1", "demo2") %in% tab_t01$term)) {
    idx1 <- which(tab_t01$term  ==  "demo1")[1]
    idx2 <- which(tab_t01$term  ==  "demo2")[1]
    idx11 <- which(tab_t01$term  ==  "educ_cat1:demo1")[1]
    idx21 <- which(tab_t01$term  ==  "educ_cat1:demo2")[1]
    idx12 <- which(tab_t01$term  ==  "educ_cat2:demo1")[1]
    idx22 <- which(tab_t01$term  ==  "educ_cat2:demo2")[1]
    cols <- setdiff(names(tab_t01), "term")
    pairs <- list(
      c(from = idx1, to = idx2),
      c(from = idx11, to = idx21),
      c(from = idx12, to = idx22)
    )

    for (p in pairs) {
      from_idx <- p["from"]
      to_idx <- p["to"]
      if (!is.na(from_idx) && !is.na(to_idx)) {
      for (col in cols) {
        if (is.na(tab_t01[to_idx, col]) && !is.na(tab_t01[from_idx, col])) {
        tab_t01[to_idx, col] <- tab_t01[from_idx, col]
        }
      }
      }
    }
    tab_t01 <- tab_t01 %>% filter(term  !=  "demo1", term  !=  "educ_cat1:demo1", term  !=  "educ_cat2:demo1")
  }

  if(reg_type == "cohort") {
    desired_order <- c(
      "(Intercept)", "age", "age_2", "educ_cat1", "educ_cat2",  "female1", "urban1",
      paste0("demo", 2:5),
      paste0("geo_level_1", 2:9),
      "educ_cat1:female1", "educ_cat2:female1", "educ_cat1:urban1", "educ_cat2:urban1",
      paste0("educ_cat1:demo", 2:5), paste0("educ_cat2:demo", 2:5),
      paste0("educ_cat1:geo_level_1", 2:9), paste0("educ_cat2:geo_level_1", 2:9),
      "educ_cat1 = educ_cat2", "educ_cat1:female1 = educ_cat2:female1", "educ_cat1:urban1 = educ_cat2:urban1", "N"
    )
  }
  if (reg_type  ==  "convex") {
    desired_order <- c(
      "(Intercept)", "educ", "educ_2", "age", "age_2", "female1", "urban1",
      paste0("demo", 2:5), 
      paste0("geo_level_1", 2:9)
    )
  }

  term_order <- function(term_val) {
    match_index <- match(term_val, desired_order)
    return(match_index)
  }

  tab_t01 <- tab_t01 %>%
    mutate(order_val = sapply(term, term_order)) %>%
    arrange(order_val) %>%
    select(-order_val) %>%
    mutate(
      term = gsub("(Intercept)", "Intercept (differential Cohort FE)", term),
      term = gsub("N", "$N_{total}$", term),
      term = gsub("educ_cat1 = educ_cat2", "$\\beta_1 = \\beta_2$", term),
      term = gsub("educ_cat1:female1 = educ_cat2:female1", "$\\pi_{female} = \\rho_{female}$", term),
      term = gsub("educ_cat1:urban1 = educ_cat2:urban1", "$\\pi_{urban} = \\rho_{urban}$", term),
      term = gsub("educ_2", "Education$^2$", term),
      term = gsub("educ_cat1", "Primary", term),
      term = gsub("educ_cat2", "Secondary", term),
      term = gsub("educ", "Education", term),
      term = gsub("age_2", "Age$^2$", term),
      term = gsub("age", "Age", term),
      term = gsub("female1", "Female", term),
      term = gsub("urban1", "Urban", term),
      term = gsub("demo", "Dem. Group", term),
      term = gsub("geo_level_1", "Region", term),
      term = gsub(":", " x ", term))

  addtorow <- list()
  addtorow$pos = { if (reg_type != "convex") list(0, 0, 0, nrow(tab_t01)-5) else list(0, 0, 0, nrow(tab_t01)-3)}

  cohort_summary <- lm_raw %>%
    group_by(country) %>%
    summarise(label_min = min(as.numeric(cohort)), label_max = max(as.numeric(cohort)), .groups = 'drop') %>%
    mutate(label_min = factor(label_min, levels = names(cohort_5_lab), labels = cohort_5_lab),
          label_max = factor(label_max, levels = names(cohort_5_lab), labels = cohort_5_lab))
  labels_cohort <- data.frame(country = sort(unique(lm_raw$country))) %>%
    left_join(cohort_summary, by = "country") %>%
    select(label_min, label_max) %>%
    pivot_longer(cols = everything(), names_to = "type", values_to = "label") %>%
    pull(label)
  col_labels_cohort <- sapply(labels_cohort, function(label) {paste0(" & \\multicolumn{2}{c}{", label, "}")})
  col_labels_cohort_str <- paste0(paste(col_labels_cohort, collapse = ""), " \\\\\n")

  if(outcome == "lfp"){addtorow$command <- c("& \\multicolumn{4}{c}{Afghanistan} & \\multicolumn{4}{c}{Bangladesh} & \\multicolumn{4}{c}{Bhutan} & \\multicolumn{4}{c}{India} & \\multicolumn{4}{c}{Pakistan} & \\multicolumn{4}{c}{Sri Lanka}  \\\\\n", 
                        paste0( "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13} \\cmidrule(lr){14-17} \\cmidrule(lr){18-21} \\cmidrule(lr){22-25}", col_labels_cohort_str), 
                        "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9} \\cmidrule(lr){10-11} \\cmidrule(lr){12-13} \\cmidrule(lr){14-15} \\cmidrule(lr){16-17} \\cmidrule(lr){18-19} \\cmidrule(lr){20-21} \\cmidrule(lr){22-23} \\cmidrule(lr){24-25}
                        Variable & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} \\\\\n", 
                        "\\hline \n")
                    n_col = 12
  }
  if(outcome == "paidwage"){addtorow$command <- c("& \\multicolumn{4}{c}{Afghanistan} & \\multicolumn{4}{c}{Bangladesh} & \\multicolumn{4}{c}{Bhutan} & \\multicolumn{4}{c}{India} & \\multicolumn{4}{c}{Nepal} & \\multicolumn{4}{c}{Pakistan} & \\multicolumn{4}{c}{Sri Lanka}  \\\\\n", 
                          paste0( "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13} \\cmidrule(lr){14-17} \\cmidrule(lr){18-21} \\cmidrule(lr){22-25}", col_labels_cohort_str), 
                          "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9} \\cmidrule(lr){10-11} \\cmidrule(lr){12-13} \\cmidrule(lr){14-15} \\cmidrule(lr){16-17} \\cmidrule(lr){18-19} \\cmidrule(lr){20-21} \\cmidrule(lr){22-23} \\cmidrule(lr){24-25} \\cmidrule(lr){26-27} \\cmidrule(lr){28-29}
                          Variable & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} \\\\\n", 
                          "\\hline \n")
                        n_col = 14
  }
  if(outcome == "wage"){addtorow$command <- c("& \\multicolumn{4}{c}{Bangladesh}  & \\multicolumn{4}{c}{India} & \\multicolumn{4}{c}{Pakistan} & \\multicolumn{4}{c}{Sri Lanka}  \\\\\n", 
                        paste0( "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13} \\cmidrule(lr){14-17}", col_labels_cohort_str), 
                        "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9} \\cmidrule(lr){10-11} \\cmidrule(lr){12-13} \\cmidrule(lr){14-15} \\cmidrule(lr){16-17}
                        Variable & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} & \\multicolumn{1}{l}{Coef.} &  \\multicolumn{1}{l}{p-value} \\\\\n", 
                        "\\hline \n")
                        n_col = 8
  }
  output_raw <- print(xtable(tab_t01, NA.string = ""), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow, booktabs = TRUE,  # align = alignment, 
        sanitize.text.function = function(x){ x }, floating = FALSE, file = "")
  output_name = { if (reg_type == "cohort") paste0("/annex/reg_", outcome, "_educ_cat.tex") else paste0("/annex/reg_", outcome, "_educ_years.tex")}
  replacement <- paste0("\\1{l *{", n_col, "}{S[table-format = 1.3(3)]S[table-format = 1.3]}}")
  output <- sub("(\\\\begin\\{tabular\\})\\{(.*?)\\}", replacement, output_raw)
  cat(output, file = paste0(path_tables, output_name), sep = "\n")
}

output_reg_tex("cohort", "lfp")
output_reg_tex("cohort", "paidwage") 
output_reg_tex("cohort", "wage") 
output_reg_tex("convex", "lfp")
output_reg_tex("convex", "paidwage") 
output_reg_tex("convex", "wage") 

#########################################################################################/
#4. Evolution LPF & Wage-Employment across Cohorts####
#########################################################################################/
if(restimation == TRUE){
  lfp_paidwage_shares <- data_labor %>%
    mutate(employment = case_when(
      lfp  ==  0 ~ "0", 
      lfp  ==  1 & paidwage  ==  0 ~ "2", 
      (lfp  ==  1 & paidwage  ==  1) | (paidwage  ==  1 & country == "Nepal") ~ "3",
      paidwage  ==  0 & country == "Nepal" ~ "1",
      TRUE ~ NA_character_
    )) %>%
    filter(!is.na(employment) & !is.na(cohort_5)) %>%
    group_by(country, cohort_5, employment) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(country, cohort_5) %>%
    mutate(share = n / sum(n)) %>%
    ungroup() %>%
    mutate(employment = factor(employment, levels = c("0", "1", "2", "3")))
  save(lfp_paidwage_shares, file = paste0(path_results, "/lfp_paidwage_shares.RData"))
} else {
  load(paste0(path_results, "/lfp_paidwage_shares.RData"))
}

ggplot(lfp_paidwage_shares, aes(x = cohort_5, y = share, fill = employment)) +
  geom_col(position = position_stack(reverse = TRUE)) +
  facet_wrap(~country) +
  scale_x_continuous(name = "Birth Cohort", breaks = seq(1, 10, 1), labels = cohort_5_lab) +
  ylab("Population Share (35-54 years old)") +
  scale_fill_manual("", values = c("0" = "grey80",
                                   "1" = "grey50",
                                   "2" = "violet",
                                   "3" = "orange"),
                        labels = c("0" = "Inactive",
                                   "1" = "Inactive/no Wage-Employment (Nepal)",
                                   "2" = "Active no Wage-Employment",
                                   "3" = "Wage-Employment")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        axis.line = element_line(color = "black"),
        legend.position = c(.8, .1),
        panel.background = element_blank())
ggsave(paste0(path_figures, "/annex/lfp_paidwage_shares.png"), width = 10, height = 6)