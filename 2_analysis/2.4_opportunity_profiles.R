#########################################################################################/
# Overview####
#title: "2.4_opportunity_profiles.R"
#author: "Fabian Reutzel"
#########################################################################################/
#########################################################################################/
#1. Profile Estimation #####
#########################################################################################/
if(restimation == TRUE){
  if(outcome_dim == "all" | outcome_dim == "educ"){
    out <- c("prim", "uppsec", "educ")
    profiles_educ_cs4        <- profiles(data_educ, circumstances_cs4, outcome = "educ", estimation = "para", type = "cohort_5", boot_n)
    profiles_prim_cs4        <- profiles(data_educ, circumstances_cs4, outcome = "prim", estimation = "para", type = "cohort_5", boot_n)
    profiles_uppsec_cs4      <- profiles(data_educ, circumstances_cs4, outcome = "uppsec", estimation = "para", type = "cohort_5", boot_n)
    save(profiles_educ_cs4, file = paste0(path_results, "/profiles_educ_cs4.RData"))
    save(profiles_prim_cs4, file = paste0(path_results, "/profiles_prim_cs4.RData"))
    save(profiles_uppsec_cs4, file = paste0(path_results, "/profiles_uppsec_cs4.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "cons"){
    out <- c("cons")
    profiles_cons_cs3     <- profiles(data_cons %>% 
                                        filter(!((year == 1993) & (country == "India"))) %>% #exclude first survey due to different demo granularity
                                        mutate(hh_cons_wb = ifelse(country != "India", hh_cons_wb, ifelse(cohort_5 >= 6, NA, hh_cons_wb_old))), #use old measure for 1970-74 for comparability
                                      circumstances_cs3, outcome = "hh_cons_wb", estimation = "para", type = "cohort_5", boot_n)
    save(profiles_cons_cs3, file = paste0(path_results, "/profiles_cons_cs3.RData"))
  }
  if(outcome_dim == "all" | outcome_dim == "labor"){
    out <- c("lfp", "paidwage", "wage")
    profiles_lfp_cs4          <- profiles(data = data_labor, circumstances = circumstances_cs4, outcome = "lfp", estimation = "para", type = "cohort_5", boot_n)
    profiles_paidwage_cs4     <- profiles(data_labor, circumstances_cs4, outcome = "paidwage", estimation = "para", type = "cohort_5", boot_n)
    profiles_wage_cs4         <- profiles(data_labor, circumstances_cs4, outcome = "wage", estimation = "para", type = "cohort_5", boot_n)
    save(profiles_lfp_cs4, file = paste0(path_results, "/profiles_lfp_cs4.RData"))
    save(profiles_paidwage_cs4, file = paste0(path_results, "/profiles_paidwage_cs4.RData"))
    save(profiles_wage_cs4, file = paste0(path_results, "/profiles_wage_cs4.RData"))
  }
} else {
  load(paste0(path_results, "/profiles_educ_cs4.RData"))
  load(paste0(path_results, "/profiles_prim_cs4.RData"))
  load(paste0(path_results, "/profiles_cons_cs3.RData"))
  load(paste0(path_results, "/profiles_lfp_cs4.RData"))
  load(paste0(path_results, "/profiles_paidwage_cs4.RData"))
  load(paste0(path_results, "/profiles_wage_cs4.RData"))
}

#########################################################################################/
#2. Profile Figures#####
#########################################################################################/
if(outcome_dim == "all"){out <- c("cons", "prim", "educ", "lfp", "paidwage", "wage")}
for (o in 1 : length(out)){
  #load results
  if(out[o] != "cons"){prof_raw <- get(paste0("profiles_", out[o], "_cs4"))}
  if(out[o] == "cons"){prof_raw <- get(paste0("profiles_", out[o], "_cs3"))}

  #define minimum type size restriction
  n_min <- ifelse(out[o] != "cons" & out[o] != "wage", 20, 15)

  #select t0 & t1
  if(out[o] == "wage"){prof_raw <- prof_raw %>%  #adjust for small sample size in early/late cohorts
    filter(!(year <= 2 & (country == "Bangladesh" | country == "Pakistan"))) %>%
    filter(!(year >= 7 & (country == "Sri Lanka")))
  }
  if(out[o] == "cons"){prof_raw <- prof_raw %>%  #adjust for small sample size in early/late cohorts
    filter(!((year < 2) & (country == "Bangladesh"))) %>%
    filter(!((year < 2) & (country == "India"))) %>%
    filter(!((year <= 2 | year == 7)& (country == "Pakistan"))) %>%
    filter(!((year >= 7 | year == 1) & country == "Sri Lanka"))
  }
  prof_0 <- prof_raw %>% group_by(country) %>% filter(year == min(year))
  prof_1 <- prof_raw %>% group_by(country) %>% filter(year == max(year))
  #apply sample size restriction
  prof_0 <- prof_0 %>% filter(N >= n_min & is.na(y_hat_p) != 1)
  prof_1 <- prof_1 %>% filter(N >= n_min & is.na(y_hat_p) != 1)

  #generate type restriction (only keep types present in both cohorts with both genders)
  if (out[o] == "educ" | out[o] == "prim"){
    type_rest_0 <- prof_0 %>%
      group_by(country, demo, urban, geo_level_1) %>%
      summarise(n_female = sum(female == 1, na.rm = TRUE),
                n_male   = sum(female == 0, na.rm = TRUE),
                .groups = "drop") %>%
      filter(n_female > 0 & n_male > 0) %>%
      select(country, demo, urban, geo_level_1)
    type_rest_1 <- prof_1 %>%
      group_by(country, demo, urban, geo_level_1) %>%
      summarise(n_female = sum(female == 1, na.rm = TRUE),
                n_male   = sum(female == 0, na.rm = TRUE),
                .groups = "drop") %>%
      filter(n_female > 0 & n_male > 0) %>%
      select(country, demo, urban, geo_level_1)
    type_rest_01 <- inner_join(type_rest_0, type_rest_1, by = c("country", "demo", "urban", "geo_level_1"))
    prof_0 <- prof_0 %>% inner_join(type_rest_01, by = c("country", "demo", "urban", "geo_level_1"))
  }
  #generate type restriction (only keep types present in both cohorts)
if (out[o] != "educ" & out[o] != "prim"){
  type_rest_0 <- prof_0 %>% select(country, type)
  type_rest_1 <- prof_1 %>% select(country, type)
  type_rest_01 <- inner_join(type_rest_0, type_rest_1, by = c("country", "type"))
  prof_0 <- prof_0 %>% inner_join(type_rest_01, by = c("country", "type"))
  }

  #calculate median outcome in t0 & type_id_harm
  prof_0 <- prof_0 %>%
    group_by(country) %>%
    mutate(country_median = weightedMedian(y_hat_p, w = N)) %>%
    arrange(country, y_hat_p) %>%
    mutate(type_id = row_number())  %>%
    mutate(type_id_harm = ((type_id-1)/max(type_id-1)*100))

  #Opportunity Profile in t0 (incl. type_id_harm)
  prof_0_std <- prof_0 %>%
    group_by(country) %>%
    mutate(std_y_hat_p = y_hat_p/country_median,
            std_y_hat_l = y_hat_l/country_median,
            std_y_hat_u = y_hat_u/country_median) %>%
    mutate(urban = factor(ifelse(grepl("U-", type), 1, 0), labels = c("0" = "Rural", "1" = "Urban")))
  if(out[o] != "cons"){prof_0_std <- prof_0_std %>% mutate(female = factor(ifelse(grepl("♀", type), 1, 0), labels = c("0" = "♂", "1" = "♀")))}

  #add type_id to t1
  prof_1 <- inner_join(prof_1, prof_0 %>% select(c("country", "type", "type_id_harm", "country_median")), by = c("country", "type")) 

  ##generate change dataset
  prof_change <- inner_join(prof_1, prof_0, by = c("country", "type", "type_id_harm"))
  #standardize outcome (consumption/wage) + compute change/growth
  if(out[o] == "cons" | out[o] == "wage"){
    prof_change <- prof_change %>%
      mutate(y_hat_p_ratio.x = y_hat_p.x/country_median.x, y_hat_l_ratio.x = y_hat_l.x/country_median.x, y_hat_u_ratio.x = y_hat_u.x/country_median.x,
              y_hat_p_ratio.y = y_hat_p.y/country_median.y, y_hat_l_ratio.y = y_hat_l.y/country_median.y, y_hat_u_ratio.y = y_hat_u.y/country_median.y) %>%
      mutate(change_y_hat_p_ratio = y_hat_p_ratio.x-y_hat_p_ratio.y, change_y_hat_u_ratio = y_hat_u_ratio.x-y_hat_u_ratio.y, change_y_hat_l_ratio = y_hat_l_ratio.x-y_hat_l_ratio.y, 
              change_y_hat_p = y_hat_p.x-y_hat_p.y, change_y_hat_u = y_hat_u.x-y_hat_u.y, change_y_hat_l = y_hat_l.x-y_hat_l.y,
              growth_y_hat_p = (change_y_hat_p/y_hat_p.y)*100, growth_y_hat_u = (change_y_hat_u/y_hat_u.y)*100, growth_y_hat_l = (change_y_hat_l/y_hat_l.y)*100)
  }
  if(out[o] != "cons" & out[o] != "wage"){
    prof_change <- prof_change %>%
      mutate(change_y_hat_p = y_hat_p.x-y_hat_p.y, change_y_hat_u = y_hat_u.x-y_hat_u.y, change_y_hat_l = y_hat_l.x-y_hat_l.y,
              growth_y_hat_p = (change_y_hat_p/y_hat_p.y)*100, growth_y_hat_u = (change_y_hat_u/y_hat_u.y)*100, growth_y_hat_l = (change_y_hat_l/y_hat_l.y)*100)
  }

  prof_change <- prof_change %>%
    #topcode growth rate at 300%
    mutate(growth_y_hat_p = ifelse(growth_y_hat_p<300, growth_y_hat_p, 300),
            growth_y_hat_u = ifelse(growth_y_hat_u<300, growth_y_hat_u, 300),
            growth_y_hat_l = ifelse(growth_y_hat_l>-300, growth_y_hat_l, -300),
            growth_y_hat_l = ifelse(growth_y_hat_l<300, growth_y_hat_l, 300)) %>%
    filter(is.na(change_y_hat_p) != 1) %>%
    mutate(urban = factor(ifelse(grepl("U-", type), 1, 0), labels = c("0" = "Rural", "1" = "Urban")))
  if(out[o] != "cons"){prof_change <- prof_change %>% mutate(female = factor(ifelse(grepl("♀", type), 1, 0), labels = c("0" = "♂", "1" = "♀")))}

  #combine profiles (t0, t1) in one graph with ordering of t0
  prof_01_adj <- rbind(prof_0, prof_1) %>%
    mutate(std_y_hat_p = y_hat_p/country_median,
           std_y_hat_l = y_hat_l/country_median,
           std_y_hat_u = y_hat_u/country_median) %>%
    #harmonize year labels
    group_by(country) %>%
    mutate(year = ifelse(year == min(year), 0, 1)) %>%
    ungroup()
  if(out[o] == "educ" | out[o] == "prim"){prof_01_adj <- prof_01_adj %>% mutate(year = factor(year, levels = c(0, 1), labels = c("1950s", "1990s")))}
  if(out[o] != "educ" & out[o] != "prim"){prof_01_adj <- prof_01_adj %>% mutate(year = factor(year, levels = c(0, 1), labels = c("1950s", "1980s")))}
  if(out[o] != "cons"){prof_01_adj <- prof_01_adj %>% mutate(female = factor(ifelse(grepl("♀", type), 1, 0), labels = c("0" = "♂", "1" = "♀")))}

  #set figure parameters
  scale_y_limits = c(0, ifelse(max(prof_0_std$y_hat_p)<= 1, 1, max(prof_0_std$y_hat_p)))
  scale_y_limits_std = c(0, max(prof_0_std$std_y_hat_p))

  country <- unique(prof_0_std$country)
  #adjust legend position
  if(length(country)!=6 & length(country)!=4){legend_position = c(.8, .15)} else {legend_position = "bottom"}

  ###2.1 Opportunity Profile in t0####
  if(out[o] == "cons"){ #difference across urban/rural
    ggplot(prof_0_std, 
            aes(x = type_id_harm, y = std_y_hat_p, color = urban, shape = urban, group = country)) +
      geom_point(aes(color = urban), size = 2) +
      scale_shape_manual("", values = c(4, 19), labels = c("Rural", "Urban")) +
      scale_color_manual("", values = c("green", "darkgreen"), labels = c("Rural", "Urban")) +
      scale_y_continuous(limits = scale_y_limits_std) +
      facet_wrap(~country) +
      ylab("Opportunity Ratio wrt Median Consumption in 1950s") + xlab("Opportunity Groups") +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/annex/prof_", out[o], ".png"), width = 8, height = 6)
  }
  if(out[o] != "cons" & out[o] != "wage" & out[o] != "prim"){
    ggplot(prof_0_std,
            aes(x = type_id_harm, y = y_hat_p, group = country)) +
      geom_point(aes(shape = urban, color = female)) +
      scale_color_manual("", values = c("blue", "red"), labels = c("♂ Male", "♀ Female")) +
      scale_shape_manual("", values = c(4, 19), labels = c("Rural", "Urban")) +
      scale_y_continuous(limits = scale_y_limits) +
      facet_wrap(~country) +
      ylab("Type-Average in 1950s") + xlab("Opportunity Groups") +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    if(out[o] == "educ"){
      ggsave(paste0(path_figures, "/main/prof_", out[o], ".png"), width = 8, height = 6)
    } else {
      ggsave(paste0(path_figures, "/annex/prof_", out[o], ".png"), width = 8, height = 6)
    }
  }
  ###2.2 Growth Incidence & Absolute Change####
  if(out[o] == "educ"){
    ggplot(prof_change,
            aes(x = type_id_harm, y = change_y_hat_p, group = country)) +
      geom_point(aes(shape = urban, color = female)) +
      geom_smooth(method = "loess", se = FALSE, color = "black") +
      scale_color_manual("", values = c("blue", "red"), labels = c("♂ Male", "♀ Female")) +
      scale_shape_manual("", values = c(4, 19), labels = c("Rural", "Urban")) +
      facet_wrap(~country) +
      ylab("Change in Type-Average (1950s-1990s)") + xlab("Opportunity Groups") +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/main/change_5090s_", out[o], ".png"), width = 8, height = 6)
  }
  if(out[o] == "cons"){
    ggplot(prof_change,
            aes(x = type_id_harm, y = growth_y_hat_p, group = country, weight = N.x)) +
      geom_point(aes(color = urban, shape = urban)) +
      geom_smooth(method = "loess", se = FALSE, color = "black") +
      facet_wrap(~country) +
      scale_shape_manual("", values = c(4, 19), labels = c("Rural", "Urban")) +
      scale_color_manual("", values = c("green", "darkgreen"), labels = c("Rural", "Urban")) +
      ylab("Growth rate (1950s-1980s)") + xlab("Opportunity Groups") +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/main/growth_5080s_", out[o], ".png"), width = 8, height = 6)
  }
  ##2.3 CDFs####
  profiles_n <- prof_01_adj %>%
    arrange(country, year, type_id_harm) %>%
    group_by(country, year) %>%
    mutate(n = N / sum(N),
            n_wt = N_wt / sum(N_wt)) %>%
    ungroup()%>%
    group_by(country, type_id_harm) %>%
    mutate(change_n = n[which.max(as.integer(year))] - n[which.min(as.integer(year))],
            growth_n = (n[which.max(as.integer(year))] - n[which.min(as.integer(year))]) / n[which.min(as.integer(year))],
            change_n_wt = n_wt[which.max(as.integer(year))] - n_wt[which.min(as.integer(year))],
            growth_n_wt = (n_wt[which.max(as.integer(year))] - n_wt[which.min(as.integer(year))]) / n_wt[which.min(as.integer(year))]) %>%
    ungroup()
  #CDF by urbanity
  profiles_cdf <- prof_01_adj %>%
    arrange(country, year, type_id_harm) %>%
    group_by(country, year) %>% 
    mutate(cum_pop_share = cumsum(N_wt)/sum(N_wt)) %>%
    ungroup()%>% 
    group_by(country, year, urban) %>% 
    mutate(cum_pop_share_urban = cumsum(N_wt)/sum(N_wt)) %>%
    mutate(cum_pop_share_urban_total = cumsum(N_wt)) %>%
    ungroup()%>% 
    group_by(country, year) %>% 
    mutate(cum_pop_share_urban_total = cum_pop_share_urban_total/sum(N_wt)) %>%
    ungroup()
  #CDF by gender
  if(out[o] != "cons"){profiles_cdf <- profiles_cdf %>%
    group_by(country, year, female) %>% 
    mutate(cum_pop_share_female = cumsum(N)/sum(N)) %>%
    mutate(cum_pop_share_female_total = cumsum(N)) %>%
    ungroup()%>%
    group_by(country, year) %>%
    mutate(cum_pop_share_female_total = cum_pop_share_female_total/sum(N)) %>%
    ungroup()
  }
  if(out[o] == "educ"){
    ggplot(profiles_cdf %>% filter(year == "1950s"),
            aes(x = type_id_harm, y = cum_pop_share_female, color = female)) +
      facet_wrap(~country) +
      geom_point(aes(shape = urban, color = female)) +
      geom_line(aes(y = cum_pop_share), color = "black") +
      geom_line(aes(group = female)) +
      ylab("Population-CDF") + xlab("Opportunity Groups") +
      scale_color_manual("", values = c("blue", "red"), labels = c("♂ Male", "♀ Female")) +
      scale_shape_manual("", values = c(4, 19), labels = c("Rural", "Urban")) +
      scale_linetype_manual(values = c("solid", "dashed")) +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/annex/cdf_", out[o], "_female.png"), width = 8, height = 6)
  }
  if(out[o] == "cons"){
    ggplot(profiles_cdf,
            aes(x = type_id_harm, y = cum_pop_share_urban_total, color = urban, linetype = year)) +
      facet_wrap(~country) +
      geom_point(aes(shape = year)) +
      geom_line(aes(y = cum_pop_share, linetype = year), color = "black") +
      geom_line(aes(group = interaction(urban, year))) +
      geom_text(data = . %>% filter(country == "Bhutan"&type == "U-West"), aes(label = paste0(geo_level_1)), color = "black", vjust = 1, size = 3, show.legend = FALSE) +
      ylab("Total Population-CDF") + xlab("Opportunity Groups") +
      scale_color_manual("", values = c("green", "darkgreen"), labels = c("Rural", "Urban")) + 
      scale_linetype_manual(values = c("solid", "dashed")) +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/annex/cdf_", out[o], "_urban.png"), width = 8, height = 6)
    ggplot(profiles_n %>% filter(year == "1950s"),
            aes(x = type_id_harm, y = growth_n_wt, color = urban, shape = urban)) +
      facet_wrap(~country) +
      geom_point() +
      geom_text(data=. %>% filter(country == "Sri Lanka" & type == "R-Sri Lanka Tamil/Moors-East"), aes(label=paste0(demo, "-", geo_level_1)), color="black", hjust=0.45, vjust=1, size=3, show.legend=FALSE) +
      geom_text(data=. %>% filter(country == "Sri Lanka" & type == "R-Sri Lanka Tamil/Moors-North"), aes(label=paste0(demo, "-", geo_level_1)), color="black", hjust=0.45, vjust=1, size=3, show.legend=FALSE) +
      geom_hline(yintercept = 0, linetype = "solid", color = "gray50") +
      ylab("Growth in Population Share") + xlab("Opportunity Groups") +
      scale_y_continuous(labels = scales::percent) +
      scale_shape_manual("", values = c(4,  19),  labels = c("Rural",  "Urban")) +
      scale_color_manual("", values = c("green", "darkgreen"),  labels = c("Rural",  "Urban")) +
      theme(axis.line = element_line(color = "black"),
            legend.position = legend_position,
            legend.title = element_blank(),
            legend.text = element_text(size = 11),
            panel.background = element_blank())
    ggsave(paste0(path_figures, "/annex/n_growth_", out[o], "_urban.png"), width = 8, height = 6)
  }
}

#########################################################################################/
#3. Table Population Percentiles Education#####
#########################################################################################/
if(outcome_dim == "all" | outcome_dim == "educ"){
  tab_p_educ <- profiles_educ_cs4 %>%
    group_by(country, year) %>%
    summarize(
      #mean_wage = mean(wage, na.rm = TRUE), 
      p25 = quantile(y_hat_p, 0.25, na.rm = TRUE, weights = N_wt),
      median = median(y_hat_p, na.rm = TRUE, weights = N_wt),
      p75 = quantile(y_hat_p, 0.75, na.rm = TRUE, weights = N_wt),
      p90 = quantile(y_hat_p, 0.90, na.rm = TRUE, weights = N_wt),
      p95 = quantile(y_hat_p, 0.95, na.rm = TRUE, weights = N_wt),
      p90P50 = quantile(y_hat_p, 0.90, na.rm = TRUE, weights = N_wt)/quantile(y_hat_p, 0.50, na.rm = TRUE, weights = N_wt),
      p95P50 = quantile(y_hat_p, 0.95, na.rm = TRUE, weights = N_wt)/quantile(y_hat_p, 0.50, na.rm = TRUE, weights = N_wt),
      .groups = "drop"
    ) %>%
    mutate(year = factor(year, labels = cohort_5_lab)) %>%
    filter(year %in% c("1950-54", "1995-00")) %>%
    rename(cohort = year) %>%
    mutate(country = ifelse(cohort == "1950-54", country, "")) %>%
    rename_with(function(x) ifelse(nchar(x) > 0, paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x))), x))

  output_raw <- print(xtable(tab_p_educ), include.rownames = FALSE, include.colnames = TRUE, booktabs = TRUE, floating = FALSE, file = "")
  output <- sub("(\\\\begin\\{tabular\\})\\{(.*?)\\}", "\\1{ll|rrrrr|rr}", output_raw)
  cat(output, file = paste0(path_tables, "/annex/p_educ.tex"), sep = "\n")
}