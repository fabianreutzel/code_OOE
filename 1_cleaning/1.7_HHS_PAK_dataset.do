/******************************************************************************\
#title: "1.7_HHS_PAK_dataset"
#author: "Fabian Reutzel"
#structure: 1. PSLM 2019 (district-level, census like)
			2. PSLM 2006-2014 (district-level, census like)
			3.1 HIES 2001-2018 (province-level, SARMD)
			3.2 HIES 2007-2018 (province-level, raw data)
			4. PIHS 1991
			5.  Combine datasets + adjust variables
Remarks: 
alternating sampling of survey (province/district) 
PIHS 1998: no language variable in data despite recoded in questionnaire
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. PSLM 2019
********************************************************************************
********************************************************************************
********************************************************************************
**##1.1 survey header
********************************************************************************
use "$raw/HHS/PAK/PSLM/2019/info.dta", clear 
keep hhcode psu province district language
tostring psu, replace
replace psu = substr(psu,1,7)
destring psu, replace 
save "$interim/pslm_2019_survey_info.dta", replace 

********************************************************************************
**##1.2 disability & urbanity at birth 
********************************************************************************
use "$raw/HHS/PAK/PSLM/2019/secb2.dta", clear 
gen urban_birth = (sb2q2a==2) if (sb2q2a==1|sb2q2a==2) //movers only
replace urban_birth = 0 if region==1 & sb2q01==1
replace urban_birth = 1 if region==2 & sb2q01==1
gen geo_level_2_birth = sb2q2b
replace geo_level_2_birth = district  if sb2q01==1
gen migration_geo_level_2 = (sb2q01==2) if (sb2q01==1|sb2q01==2)
*definition: at least some difficulty in one of the asked categories seeing/hearig/walking/memory/care about oneself/speaking & understanding
gen disability = (sb2q06!=1|sb2q07!=1|sb2q08!=1|sb2q09!=1|sb2q10!=1|sb2q11!=1) if (sb2q06!=.&sb2q07!=.&sb2q08!=.&sb2q09!=.&sb2q10!=.&sb2q11!=.)
drop sb*
duplicates drop hhcode psu province district idc, force // only 1 duplicate
save "$interim/pslm_2019_disability.dta", replace 

********************************************************************************
**##1.3 employment
********************************************************************************
use "$raw/HHS/PAK/PSLM/2019/sece.dta", clear 
ren hhcode hh_id 
ren idc member_id
tostring hh_id, replace 
gen child_id = hh_id + "-" + string(member_id)
gen father_id= hh_id + "-" + string(member_id)
gen mother_id= hh_id + "-" + string(member_id)
 
ren seaq06 emp_stat_og
gen 	emp_stat = 1 if emp_stat_og==4 //paid employee
replace emp_stat = 2 if emp_stat_og==5 //unpaid family worker
replace emp_stat = 3 if emp_stat_og==1|emp_stat_og==2 //employer 1-9/>10 employees
replace emp_stat = 4 if emp_stat_og==3|emp_stat_og==6 //self employed  + owner cultivator
replace emp_stat = 5 if (emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) //other: share croper/contract cultivator/live stock only
gen agri_emp = (emp_stat_og==6|emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) if emp_stat_og!=.
gen agri = ((seaq04>=6000&seaq04<7000)|(seaq04>=9200&seaq04<9300)) if seaq04!=.

keep child_id father_id mother_id emp_* agri
save "$interim/pslm_2019_employment.dta", replace 

********************************************************************************
**##1.4 education
********************************************************************************
use "$raw/HHS/PAK/PSLM/2019/secc1.dta", clear 

*harmonize hh_id, member_id, unique individual id across countries
la var psu "Primary Sampling Unit (PSU) number"
ren hhcode hh_id 
ren idc member_id
tostring hh_id, replace 

*create a unique single-var child id*/
gen child_id = hh_id + "-" + string(member_id)
gen father_id= hh_id + "-" + string(member_id)
gen mother_id= hh_id + "-" + string(member_id) 

*Clean up relevant educ vars
gen reading_ability = (sc1q1a==1) & !mi(sc1q1a==1)
gen writing_ability = (sc1q2a==1) & !mi(sc1q1a==1)
gen literate = ((reading_ability==1) & (writing_ability==1))
 
*add numbers to value lables to identify the values easier for conditions
numlabel sc1q01, add mask("# = ")
numlabel sc1q05, add mask("# = ")

*enrollment status
ren sc1q01 educ_stat_og
gen educ_stat = (educ_stat_og!=1) if educ_stat_og!=.

*need to clean up the highest completed grade and current grade to ensure the remaining categories are all ordered
gen past_educ_level = sc1q05
gen current_grade = sc1q14
ren sc1q05 past_educ_level_og
ren sc1q14 current_grade_og 

*replace the values to order the categories
foreach var of varlist past_educ_level current_grade {
	replace `var' = . if (`var'==0|`var'==25|`var'==26|`var'==27|`var'==28)
	replace `var' = 14 if (`var'==13|`var'==14|`var'==15) //BA/BSc
	replace `var' = 15 if (`var'==16|`var'==17|`var'==18|`var'==19|`var'==20|`var'==21|`var'==24) //Master + Degrees
	replace `var' = 16 if (`var'==22|`var'==23) //PhD
}
	
*generate educational attainment
gen complete_educ = past_educ_level
replace complete_educ = current_grade - 1 if (past_educ_level==. & current_grade>=2)
replace complete_educ = 1 if complete_educ==. & literate==1 
replace complete_educ = 0 if complete_educ==. & literate==0
replace complete_educ = 0 if complete_educ==. & educ_stat==0

gen educ_og = past_educ_level
replace educ_og = current_grade -1 if past_educ_level==.
replace educ_og = 0 if educ_og==. & literate==0

keep*_id literate complete_educ educ_og educ_stat
save "$interim/pslm_2019_education.dta", replace 

********************************************************************************
**##1.5 HH roster including weights (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/PAK/PSLM/2019/plist.dta", clear 

