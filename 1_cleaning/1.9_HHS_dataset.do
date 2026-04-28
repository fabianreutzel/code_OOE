/******************************************************************************\
#title: "1.9_IOp_dataset"
#author: "Fabian Reutzel"
#structure: 1. Merge datasets
\******************************************************************************/

*prepare CPI data for consumption conversion
import delimited "$raw/auxiliary/cpi2010.csv", varnames(1) clear
forvalues i = 5(1)68{
local y =`i'+1955
	rename v`i' year_`y'
}
rename countryname country
keep country year_*
reshape long year_, i(country) j(year)
rename year_ cpi
save "$raw/auxiliary/CPI.dta", replace

********************************************************************************
**#1. Merge datasets
********************************************************************************
use "$clean/HHS_AFG_dataset.dta", clear
append using "$clean/HHS_BGD_dataset.dta"
append using "$clean/HHS_BHT_dataset.dta"
append using "$clean/HHS_IND_dataset.dta"
append using "$clean/HHS_NPL_dataset.dta", force
append using "$clean/HHS_PAK_dataset.dta", force
append using "$clean/HHS_LKA_dataset.dta",force

*adjust circumstance to fit common set of circumstances
replace demo = religion if country=="Bangladesh"
replace religion = . if country=="Bangladesh"
replace demo = language if country=="Pakistan"
 
*categorical educ variable for sampling frame 
foreach var in child father mother {
drop `var'_educ_cat* // _og + _wb
gen `var'_educ_cat = 0 if `var'_educ==0
replace `var'_educ_cat = 1 if `var'_educ>0 & `var'_educ<=6
replace `var'_educ_cat = 2 if `var'_educ>6 & `var'_educ<=9
replace `var'_educ_cat = 3 if `var'_educ>9 & `var'_educ<=12
replace `var'_educ_cat = 4 if `var'_educ>12 & `var'_educ!=.
}

foreach var in child father mother {
gen `var'_educ_cat_3 = 0 if `var'_educ>=0 & `var'_educ<=6
replace `var'_educ_cat_3 = 1 if `var'_educ>6 & `var'_educ<=12
replace `var'_educ_cat_3 = 2 if `var'_educ>12 & `var'_educ!=.
}

*parental education
gen parents_educ = father_educ
replace parents_educ = mother_educ if father_educ < mother_educ
replace parents_educ = father_educ if mother_educ==. & parents_educ==.
replace parents_educ = mother_educ if father_educ==. & parents_educ==.

gen parents_educ_cat = father_educ_cat
replace parents_educ_cat = mother_educ_cat if father_educ_cat < mother_educ_cat
replace parents_educ_cat = father_educ_cat if mother_educ_cat==. & parents_educ_cat==.
replace parents_educ_cat = mother_educ_cat if father_educ_cat==. & parents_educ_cat==.

*adjust HH income/consumption by CPI
replace year = 2019 if country=="Afghanistan" & year==2020
merge m:1 country year using "$raw/auxiliary/CPI.dta", nogen keep(master match)
replace year = 2020 if country=="Afghanistan" & year==2019
*re: WB estimates already per capita (pc)
gen hh_inc_wb = hh_inc_month_wb / cpi
gen hh_cons_wb = hh_cons_month_wb /cpi
replace hh_cons_wb_old = hh_cons_wb_old / cpi
replace hh_cons_wb_new = hh_cons_wb_new / cpi

*adjust wage variable from SARMD
replace wage = . if unitwage==1 & year==2000 & country=="Bangladesh" //only 5 obs
replace wage = wage*24 if unitwage==1 //daily
replace wage = wage if unitwage==5 //montly
replace wage = wage/12 if unitwage==8 //annually
replace wage = wage/cpi
drop cpi

