/******************************************************************************\
#title: "1.11_LFS_dataset"
#author: "Fabian Reutzel"
#structure: 1. Merge LFS datasets 
\******************************************************************************/

********************************************************************************
**#1. Merge LFS datasets
********************************************************************************
use "$clean/LFS_BTN.dta", clear
append using "$clean/LFS_BGD.dta", force
append using "$clean/LFS_IND.dta", force
append using "$clean/LFS_NPL.dta", force
append using "$clean/LFS_LKA.dta", force

*keep only relevant observations
drop if lstatus == .

**adjust education 
*IND
*recover educy for surveys prior 2022 India
replace educat_orig =. if educat_orig == 99 //adjust missing for educ
*adjust for different educ coding across EUS waves
replace educat_orig = 1 if educat_orig == 0 & year == 1987 & countrycode == "IND" //0 instead of 1 for non-literate
replace educat_orig = 12 if educat_orig >= 6 & educat_orig<=9 & year == 1987 & countrycode == "IND" //graduate and above (different fields)
replace educat_orig = educat_orig + 3 if educat_orig >= 2 & educat_orig<=5 & year == 1987 & countrycode == "IND" //only 2 versions of no schooling ( non-literate, without formal schooling)
replace educat_orig = 12 if educat_orig >= 10 & educat_orig<=13 & (year == 1999|year == 1993) & countrycode == "IND" //graduate and above (different fields)
replace educat_orig = 10 if educat_orig == 9 & (year == 1999|year == 1993) & countrycode == "IND" //higher secondary (missing omission of 9 from coding)
replace educat_orig = educat_orig - 1 if educat_orig >= 5 & year == 2007 & countrycode == "IND" //(+1 option of literate without formal schooling)
replace educat_orig = 10 if educat_orig == 9 & (year == 1999|year == 1993) & countrycode == "IND" //higher secondary (readjust after -1)
gen educ_raw_EUS = educat_orig if countrycode == "IND" & year<2017
replace educy = 0 	if educ_raw_EUS == 1|educ_raw_EUS == 2|educ_raw_EUS == 3|educ_raw_EUS == 4 // no formal schooling (non-literate)
replace educy = 2 	if educ_raw_EUS == 5 	//below primary
replace educy = 5 	if educ_raw_EUS == 6 	//primary
replace educy = 8 	if educ_raw_EUS == 7 	//middle
replace educy = 10 	if educ_raw_EUS == 8|educ_raw_EUS == 9 //secondary
replace educy = 12 	if educ_raw_EUS == 10	//higher secondary
replace educy = 13 	if educ_raw_EUS == 11 //diploma/certificate course
replace educy = 15 	if educ_raw_EUS == 12 //graduate
replace educy = 17 	if educ_raw_EUS == 13 //postgraduate and above
*2017-2021 only cat7 in current version (detailed version to be recovered from raw data)
gen educ_raw_PLFS = educat7 if countrycode == "IND" & year >= 2017
replace educy = 0 	if educ_raw_PLFS == 1 //no formal schooling
replace educy = 2 	if educ_raw_PLFS == 2 //below primary
replace educy = 5 	if educ_raw_PLFS == 3 //primary
replace educy = 8 	if educ_raw_PLFS == 4 //secondary incomplete
replace educy = 10 	if educ_raw_PLFS == 5 & educat_isced == 244 //secondary
replace educy = 12 	if educ_raw_PLFS == 5 & educat_isced == 344 //higher secondary
replace educy = 13 	if educ_raw_PLFS == 6 //diploma/certificate course = Higher than secondary but not university
replace educy = 15 	if educ_raw_PLFS == 7 & educat_isced == 660 //graduate
replace educy = 17 	if educ_raw_PLFS == 7 & educat_isced == 760 //post-graduate
*re: for fully comparability surpress differntiation between post-/graduate
*re: 1987 missing distinction higher/secondary (10 vs. 12 years)