*generate country/survey/year
gen country = "Pakistan"
gen survey = "PSLM"
gen survey_name = "Pakistan Social And Living Standards Measurement"
gen year = 2019
gen coresident = "yes"

*add additional variables
merge m:1 hhcode psu using "$interim/pslm_2019_survey_info.dta", nogen keep(match master)
merge 1:1 hhcode psu idc using "$interim/pslm_2019_disability.dta", nogen keep(match master)

/* rename variables */
ren sb1q64 year_birth 
ren sb1q9 father_num 
ren sb1q10 mother_num 
ren weights wt_hh //weights are constant within HH

*Circumstance variables from HH roster
gen female = (sb1q4==2)
*re: no info on demographic group or religion

*HH relation & co-residence stat
gen hh_rel = 0 if sb1q2==1
replace hh_rel = 1 if sb1q2==2
replace hh_rel = 2 if sb1q2==3
replace hh_rel = 3 if sb1q2==5
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*re: 98 = not in HH roster; 99 = died
gen father_home = (!mi(father_num) &father_num < 98) 
gen mother_home = (!mi(mother_num) &mother_num < 98)

/* harmonize hh_id, member_id, unique individual id across the countries */
ren hhcode hh_id 
ren idc member_id
tostring hh_id, replace 
egen hh_size = max(member_id), by(hh_id) 

*create unique IDs
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num) 

**add education & occupation data
merge m:1 father_id using "$interim/pslm_2019_education.dta", /// 
	nogen keep(master match) keepusing(literate educ_stat complete_educ educ_og)
ren complete_educ father_educ 	
ren literate father_literate
ren educ_stat father_educ_stat
ren educ_og father_educ_og 	
merge m:1 father_id using "$interim/pslm_2019_employment.dta", /// 
	nogen keep(master match) keepusing(emp_* agri)
ren agri father_agri
ren emp_stat father_emp_stat

/* merge in mother's edu */
merge m:1 mother_id using "$interim/pslm_2019_education.dta", ///
	nogen keep(master match) keepusing(literate educ_stat complete_educ educ_og)
ren complete_educ mother_educ 	
ren literate mother_literate
ren educ_stat mother_educ_stat
ren educ_og mother_educ_og 	
merge m:1 mother_id using "$interim/pslm_2019_employment.dta", /// 
	nogen keep(master match) keepusing(emp_* agri)
ren agri mother_agri
ren emp_stat mother_emp_stat

/* now merge in the respondent's educ (and keep as is)*/
merge m:1 child_id using "$interim/pslm_2019_education.dta", ///
	nogen keep(master match) keepusing(literate educ_stat complete_educ educ_og)
ren complete_educ child_educ 	
ren literate child_literate
ren educ_stat child_educ_stat
ren educ_og child_educ_og 	
merge m:1 child_id using "$interim/pslm_2019_employment.dta", /// 
	nogen keep(master match) keepusing(emp_* agri)
ren agri child_agri
ren emp_stat child_emp_stat

*rename geo levels to match coding scheme 
gen geo_level_1 = 1 if province==2 //"punjab"
replace geo_level_1 = 2 if province==3 //"sindh"
replace geo_level_1 = 3 if province==1 //"khyber pakhtunkhwa"
replace geo_level_1 = 4 if province==4 //"balochistan "
ren district geo_level_2
gen urban = (region==2)

*migration
*map district of birth to region
preserve
collapse geo_level_1, by(geo_level_2)
ren geo_level_1 geo_level_1_birth
ren geo_level_2 geo_level_2_birth
save "$interim/pslm_2019_district_mapping.dta", replace
restore
merge m:1 geo_level_2_birth using "$interim/pslm_2019_district_mapping.dta", nogen
gen migration_urban = (urban_birth!=urban) if (urban_birth!=. & urban!=.)
gen migration_geo_level_1 = (geo_level_1_birth!=geo_level_1) if (geo_level_1_birth!=. & geo_level_1!=.)
tab migration_urban //2.3%
tab migration_geo_level_1 //0.9%
tab migration_geo_level_2 //5.5%

keep $var_main $var_cores $var_indiv urban* language migration*
compress
save "$interim/pslm_2019.dta", replace

