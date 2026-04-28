#########################################################################################/
# Overview####
#title: "iop_ex_ante.R"
#author: "Fabian Reutzel"
#########################################################################################/

iop_ex_ante <- function(data, circumstances, outcome, estimation = "para", type, boot_n, cohort_cores) {
  
  #########################################################################################/
  #1. define bootstrap function####
  #########################################################################################/
  iop_boot <- function(data, indices) {
    #generate random sample
    dt <- data[indices, ]

    #adjust input for forest estimation (i.e., limit sample size)
    if(estimation == "forest"){
      if (nrow(dt) > 30000) {
        dt <- dt[sample(1:nrow(dt), 30000, replace  =  FALSE), ]
      }
    }

    ##run model & get predicted outcome using the created sample
    #binary outcome
    if(outcome_type == "binary"){
      if(estimation == "para"){
        weights_setup <- svydesign(id = ~id, weights = ~wt_hh, data = dt)
        iop_reg <- svyglm(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep = ""), family = binomial("probit"), design = weights_setup)
        dt$y_hat <- iop_reg$fitted.values #predicted probability
      }
      if(estimation == "forest"){
        forest <- party::cforest(as.formula(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep  =  "")), 
                                 data = dt, weights = dt$wt_hh, control = cforest_control(mincriterion = 0.95, teststat = "max", testtype = "Bonferroni", ntree = 200, trace = TRUE, replace = FALSE, fraction = 0.75))
        gc()
        dt$index <- sample(1:100, dim(dt)[1], replace  =  TRUE)
        dt$y_hat <- 0
        for (ind in 1:100){
          dt$y_hat[dt$index == ind] <- predict(forest, newdata = dt[dt$index == ind, ])
          print(paste0("predicting forest ", ind, " of ", 100))
        }
      }
    }
    #continous outcome without transformation
    if(outcome_type == "continous"){
      if(estimation == "para"){
        iop_reg <- lm(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep  =  ""), data = dt, weights = wt_hh)
        dt$y_hat <- predict(iop_reg)
        dt <- dt %>% mutate(y_hat = ifelse(y_hat>0, y_hat, 0)) #adjust for negative predictions
      }
      if(estimation == "forest"){
        forest <- party::cforest(as.formula(paste(outcome, "~", paste(circumstances_adj, collapse = "+"), sep  =  "")), 
                               data = dt, weights = dt$wt_hh, control = cforest_control(mincriterion = 0.95, teststat = "max", testtype = "Bonferroni", ntree = 200, trace = TRUE, replace = FALSE, fraction = 0.75))
        gc()
        dt$index <- sample(1:100, dim(dt)[1], replace  =  TRUE)
        dt$y_hat <- 0
        for (ind in 1:100){
          dt$y_hat[dt$index == ind] <- predict(forest, newdata = dt[dt$index == ind, ])
          print(paste0("predicting forest ", ind, " of ", 100))
        }
      }
    }
    #continous outcome with log transformation
    if(outcome_type == "continous-log"){
      if(estimation == "para"){
        iop_reg <- lm(paste("log(", outcome, ")~", paste(circumstances_adj, collapse = "+"), sep  =  ""), data = dt, weights = wt_hh)
        dt$y_hat <- predict(iop_reg)
        dt$y_hat <- exp(dt$y_hat)
      }
      if(estimation == "forest"){
        forest <- party::cforest(as.formula(paste("log(", outcome, ")~", paste(circumstances_adj, collapse = "+"), sep  =  "")),
                                 data = dt, weights = dt$wt_hh, control = cforest_control(mincriterion = 0.95, teststat = "max", testtype = "Bonferroni", ntree = 200, trace = TRUE, replace = FALSE, fraction = 0.75))
        gc()
        dt$index <- sample(1:100, dim(dt)[1], replace  =  TRUE)
        dt$y_hat <- 0
        for (ind in 1:100){
          dt$y_hat[dt$index == ind] <- predict(forest, newdata = dt[dt$index == ind, ])
          print(paste0("predicting forest ", ind, " of ", 100))
        }
        dt$y_hat <- exp(dt$y_hat)
      }
    }

    ##generate & save distributional measures
    if(outcome_type == "binary"){
      mean_prob_hat <- weighted.mean(dt$y_hat, weights = dt$wt_hh)
      mean_prob <- weighted.mean(dt[[outcome]], weights = dt$wt_hh)
      d_index <- sum(abs(dt$y_hat-mean_prob_hat)*dt$wt_hh)/(2*sum(dt$wt_hh)*mean_prob_hat)
      boot_out <- c(abs_iop <- d_index,
                  hoi <- mean_prob*(1-d_index),
                  share <- mean_prob)
    }
    if(outcome_type != "binary"){
      dt$y_hat_adj <- ifelse(dt$y_hat == 0, 0.01, dt$y_hat)
      dt$y_adj <- ifelse(dt[[outcome]] == 0, 0.01, dt[[outcome]])
      boot_out <- c(abs_iop <- gini.wtd(dt$y_hat, weights = dt$wt_hh),
                    abs_iop_mld <- mld.wtd(dt$y_hat_adj, weights = dt$wt_hh),
                    gini <- gini.wtd(dt[[outcome]], weights = dt$wt_hh),
                    mld <- mld.wtd(dt$y_adj, weights = dt$wt_hh),
                    rel_iop <- abs_iop/gini,
                    rel_iop_mld <- abs_iop_mld/mld)
    }
    boot_out
  }

  #########################################################################################/  
  #2. get bootstrapped estimates####
  #########################################################################################/
  #prepare output
  if(type == "cohort_cores_perf"){
    country_year <- data %>% filter(year_birth >= 1950) %>% filter_at(vars(paste0(outcome), year_birth), all_vars(!is.na(.))) %>%
    group_by(country, year_birth) %>% dplyr::summarize(n()) %>% mutate(country_year = paste(country, year_birth)) %>% ungroup() %>% select(-"n()") %>% dplyr::rename(year = year_birth)}
  if(type == "cohort_cores"){country_year <- cohort_cores[, -2] %>% mutate(country_year = paste(country, year))}
  if(type == "cohort_5"){data <- data %>% dplyr::rename(year_survey = year, year = cohort_5)}
  if(type == "cohort_age_5"){data <- data %>% dplyr::rename(year_survey = year, year = cohort_age_5)}
  if(type == "cs" | type == "cohort_5" | type == "cohort_age_5"){
    country_year <- data %>% filter_at(vars(paste0(outcome), year), all_vars(!is.na(.)))%>% 
      group_by(country, year) %>% dplyr::summarize(n()) %>% mutate(country_year = paste(country, year)) %>% ungroup() %>% select(-"n()")}
  country <- as.vector(t(country_year$country))
  year <- as.vector(t(country_year[, 2]))
  if(type != "cs"){circumstances <- circumstances[-1]} #exclude age
  if(type == "cs"){circumstances <- c("age_2", circumstances)} #include age_2

  #define outcome type (binary; continuous (non-/log))
  outcome_type <- ifelse(length(unique(na.omit(data[[outcome]]))) == 2, "binary", 
                    ifelse((grepl("inc", outcome) | grepl("cons", outcome) | grepl("wage", outcome)), "continous-log", "continous"))

  if(outcome_type == "binary"){
    iop <- data.frame(country_year,
                      "abs_iop_p" = NA, "hoi_p" = NA, "share_p" = NA,
                      "abs_iop_u" = NA, "hoi_u" = NA, "share_u" = NA,
                      "abs_iop_l" = NA, "hoi_l" = NA, "share_l" = NA, "N" = NA)
  }
  if(outcome_type != "binary"){
    iop <- data.frame(country_year,
                      "abs_iop_p" = NA, "abs_iop_mld_p" = NA, "gini_p" = NA, "mld_p" = NA, "rel_iop_p" = NA, "rel_iop_mld_p" = NA,
                      "abs_iop_u" = NA, "abs_iop_mld_u" = NA, "gini_u" = NA, "mld_u" = NA, "rel_iop_u" = NA, "rel_iop_mld_u" = NA,
                      "abs_iop_l" = NA, "abs_iop_mld_l" = NA, "gini_l" = NA, "mld_l" = NA, "rel_iop_l" = NA, "rel_iop_mld_l" = NA, "N" = NA)
  }

  for (j in 1:length(country)){
    y <- year[j]
    #get relevant data
    print(country_year[j, 3])
    data_country <- data[data$country == country[j], ]
    if(type == "cohort_cores" | type == "cohort_cores_perf"){data_country_year <- data_country[data_country$year_birth >= y & data_country$year_birth <= y+3, ]}
    if(type == "cs" | type == "cohort_5" | type == "cohort_age_5"){data_country_year <- data_country[data_country$year == year[j], ]}
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

    #run bootstrap
    boot_results <- NULL
    retry_count <- 0
    max_retries <- 50
    while (is.null(boot_results) && retry_count < max_retries) {
      boot_results <- tryCatch({
        boot(data_country_year, iop_boot, R = boot_n)
      }, error = function(e) {
        NULL
      })

      #rerun when key point estimates are NA
      if (!is.null(boot_results)) {
        ci_valid <- tryCatch({
          ci1_check <- boot.ci(boot_results, type = "norm", index = 1)
          ci3_check <- boot.ci(boot_results, type = "norm", index = 3)
          !is.na(ci1_check$t0[1]) && !is.na(ci3_check$t0[1])
        }, error = function(e) {
          FALSE
        })

        if (!ci_valid) {
          boot_results <- NULL
        }
      }

      if (is.null(boot_results)) {
        retry_count <- retry_count + 1
      }
    }

    ##save results
    if(outcome_type == "binary"){
      tryCatch({
      ci1 <- boot.ci(boot_results, type = "norm", index = 1)
      ci2 <- boot.ci(boot_results, type = "norm", index = 2)
      ci3 <- boot.ci(boot_results, type = "norm", index = 3)
      #point estimates
      iop$abs_iop_p[j] <- ci1$t0[1]
      iop$hoi_p[j] <- ci2$t0[1]
      iop$share_p[j] <- ci3$t0[1]
      #upper bound
      iop$abs_iop_u[j] <- ci1$normal[3]
      iop$hoi_u[j] <- ci2$normal[3]
      iop$share_u[j] <- ci3$normal[3]
      #lower bound
      iop$abs_iop_l[j] <- ci1$normal[2]
      iop$hoi_l[j] <- ci2$normal[2]
      iop$share_l[j] <- ci3$normal[2]
      }, error = function(e){})
    }
    if(outcome_type != "binary"){
      tryCatch({
        ci1 <- boot.ci(boot_results, type = "norm", index = 1)
        ci2 <- boot.ci(boot_results, type = "norm", index = 2)
        ci3 <- boot.ci(boot_results, type = "norm", index = 3)
        ci4 <- boot.ci(boot_results, type = "norm", index = 4)
        ci5 <- boot.ci(boot_results, type = "norm", index = 5)
        ci6 <- boot.ci(boot_results, type = "norm", index = 6)
        #point estimates
        iop$abs_iop_p[j] <- ci1$t0[1]
        iop$abs_iop_mld_p[j] <- ci2$t0[1]
        iop$gini_p[j] <- ci3$t0[1]
        iop$mld_p[j] <- ci4$t0[1]
        iop$rel_iop_p[j] <- ci5$t0[1]
        iop$rel_iop_mld_p[j] <- ci6$t0[1]
        #upper bound
        iop$abs_iop_u[j] <- ci1$normal[3]
        iop$abs_iop_mld_u[j] <- ci2$normal[3]
        iop$gini_u[j] <- ci3$normal[3]
        iop$mld_u[j] <- ci4$normal[3]
        iop$rel_iop_u[j] <- ci5$normal[3]
        iop$rel_iop_mld_u[j] <- ci6$normal[3]
        #lower bound
        iop$abs_iop_l[j] <- ci1$normal[2]
        iop$abs_iop_mld_l[j] <- ci2$normal[2]
        iop$gini_l[j] <- ci3$normal[2]
        iop$mld_l[j] <- ci4$normal[2]
        iop$rel_iop_l[j] <- ci5$normal[2]
        iop$rel_iop_mld_l[j] <- ci6$normal[2]
      }, error = function(e){})
    }
    #sample size
    iop$N[j] <- nrow(data_country_year)
  }
  
  ##label output
  if(type == "cohort_cores" | type == "cohort_cores_perf"){
    iop <- iop %>% mutate(country_year = paste0(country, " ", year, "-", year+3))
  }
  if(type == "cohort_5"){
    iop <- iop %>% mutate(year_lab = factor(year, levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10"),
                    labels = c("1" = "1950-1954", "2" = "1955-1959", "3" = "1960-1964", "4" = "1965-1969", "5" = "1970-1974",
                             "6" = "1975-1979", "7" = "1980-1984", "8" = "1985-1989", "8" = "1990-1994", "10" = "1995-1999"))) %>%
                  mutate(country_year = paste0(country, " ", year_lab)) %>% select(-year_lab)
  }
  if(type == "cohort_age_5"){
    iop_measures <- c("abs_iop_p", "abs_iop_mld_p", "gini_p", "mld_p", "rel_iop_p", "rel_iop_mld_p",
                      "abs_iop_u", "abs_iop_mld_u", "gini_u", "mld_u", "rel_iop_u", "rel_iop_mld_u",
                      "abs_iop_l", "abs_iop_mld_l", "gini_l", "mld_l", "rel_iop_l", "rel_iop_mld_l", "N")
    iop_measures <- c("rel_iop_p", "N")
    #label cohorts & age-groups
    iop <- iop %>%
      mutate(cohort_5_lab = factor(as.numeric(substr(year, 1, 2)),
                                              levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10"),
                                              labels = c("1" = "1950-54", "2" = "1955-59", "3" = "1960-64", "4" = "1965-69", "5" = "1970-74",
                                                       "6" = "1975-79", "7" = "1980-84", "8" = "1985-89", "9" = "1990-94", "10" = "1995-00")),
             age_5_lab = factor(as.numeric(substr(year, 3, 4)),
                                           levels = c("-1", "0", "1", "2", "3", "4", "5", "6", "7", "8"),
                                           labels = c("-1" = "Avr. IOp", "0" = "Total Obs.", "1" = "25-29", "2" = "30-34", "3" = "35-39", "4" = "40-44", "5" = "45-49", "6" = "50-54",
                                                    "7" = "55-59", "8" = "60-64")))
    
    #generate country-specific lists of tables with rel_iop_p & N
    country_list <- vector(mode = "list", length = length(unique(iop$country)))
    i = 1
    for(c in unique(iop$country)){
      #select & format & name 
      result_iop <- reshape(iop%>%filter(country == c)%>%select(rel_iop_p, cohort_5_lab, age_5_lab), idvar = "age_5_lab", timevar = "cohort_5_lab", direction = "wide")
      colnames(result_iop) <- gsub("rel_iop_p.", "", colnames(result_iop))
      result_N <- reshape(iop%>%filter(country == c)%>%select(N, cohort_5_lab, age_5_lab), idvar = "age_5_lab", timevar = "cohort_5_lab", direction = "wide")
      colnames(result_N) <- gsub("N.", "", colnames(result_N))
      #generate aggregates
      result_iop$Total <- rowMeans(result_iop[, -1], na.rm = TRUE)
      result_N$Total <- rowSums(result_N[, -1], na.rm = TRUE)
      result_all_iop <- as.data.frame(t(c(age_5_lab = -1, colMeans(result_iop[, -1], na.rm = TRUE))))
      result_all_N <- as.data.frame(t(c(age_5_lab = 0, colSums(result_N[, -1], na.rm = TRUE))))
      result_all <- rbind(result_all_iop, result_all_N)
      result_all$age_5_lab <- as.factor(result_all$age_5_lab)
      for(r in 1:length(unique(result_iop$age_5_lab))){
        result_all <- bind_rows(result_N[r, ], result_all)
        result_all <- bind_rows(result_iop[r, ], result_all)
      }
      #label results
      result_all <- result_all[order(result_all$age_5_lab, decreasing = FALSE), ]
      result_all <- result_all[, order(colnames(result_all))]
      result_all <- cbind(result_all[, (ncol(result_all)-1)], result_all[, -(ncol(result_all)-1)])
      colnames(result_all) <- c("Age Group", colnames(result_all)[-c(1, ncol(result_all))], "Avr. IOp / N")
      result_all[nrow(result_all)-1, 1] <- factor(-1, levels = c("-1"), labels = c("0" = "Avr. IOp"))
      result_all[nrow(result_all), 1] <- factor(0, levels = c("0"), labels = c("0" = "Total Obs."))
      result_all[, -1] <- round(result_all[, -1], 3)
      result_all_lab <- colnames(result_all)
      result_all <- as.data.frame(lapply(result_all, as.character))
      result_all[seq(2, nrow(result_all)-2, 2), 1] <- rep("", (nrow(result_all)-2)/2)
      colnames(result_all) <- result_all_lab
      country_list[[i]] <- result_all
      i <- i + 1
    }
    names(country_list) <- unique(iop$country)
    iop <- country_list
  }
  return(iop)
}