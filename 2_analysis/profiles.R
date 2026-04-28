#########################################################################################/
#Overview####
#title: "profiles"
#author: "Fabian Reutzel"
#########################################################################################/

profiles <- function(data, circumstances, outcome, estimation, type, boot_n) {

  #########################################################################################/
  #1. define bootstrap function####
  #########################################################################################/
  profiles_boot <- function(data, indices){
    #generate random sample
    dt <- data[indices, ]
    #dt <- data_country_year
    #parametric predictions (Ferreira & Gignoux 2011)
    if(estimation == "para"){
      #estimation
      if(outcome_type == "binary"){
          weights_setup <- svydesign(id = ~id, weights = ~wt_hh, data = dt)
          iop_reg <- svyglm(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep = ""), family = binomial("probit"), design = weights_setup)
      }
      if(outcome_type == "continous"){
          iop_reg <- lm(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep = ""), data = dt, weights = wt_hh)
      }
      if(outcome_type == "continous-log"){
          iop_reg <- lm(paste("log(", outcome, ")~", paste(circumstances_adj, collapse = "+"), sep = ""), data = dt, weights = wt_hh)
      }
      #get predictions for all possible circ combinations found in the full dataset
      circ_combi_y <- predict(iop_reg, newdata = circ_combi, type = "response")
      #adjust negative predictions
      circ_combi_y <- as.data.frame(circ_combi_y) %>% mutate(circ_combi_y = ifelse(circ_combi_y>0, circ_combi_y, 0)) 
      circ_combi_y <- as.vector(circ_combi_y$circ_combi_y)
      if(outcome_type == "continous-log"){ #adjust for log-transformation
          circ_combi_y <- exp(circ_combi_y)
      }
    }
    #non-parametric predictions for all possible circ combinations found in the full dataset (Checchi & Peragine 2010)
    if(estimation == "nonpara"){
      circ_combi_y <- dt %>% group_by(across(all_of(circumstances_adj))) %>% summarise(circ_combi_y = weighted.mean(!!sym(outcome), w = wt_hh))
      circ_combi_y <- circ_combi_y %>% right_join(circ_combi) #adjust for missing types
      circ_combi_y <- as.vector(circ_combi_y$circ_combi_y)
    }
    return(circ_combi_y)
  }

  #########################################################################################/
  #2. get bootstrapped estimates####
  #########################################################################################/
  #prepare output
  if(type == "cohort_5"){data <- data %>% dplyr::rename(year_survey = year, year = cohort_5)}
  if(type == "cs" | type == "cohort_5"){
    country_year <- data %>% filter_at(vars(paste0(outcome), year), all_vars(!is.na(.))) %>%
      group_by(country, year) %>% dplyr::summarize(n()) %>% mutate(country_year = paste(country, year)) %>% ungroup() %>% select(-"n()")}
  country <- as.vector(t(country_year$country))
  year <- as.vector(t(country_year[, 2]))
  if(type != "cs"){circumstances <- circumstances[-1]} #exclude age

  #define outcome type (binary; continuous (non-/log))
  outcome_type <- ifelse(length(unique(na.omit(data[[outcome]]))) == 2, "binary", 
                         ifelse((grepl("inc", outcome)|grepl("cons", outcome)|grepl("wage", outcome)), "continous-log", "continous"))
  outcome_type <- ifelse(outcome == "paidwage", "binary", outcome_type)

  profiles <- data.frame(t(c(rep(NA, length(circumstances)+7))))
  colnames(profiles) <- c("country", "year", "country_year", paste0(circumstances), "y_hat_p", "y_hat_u", "y_hat_l", "N")

  for (j in 1:length(country)){
    y <- year[j]
    #get relevant data
    print(country_year[j, 3])
    data_country <- data[data$country == country[j], ]
    if(type == "cs" | type == "cohort_5"){data_country_year <- data_country[data_country$year == year[j], ]}
    data_country_year <- data_country_year %>% filter_at(vars(paste0(outcome)), all_vars(!is.na(.)))
    #get relevant circumstances
    circumstances_adj <- as.vector(NA)
    for (c in 1:length(circumstances)){
      data_test <- data_country_year %>%filter_at(vars(paste0(circumstances[c])), all_vars(!is.na(.))) 
      if(nrow(data_test)>0 & sapply(lapply(subset(data_test, select = circumstances[c]), unique), length)>1){
        circumstances_adj <- c(circumstances_adj, circumstances[c])}
    }
    circumstances_adj <- circumstances_adj[-1]
    data_country_year <-  data_country_year %>% filter_at(vars(paste0(circumstances_adj)), all_vars(!is.na(.)))
    circ_combi <- data_country_year  %>% select(paste0(circumstances_adj)) %>% crossing()

    country_year_j <- country_year[j, ]
    country_year_j <- country_year_j[rep(1, nrow(circ_combi)), ]
    profiles_j <- cbind(country_year_j, circ_combi, y_hat_p = NA, y_hat_u = NA, y_hat_l = NA)

    #run bootstrap
    tryCatch({
      boot_results  <- boot(data_country_year, profiles_boot, R = boot_n)
    }, error = function(e){})

    ##save results
    for (c in 1:nrow(circ_combi)){
      tryCatch({
        ci_circ <- boot.ci(boot_results, type = "norm", index = c)
        #point estimates
        profiles_j$y_hat_p[c] <- ci_circ$t0[1]
        #upper bound
        profiles_j$y_hat_u[c] <- ci_circ$normal[3]
        #lower bound
        profiles_j$y_hat_l[c] <- ci_circ$normal[2]
      }, error = function(e){})
    }
    #sample size
    n_profiles_j <- data_country_year %>% group_by_at(paste0(circumstances_adj)) %>% dplyr::summarise(N = n())
    n_wt_profiles_j <- data_country_year %>% group_by_at(paste0(circumstances_adj)) %>% dplyr::summarise(N_wt = sum(wt_hh))
    profiles_j <- right_join(profiles_j, n_profiles_j) %>% right_join(n_wt_profiles_j) 
    profiles <- bind_rows(profiles, profiles_j)
  }
  ##add labels
  profiles <- profiles[-1, ]
  prof <- profiles
  profiles <- prof

  #cohort labels
  if(type == "cohort_5"){
    profiles <- profiles %>% mutate(year_lab = factor(year, levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10"), labels = cohort_5_lab)) %>%
      mutate(country_year = paste0(country, " ", year_lab)) %>% select(-year_lab)}

  #demo + geo_level lables
  if(length(demo_lab)<9){ #single country
    profiles$demo <- factor(profiles$demo, labels = names(demo_lab))
    profiles$geo_level_1 <- factor(profiles$geo_level_1, labels = names(geo_level_1_lab))}
  if (length(unique(profiles$demo))>15) {
    if(outcome == "hh_cons_wb"){ #excl. Afghanistan + Nepal
      profiles$demo <- factor(profiles$demo, labels = names(demo_lab)[-c(1:5, 13:16)])
      profiles$geo_level_1 <- factor(profiles$geo_level_1, labels = names(geo_level_1_lab)[-c(1:7, 24:28)])}
    if(outcome == "lfp"){ #excl. Nepal
      profiles$demo <- factor(profiles$demo, labels = names(demo_lab)[-c(13:16)])
      profiles$geo_level_1 <- factor(profiles$geo_level_1, labels = names(geo_level_1_lab)[-c(24:28)])}
    if(outcome == "wage"){#excl. + Bhutan
      profiles$demo <- factor(profiles$demo, labels = names(demo_lab)[-c(1:5, 13:16)])
      profiles$geo_level_1 <- factor(profiles$geo_level_1, labels = names(geo_level_1_lab)[-c(1:7, 15:18, 24:28)])} 
    if(outcome != "hh_cons_wb"&outcome != "lfp"&outcome != "wage") {
      profiles$demo <- factor(profiles$demo, labels = names(demo_lab))
      profiles$geo_level_1 <- factor(profiles$geo_level_1, labels = names(geo_level_1_lab))
    }
  }

  #generate type label
  if(outcome != "hh_cons_wb"){
    profiles$type <- paste0(ifelse(profiles$female == 0, "♂", "♀"), "-", ifelse(profiles$urban == 0, "R", "U"), "-", profiles$demo, "-", profiles$geo_level_1)
  } else {
    profiles$type <- paste0(ifelse(profiles$urban == 0, "R", "U"), "-", profiles$demo, "-", profiles$geo_level_1)
  }

  #adjust for missing demo Bhutan
  profiles$type <- sub("-NA", "", profiles$type)

  return(profiles)
}