*BGD
*correct years of education BGD (2013 excluded from education returns analysis due to too low <primary share 38 vs 49 (2015) vs 51 (2010))
gen educ_raw_BGD = educat_orig if countrycode == "BGD"
replace educy = 0 	if educ_raw_BGD == 1 & (year == 2005|year == 2010) 
replace educy = 5 	if educ_raw_BGD == 2 & (year == 2005|year == 2010) //class 1-5 (in/complete primary) BUT share of 0 aligns with subsequent surveys
replace educy = 7 	if educ_raw_BGD == 3 & (year == 2005|year == 2010) //class 6-8
replace educy = 9 	if educ_raw_BGD == 4 & (year == 2005|year == 2010) //class 9
replace educy = 10 	if educ_raw_BGD == 5 & (year == 2005|year == 2010) //secondary
replace educy = 12 	if educ_raw_BGD == 6 & (year == 2005|year == 2010) //intermediate
replace educy = 12 	if educ_raw_BGD == 10 & (year == 2005|year == 2010) //technical equcation (technical/vocational)
replace educy = 15 	if educ_raw_BGD == 7 & (year == 2005|year == 2010) //graduate
replace educy = 17 	if educ_raw_BGD == 8|educ_raw_BGD == 9 & (year == 2005|year == 2010) //postgraduate/medical/engineering
*replace educy = . 	if educ_raw_BGD == 11 & (year == 2005|year == 2010) //others
replace educy = 0 	if educ_raw_BGD == . & year == 2013 & countrycode == "BGD" //no missings in previous years 
replace educy = educ_raw_BGD if educ_raw_BGD<=10 & year>2010 
replace educy = 10 	if educ_raw_BGD == 11 & year == 2013 //SSC
replace educy = 12 	if educ_raw_BGD == 12 & year == 2013 //HSC
replace educy = 13 	if educ_raw_BGD == 13 & year == 2013 //diploma
replace educy = 15 	if educ_raw_BGD == 14 & year == 2013 //bachelor
replace educy = 17 	if educ_raw_BGD == 15|educ_raw_BGD == 16 & year == 2013 //masters + PhD
replace educy = 12 	if educ_raw_BGD == 11 & year >= 2015 //HSC
replace educy = 13 	if educ_raw_BGD == 12 & year >= 2015 //diploma
replace educy = 15 	if educ_raw_BGD == 13 & year >= 2015 //bachelor
replace educy = 17 	if educ_raw_BGD == 14|educ_raw_BGD == 15 & year >= 2015 //masters + PhD

*LKA
*correct years of education LKA for categorical coding prior 1996
replace educy = 4 	if  educat_orig == 1 & year<=1995 & countrycode == "LKA"  //Passed Grade 0-4 = primary incomplete

*adjust country variable
replace country = "Bangladesh" if countrycode == "BGD"
replace country = "Bhutan" if countrycode == "BTN"
replace country = "India" if countrycode == "IND"
replace country = "Nepal" if countrycode == "NPL"
replace country = "Sri Lanka" if countrycode == "LKA"

*adjust survey names 
replace survey = "EUS" if country == "India" & year<2017
replace survey = "PLFS" if country == "India" & year >= 2017
gen survey_name = "Labor Force Survey (GLD)"
replace survey_name = "Labor Force Survey (SARLAB)" if country == "Bhutan"

*generate cohort variables
gen year_birth = year-age
gen age_2 = age^2
egen cohort_5 = cut(year_birth), at(1950 (5) 2000)
replace cohort_5 = (cohort_5-1945)/5
*age-cohort identifiers
egen age_5 = cut(age), at(25 (5) 65)
replace age_5 = (age_5-20)/5
gen cohort_age_5 =		"0"+string(cohort_5)+"0"+string(age_5) 	if cohort_5!=. & age_5!=. & cohort_5<10.
replace cohort_age_5 =	string(cohort_5)+"0"+string(age_5)		if cohort_5!=. & age_5!=. & cohort_5 >= 10. 

*generate harmonized demo variable
ren demo demo_raw
gen demo 	 = demo_raw + 20 if country == "Bangladesh" & demo_raw!=.
replace demo = demo_raw + 40 if country == "India" & demo_raw!=.
replace demo = demo_raw + 60 if country == "Nepal"  & demo_raw!=.
replace demo = demo_raw + 80 if country == "Sri Lanka" & demo_raw!=.