********************************************************************************
********************************************************************************
**#2. PSLM 2006-2014 => district level microdata
*re: year correponds to START of survey, e.g. 2006 = 2006-2007
*2006 PAKISTAN SOCIAL AND LIVING STANDARDS MEASUREMENT SURVEY (ROUND-III)
*2008 PAKISTAN SOCIAL AND LIVING STANDARDS MEASUREMENT SURVEY (ROUND-V)
*2010 PAKISTAN SOCIAL AND LIVING STANDARDS MEASUREMENT SURVEY (ROUND-VI)
*2012 PAKISTAN SOCIAL AND LIVING STANDARDS MEASUREMENT SURVEY (ROUND–VIII)
*2014 PAKISTAN SOCIAL AND LIVING STANDARDS MEASUREMENT SURVEY (ROUND–X)
********************************************************************************
********************************************************************************
forval year = 2006(2)2014 {
	*local year 2008
	use "$raw/HHS/PAK/PSLM/`year'/sec_b.dta", clear

	*generate country/survey/year
	gen country = "Pakistan"
	gen survey = "PSLM"
	gen survey_name = "Pakistan Social And Living Standards Measurement"
	gen year = `year'
	gen coresident = "yes"

	*add weights (re: only psu level weights for 2008 & 2012)
	if `year'==2006 merge m:1 hhcode using "$raw/HHS/PAK/PSLM/`year'/hhweights.dta", keepusing(weights) nogen keep(match)
	if `year'==2008 merge m:1 psu using "$raw/HHS/PAK/PSLM/`year'/weights.dta", keepusing(weights) nogen keep(match)
	if (`year'==2010|`year'==2014) merge m:1 hhcode using "$raw/HHS/PAK/PSLM/`year'/hhweights.dta", keepusing(weight) nogen keep(match)
	if `year'==2012 merge m:1 psu using "$raw/HHS/PAK/PSLM/`year'/weights.dta", keepusing(weight) nogen keep(match)
	
	*add education data
	if `year'==2014 tostring psu, replace
	merge 1:1 hhcode idc using "$raw/HHS/PAK/PSLM/`year'/sec_c.dta", keep(match) nogen 
	if `year'==2014 destring psu, replace
	*add occupation + income data
	merge 1:1 hhcode idc using "$raw/HHS/PAK/PSLM/`year'/sec_e.dta", keep(match) nogen 
	
	*add language data
	if `year'==2012 tostring hhcode, replace
	if `year'>=2012 merge m:1 hhcode using "$raw/HHS/PAK/PSLM/`year'/sec_a.dta", nogen keepusing(language)
	if `year'==2012 destring hhcode, replace
	if `year'==2010 merge m:1 hhcode using "$raw/HHS/PAK/PSLM/`year'/sec_a.dta", nogen keepusing(lang)
	if `year'==2010 ren lang language
	
	**rename variables 
	ren weight* wt_hh
	ren hhcode hh_id
	ren idc member_id
	ren province geo_level_1
	*ren district geo_level_2
	if `year'!=2014 gen urban = (region==1)
	if `year'==2014 gen urban = (region==2)

	*ren dist* geo_level_2 // constant only for PSLM 2006-2014. i.e. 2020 different
	
	*adjust roster coding
	if (`year'==2006|`year'==2008)				ren sbq03 hh_rel_og
	if (`year'==2010|`year'==2012|`year'==2014) ren sbq02 hh_rel_og
	if (`year'==2006|`year'==2008)	gen female = (sbq01==2) if sbq01!=.
	if (`year'==2010|`year'==2012) 	gen female = (sbq03==2) if sbq03!=.
	if `year'==2014 				gen female = (sbq04==2) if sbq04!=.
	
	*education
	gen educ_stat = (scq03==1) if scq03!=.
	gen literate = (scq01==1) if scq01!=.
	ren scq04 highest_educ
	ren scq06 current_educ
	gen educ_og = highest_educ
	replace educ_og = current_educ if !mi(current_educ)
	replace educ_og = 98 if literate==0 & educ_og==.
	replace educ_og = 98 if educ_stat==0 & educ_og==.
	gen educ_cat_og = .
	
	*occupation
	if (`year'==2006|`year'==2008){
		gen agri = (seq10==1) if seq10!=. 
		*gen agri_occu = (seq09==6) if seq09!=. //excl. unskilled agri worker
		ren seq07 emp_stat_og
		gen 	emp_stat = 1 if emp_stat_og==1 //paid employee
		replace emp_stat = 2 if emp_stat_og==6 //unpaid family worker
		replace emp_stat = 3 if emp_stat_og==7 //employer
		replace emp_stat = 4 if emp_stat_og==2|emp_stat_og==4 //self employed  + owner cultivator
		replace emp_stat = 5 if (emp_stat_og==5|emp_stat_og==4|emp_stat_og==8) //other: share croper/contract cultivator/live stock only
		gen agri_emp = (emp_stat_og==3|emp_stat_og==4|emp_stat_og==5|emp_stat_og==8) if emp_stat_og!=.
	}
	if (`year'==2010|`year'==2012) {
		gen agri = (seq05==1) if seq05!=. 
		*gen agri_occu = (seq04==6) if seq04!=. //excl. unskilled agri worker
	}
	if `year'==2014 {
		gen agri = (seq05>100&seq05<200) if seq05!=. 
		*gen agri_occu = ((seq04>6000&seq04<7000)|(seq04>9200&seq04<9300)) if seq04!=. 
	}
	if (`year'==2010|`year'==2012|`year'==2014) {
		ren seq06 emp_stat_og
		gen 	emp_stat = 1 if emp_stat_og==4 //paid employee
		replace emp_stat = 2 if emp_stat_og==5 //unpaid family worker
		replace emp_stat = 3 if emp_stat_og==1|emp_stat_og==2 //employer 1-9/>10 employees
		replace emp_stat = 4 if emp_stat_og==3|emp_stat_og==6 //self employed  + owner cultivator
		replace emp_stat = 5 if (emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) //other: share croper/contract cultivator/live stock only
		gen agri_emp = (emp_stat_og==6|emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) if emp_stat_og!=.
	}
	
	*individual income 
	if (`year'==2006|`year'==2008){
		replace seq14 = 0 if seq14==.
		gen inc_month = ((seq13*seq14) + seq16) / 12
	}
	if (`year'==2010|`year'==2012|`year'==2014){
		replace seq09 = 0 if seq09==.
		gen inc_month = (seq08*seq09+seq11+seq15+seq17+seq19+seq21)/12
	}

	*HH relation & co-residence status
	gen hh_rel = 0 if hh_rel_og==1
	replace hh_rel = 1 if hh_rel_og==2
	replace hh_rel = 2 if hh_rel_og==3
	replace hh_rel = 3 if hh_rel_og==5
	replace hh_rel = 4 if hh_rel_og==6
	gen child_coresident = (hh_rel==2)
	egen hh_size = max(member_id), by(hh_id) 
	gen child_id = string(_n)
	
	*add parental co-resident info
	parent_merge
	
	*format education variable 
		if (`year'==2006|`year'==2008) foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) //no other diplomas category
		gen `var' = `var'_og if inrange(`var'_og, 0, 10) 
		replace `var' = 12 if (`var'_og==11) //FA/F.Sc 
		replace `var' = 14 if `var'_og==12 //BA/BSc
		replace `var' = 15 if inlist(`var'_og, 13, 14, 15, 16, 17) //MSc + all other degrees 
		replace `var' = 16 if `var'_og==18 //PhD
	}
	if (`year'==2010) foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) // no class11 obs 
		gen `var' = `var'_og if inrange(`var'_og, 0, 10) // no class11 obs 
		replace `var' = 12 if (`var'_og==12) //class 12
		replace `var' = 13 if (`var'_og==17) //Polytechnic/Other Diplomas
		replace `var' = 14 if (`var'_og==14) //B.A/B.Sc 
		replace `var' = 15 if inlist(`var'_og, 16, 18, 19, 20, 21)
		replace `var' = 16 if `var'_og==22
	}
	if (`year'==2012|`year'==2014) foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) 
		gen `var' = `var'_og if inrange(`var'_og, 0, 10) 
		replace `var' = 12 if (`var'_og==12) //12=FA/F.Sc
		replace `var' = 13 if (`var'_og==11) //polytechnic diploma/other diplomas
		replace `var' = 14 if (`var'_og==13) //B.A/B.Sc
		replace `var' = 15 if inlist(`var'_og, 14, 15, 16, 17, 18) //Master+Degrees
		replace `var' = 16 if `var'_og==19 //phd
	}
	*adjust for literacy 	
	foreach var in child mother father {
		replace `var'_educ = 0 if `var'_educ_og==98
		replace `var'_educ = 0 if `var'_educ_og==. & `var'_literate==0
		replace `var'_educ = 1 if `var'_educ_og==. & `var'_literate==1
	}

	if `year'<2010 keep $var_main $var_cores $var_indiv *inc* urban 
	if `year'>=2010 keep $var_main $var_cores $var_indiv *inc* urban language
	drop highest_educ current_educ
	compress
	save "$interim/pslm_`year'", replace
}