**generate cohort variables
gen year_birth = year-age
gen age_2 = age^2
egen cohort_5 = cut(year_birth), at(1950 (5) 2000)
replace cohort_5 = (cohort_5-1945)/5
*age-cohort identifiers
egen age_5 = cut(age), at(25 (5) 65)
replace age_5 = (age_5-20)/5
gen cohort_age_5 =		"0"+string(cohort_5)+"0"+string(age_5) 	if cohort_5!=.&age_5!=. & cohort_5<10.&age_5<10
replace cohort_age_5 = 	"0"+string(cohort_5) +string(age_5) 	if cohort_5!=.&age_5!=. & cohort_5<10.&age_5>10
replace cohort_age_5 =	string(cohort_5)+"0"+string(age_5)		if cohort_5!=.&age_5!=. & cohort_5>=10.&age_5<10 
replace cohort_age_5 =	string(cohort_5)+string(age_5) 			if cohort_5!=.&age_5!=. & cohort_5>=10.&age_5>10 

*generate harmonized demo variable
ren demo demo_raw
gen demo = demo_raw + 20 if country=="Bangladesh" & demo_raw!=.
replace demo = demo_raw + 10 if country=="Afghanistan" & demo_raw!=.
replace demo = demo_raw + 40 if country=="India" & demo_raw!=.
replace demo = demo_raw + 60 if country=="Nepal"  & demo_raw!=.
replace demo = demo_raw + 70 if country=="Pakistan"  & demo_raw!=.
replace demo = demo_raw + 80 if country=="Sri Lanka" & demo_raw!=.
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
	82 "Sri Lanka Tamil/Moors" ///
	83 "Indian Tamil" 
lab val demo demo_harmonized

*generate harmonized geo variable
ren geo_level_1 geo_level_1_raw
gen geo_level_1 = geo_level_1_raw + 10 if country=="Afghanistan" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 20 if country=="Bangladesh" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 30 if country=="Bhutan" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 40 if country=="India" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 50 if country=="Maldives" & geo_level_1_raw!=. 
replace geo_level_1 = geo_level_1_raw + 60 if country=="Nepal" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 70 if country=="Pakistan" & geo_level_1_raw!=.
replace geo_level_1 = geo_level_1_raw + 80 if country=="Sri Lanka" & geo_level_1_raw!=.
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
	43 "East" ///
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
drop if wt_hh==. //few obs Afghanistan (2019) but 20% of Bangladesh (2012+2015)
replace wt_hh = wt_hh_wb if wt_hh_wb!=.
ren wt_hh wt_hh_og
bysort country year survey : egen wt_hh_n = count(wt_hh_og)
bysort country year survey : egen wt_hh_sum = sum(wt_hh_og)
gen wt_hh = (wt_hh_og/wt_hh_sum)*wt_hh_n
drop wt_hh_n wt_pop
replace wt_hh_og = round(wt_hh_og)
replace wt_hh = round(wt_hh*1000)
replace wt_hh = 1 if survey=="NPHC" //census data & not used with other datasets 

*drop obs without circumstances (female, urban, demo, geo_level_1)
keep if female!=. & geo_level_1!=.
drop if urban==. & country!="Maldives" 
drop if demo==. & (country!="Bhutan"&country!="Maldives") 