*adjust Sri Lanka for sample size concerns (+ reduce types)
replace demo = 82 if demo == 84 //Sri Lanka Tamil + Moors
replace demo = 81 if demo == 85 //Sinhalese + Others

lab def demo_harmonized ///
	11 "Pashtun" ///
	12 "Tajik" ///
	13 "Uzbek" ///
	14 "Nuristani" ///
	15 "Others + Mixed" ///
	20 "Hindu + Others" ///
	21 "Muslim" ///
	41 "Scheduled Caste" ///
    42 "Scheduled Tribe" ///
    43 "Other backward Class" ///
    44 "Muslim" ///
	45 "Others" /// 
	61 "Janajati" ///
	62 "Khas" ///
	63 "Muslim" ///
	64 "Others" ///
	71 "Urdu" ///
	72 "Punjabi + Hindko" ///
	73 "Sindhi" ///
	74 "Pushtu" ///
	75 "Others" ///
	81 "Sinhalese + Others" ///
	82 "Sri Lanka Tamil + Moors" ///
	83 "Indian Tamil"
lab val demo demo_harmonized

**generate harmonized geo variable
ren geo_level_1 geo_level_1_raw
gen 	geo_level_1 = .
replace geo_level_1 = geo_level_1_raw + 20 if country == "Bangladesh" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 30 if country == "Bhutan" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 40 if country == "India" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 60 if country == "Nepal" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 80 if country == "Sri Lanka" & geo_level_1_raw!=.

*adjust Sri Lanka for sample size concerns
replace geo_level_1 = 86 if geo_level_1 == 87 // North West + North Central
replace geo_level_1 = 82 if geo_level_1 == 89 // Central + Sabaragamuwa
replace geo_level_1 = 87 if geo_level_1 == 88

lab def geo_level_1_harmonized ///
	11 "Central" ///
	12 "West" ///
	13 "East" ///
	14 "North East" ///
	15 "North West" ///
	16 "South East" ///
	17 "South West" ///
	21 "Barisal" ///
	22 "Chittagong" ///
	23 "Dhaka" ///
	24 "Khulna" ///
	25 "Rajshahi" ///
	26 "Rangpur" ///
	27 "Sylhet" ///
	31 "West" ///
	32 "West Central" ///
	33 "East Central" ///
	34 "East" ///
	41 "North" ///
	42 "Central" ////
	43 "East" ///´
	44 "North East" ////
	45 "West" /// 
	46 "South" ///
	61 "East" ///
	62 "Central" ///
	63 "West" ///
	64 "Mid-West" ///
	65 "Far-West" ///
	71 "Punjab" ///
	72 "Sindh" ///
	73 "Khyber Pakhtunkhwa" ///
	74 "Balochistan" ///
	81 "West" ///
	82 "Central + Sabaragamuwa" ///
	83 "South" ///
	84 "North" ///
	85 "East" ///
	86 "North West/Central" ///
	87 "Uva"
lab val geo_level_1 geo_level_1_harmonized

*rescale weights 
ren weight wt_hh_og
bysort country year survey : egen wt_hh_n = count(wt_hh_og)
bysort country year survey : egen wt_hh_sum = sum(wt_hh_og)
gen wt_hh = (wt_hh_og/wt_hh_sum)*wt_hh_n
replace wt_hh_og = round(wt_hh_og)
replace wt_hh = round(wt_hh*1000)

*adjust female indicator
replace female = 0 if male == 1
replace female = 1 if male == 0

*adjust employment status variable last 7 days for last year 
tab lstatus if empstat == . & empstat_year!=. // India only
replace empstat = empstat_year if empstat == . & lstatus!=3 & lstatus!=.