*append all years
use "$interim/pslm_2006.dta", clear
forval year = 2008(2)2014 {
append using "$interim/pslm_`year'.dta",force
}
compress
save "$interim/pslm_2006_2014.dta", replace

********************************************************************************
********************************************************************************
**#3. HIES 2001-2018 (raw + SARMD) => province level microdata
*re: exclusion 2001 2004 2005 because no language (i.e., circumstance) available
********************************************************************************
********************************************************************************

********************************************************************************
**##3.1 HIES 2001-2018 (SARMD) => recover consumption variable 
*re: PSLM province-level conincides with HIES
*2001 PAKISTAN INTEGRATED HOUSEHOLD SURVEY (PIHS)
*2004 PSLM/HIES 2004-05 (ROUND-1)
*2005 PSLM/HIES 2005-06 (ROUND-3)
*2007 PSLM/HIES 2007-08
*2011 PSLM/HIES 2011-2012
*2013 PSLM/HIES 2013-14
*2015 PSLM/HIES 2015-16
*2018 PSLM/HIES 2018-19
********************************************************************************
foreach year in 2001 2004 2005 2007 2010 2011 2013 2015 2018 {
	*load SARMD data
	if `year'== 2001 use "$raw/HHS/PAK/SARMD/PAK_2001_PIHS_v01_M_v05_A_SARMD.dta", clear
	if `year'== 2004 use "$raw/HHS/PAK/SARMD/PAK_2004_HIES_v01_M_v05_A_SARMD.dta", clear
	if `year'== 2005 use "$raw/HHS/PAK/SARMD/PAK_2005_HIES_v02_M_v02_A_SARMD.dta", clear
	if `year'== 2007 use "$raw/HHS/PAK/SARMD/PAK_2007_HIES_v02_M_v02_A_SARMD.dta", clear
	if `year'== 2010 use "$raw/HHS/PAK/SARMD/PAK_2010_HIES_v01_M_v05_A_SARMD.dta", clear
	if `year'== 2011 use "$raw/HHS/PAK/SARMD/PAK_2011_HIES_v01_M_v05_A_SARMD.dta", clear
	if `year'== 2013 use "$raw/HHS/PAK/SARMD/PAK_2013_HIES_v01_M_v05_A_SARMD.dta", clear
	if `year'== 2015 use "$raw/HHS/PAK/SARMD/PAK_2015_HIES_v01_M_v03_A_SARMD.dta", clear
	if `year'== 2018 use "$raw/HHS/PAK/SARMD/PAK_2018_HIES_v01_M_v01_A_SARMD.dta", clear

	*generate country/survey/year
	gen country = "Pakistan"
	if year>=2005 replace survey = "PSLM/HIES "
	if year<2005 gen survey = "PSLM/HIES "
	if year==2001 replace survey = "PIHS/HIES"
	gen survey_name = "Household Integrated Economic Survey"
	gen coresident = "yes"

	*rename variables
	ren idh hh_id
	ren idp child_id
	ren wgt wt_hh
	cap ren pop_wgt wt_ind
	ren subnatid* geo_level_*
	gen female = 1 - male
	tostring psu, replace
	ren hsize hh_size

	*re: urban coding in 2015 likely to be mistake as coding in 2014-15 PSLM changed
	if "`year'"=="2015" replace urban = (urban==0)

	*occupation
	gen emp_stat = empstat
	gen emp_self = (emp_stat==4) if emp_stat!=.
	gen agri = (occup==6) if occup!=.
	*gen agri = (industry==1) if industry!=. // even less reperesentative
	if year>2007 drop empstat_*

	*education 
	ren literacy literate
	ren everattend educ_stat
	ren educy educ_og
	replace educ_og = 0 if educ_stat==0 & educ_og==.
	gen educ_cat_og = .
	
	*hh expenditure (marked as consumption)
	ren welfare hh_cons_month_wb 
	
	*individual income (wage only)
	if ("`year'"=="2001"|"`year'"=="2004") {
		gen inc_month = wage*4 if unitwage==2
		replace inc_month = wage if unitwage==5
		replace inc_month = wage/12 if unitwage==8
	}
	if ("`year'"=="2011"|"`year'"=="2013"|"`year'"=="2015"){
		gen inc_month = wage*4 if unitwage==2
		replace inc_month = wage if unitwage==5
		replace inc_month = wage/12 if unitwage==8
		replace inc_month = inc_month + (wage_2/12) if wage_2!=. & unitwage==8
	}

	if ("`year'"=="2018") gen inc_month = t_wage_total/12
	if ("`year'"!="2005"&"`year'"!="2007") {
		gen inc_month_wb = wage*4 if unitwage==2
		replace inc_month_wb = wage if unitwage==5
		replace inc_month_wb = wage/12 if unitwage==8
	}
	
	*HH income 
	if ("`year'"!="2005"&"`year'"!="2007") {
		egen hh_inc_month_wb = total(inc_month_wb), by(hh_id) 
	}
		
	*HH relation & co-residence status
	gen hh_rel = 0 if relationharm==1
	replace hh_rel = 1 if relationharm==2
	replace hh_rel = 2 if relationharm==3
	replace hh_rel = 3 if relationharm==6
	gen child_coresident = (hh_rel==2)
	
	*add parental co-resident info
	parent_merge

	*re: education formating according to questionaire UNNECCESSARY as mapping done by WB
	foreach var in child father mother {
	gen `var'_educ = `var'_educ_og 
	replace `var'_educ = 14 if `var'_educ_og==15 //presumably 4y BSc
	replace `var'_educ = 16 if `var'_educ_og>16 & `var'_educ_og!=.
	replace `var'_educ = 0 if `var'_educ_og==. & `var'_literate==0
	replace `var'_educ = 1 if `var'_educ_og==. & `var'_literate==1
	}

	drop int_month
	if "`year'"=="2005"|"`year'"=="2007" keep $var_main $var_cores $var_indiv lstatus empstat* urban* *_wb
	if "`year'"!="2015"&"`year'"!="2005"&"`year'"!="2007" keep $var_main $var_cores $var_indiv $var_labor urban* *_wb
	if "`year'"=="2015" keep $var_main $var_cores $var_indiv $var_labor urban* *_wb language
	compress
	save "$interim/PAK_SARMD_hies_`year'.dta", replace
}