*harmonize coding of educational degrees based on country-specific degree structure
gen child_educ_cat_harm = .
replace child_educ_cat_harm = 0 if child_educ==0  //no education
*Afghanistan
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<6 & 	country=="Afghanistan"
replace child_educ_cat_harm = 2 if child_educ==6 	& 					country=="Afghanistan"
replace child_educ_cat_harm = 3 if child_educ>6 	& child_educ<9 & 	country=="Afghanistan"
replace child_educ_cat_harm = 4 if child_educ>=9 	& child_educ<12 & 	country=="Afghanistan"
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="Afghanistan"
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="Afghanistan"
*Bangladesh
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<5 & 	country=="Bangladesh"
replace child_educ_cat_harm = 2 if child_educ==5 	& 					country=="Bangladesh"
replace child_educ_cat_harm = 3 if child_educ>5 	& child_educ<10 & 	country=="Bangladesh"
replace child_educ_cat_harm = 4 if child_educ>=10 	& child_educ<12 & 	country=="Bangladesh"
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="Bangladesh"
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="Bangladesh"
*Bhutan
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<6 & 	country=="Bhutan"
replace child_educ_cat_harm = 2 if child_educ==6 	& 					country=="Bhutan"
replace child_educ_cat_harm = 3 if child_educ>6 	& child_educ<10 & 	country=="Bhutan"
replace child_educ_cat_harm = 4 if child_educ>=10 	& child_educ<12 & 	country=="Bhutan" //SSC
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="Bhutan" //HSC
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="Bhutan"
*India
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<6 & 	country=="India"
replace child_educ_cat_harm = 2 if child_educ==6 	& 					country=="India"
replace child_educ_cat_harm = 3 if child_educ>6 	& child_educ<10 & 	country=="India" //middle + SSC incomplete
replace child_educ_cat_harm = 4 if child_educ>=10 	& child_educ<12 & 	country=="India"
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="India"
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="India"
*Nepal
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<5 & 	country=="Nepal"
replace child_educ_cat_harm = 2 if child_educ==5 	& 					country=="Nepal" //primary<2000 (i.e., our cohorts)
replace child_educ_cat_harm = 3 if child_educ>5 	& child_educ<10 & 	country=="Nepal" //lower secondary 6-7 + secondary incomplete
replace child_educ_cat_harm = 4 if child_educ>=10 	& child_educ<12 & 	country=="Nepal" //SLC
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="Nepal"
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="Nepal"
*Pakistan
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<5 & 	country=="Pakistan"
replace child_educ_cat_harm = 2 if child_educ==5 	& 					country=="Pakistan"
replace child_educ_cat_harm = 3 if child_educ>5 	& child_educ<10 & 	country=="Pakistan" //middle + SSC incomplete
replace child_educ_cat_harm = 4 if child_educ>=10 	& child_educ<12 & 	country=="Pakistan"
replace child_educ_cat_harm = 5 if child_educ==12 	&				 	country=="Pakistan"
replace child_educ_cat_harm = 6 if child_educ>12 	& child_educ!=. &	country=="Pakistan"
*Sri Lanka
replace child_educ_cat_harm = 1 if child_educ>=1 	& child_educ<5 & 	country=="Sri Lanka"
replace child_educ_cat_harm = 2 if child_educ==5 	& 					country=="Sri Lanka"
replace child_educ_cat_harm = 3 if child_educ>5 	& child_educ<9 & 	country=="Sri Lanka"
replace child_educ_cat_harm = 4 if child_educ>=9 	& child_educ<12 & 	country=="Sri Lanka"
replace child_educ_cat_harm = 5 if child_educ==12 	| child_educ==13 & 	country=="Sri Lanka" //reform in 1970s change secondary from 12 to 13 year system (i.e., only at  max 2 cohorts under previous scheme) 
replace child_educ_cat_harm = 6 if child_educ>13 	& child_educ!=.	&	country=="Sri Lanka"

lab def child_educ_cat_harm ///
	0 "No formal Education" ///
	1 "Primary Education incomplete" ///
	2 "Primary Education" ///
	3 "Lower Secondary incomplete" ///
	4 "Lower Secondary + Upper Secondary incomplete" ///
	5 "Upper Secondary" ///
	6 "Tertiary (incl. non-university)"
lab var child_educ_cat_harm child_educ_cat_harm	

*generate identifier for estimation samples
replace hh_cons_wb = . if hh_cons_wb==0 //1 obs
gen sample_iop_cons = (hh_cons_wb!=.|hh_cons_wb_new!=.) 
gen sample_iop_labor = (survey=="HIES"|survey=="NLSS"|survey=="BLSS"|survey=="BLFS"|survey=="NSS - Employment"|survey=="NRVA"|survey=="ALCS"|survey=="IELFS")

*keep relevant variables
keep country year year_birth survey survey_name coresident sample_* child_id hh_id hh_rel wt_hh wt_hh_og child_coresident age age_2 female urban* geo_level* demo* religion language caste migration* *_educ *_educ_cat* *_literate hh_cons_wb* hh_inc_wb cohort* lstatus empstat wage
compress

*generate migration overview 
preserve
keep if age>=15 
drop if migration_geo_level_1==. & migration_urban==.
keep country year survey *geo_level_* *urban*
save "$clean/migration_dataset.dta", replace
restore
drop migration* 

*adjust naming convention
ren coresident survey_coresident
ren child_* *

save "$clean/HHS_dataset.dta", replace

*create consumption dataset for robustness check India
drop if country!="India"|survey=="LFS"|survey=="IHDS"
keep if hh_cons_wb!=. | hh_cons_wb_new!=. 
save "$clean/IND_cons.dta", replace