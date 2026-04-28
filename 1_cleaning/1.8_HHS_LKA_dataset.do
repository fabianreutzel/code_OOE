/******************************************************************************\
#title: "1.8_HHS_LKA_dataset"
#author: "Fabian Reutzel"
#structure: 1. HIES 2002 2006 2009 2012 2019 (SARMD)
			2. HIES 1995 (raw)
			3. HIES 1990 (raw)
			4. Combine datasets
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. 2011-12 2002 2006 2009 2012 2019
********************************************************************************
********************************************************************************
use "$raw/HHS/LKA/SARMD/LKA_2019_HIES_v01_M_v03_A_SARMD_IND.dta", clear
replace subnatid1 = substr(subnatid1,1,1)
replace subnatid2 = substr(subnatid2,1,2)
drop relationcs
tostring psu, replace
replace soc = substr(soc,1,1)
destring soc, replace
replace soc = 99 if soc==5 // adjust for switch Burgher/Malay
replace soc = 5 if soc==6
replace soc = 6 if soc==99
append using "$raw/HHS/LKA/SARMD/LKA_2016_HIES_v01_M_v02_A_SARMD_IND.dta"
replace subnatid1 = substr(subnatid1,1,1)
replace subnatid2 = substr(subnatid2,1,2)
destring psu subnatid1 subnatid2, replace
foreach yy in 02 06 09 12 {
  append using "$raw/HHS/LKA/SARMD/LKA_20`yy'_HIES_v01_M_v03_A_SARMD_IND.dta"
}

*generate country/survey/year
gen country = "Sri Lanka"
replace survey = "HIES"
gen survey_name = "Household Income and Expenditure Survey"
gen coresident = "yes"

*rename variables
ren idh hh_id
ren idp child_id
ren wgt wt_hh
cap ren pop_wgt wt_ind
ren subnatid* geo_level_*
tostring psu, replace
gen female = 1 - male
ren soc demo
ren hsize hh_size

*employment
replace lstatus = lstatus_v2 if year==2016 //defintion appears harmonized
replace empstat = empstat_v2 if year==2016 //defintion appears harmonized
gen emp_stat = empstat
gen emp_self = (emp_stat==4) if emp_stat!=.

*re: 2002 question non-comparable: 
*Engage in any of the following activities during last month/cultivation year as employer, employee or own account worker?
*gen byte empstat=1 if r1c11==1 //Paid employment
*replace empstat=4 if r1c12==1| r1c13==1 | r1c14==1 //Agriculture (Seasonal crops) | Agricultural (Non seasonal crops, livestock, fishing) | Non agricultural activities

*occupation	
gen agri_occu = (occup==6) if occup!=.
gen agri = (industry==1) if industry!=.
*adjust for 2016
replace agri_occu = (occup_v2==6) if occup_v2!=.
replace agri = (industry_v2==1) if industry_v2!=.

*education 
gen literate = . //educ_stat 
ren educy educ_og
gen educ_stat = .
gen educ_cat_og = . //categorical variable entirely based on years

*hh expenditure / income
ren welfare hh_cons_month_wb
ren welfareother hh_inc_month_wb

*individual income (wage only)
replace wage = wage_v2 if year==2016
gen inc_month_wb = wage //re: unitwage=monthly for all obs 

*HH relation & co-residence status
gen hh_rel = 0 if relationharm==1
replace hh_rel = 1 if relationharm==2
replace hh_rel = 2 if relationharm==3
replace hh_rel = 3 if relationharm==6
gen child_coresident = (hh_rel==2)

*add parental co-resident info
parent_merge

*format education variables (UNNECESSARY to follow questionnaire as WB already mapped into years)
foreach var in child_educ mother_educ father_educ {
  gen `var' = `var'_og
  replace `var' = 13 if `var'_og==14 & (year==2012|year==2016|year==2019) //GAQ/GSQ = univ. entry exam after 13y; coded as such in all previous waves 
  replace `var' = 17 if `var'_og==15 & (year==2012|year==2016) //passed degree 17y; coded as such in all previous waves
  replace `var' = 19 if (`var'_og==16|`var'_og==17) & (year==2012|year==2016) //passed post-graduate/phd 19y; coded as such in all previous waves
  replace `var'_stat = (`var'!=0) if `var'!=.
}
keep $var_main $var_indiv $var_cores urban demo* *_wb wage lstatus empstat unitwage
save "$interim/LKA_hies_2002_2019.dta", replace

********************************************************************************
********************************************************************************
**#2. HIES 1995
********************************************************************************
********************************************************************************

********************************************************************************
**##2.1 generate mapping for geo_level_2 1995 to >=2002
********************************************************************************
use "$raw/HHS/LKA/SARMD/LKA_2002_HIES_v01_M_v03_A_SARMD_IND.dta", clear
ren subnatid2 district_2002
decode district_2002, gen(district_adj)
duplicates drop district_2002, force
keep district_2002 district_adj
save "$interim/LKA_district_2002.dta", replace

insheet using "$raw/HHS/LKA/HIES/1995-96/RECORD_TYPE_2.CSV", clear
ren district district_1995
la def district_1995 ///
	1 "Colombo" ///
	2 "Gampaha" ///
	3 "Kalutara" ///
	4 "Kandy" ///
	5 "Matale" ///
	6 "Nuwara-eliya" ///
	7 "Galle" ///
	8 "Matara" ///
	9 "Hambantota" ///
	18 "Kurunegala" ///
	19 "Puttlam" ///
	20 "Anuradhapura" ///
	21 "Polonnaruwa" ///
	22 "Badulla" ///
	23 "Moneragala" ///
	24 "Ratnapura" ///
	25 "Kegalle",  replace
la val district_1995 district_1995
decode district_1995, gen(district_adj)
duplicates drop district_1995, force
keep district_1995 district_adj
save "$interim/LKA_district_1995.dta", replace

use "$interim/LKA_district_2002.dta", clear
merge 1:1 district_adj using  "$interim/LKA_district_1995.dta", nogen 
save "$interim/LKA_district_1995_2002.dta", replace

insheet using "$raw/auxiliary/geo_level/LKA_province_district_mapping.csv", clear
save "$interim/LKA_province_district_mapping.dta", replace

********************************************************************************
**##2.2 HH roster
********************************************************************************
insheet using "$raw/HHS/LKA/HIES/1995-96/RECORD_TYPE_2.CSV", clear
duplicates drop sector district d_s__division census_block_number household_number serial_number, force

*generate country/survey/year
gen country = "Sri Lanka"
gen survey = "HIES"
gen survey_name = "Household Income and Expenditure Survey"
gen year = 1995
gen coresident = "yes"

*adjust geo_level_2
rename district district_1995
merge m:1 district_1995 using "$interim/LKA_district_1995_2002.dta", nogen keepusing(district_2002)

*adjust geo_level_1
ren district_2002 district
merge m:1 district using "$interim/LKA_province_district_mapping.dta", nogen keepusing(province)
rename district geo_level_2
rename province geo_level_1

*gen unique hh_id
gen hhid = string(sector) + "-" + string(district_1995) + "-" + ///
string(d_s__division) + "-" + string(census_block_number) + "-" + string(household_number)
egen hh_id = group(hhid)

*rename variables
ren serial_number member_id
gen child_id = string(hh_id) + "-" + string(member_id)
ren inflation_factos wt_hh
gen female = sex == "2" & !mi(sex)
destring age, replace
ren census_block_number psu
egen hh_size = max(member_id), by(hh_id) 

*urban => re: no geo_level_1
gen urban = (sector==1) if sector!=.
*replace urban = . if sector==3

*religion
destring religion, replace
la define religion 1 "Buddhist" 2 "Hindu" 3 "Muslim" 4 "Christian" 9 "Other", replace
la val religion religion

*demo
ren ethnicity demo
destring demo, replace
replace demo = 7 if demo==9 //align with World Bank coding 

*occupation
replace industry_code = "" if industry_code=="***"
destring industry_code, replace
gen agri = (industry_code==1|(industry_code>=10&industry_code<20)|(industry_code>=100&industry_code<200)) if industry_code!=.
destring employment_status, replace
lab def emp_stat_og 1 "gov employee" 2 "semi-gov employee" 3 " private employee" 4 "employer" 5 "own account worker" 6 "unpaid family worker", replace
ren employment_status emp_stat_og
lab val emp_stat_og emp_stat_og
gen emp_salary = (emp_stat_og==1|emp_stat_og==2|emp_stat_og==3) if emp_stat_og!=.
gen 	emp_stat = 1 if emp_salary==1 //Paid employee
replace emp_stat = 2 if emp_stat_og==6 //Non-paid employee
replace emp_stat = 3 if emp_stat_og==4 //Employer
replace emp_stat = 4 if emp_stat_og==5 //Self-employed
gen empstat = emp_stat
destring activity, replace
gen 	lstatus = 1 if activity==1
replace lstatus = 2 if activity==2
replace lstatus = 3 if activity!=1&activity!=2&activity!=. 

*education 
destring l_o_education literacy, replace
gen literate = (literacy==1) if literacy!=.  
ren l_o_education educ_og
replace educ_og = 0 if literate==0 & educ_og==.
gen educ_stat = . 
gen educ_cat_og = . 

*HH relation & co-residence status
gen hh_rel = 0 if relationship==1
replace hh_rel = 1 if relationship==2
replace hh_rel = 2 if relationship==3
replace hh_rel = 3 if relationship==4
gen child_coresident = (hh_rel==2)

*add parental co-resident info
parent_merge

foreach var in child_educ mother_educ father_educ {
  gen `var' = 0 if `var'_og==99
  replace `var' = `var'_og if inrange(`var'_og, 1, 13)
  replace `var' = 13 if `var'_og==14 // GAQ/GSQ = univ. entry exam after
  replace `var' = 17 if `var'_og==15 // degree
  replace `var' = 19 if `var'_og==16 // post graduate
  replace `var'_stat = (`var'!=0) if `var'!=.
}
tostring hh_id, replace
tostring psu, replace
keep $var_main $var_indiv $var_cores $var_outcome urban demo* empstat lstatus
compress
save "$interim/LKA_hies_1995.dta", replace

********************************************************************************
********************************************************************************
**#3. HIES 1990
********************************************************************************
********************************************************************************
insheet using "$raw/HHS/LKA/HIES/1990-91/REC2.CSV", clear
duplicates drop sector* district* a_g_a* census_block* hhnum* serno*, force

*generate country/survey/year
gen country = "Sri Lanka"
gen survey = "HIES"
gen survey_name = "Household Income and Expenditure Survey"
gen year = 1990
gen coresident = "yes"

*adjust geo_level_2
*readjust for coding error as sample size of 17/18 corresponds btw 1990/1995)
*1990: 17(6261) vs 18(3,523) & 1995: 18(6008) vs 19(3,799)
ren district district_raw
gen 	district = district_raw
replace district = district + 1 if district>9 
rename district district_1995
merge m:1 district_1995 using "$interim/LKA_district_1995_2002.dta", nogen keepusing(district_2002)

*adjust geo_level_1
ren district_2002 district
merge m:1 district using "$interim/LKA_province_district_mapping.dta", nogen keepusing(province)
rename district geo_level_2
rename province geo_level_1

*gen unique hh_id
gen hhid = string(sectorq_3) + "-" + string(district_raw) + "-" + ///
	string(a_g_a_divq_6) + "-" + string(census_blocknoq_2) + "-" + string(hhnumberq_1)
egen hh_id = group(hhid)

*rename variables
ren serno* member_id
gen child_id = string(hh_id) + "-" + string(member_id)
ren *03q_51 relationship
ren *04q_52 sex
destring *05q_53 , gen(age)
ren inflation_facto* wt_hh
gen female = (sex=="2") if !mi(sex)
ren census_blocknoq_2 psu
egen hh_size = max(member_id), by(hh_id) 

gen urban = (sector==1)

*religion
ren *07q_55 religion
destring religion, replace
la val religion religion

*demo
ren *06q_54 demo
destring demo, replace
replace demo = 8 if demo==9
la val demo demo

*occupation
ren column_15q_61 industry_code
ren column_16q_62 employment_status
replace industry_code = "" if industry_code=="***"
destring industry_code, replace
gen agri = (industry_code==1|(industry_code>=10&industry_code<20)|(industry_code>=100&industry_code<200)) if industry_code!=.
destring employment_status, replace
lab def emp_stat_og 1 "gov employee" 2 "semi-gov employee" 3 " private employee" 4 "employer" 5 "own account worker" 6 "unpaid family worker", replace
ren employment_status emp_stat_og
lab val emp_stat_og emp_stat_og
gen emp_salary = (emp_stat_og==1|emp_stat_og==2|emp_stat_og==3) if emp_stat_og!=.
gen 	emp_stat = 1 if emp_salary==1 //Paid employee
replace emp_stat = 2 if emp_stat_og==6 //Non-paid employee
replace emp_stat = 3 if emp_stat_og==4 //Employer
replace emp_stat = 4 if emp_stat_og==5 //Self-employed
gen empstat = emp_stat
destring column_11q_59, gen(activity)
gen 	lstatus = 1 if activity==1
replace lstatus = 2 if activity==2
replace lstatus = 3 if activity!=1&activity!=2&activity!=. 

*education 
ren *08q_56 educ_og
ren *09q_57 literacy
destring educ_og literacy, replace
gen literate = (literacy==1) if literacy!=.  
replace educ_og = 0 if literate==0 & educ_og==.
gen educ_stat = .
gen educ_cat_og = . 

*HH relation & co-residence status
gen hh_rel = 0 if relationship==1
replace hh_rel = 1 if relationship==2
replace hh_rel = 2 if relationship==3
replace hh_rel = 3 if relationship==4
gen child_coresident = (hh_rel==2)

*add parental co-resident info
parent_merge

foreach var in child_educ mother_educ father_educ {
  gen `var' = 0 if `var'_og==99
  replace `var' = `var'_og if inrange(`var'_og, 1, 13)
  replace `var' = 13 if `var'_og==14 //GAQ/GSQ = univ. entry exam after
  replace `var' = 17 if `var'_og==15 // degree
  replace `var' = 19 if `var'_og==16 // post graduate
  replace `var'_stat = (`var'!=0) if `var'!=.
}
tostring hh_id, replace
tostring psu, replace
keep $var_main $var_indiv $var_cores urban demo* empstat lstatus
compress
save "$interim/LKA_hies_1990.dta", replace

********************************************************************************
********************************************************************************
**#4. Combine datasets
********************************************************************************
********************************************************************************
use "$interim/LKA_hies_2002_2019.dta", clear
append using "$interim/LKA_hies_1995.dta"
append using "$interim/LKA_hies_1990.dta"

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*top code education as mapping of degrees into years varies
*i.e., distinction between degree(Bachelor) and post-grad degree (master, phd) not consistent across time 
foreach var in child mother father {
  replace `var'_educ = 16 if `var'_educ>16 & `var'_educ<=19
}

*adjust circumstance variables to curtail sample variance
ren demo demo_og
gen demo_extd = demo_og 
lab define demo_extd ///
	1 "Sinhalese" ///
	2 "Sri Lanka Tamil" ///
	3 "Indian Tamil" ///
	4 "Sri Lanka Moors" ///
	5 "Malay + Other" ///
	6 "Burgher" ///
	7 "Other"
lab val demo_extd demo_extd

*combine others + Sinhalese + combine Sri Lanka Tamil+Moors
*preserve
*collapse child_educ, by(demo)
*Sinhalese			7.827323
*Sri Lanka Tamil	6.807484
*Indian Tamil		5.037744
*Sri Lanka Moors	6.992605
*Others				8.115897
*restore

gen demo = demo_extd
replace demo = 1 if demo_extd>4 & demo_extd!=.
replace demo = 1 if demo_extd==. & (year==1990|year==1995) //code missing as others as similar priveleged (1990/95)
replace demo = 2 if demo_extd==4 & demo_extd!=.
lab define demo ///
	1 "Sinhalese + Others" ///
	2 "Sri Lanka Tamil + Moors" ///
	3 "Indian Tamil"
lab val demo demo

*regroup provinces by geographic region 
*preserve
*collapse child_educ, by(geo_level_1)
*geo_level_1	child_educ
*West			8.303021
*Central		6.91109
*South			7.469625
*North			7.87567
*East			7.158049
*North West		7.366012
*North Central	7.254181
*Uva			6.529892
*Sabaragamuwa	7.215607
*restore

drop geo_level_3
ren geo_level_2 geo_level_3
ren geo_level_1 geo_level_2
gen 	geo_level_1 = geo_level_2
replace geo_level_1 = 6 if geo_level_2==7 // North West + North Central
replace geo_level_1 = 2 if geo_level_2==9 // Central + Sabaragamuwa
replace geo_level_1 = 7 if geo_level_2==8

lab def geo_level_1 ///
	1 "West" ///
	2 "Central + Sabaragamuwa" ///
	3 "South" ///
	4 "North" ///
	5 "East" ///
	6 "North West/Central" ///
	7 "Uva" 
lab val geo_level_1 geo_level_1

lab def geo_level_2 ///
	1 "West" ///
	2 "Central" ///
	3 "South" ///
	4 "North" ///
	5 "East" ///
	6 "North West" ///
	7 "North Central" ///
	8 "Uva" ///
	9 "Sabaragamuwa"
lab val geo_level_2 geo_level_2

lab var geo_level_1 "Region" //7
lab var geo_level_2 "Province" //9
lab var geo_level_3 "District" //25

drop *_og
compress
save "$clean/HHS_LKA_dataset.dta", replace