********************************************************************************
**##3.2 HIES 2007-2018 (raw data)
*re: include language as circumstance (no info in 2001 2004 2005)
********************************************************************************
foreach year in 2007 2010 2011 2013 2015 2018 {
	*load HH roster
	if "`year'"=="2007" use "$raw/HHS/PAK/HIES/2007/plist.dta", clear
	if "`year'"=="2010" use "$raw/HHS/PAK/HIES/2010/plist.dta", clear
	if "`year'"=="2011" use "$raw/HHS/PAK/HIES/2011/plist.dta", clear
	if "`year'"=="2013" use "$raw/HHS/PAK/HIES/2013/plist.dta", clear
	if "`year'"=="2015" use "$raw/HHS/PAK/HIES/2015/plist.dta", clear
	if "`year'"=="2018" use "$raw/HHS/PAK/HIES/2018/plist.dta", clear

	*generate country/survey/year
	gen country = "Pakistan"
	gen survey = "HIES"
	gen survey_name = "Household Integrated Economic Survey"
	gen year = `year'
	gen coresident = "yes"
	
	*add education data	
	if "`year'"=="2007" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2007/sec2a.dta", keep(master match) nogen 
	if "`year'"=="2010" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2010/sec_c.dta", keep(master match) nogen 
	if "`year'"=="2011" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2011/sec_2a.dta", keep(master match) nogen 
	if "`year'"=="2013" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2013/sec_2ab.dta", keep(master match) nogen 
	if "`year'"=="2015" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2015/sec_2a.dta", keep(master match) nogen 
	if "`year'"=="2018" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2018/sec_2ab.dta", keep(master match) nogen 

	*rename education variables 
	if "`year'"=="2007"{
		ren s2bq* q* 
		gen literate = (s2aq01==1&s2aq02==1) if s2aq01!=.|s2aq02!=.
		gen educ_stat = (q01!=1) if q01!=.
		ren q05 highest_educ
		ren q14 current_educ
	}
	if "`year'"=="2010"{
		ren scq* q* 
		gen literate = (q01==1&q02==1) if q01!=.|q02!=.
		gen educ_stat = (q03==1) if q01!=.
		ren q04 highest_educ
		ren q06 current_educ
	}
	if "`year'"=="2011"{
		ren s2bq* q* 
		gen literate = (s2aq01==1&s2aq02==1) if s2aq01!=.|s2aq02!=.
		gen educ_stat = (q01!=1) if q01!=.
		ren q05 highest_educ
		ren q14 current_educ
	}
	if "`year'"=="2013"{
		ren s2bq* q* 
		gen literate = (s2aq01==1&s2aq02==1) if s2aq01!=.|s2aq02!=.
		gen educ_stat = (q01!=1) if q01!=.
		ren q05 highest_educ
		ren q14 current_educ
	}
	if "`year'"=="2015"{
		ren s2ac* q* 
		gen literate = (q01==1&q02==1) if q01!=.|q02!=.
		gen educ_stat = (q04==1) if q04!=.
		ren q05 highest_educ
		ren q07 current_educ
	}
	if "`year'"=="2018"{
		ren s2bq* q* 
		gen literate = (s2aq01==1&s2aq02==1) if s2aq01!=.|s2aq02!=.
		gen educ_stat = (q01!=1) if q04!=.
		ren q05 highest_educ
		ren q14 current_educ
	}
	
	*recode education
	gen educ_og = highest_educ
	replace educ_og = current_educ if !mi(current_educ)
	replace educ_og = 98 if literate==0 & educ_og==.
	replace educ_og = 98 if educ_stat==0 & educ_og==.
	gen educ_cat_og = .
		
	*add occupation + income data
	if "`year'"=="2007" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2007/sec1b.dta", keep(master match) nogen 
	if "`year'"=="2010" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2010/sec_e.dta", keep(master match) nogen 
	if "`year'"=="2011" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2011/sec_1b.dta", keep(master match) nogen 
	if "`year'"=="2013" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2013/sec_1b.dta", keep(master match) nogen 
	if "`year'"=="2015" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2015/sec_1b.dta", keep(master match) nogen 
	if "`year'"=="2018" merge 1:1 hhcode idc using "$raw/HHS/PAK/HIES/2018/sec_1b (2).dta", keep(master match) nogen 
	
	*add language data 
	if "`year'"=="2007" gen sno = 0 // merge with language of first interview	
	if "`year'"=="2007" merge m:1 hhcode sno using "$raw/HHS/PAK/HIES/2007/survey information.dta", keep(master match) keepusing(language) nogen 
	if "`year'"=="2010" merge m:1 hhcode using "$raw/HHS/PAK/HIES/2010/sec_a.dta", keep(master match) keepusing(lang) nogen 
	if "`year'"=="2011" merge m:1 hhcode using "$raw/HHS/PAK/HIES/2011/sec_00a.dta", keep(master match) keepusing(lang) nogen 
	if "`year'"=="2013" merge m:1 hhcode using "$raw/HHS/PAK/HIES/2013/sec_00a.dta", keep(master match) keepusing(lang) nogen 
	if "`year'"=="2015" merge m:1 hhcode using "$raw/HHS/PAK/HIES/2015/sec_00a.dta", keep(master match) keepusing(lang) nogen 
	if "`year'"=="2018" drop q04
	if "`year'"=="2018" merge m:1 hhcode using "$raw/HHS/PAK/HIES/2018/sec_00.dta", keep(master match) keepusing(q04) nogen 
	
	**rename variables 
	ren weight* wt_hh
	ren idc member_id
	ren province geo_level_1
	if ("`year'"=="2007"|"`year'"=="2010"|"`year'"=="2011") gen urban = (region==1)
	if ("`year'"=="2013"|"`year'"=="2015"|"`year'"=="2018") gen urban = (region==2)

	if "`year'"=="2007" ren s1bq* seq*
	if "`year'"=="2010" ren seq* seq*
	if "`year'"=="2011" ren s1bq* seq*
	if "`year'"=="2013" ren s1bq* seq*
	if "`year'"=="2015" ren s1bq* seq*
	if "`year'"=="2018" ren s1bq* seq*

	if "`year'"=="2018" ren q04 language
	ren lang* language

	if  "`year'"=="2013"|"`year'"=="2015"|"`year'"=="2018"{
		ren geo_level_1 geo_level_1_raw
		gen geo_level_1 = 1 if geo_level_1_raw==2 //punjab
		replace geo_level_1 = 2 if geo_level_1_raw==3 //sindh
		replace geo_level_1 = 3 if geo_level_1_raw==1 //nwfp
		replace geo_level_1 = 4 if geo_level_1_raw==4 //balochistan
		drop geo_level_1_raw
	}
	
	*adjust roster coding
	if "`year'"!="2010" ren s1aq02 hh_rel_og
	if "`year'"=="2010" ren sbq02 hh_rel_og
	if "`year'"=="2007" gen female = (s1aq03==2) if s1aq03!=.
	if "`year'"=="2010" gen female = (sbq03==2) if sbq03!=.
	if "`year'"=="2011" gen female = (s1aq03==2) if s1aq03!=.
	if "`year'"=="2013" gen female = (s1aq04==2) if s1aq04!=.
	if "`year'"=="2015" gen female = (s1aq04==2) if s1aq04!=.
	if "`year'"=="2018" gen female = (s1aq04==2) if s1aq04!=.
	
	*occupation
	ren seq06 emp_stat_og
	gen 	emp_stat = 1 if emp_stat_og==4 //paid employee
	replace emp_stat = 2 if emp_stat_og==5 //unpaid family worker
	replace emp_stat = 3 if emp_stat_og==1|emp_stat_og==2 //employer 1-9/>10 employees
	replace emp_stat = 4 if emp_stat_og==3|emp_stat_og==6 //self employed  + owner cultivator
	replace emp_stat = 5 if (emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) //other: share croper/contract cultivator/live stock only
	gen agri_emp = (emp_stat_og==6|emp_stat_og==7|emp_stat_og==8|emp_stat_og==9) if emp_stat_og!=.
	
	if "`year'"=="2007"| "`year'"=="2010"|"`year'"=="2011"{
		gen agri = ((seq04==61|seq04==62|seq04==92)) if seq04!=. 
	}
	if  "`year'"=="2013"|"`year'"=="2015"|"`year'"=="2018"{
		gen agri= ((seq04>6000&seq04<7000)|(seq04>9200&seq04<9300)) if seq04!=. 
	}
	
	*individual income 
	replace seq09 = 0 if seq09==. // replace months of work with zero if missing
	replace seq10 = 0 if seq08!=. //replace annual income of monthly income available
	gen inc_month = (seq08*seq09+seq10+seq15+seq17+seq19+seq21)/12

	*HH income 
	egen hh_inc_month = total(inc_month), by(hhcode) 
	
	*HH relation & co-residence status
	gen hh_rel = 0 if hh_rel_og==1 //head
	replace hh_rel = 1 if hh_rel_og==2 //spouse
	replace hh_rel = 2 if hh_rel_og==3 //son/daughter
	replace hh_rel = 3 if hh_rel_og==5 //father/mother
	replace hh_rel = 4 if hh_rel_og==4 //grand child
	gen child_coresident = (hh_rel==2)
	
	*adjust IDs for SARMD merge
	if "`year'"=="2007"{
		gen double idh = hhcode
		tostring idh, replace
		replace idh = substr(idh,1,6) + substr(idh,8,10) 
		gen str2 member_id_str= string(member_id,"%02.0f") 
		gen str11 idp = idh + member_id_str 
	}
	if "`year'"!="2007"{
		clonevar idh=hhcode
		tostring idh, replace format(%11.0f)
		gen double idp_= hhcode*100+member_id
		gen idp=string(idp_,"%16.0g")
	}
	gen hh_id = idh
	gen child_id = idp

	*HH size
	egen hh_size = count(member_id), by(hh_id)

	*add parental co-resident info
	parent_merge
	
	* format education variable 
	if "`year'"=="2007"|"`year'"=="2010"{
	foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) // no class11 obs 
		gen `var' = `var'_og if inrange(`var'_og, 0, 11) 
		replace `var' = 12 if (`var'_og==12) //class 12
		replace `var' = 13 if (`var'_og==17) //Polytechnic/Other Diplomas
		replace `var' = 14 if (`var'_og==14|`var'_og==15) //B.A/B.Sc 
		replace `var' = 15 if inlist(`var'_og, 16, 18, 19, 20, 21) //MSc + Degrees
		replace `var' = 16 if `var'_og==22 //phd
		}
	}
	if "`year'"=="2011"|"`year'"=="2013"|"`year'"=="2015"{
		foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) // no class11 obs 
		gen `var' = `var'_og if inrange(`var'_og, 0, 10) // no class11 obs 
		replace `var' = 12 if (`var'_og==12) //class 12 (fa/f.sc/icom)
		replace `var' = 13 if (`var'_og==11) //Polytechnic/Other Diplomas
		replace `var' = 14 if (`var'_og==13) //B.A/B.Sc 
		replace `var' = 15 if inlist(`var'_og, 14,15,16,17,18) //MSc + Degrees 
		replace `var' = 16 if `var'_og==19 //phd
		}
	}
	if "`year'"=="2018"{
		foreach var in child_educ mother_educ father_educ {
		*gen `var' = `var'_og + 1 if inrange(`var'_og, 0, 10) // no class11 obs 
		gen `var' = `var'_og if inrange(`var'_og, 0, 10) // no class11 obs 
		replace `var' = 12 if (`var'_og==12) //class 12 (fa/f.sc/icom)
		replace `var' = 13 if (`var'_og==11) //Polytechnic/Other Diplomas
		replace `var' = 14 if (`var'_og==13|`var'_og==14|`var'_og==15) //B.A/B.Sc
		replace `var' = 15 if inlist(`var'_og,16,17,18,19,20,21,24) //MSc + Degrees + MS
		replace `var' = 16 if (`var'_og==22|`var'_og==23) //phd
		}
	}
	
	*adjust for literacy 	
	foreach var in child mother father {
		replace `var'_educ = 0 if `var'_educ_og==98
		replace `var'_educ = 0 if `var'_educ_og==. & `var'_literate==0
		replace `var'_educ = 1 if `var'_educ_og==. & `var'_literate==1
	}
	
	*add HH consumption (SAMRD)
	if "`year'"=="2007" merge 1:1 hh_id child_id using "$interim/PAK_SARMD_hies_`year'.dta", nogen keep(match) keepusing(hh_cons_month_wb lstatus empstat)
	if "`year'"!="2007" merge 1:1 hh_id child_id using "$interim/PAK_SARMD_hies_`year'.dta", nogen keep(match) keepusing(hh_cons_month_wb hh_inc_month_wb inc_month_wb lstatus empstat wage unitwage)
	
		if "`year'"=="2007" keep $var_main $var_cores $var_indiv *inc* *cons* urban language lstatus empstat *emp
		if "`year'"!="2007" keep $var_main $var_cores $var_indiv *inc* *cons* urban language $var_labor
	drop highest_educ current_educ
	compress
	save "$interim/PAK_hies_`year'", replace
}	
	
	
*append all years
use "$interim/PAK_hies_2007.dta", clear
foreach year in 2010 2011 2013 2015 2018 {
append using "$interim/PAK_hies_`year'.dta",force
}
save "$interim/PAK_hies_2007_2018.dta", replace

