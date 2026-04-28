/******************************************************************************\
#title: "1.2_HHS_BGD_dataset"
#author: "Fabian Reutzel"
#structure: 1. HIES 2000 2005 2010 2016 2022 (SARMD)
			2. Combine datasets + adjust variables
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. HIES 2000 2005 2010 2016 2022
*re: geo_level_2 not correctly reported in SARMD => corrected in 2.
********************************************************************************
********************************************************************************
foreach year in 2000 2005 2010 2016 2022 {
	*load data
	if `year'<2016 use "$raw/HHS/BGD/SARMD/BGD_`year'_HIES_v01_M_v05_A_SARMD_IND.dta", clear
	if "`year'"=="2016" use "$raw/HHS/BGD/SARMD/BGD_`year'_HIES_v01_M_v04_A_SARMD_IND.dta", clear
	if "`year'"=="2022" use "$raw/HHS/BGD/SARMD/BGD_`year'_HIES_v01_M_v01_A_SARMD_IND.dta", clear

	*generate country/survey/year
	drop survey
	gen country = "Bangladesh"
	gen survey = "HIES"
	gen survey_name = "Household Income and Expenditure Survey"
	gen coresident = "yes"

	*rename variables
	ren wgt wt_hh
	ren pop_wgt wt_ind
	ren idh hh_id
	ren idp child_id
	gen female = 1 - male
	ren hsize hh_size
	
	*geo_level coding
	gen geo_level_1 = substr(subnatid1,1,2) 
	destring geo_level_1, replace
	gen geo_level_2 = substr(subnatid2,1,2) 
	destring geo_level_2, replace
	if "`year'"=="2022" replace geo_level_2 = . //no comparable info 

	*readjust new district formed in 2015 (i.e. Mymensingh previously part of Dhaka)
	if "`year'"=="2016" replace geo_level_1 = 30 if geo_level_1==45
	if "`year'"=="2022"{
		ren geo_level_1 geo_level_1_og
		gen geo_level_1 = .
		replace geo_level_1 = 10	if geo_level_1_og==1 //Barisal
		replace geo_level_1 = 20	if geo_level_1_og==2 //Chittagong
		replace geo_level_1 = 30	if geo_level_1_og==3 //Dhaka
		replace geo_level_1 = 40	if geo_level_1_og==4 //Khulna
		replace geo_level_1 = 30	if geo_level_1_og==5 //Mymensingh- prior part of Dhaka
		replace geo_level_1 = 50	if geo_level_1_og==6 //Rajshahi
		replace geo_level_1 = 55	if geo_level_1_og==7 //Rangpur
		replace geo_level_1 = 60	if geo_level_1_og==8 //Sylhet
		drop geo_level_1_og
	}	
		
	*religion (adjust coding for IHS accordance)
	if "`year'"=="2022"{
		gen religion_og = substr(soc,1,2) 
		destring religion_og, replace
	}
	if "`year'"!="2022" ren soc religion_og
	replace religion_og = 99 if religion_og==3
	replace religion_og = 3 if religion_og==4
	replace religion_og = 4 if religion_og==99
	lab def religion_og 1 "Muslim" 2 "Hindu" 3 "Christian" 4 "Buddhist" 
	lab val religion_og religion_og
	gen religion = (religion_og==1) if religion_og!=.
	
	*agriculture & employment status (primary occupation)
	gen agri = (occup==6) if occup!=.
	replace agri = 0 if industry!=. & agri==.
	replace agri = 1 if industry==1
	if "`year'"=="2022" replace agri = 0 //no obs

	if (`year'>2000 & `year'<2022) ren empstat emp_stat
	if "`year'"=="2000" ren empstat_v2 emp_stat //somehow  off by gender
	*re: empstat_v2 only 2 levels (paid/self; 56%/44%)
	if "`year'"=="2022" ren empstat_year emp_stat
	if "`year'"=="2022" drop empstat 
	gen empstat = emp_stat //variable with WB definition for LM
	*re: 2010 & 2016 exact same employment question despite differnt summary stats
	
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

	*income (ass:25 working days per month)
	if "`year'"=="2000" ren *wage_v2* *wage*
	if "`year'"=="2000" ren *wage_2_v2* *wage_2*
	replace wage = 0 if wage==.
	replace wage_2 = 0 if wage_2==.
	gen inc_month_1 = wage*25 if unitwage==1
	replace inc_month_1 = wage if unitwage==2
	gen inc_month_2 = wage_2*25 if unitwage_2==1
	replace inc_month_2 = wage_2 if unitwage_2==2
	gen inc_month_wb = inc_month_1 + inc_month_2

	*HH expenditure
	ren welfare hh_cons_month_wb //marked as expenditure (in line with the extended consumption definition)

	*format education variable
	foreach var in child father mother {
	gen `var'_educ = `var'_educ_og if `var'_educ_og>0 & `var'_educ_og!=.
	replace `var'_educ = 16 if (`var'_educ_og>=16 & `var'_educ_og!=.) //topcode for comparability 
	replace `var'_educ = 1 if (`var'_literate==1 & `var'_educ_og==.)
	replace `var'_educ = 0 if `var'_educ_og==0
	replace `var'_educ = 0 if (`var'_literate==0 & `var'_educ_og==.)
	replace `var'_educ = 0 if (`var'_educ_stat==0 & `var'_educ_og==.)
	}

	keep $var_main $var_cores $var_indiv $var_labor urban religion_og *_wb //educ_cat_og
	compress
	save "$interim/BGD_hies_`year'.dta", replace
}

********************************************************************************
********************************************************************************
**#2. Combine datasets + adjust variables
********************************************************************************
********************************************************************************
use "$interim/BGD_hies_2000.dta", clear
foreach year in 2005 2010 2016 2022 {
  append using "$interim/BGD_hies_`year'"
}

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*adjust circumstance variables
gen religion = (religion_og==1) if religion_og!=.
lab def religion 0 "Hindu + Others" 1 "Muslim" //re:others <2%
lab val religion religion
*language & demo limited variation in sample

*adjust coding geo_level for harmonization
ren geo_level_1 geo_level_1_og_raw
merge m:1 geo_level_2 using "$raw/auxiliary/geo_level/BGD_division_mapping.dta"
ren geo_level_1 geo_level_1_og
replace geo_level_1_og = geo_level_1_og_raw if year==2017|year==2022
gen geo_level_1 =  geo_level_1_og/10
replace geo_level_1 = 6 if geo_level_1_og==55
replace geo_level_1 = 7 if geo_level_1_og==60

*define geo labels
lab def geo_level_1_og ///
	10"Barisal" ///
	20"Chittagong" ///
	30"Dhaka" ///
	40"Khulna" ///
	50"Rajshahi" ///
	55"Rangpur" ///
	60"Sylhet" //re: disregard Mymensingh founded in 2015
lab def geo_level_1 ///
	1"Barisal" ///
	2"Chittagong" ///
	3"Dhaka" ///
	4"Khulna" ///
	5"Rajshahi" ///
	6"Rangpur" ///
	7"Sylhet"
lab def geo_level_2 ///
	1"Bagerhat" ///
	10"Bogra" ///
	12"Brahmanbaria" ///
	13"Chandpur" ///
	15"Chittagong" ///
	18"Chuadanga" ///
	19"Comilla" ///
	22"Cox's bazar" ///
	26"Dhaka" ///
	27"Dinajpur" ///
	29"Faridpur" ///
	3"Bandarban" ///
	30"Feni" ///
	32"Gaibandha" ///
	33"Gazipur" ///
	35"Gopalganj" ///
	36"Habiganj" ///
	38"Jaipurhat" ///
	39"Jamalpur" ///
	4"Barguna" ///
	41"Jessore" ///
	42"Jhalokati" ///
	44"Jhenaidah" ///
	46"Khagrachari" ///
	47"Khulna" ///
	48"Kishoreganj" ///
	49"Kurigram" ///
	50"Kushtia" ///
	51"Lakshmipur" ///
	52"Lalmonirhat" ///
	54"Madaripur" ///
	55"Magura" ///
	56"Manikganj" ///
	57"Meherpur" ///
	58"Maulvibazar" ///
	59"Munshigan" ///
	6"Barisal" ///
	61"Mymensingh" ///
	64"Naogaon" ///
	65"Narail" ///
	67"Narayanganj" ///
	68"Narsingdi" ///
	69"Natore" ///
	70"Nawabganj" ///
	72"Netrokona" ///
	73"Nilphamari" ///
	75"Noakhali" ///
	76"Pabna" ///
	77"Panchagar" ///
	78"Patuakhali" ///
	79"Pirojpur" ///
	81"Rajshahi" ///
	82"Rajbari" ///
	84"Rangamati" ///
	85"Rangpur" ///
	86"Shariatpur" ///
	87"Satkhira" ///
	88"Sirajganj" ///
	89"Sherpur" ///
	9"Bhola" ///
	90"Sunamganj" ///
	91"Sylhet" ///
	93"Tangail" ///
	94"Thakurgaon"
lab val geo_level_1 geo_level_1
lab val geo_level_1_og geo_level_1_og
lab val geo_level_2 geo_level_2

*simplify emp_stat definitions
lab def emp_stat 0 "Self-employed/Employer" 1 "Paid Employee"
foreach var in child father mother {
	replace `var'_emp_stat = 0  if `var'_emp_stat==3|`var'_emp_stat==4
	lab var `var'_emp_stat emp_stat 
}

*exclude 2015 from education analysis (only 1/3 of obs has info on years of education + cat_wb seems not aligining with it)
replace child_educ = . if year==2015

drop *og empstat_*
drop if geo_level_1==.
lab var geo_level_1 "Division" //7
lab var geo_level_2 "District" //64
compress
save "$clean/HHS_BGD_dataset.dta", replace