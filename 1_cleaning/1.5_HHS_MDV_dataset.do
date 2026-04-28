/******************************************************************************\
#title: "1.5_HHS_MDV_dataset" => not used in analysis due to absent circumstances
#author: "Fabian Reutzel"
#structure: 1. HIES 2009
			2. HIES 2016 // excluded b/c of missing hh_rel
			3. HIES 2019
			4. Combine datasets
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. HIES 2009
********************************************************************************
********************************************************************************
use "$raw\maldives\HIES_2009\data\MDV_2009_HIES_v01_M_v04_A_SARMD_IND.dta", clear

*generate country/survey/year
drop survey
gen country = "Maldives"
gen survey_name = "Household Income and Expenditure Survey"
gen survey = "HIES"
gen coresident = "yes"

*rename variables
ren wgt wt_hh
ren pop_wgt wt_ind
gen geo_level_1 = (subnatid1==1) if subnatid1!=. 
gen geo_level_2 = int(subnatid2/100) 
ren hsize hh_size
ren idh hh_id
ren idp child_id
gen female = 1 - male

*agriculture & employment status (primary occupation)
gen agri = (occup==6) if occup!=.
replace agri = 0 if industry!=. & agri==.
replace agri = 1 if industry==1
ren empstat emp_stat
gen emp_self = (emp_stat==3|emp_stat==4) if emp_stat!=.

*education variables
ren everattend educ_stat
ren literacy literate
ren educy educ_og
ren educat7 educ_cat_og
replace educ_cat_og = . if educ_cat_og==8 //replace others with missing
*re: only missing years of education are "others" 
 
*relation to hhhead 
gen hh_rel = 0 if relationharm==1
replace hh_rel = 1 if relationharm==2
replace hh_rel = 2 if relationharm==3
replace hh_rel = 3 if relationharm==4
gen child_coresident = (hh_rel==2)

*add parental background 
parent_merge

*no religion/demo info 
 
*income 
replace wage = 0 if wage==.
gen inc_month = wage*25 if unitwage==1
replace inc_month = wage if unitwage==2

*hh expenditure
ren welfare hh_cons_month //marked as expenditure (in line with the extended consumption definition)
*re: no differences with other welfare var only slightly with spatially deflated var
*gen hh_cons_month_ppp = welfare / ppp


/* format education variable */
foreach var in child father mother {
gen `var'_educ = `var'_educ_og +1 if `var'_educ_og>0 & `var'_educ_og!=.
replace `var'_educ = 14 if `var'_educ_og==14
replace `var'_educ = 16 if `var'_educ_og==16
replace `var'_educ = 1 if (`var'_literate==1 & `var'_educ_og==.)
replace `var'_educ = 0 if (`var'_educ_og==0|(`var'_educ_og==. & `var'_educ_stat==0))
replace `var'_educ = 0 if (`var'_literate==0 & `var'_educ_og==.)
}

keep $var_main $var_cores $var_indiv inc_month hh_cons_month 
compress
save "$raw\maldives\hies_2009.dta", replace

********************************************************************************
********************************************************************************
**#2. HIES 2016 => cannot identify hh_rel (variable omitted; see HIES_2016_confirmation_non_usage.pdf)
********************************************************************************
/********************************************************************************
use "$raw\maldives\HIES_2016\data\HIES2016_StataFormat\WeightedDataset\F4.dta", clear
*add weights
merge m:1 Form_ID using "$raw\maldives\HIES_2016\data\HIES2016_StataFormat\WeightedDataset\ID.dta", nogen 

*generate country/survey/year
gen country = "Maldives"
gen survey = "HIES"
gen year = 2016
gen coresident = "yes"

*rename variables
gen geo_level_1 = (Atoll==10)
ren Atoll geo_level_2
gen psu = geo_level_2 //no additional psu variable  
ren Form_ID hh_id
ren Id child_id
ren hhw_aj wt_hh

**education
gen literate = (Q417==1) if Q417!=9 //mother tongue
*gen literate_eng = (Q418==1) if Q418!=9 //english
gen educ_stat = (Q419==1) if Q419!=9 

*mapping academic + vocational degrees according to Aditi scheme
gen educ_degree = 0 if Q424==8
replace educ_degree = 10 if Q424==1 //O-Level
replace educ_degree = 12 if Q424==2 //A-Level
replace educ_degree = 12 if Q424==3 //ACAD./VOCAT.CERT.OR DIPLOMA(LESS THAN 6 
replace educ_degree = 13 if Q424==4 //ACAD./VOCAT.CERT.OR DIPLOMA(MORE THAN 6
replace educ_degree = 14 if Q424==5 //FIRST DEGREE/MBBS
replace educ_degree = 15 if Q424==6 //Post-grad/masters degree 
replace educ_degree = 15 if Q424==7 //Post-grad/phd degree 

gen educ_og = Q421 if Q421!=99
replace educ_og = 15 if (educ_og>15 & educ_og!=.)
*add degree info to improve capture of higher education 
replace educ_og = educ_degree if educ_og==.
replace educ_og = educ_degree if educ_degree>educ_og & educ_degree!=. & educ_og!=.

gen educ_cat_og = high_edu if high_edu!=9

**Cirumstance Variables
ren Q406 age
gen demo = (Q407==1) if Q407!=9 //9=not stated
lab def demo 0 "non-foreign origin" 1 "foreign born"
lab val demo demo
*ren birth_island Q411Code //too granular & only available for subsample (4,251)
gen female = (m1a_q02==1)
*re: no info on religion/ethnicity
*re: disab =(Q526==10 | Q526==12) only asked to UE F5

*relation to hhhead 
*get father/mother_id
gen hh_rel = 0 if hoh==1
replace hh_rel = 1 if relhhh==2
replace hh_rel = 2 if relhhh==3
bysort hh_id (hh_rel): gen member_id_adj = _n
egen n_spouse = total(hh_rel) if  hh_rel==1, by(hh_id) //identify polygamous families
replace member_id_adj = . if member_id_adj==1 & hh_rel!=0
replace member_id_adj = . if member_id_adj==2 & hh_rel!=1
replace member_id_adj = . if hh_rel>1 | (n_spouse>1 & n_spouse!=.)
gen father_id = hh_id + "-" + string(1) if member_id_adj==1
gen mother_id = hh_id + "-" + string(2) if member_id_adj==2
replace father_id = hh_id + "-" + string(.) if father_id==""
replace mother_id = hh_id + "-" + string(.) if mother_id==""
replace mother_id = (hh_id + "-" + string(2)) if (Sex==1 & member_id_adj==1)
replace father_id = (hh_id + "-" + string(.)) if (Sex==1 & member_id_adj==1)
replace father_id = (hh_id + "-" + string(1)) if (Sex==2 & member_id_adj==2)
replace mother_id = (hh_id + "-" + string(.)) if (Sex==2 & member_id_adj==2)
*/
********************************************************************************
********************************************************************************
**#3.HIES 2019
*re: no urbanity status
********************************************************************************
********************************************************************************
********************************************************************************
**#3.1 HH consumption
********************************************************************************
use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\master_exp.dta", clear
ren uqhh__id hh_id
ren monthly_exp exp_main
collapse (sum) exp_main, by(hh_id)
keep hh_id exp_main
save "$raw\maldives\HIES_2019\working\hies_2019_expenditure_main.dta", replace

use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\nonfood_expunit.dta", clear
ren uqhh__id hh_id
gen exp_non_food = ex_amnt*factor_month
collapse (sum) exp_non_food, by(hh_id)
keep hh_id exp_non_food
save "$raw\maldives\HIES_2019\working\hies_2019_expenditure_non_food.dta", replace

use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\other_exp.dta", clear
ren uqhh__id hh_id
ren cost_item_serv exp_utilities // incl. domestic servant
collapse (sum) exp_utilities, by(hh_id)
keep hh_id exp_utilities
save "$raw\maldives\HIES_2019\working\hies_2019_expenditure_utilities.dta", replace

use "$raw\maldives\HIES_2019\working\hies_2019_expenditure_main.dta", replace
merge 1:1 hh_id using  "$raw\maldives\HIES_2019\working\hies_2019_expenditure_non_food.dta", nogen 
merge 1:1 hh_id using  "$raw\maldives\HIES_2019\working\hies_2019_expenditure_utilities.dta", nogen 
gen hh_cons_month = exp_main+exp_non_food+exp_utilities
keep hh_id hh_cons_month
save "$raw\maldives\HIES_2019\working\hies_2019_hh_consumption.dta", replace

********************************************************************************
**#3.2 income
********************************************************************************
use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\occupation.dta", clear
ren uqhh__id hh_id
ren UsualMembers__id member_id

*winsorize input variables (non-/self-employment) & compare to pre-build variable
ren incmvr_tot wage_inc_og
ren primaryIncomeAndProfitInBusiness self_inc_og
ren emp_income emp_inc_og
replace wage_inc_og = 0 if wage_inc_og==.
replace self_inc_og = 0 if self_inc_og==.
gen emp_inc = wage_inc_og + self_inc_og
sum emp_inc_og
sum emp_inc

*aggregate across primary + secondary occu
bysort hh_id member_id (occupation__id): gen inc_month = sum(emp_inc)
bysort hh_id member_id (occupation__id): gen full = (_n==_N)
keep if full==1
drop full

keep hh_id member_id inc_month
save "$raw\maldives\HIES_2019\working\hies_2019_income.dta", replace

********************************************************************************
**#3.3 employment
********************************************************************************
use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\occupation.dta", clear
keep if occupation__id==1 //primary occupation 
merge 1:1 uqhh__id UsualMembers__id using "$raw\maldives\HIES_2019\data\HIES2019_STATA format\Usualmembers.dta", nogen keep(match)

*create unique IDs
ren uqhh__id hh_id
ren UsualMembers__id member_id

**employment variables
ren primaryStatusEmp emp_stat_og
gen emp_stat = 0 if emp_stat_og==5 //Contributing family worker
replace emp_stat = 1 if emp_stat_og==6 //Group worker
replace emp_stat = 2 if (emp_stat_og==3|emp_stat_og==4) //Own account worker (with/-out family members)
replace emp_stat = 3 if emp_stat_og==1 //Employee
replace emp_stat = 4 if emp_stat_og==2 //Employer
*re: corresponds to ilo_job1_ste_icse93 reorder

gen emp_self = (ilo_job1_ste_aggregate==2) if ilo_job1_ste_aggregate!=3
gen agri = (isic_section==1) if isic_section!=.a
*gen emp_formal = (ilo_job1_ife_nature==2) if ilo_job1_ife_nature!=.a
*gen emp_formal = (ilo_job1_ife_prod==2) if ilo_job1_ife_prod!=.a //Formality Unit of Production

keep hh_id member_id emp_stat agri
save "$raw\maldives\HIES_2019\working\hies_2019_employment.dta", replace

********************************************************************************
**#3.4 education REVIEW
********************************************************************************
use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\Usualmembers.dta", clear

*create unique IDs
ren uqhh__id hh_id
ren UsualMembers__id member_id
gen child_id = hh_id + "-" + string(member_id)

**educational variables
gen literate = (Literate_mothertongue==1) if Literate_mothertongue!=.a 
gen literate_eng = (Literate_english==1) if Literate_english!=.a
gen educ_stat = (edu_everattend==1) if edu_everattend!=.a

*gen educ_og = Edu_highestgrade 
*re: lower coverage & unclear assignemnt due to varying school system

*mapping academic + vocational degrees according to Aditi scheme
/*gen educ_degree = 0 if HighestCert==7
replace educ_degree = 10 if HighestCert==0 //O-Level
replace educ_degree = 12 if HighestCert==1 //A-Level
replace educ_degree = 12 if HighestCert==2 //ACAD./VOCAT.CERT.OR DIPLOMA(LESS THAN 6 
replace educ_degree = 13 if HighestCert==3 //ACAD./VOCAT.CERT.OR DIPLOMA(MORE THAN 6
replace educ_degree = 14 if HighestCert==4 //FIRST DEGREE/MBBS
replace educ_degree = 15 if HighestCert==5 //Post-grad/masters degree 
replace educ_degree = 16 if HighestCert==6 //Post-grad/phd degree */

*mapping academic + vocational degrees according to WB (2009 data)
gen educ_degree = 0 if HighestCert==7
replace educ_degree = 10 if HighestCert==0 //O-Level
replace educ_degree = 12 if HighestCert==1 //A-Level
replace educ_degree = 12 if HighestCert==2 //ACAD./VOCAT.CERT.OR DIPLOMA(LESS THAN 6 
replace educ_degree = 15 if HighestCert==3 //ACAD./VOCAT.CERT.OR DIPLOMA(MORE THAN 6
replace educ_degree = 15 if HighestCert==4 //FIRST DEGREE/MBBS
replace educ_degree = 15 if HighestCert==5 //Post-grad/masters degree 
replace educ_degree = 15 if HighestCert==6 //Post-grad/phd degree

gen educ_og = Edu_yearsofschooling if Edu_yearsofschooling!=.a
replace educ_og = 15 if (educ_og>15 & educ_og!=.)
*add degree info to improve capture of higher education 
replace educ_og = educ_degree if educ_og==.
replace educ_og = educ_degree if educ_degree>educ_og & educ_degree!=. & educ_og!=.

*educ_og based on pre-build degree-based educational attainment variable
/*gen educ_cat_og = high_edu if high_edu!=9
replace educ_cat_og = . if high_edu==7 //level not stated
replace educ_cat_og = 0 if high_edu==8 //never attended */

save "$raw\maldives\HIES_2019\working\hies_2019_education.dta", replace

********************************************************************************
**#3.5 individual-level file
********************************************************************************
use "$raw\maldives\HIES_2019\data\HIES2019_STATA format\Usualmembers.dta", clear

*generate country/survey/year
gen country = "Maldives"
gen survey = "HIES"
gen survey_name = "Household Income and Expenditure Survey"
gen year = 2019
gen coresident = "yes"

*rename variables
ren uqhh__id hh_id
ren UsualMembers__id member_id
gen child_id = hh_id + "-" + string(member_id)
gen geo_level_1 = (atoll_code==10) if atoll_code!=. 
ren atoll_code geo_level_2  //island code 
ren wgt wt_hh
ren Age age
ren DOBYear year_birth
ren hhsize hh_size
gen female = (Sex==1)

*demographic group: non-/national OR foreign-born
gen demo = (placebirth_OtherCountry!=.)
lab def demo 0 "non-foreign origin" 1 "foreign born"
lab val demo demo

*urbanity==geo_level_1, i.e. main island
gen migration_geo_level_2 = (placeofbirth!=1) if placeofbirth!=.
gen migration_geo_level_1 = 0 if (placeofbirth==1|(placeofbirth!=1 & geo_level_2!=10))
replace migration_geo_level_1 = 1 if (placeofbirth!=1 & geo_level_2==10)
gen migration_ever = (residedanother==1) if residedanother!=.
tab migration_geo_level_2 //39.3%
tab migration_geo_level_1 //8.6%
tab migration_ever //33.6

*re: no info on religion/ethnicity
ren disability disability_og
gen disability = disability_og if disability_og!=9

*add employment data
merge 1:1 hh_id member_id using "$raw\maldives\HIES_2019\working\hies_2019_employment.dta", nogen

*add education data
merge 1:1 hh_id member_id using "$raw\maldives\HIES_2019\working\hies_2019_education.dta", nogen

*relation to hhhead 
gen hh_rel = 0 if ishead==1
replace hh_rel = 1 if relhhh==2
replace hh_rel = 2 if (relhhh==3|relhhh==4)
replace hh_rel = 3 if relhhh==6
gen child_coresident = (hh_rel==2)

parent_merge

*add individual income
merge 1:1 hh_id member_id using "$raw\maldives\HIES_2019\working\hies_2019_income.dta", nogen keep(master match)

*add HH income
merge m:1 hh_id  using "$raw\maldives\HIES_2019\working\hies_2019_hh_consumption.dta", nogen keep(master match)

*adjust education variables
foreach var in child mother father {
gen `var'_educ = `var'_educ_og +1 if `var'_educ_og>0 & `var'_educ_og!=.
replace `var'_educ = 0 if (`var'_educ_og==0|(`var'_educ_og==. & `var'_educ_stat==0))
replace `var'_educ = 0 if ((`var'_educ_og==0|`var'_educ_og==.) & `var'_literate==0)
replace `var'_educ = 1 if ((`var'_educ_og==0|`var'_educ_og==.) & `var'_literate==1)
}

drop wthoutpay
keep $var_main $var_indiv $var_cores disability demo* migration*
compress
save "$raw\maldives\hies_2019.dta", replace

********************************************************************************
********************************************************************************
**#4. Combine datasets
********************************************************************************
********************************************************************************
use "$raw\maldives\hies_2009.dta", clear
*append using "$raw\maldives\hies_2016.dta", force //recover hh_rel needed
append using "$raw\maldives\hies_2019.dta", force 

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*re: geo_level_1 = capital island (Male) or not //used as definition of urbanity in 2009
*re: geo_level_2 = island groups as defined in HIES 2019 (only 3 islands that appear in 2003 but not in 2019)
drop demo disability //only available in 2019

compress
save "$interim\maldives_dataset.dta", replace