********************************************************************************
********************************************************************************
**#4. PIHS 1991
*re: inc data available (Sec 5) BUT messy + in-kind payments partially in non-monetary values
*re: employment question really different to later waves 
********************************************************************************
********************************************************************************
use "$raw/HHS/PAK/PIHS/1991/F01B.DTA", clear
 
*generate country/survey/year
gen country = "Pakistan"
gen survey = "PIHS"
gen survey_name = "Pakistan Integrated Household Survey"
gen year = 1991
gen coresident = "no"

*rename variables 
ren fhom father_home
ren mhom mother_home
ren fsch father_educ_og
ren msch mother_educ_og

*lab def occ 1 "Agriculture" 2 "Business" 3 "Other"
gen father_agri = (focc==1) if focc!=.
gen mother_agri = (mocc==1) if mocc!=.
gen father_literate = (flit==1) if flit!=.
gen mother_literate = (mlit==1) if mlit!=.
ren focc father_occu
ren mocc mother_occu

replace father_educ_og = 0 if flit==2
replace mother_educ_og = 0 if mlit==2

*re: parental place of birth (urban/rural) available

*add demographic details
merge 1:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F01A.DTA", keepusing(sex rel agey) keep(match) nogen

*rename variables 
gen female = (sex==2)
ren agey age