*adjust education
replace educy = 16 if educy>16 & educy!=. //topcode in line with IOp_dataset
ren educy educ 
gen educ_cat_harm = .
replace educ_cat_harm = 0 if educ == 0 //no education
*Bangladesh
replace educ_cat_harm = 1 if educ >= 1 	 &  educ<5 & 	country == "Bangladesh"
replace educ_cat_harm = 2 if educ == 5 	 &  			country == "Bangladesh"
replace educ_cat_harm = 3 if educ>5 	 &  educ<10 & country == "Bangladesh"
replace educ_cat_harm = 4 if educ >= 10 	 &  educ<12 & country == "Bangladesh"
replace educ_cat_harm = 5 if educ == 12 	 & 			country == "Bangladesh"
replace educ_cat_harm = 6 if educ>12 	 &  educ!=.  & 	country == "Bangladesh"
*Bhutan (not mapped to years as not used in analysis)
// replace educ_cat_harm = 1 if educ >= 1 	 &  educ<6 & 	country == "Bhutan"
// replace educ_cat_harm = 2 if educ == 6 	 &  			country == "Bhutan"
// replace educ_cat_harm = 3 if educ>6 	 &  educ<10 & 	country == "Bhutan"
// replace educ_cat_harm = 4 if educ >= 10 	 &  educ<12 & country == "Bhutan" //SSC
// replace educ_cat_harm = 5 if educ == 12 	 & 	 		country == "Bhutan" //HSC
// replace educ_cat_harm = 6 if educ>12 	 &  educ!=.  & 	country == "Bhutan"
*India 
replace educ_cat_harm = 1 if educ >= 1 	 &  educ<6 & 	country == "India"
replace educ_cat_harm = 2 if educ == 6 	 &  			country == "India"
replace educ_cat_harm = 3 if educ>6 	 &  educ<10 & country == "India" //middle + SSC incomplete
replace educ_cat_harm = 4 if educ >= 10 	 &  educ<12 & country == "India"
replace educ_cat_harm = 5 if educ == 12 	 & 			country == "India"
replace educ_cat_harm = 6 if educ>12 	 &  educ!=.  & 	country == "India"
*Nepal 
replace educ_cat_harm = 1 if educ >= 1 	 &  educ<5 & 	country == "Nepal"
replace educ_cat_harm = 2 if educ == 5 	 &  			country == "Nepal" //primary<2000 (i.e., our cohorts)
replace educ_cat_harm = 3 if educ>5 	 &  educ<10 & country == "Nepal" //middle/lower secondary 6-7 (peak at 7) + secondary incomplete
replace educ_cat_harm = 4 if educ >= 10 	 &  educ<12 & country == "Nepal" //SLC
replace educ_cat_harm = 5 if educ == 12 	 & 			country == "Nepal"
replace educ_cat_harm = 6 if educ>12 	 &  educ!=.  & 	country == "Nepal"
*Sri Lanka
replace educ_cat_harm = 1 if educ >= 1 	 &  educ<5 & 	country == "Sri Lanka"
replace educ_cat_harm = 2 if educ == 5 	 &  			country == "Sri Lanka"
replace educ_cat_harm = 3 if educ>5 	 &  educ<9 & 	country == "Sri Lanka"
replace educ_cat_harm = 4 if educ >= 9 	 &  educ<12 & country == "Sri Lanka"
replace educ_cat_harm = 5 if educ == 12 	| educ == 13 & country == "Sri Lanka" //reform in 1970s change secondary from 12 to 13 year system (i.e., only at  max 2 cohorts under previous scheme) 
replace educ_cat_harm = 6 if educ>13 	 &  educ!=. & 	country == "Sri Lanka"

lab def educ_cat_harm ///
	0 "No formal Education" ///
	1 "Primary Education incomplete" ///
	2 "Primary Education" ///
	3 "Lower Secondary incomplete" ///
	4 "Lower Secondary + Upper Scondary incomplete" ///
	5 "Upper Scondary" ///
	6 "Tertiary (incl. non-university)"
lab var educ_cat_harm educ_cat_harm	

*drop obs without circumstances (female, urban, demo, geo_level_1)
keep if female!=. & geo_level_1!=. & urban!=.
drop if demo == . & country!="Bhutan"
*re: Sri Lanka 2004 is dropped b/c of missing demo variable
 drop if wt_hh==.
 
*adjust naming convention
ren pid id

keep country year survey survey_name id wt_hh cohort_* age age_2 female geo_level_1 urban demo lfp paidwage wage lstatus empstat educ_cat_harm educ
order _all, alphabetic
compress
save "$clean/LFS_dataset.dta", replace