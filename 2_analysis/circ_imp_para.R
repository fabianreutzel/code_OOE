#########################################################################################/
# Overview####
#title: "circ_imp_para"
#author: "Fabian Reutzel"
#########################################################################################/

circ_imp_para <- function(data, circumstances, outcome, type, boot_n, cohort_cores) {

  #########################################################################################/  
  #1. define bootstrap function####
  #########################################################################################/  
  circ_imp_boot <- function(data, indices) {
    #generate random sample
    dt <- data[indices, ]
    #dt <- data_country_year

    ##Shapley decomposition based on Shorrocks (2013)
    #generate all possible circumstance permutations for decomposition
    sets <- lapply(1:(length(circumstances_adj)), function(i) combn(circumstances_adj, i, simplify  =  F))
    powerset_raw <- unlist(sets, recursive = F) #excl. the empty set
    #adjust recording of permutations to allow matching
    names(powerset_raw) <- seq(1, length(powerset_raw), 1)
    powerset <- as.vector(rep(NA, length(powerset_raw)))
    for (i in 1:length(powerset)) {
      powerset[i] <- toString(paste(unlist(powerset_raw[i])))
    }

    #calculate absolute IOp for all possible subsets of circumstances
    abs_iop_powerset <- NA
    for (i in 1:length(powerset)) {
      #outcome-specific IOp regression
      if(outcome_type == "binary"){
        weights_setup<-svydesign(id = ~id, weights = ~wt_hh, data = dt)
        iop_reg <- svyglm(paste(outcome, "~", paste(unlist(powerset_raw[i]), collapse = "+"), sep = ""), family = binomial("probit"), design = weights_setup)
        dt$y_hat <- iop_reg$fitted.values}
      if(outcome_type == "continous"){
        iop_reg <- lm(paste(outcome, "~", paste(unlist(powerset_raw[i]), collapse = "+"), sep  =  ""), data = dt, weights = wt_hh)
        dt$y_hat<-predict(iop_reg)}
      if(outcome_type == "binary"){dt <- dt %>% mutate(y_hat = ifelse(y_hat>0, y_hat, 0))}
      if(outcome_type == "continous"){dt <- dt %>% mutate(y_hat = ifelse(y_hat>0, y_hat, 0.001))}
      if(outcome_type == "continous-log"){
        iop_reg <- lm(paste("log(", outcome, ")~", paste(unlist(powerset_raw[i]), collapse = "+"), sep  =  ""), data = dt, weights = wt_hh)
        dt$y_hat<-predict(iop_reg)
        dt$y_hat<-exp(dt$y_hat)}
      #summarize predicted distribution
      if(outcome_type == "binary"){
        mean_prob_hat <- weighted.mean(dt$y_hat, weights = dt$wt_hh)
        mean_prob <- weighted.mean(dt[[outcome]], weights = dt$wt_hh)
        d_index <- sum(abs(dt$y_hat-mean_prob_hat)*dt$wt_hh)/(2*sum(dt$wt_hh)*mean_prob_hat)
        abs_iop_i <- d_index
        abs_iop_powerset[i] <- abs_iop_i}
      if(outcome_type != "binary"){
        abs_iop_i <- gini.wtd(dt$y_hat, weights = dt$wt_hh)
        abs_iop_powerset[i] <- abs_iop_i}
    }

    #match relevant comparisons for each circumstance 
    circ_imp <- NA
    for (c in 1:length(circumstances_adj)) {
      circ <- circumstances_adj[c]
      id_1 <- lapply(powerset_raw, function(x) circ %in% x)
      name_c0 <-  str_replace(powerset, circ, "") 
      name_c0 <-  str_replace(name_c0, ", ", "")
      name_c0 <-  str_replace(name_c0, ", ", "")
      name_c0 <-  str_replace(name_c0, ", ", "")
      name_c0 <-  str_replace(name_c0, ", ", "")
      name_c0 <-  str_replace(name_c0, "  ", " ")
      name_c0 <-  trimws(name_c0)
      name_c1 <-  str_replace(powerset, ", ", "") 
      name_c1 <-  str_replace(name_c1, ", ", "")
      name_c1 <-  str_replace(name_c1, ", ", "")
      name_c1 <-  str_replace(name_c1, ", ", "")
      name_c1 <-  str_replace(name_c1, ", ", "")

      c_all <- as.data.frame(cbind(unlist(name_c1), abs_iop_powerset))
      c_1 <- as.data.frame(cbind(unlist(name_c1), unlist(id_1), abs_iop_1 = abs_iop_powerset)) %>% filter(V2 == "TRUE") %>% select(-V2)
      c_0 <- as.data.frame(cbind(unlist(name_c0), unlist(id_1)))%>% filter(V2 == "TRUE")%>% select(-V2)
      c_0 <- left_join(c_0, c_all, by = ("V1" = "V1")) %>% plyr::rename(c("abs_iop_powerset" = "abs_iop_0"))
      c_final <- cbind(c_1, c_0)
      c_final[1, 4] <- 0 #add zero abs_iop for empty set
      c_final <- c_final[, -3] %>% mutate(abs_iop_delta  =  as.numeric(abs_iop_1)-as.numeric(abs_iop_0))
      n_miss <- sum(is.na(c_final$abs_iop_delta))
      c_marg <- sum(c_final$abs_iop_delta, na.rm = TRUE)/(nrow(c_final)-n_miss)
      circ_imp[c] <- c_marg
    }
    rel_iop<-abs_iop_powerset[length(powerset)]/gini.wtd(dt[[outcome]], weights = dt$wt_hh)
    circ_imp <- c((circ_imp/sum(circ_imp)), abs_iop_powerset[length(powerset)], sum(circ_imp), rel_iop)
    return(circ_imp)
  }


  #########################################################################################/
  #2. get bootstrapped estimates####
  #########################################################################################/

  #prepare input
  if(type == "cohort_cores_perf"){  
    country_year <- data %>% filter(year_birth >= 1950) %>% filter_at(vars(paste0(outcome), year_birth), all_vars(!is.na(.)))%>% 
      group_by(country, year_birth) %>% dplyr::summarize(n()) %>% mutate(country_year = paste(country, year_birth)) %>% ungroup() %>% select(-"n()") %>% dplyr::rename(year = year_birth)}
  if(type == "cohort_cores"){country_year <- cohort_cores[, -2] %>% mutate(country_year = paste(country, year))}
  if(type == "cohort_5"){data <- data %>% dplyr::rename(year_survey = year, year = cohort_5)}
  if(type == "cs" | type == "cohort_5"){
    country_year <- data %>% filter_at(vars(paste0(outcome), year), all_vars(!is.na(.)))%>% 
      group_by(country, year) %>% dplyr::summarize(n()) %>% mutate(country_year = paste(country, year)) %>% ungroup() %>% select(-"n()")}
  country <- as.vector(t(country_year$country))
  year <- as.vector(t(country_year[, 2]))
  if(type != "cs")  circumstances <- circumstances[-1] #exclude age

  #define outcome type (binary; continuous (non-/log))
  outcome_type <- ifelse(length(unique(data[[outcome]])) == 2, "binary",
                         ifelse((grepl("inc", outcome) | grepl("cons", outcome) | grepl("wage", outcome)), "continous-log", "continous"))
  #results shapley value
  circ_mat <- as.data.frame(matrix(nrow = nrow(country_year), ncol = length(circumstances)+3, as.numeric(NA)))
  colnames(circ_mat) <- c(circumstances, "full", "sum_marg", "rel_iop")
  circ_imp_para <- data.frame(country_year, circ_mat)
  #results relative importance (comparable to forest)
  circ_mat_adj <- as.data.frame(matrix(nrow = nrow(country_year), ncol = length(circumstances), as.numeric(NA)))
  colnames(circ_mat_adj) <- circumstances
  circ_imp_para_adj <- data.frame(country_year, circ_mat_adj)
  
  for (j in 1:length(country)){
    y <- year[j]
    #get relevant data
    print(country_year[j, 3])
    data_country <- data[data$country == country[j], ]
    if(type == "cohort_cores" | type == "cohort_cores_perf"){data_country_year<-data_country[data_country$year_birth >= y & data_country$year_birth <= y+3, ]}
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
    #run bootstrap
    tryCatch({
      boot_results <-boot(data_country_year, circ_imp_boot, R = boot_n)
      #save results
      circ_imp <- boot_results$t0
      names(circ_imp) <- c(circumstances_adj, "full", "sum_marg", "rel_iop")
      circ_imp_j <- data.frame(c(country_year[j, 3], circ_imp))
      circ_imp_para <- circ_imp_para %>% rows_update(circ_imp_j, by = "country_year")
    }, error = function(e){})
  }
  return(circ_imp_para)
}