*HH relation & co-residence status
gen hh_rel = 0 if rel==1
replace hh_rel = 1 if rel==2
replace hh_rel = 2 if rel==3
replace hh_rel = 3 if rel==5
gen child_coresident = (hh_rel==2)

*child education details
merge 1:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F03A.DTA", keepusing(read write) keep(master match) nogen
merge 1:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F03B2.DTA", keepusing(gradep) keep(master match) nogen
merge 1:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F03B1.DTA", keepusing(grade schc) keep(master match) nogen

gen child_literate = 1 if read==1 & write==1 
replace child_literate = 0 if read==2
replace child_literate = 0 if write==2

ren gradep child_educ_og
replace child_educ_og = grade if child_educ_og==.
replace child_educ_og = 0 if child_literate==0 & child_educ_og==.
foreach var in child_educ {
gen 	`var' = 0 if child_literate==0
replace `var' = `var'_og if inrange(`var'_og, 1, 10)
replace `var' = `var'_og if inlist(`var'_og, 11, 12)
replace `var' = 13 if `var'_og==16 //Technical/Vocational School
replace `var' = 14 if inlist(`var'_og, 13, 14)
replace `var' = 15 if inlist(`var'_og, 15, 17, 18, 19, 20) //Post-graduate + Degrees 
}

*add weights
tostring clust, replace
merge m:1 clust using "$raw/HHS/PAK/PIHS/1991/weights.dta", keep(match) nogen
ren weight wt_hh

*add ethnicity
destring clust, replace
merge m:1 hid using "$raw/HHS/PAK/PIHS/1991/F00A.DTA", keepusing(religion langint) keep(master match) nogen
la define religion 1 "Muslim" 2 "Christian" 3 "Other"
la val religion religion
ren langint language
la define language 1 "Urdu" 2 "Punjabi" 3 "Sindhi" 4 "Pashtu" 5 "Baluchi" 6 "Other"
la val language language

*add occupation
merge m:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F05A1.DTA", keepusing(agwrk12m) keep(master match) nogen
gen child_agri = 1 if agwrk12m==1
merge m:1 hid pid using "$raw/HHS/PAK/PIHS/1991/F05B1.DTA", keepusing(nonag12m curwrkm pmtwrkm) keep(master match) nogen
replace child_agri = 0 if nonag12m==1
*LFP questions rather non-standard 
// gen lstatus = .
// replace lstatus = 0 if agwrk12m==2 & nonag12m==2
// replace lstatus = 1 if agwrk12m==1 | nonag12m==1
// tab lstatus //~30% LFP
// gen empstat = .
// replace empstat = 1 if curwrkm==1 & pmtwrkm==1 //Paid employee
// replace empstat = 2 if curwrkm==1 & pmtwrkm==2 //Non-paid employee
// replace empstat = 1 if  agwrk12m==1 //employee in agriculture
*re: no self-employed/employer identification possible (different questionaire)

*add hh expenditure + urban/rural + province data
ren hid hhcode
merge m:1 hhcode using "$raw/HHS/PAK/PIHS/1991/PIHSEXPN.DTA", keepusing(hhsize vexp0000 province urbrural) keep(master match) nogen
ren hhsize hh_size
*ren vexp0000 hh_cons_month
ren province geo_level_1 //verified by REGIONS.TXT
gen urban = (urbrural==1) if urbrural!=.

*rename identifiers
ren hhcode hh_id
ren pid child_id
ren clust psu

*save education data only
preserve
keep hh_id child_*
save "$interim/pihs_1991_education.dta", replace
restore

*bring in mother's education
ren child_id child_id_og
gen child_id = mid
replace child_id = 999 if mi(child_id)
merge m:1 hh_id child_id using "$interim/pihs_1991_education.dta", ///
	keepusing(child_educ_og child_literate) keep(master match) nogen
ren child_educ_og mother_educ_matched
ren child_literate mother_literate_matched

*bring in father education
replace child_id = fid
replace child_id = 999 if mi(child_id)
merge m:1 hh_id child_id using "$interim/pihs_1991_education.dta", ///
	keepusing(child_educ_og child_literate) keep(master match) nogen
ren child_educ_og father_educ_matched
ren child_literate father_literate_matched

*revert child id to its original meaning
drop child_id
ren child_id_og member_id
tostring hh_id, replace
gen child_id = hh_id + "-" + string(member_id)

*format direct questionaire parent education vars
foreach var in father_educ mother_educ {
gen `var' = 0 if `var'_og==0
replace `var' = 0 if `var'_og==1
replace `var' = 5 if `var'_og==2
replace `var' = 6 if `var'_og==3
replace `var' = 8 if `var'_og==4
replace `var' = 12 if `var'_og==5
}

*replace parent education data if missing with extracted data
replace mother_educ = mother_educ_matched if mother_educ_og==. & !mi(mother_educ_matched)
replace father_educ = father_educ_matched if father_educ_og==. & !mi(father_educ_matched)
drop *matched

*topcode parent education vars from coresident
foreach var in father_educ mother_educ {
replace `var' = . if `var'==21	//other
replace `var' = 16 if `var'>16
}

*generate educ_stat
foreach var in child father mother {
gen `var'_educ_stat = (`var'_educ>1 & `var'_educ!=.)
}
gen child_emp_stat = .

*re: exclude religion*  because only available in 1991
keep $var_main $var_cores $var_indiv urban language
save "$interim/pihs_1991.dta", replace

********************************************************************************
********************************************************************************
**#5. Combine datasets + adjust variables
********************************************************************************
********************************************************************************
use "$interim/PAK_hies_2007_2018.dta", clear 
append using "$interim/pslm_2006_2014.dta", force
append using "$interim/pslm_2019.dta", force
append using "$interim/pihs_1991.dta", force

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*combine Master+Degrees & PhD for cross-country harmonization
foreach var in child father mother {
replace `var'_educ = 16 if `var'_educ==15
}

*adjust monetary outcomes 
replace hh_inc_month = .  if hh_inc_month==0
replace inc_month = .  if inc_month==0
replace hh_inc_month = .  if hh_inc_month<1
replace inc_month = .  if inc_month<1

*adjust circumstance variables
ren language language_og
gen language_extd = language_og //NOT FULLY HARMONIZED as granularity differs across waves
replace language_extd = 2 if language_og==8 //Hindko is mutually intelligible with Punjabi (+ both simialry advantaged, 5.16 vs. 5.22)
replace language_extd = 5 if language_og==9 // Siraiki 6.8% of pop + disadvantaged, 3.0
replace language_extd = 6 if language_og==7 // Balti 2.86% of pop (i.e. 6th largest group + advantaged)
replace language_extd = 7 if (language_og==5|language_og==6|language_og==10) // balochi + kashmiri + others
lab drop language
lab def language_extd ///
	1 "Urdu" ///
	2 "Punjabi + Hindko" ///
	3 "Sindhi" ///
	4 "Pushtu" ///
	5 "Siraiki" ///
	6 "Balti" ///
	7 "Other"
lab val language_extd language_extd

gen language = language_extd
replace language = 5 if language_extd>5 & language_extd!=.
lab def language ///
	1 "Urdu" ///
	2 "Punjabi + Hindko" ///
	3 "Sindhi" ///
	4 "Pushtu" ///
	5 "Other"
lab val language language

drop geo_level_2 //only availbale for 2019
lab def geo_level_1 ///
	1 "Punjab" ///
	2 "Sindh" ///
	3 "Khyber Pakhtunkhwa" ///
	4 "Balochistan"
lab val geo_level_1 geo_level_1

*re: urban_birth disability only available 2019
*re urban: 1991 high urban (49%); 2014 high rural share (82%) in line with survey doc 

*exclude surveys without language
drop if (year==2006|year==2008)

lab var geo_level_1 "Province" //other levels cannot be recovered consistently

compress
save "$clean/HHS_PAK_dataset.dta", replace