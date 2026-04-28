#########################################################################################/
# Overview####
#title: "robustness_migration"
#author: "Fabian Reutzel"
#########################################################################################/
dt_migration <- read_stata(paste0(path_data, "/clean/migration_dataset.dta"))
tab_migration <- dt_migration %>% group_by(country, survey, year) %>%
  dplyr::summarize(urban = (mean(migration_urban, na.rm = TRUE))*100,
                  geo_level_1 = (mean(migration_geo_level_1, na.rm = TRUE))*100,
                  geo_level_2 = (mean(migration_geo_level_2, na.rm = TRUE))*100,
                  n = as.factor(n())) %>%
  mutate(year = factor(year))

addtorow <- list()
addtorow$pos <- list(0, 0)
addtorow$command <- c("& & & \\multicolumn{3}{c}{Migration Birth to Current Location} \\\\\n",
                      " \\cmidrule(lr){4-6}  Country & Survey & Year & Urban & Region & Sub-Region & N \\\\\n")
print(xtable(tab_migration, digits = 2), include.rownames = FALSE, include.colnames = FALSE, add.to.row = addtorow,
      floating = FALSE, booktabs = TRUE, file = paste0(path_tables, "/annex/migration.tex"))