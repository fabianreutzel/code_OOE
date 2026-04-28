/******************************************************************************\
#title: "1.1_HHS_AFG_dataset"
#author: "Fabian Reutzel"
#structure: 0. Province to ethnicity mapping 
			1. IELFS 2019-20 (raw)
			2. ALCS 2016-17 (raw + SARMD)
			3. ALCS 2013-14 (raw)
			4. NRVA 2011-12 (raw + SARMD)
			5. NRVA 2007-08 (raw + SARMD)
			6. Combine datasets + adjust variables
\******************************************************************************/

********************************************************************************
********************************************************************************
**#0. Province to ethnicity mapping 
*based on "Afghanistan in 2019: A Survey of the Afghan People"
*available at: https://dataverse.ada.edu.au/file.xhtml?fileId=15541&version=2.2
********************************************************************************
********************************************************************************
use "$raw/auxiliary/demo/2019_Afghan_data_STATA.dta", clear
*precode WB
ren ethnic demo_lim //5 levels
tabulate demo_lim, generate(demo_lim_)
*most extensive 
ren z10 demo_extd //12 levels
replace demo_extd = 996  if demo_extd==107 //kirghiz
replace demo_extd = 996  if demo_extd>=113 & demo_extd<=138
replace demo_extd = .  if (demo_extd==998 | demo_extd==999)
*prefered coding
tabulate demo_extd, generate(demo_extd_)
gen demo = demo_extd //8 levels
replace demo = 996  if demo_extd>=109 & demo_extd<=138
tabulate demo, generate(demo_)

ren m7 geo_level_2
ren region geo_level_1
drop demo_extd demo demo_lim

*get population shares
collapse demo_* , by(geo_level_1 geo_level_2)

*get share of majority group within geo_level_2
egen share_demo_lim = rowmax(demo_lim_1 demo_lim_2 demo_lim_3 demo_lim_4)
sum share_demo_lim, d
gen demo_lim_70 = (share_demo_lim>=.70) //18 of 34

egen share_demo = rowmax(demo_1 demo_2 demo_3 demo_4 demo_5 demo_6 demo_7)
sum share_demo, d
gen demo_70 = (share_demo>=.7) //19 of 34 => 65 adds 1 more to major group

*get major demographic group
gen str demo_70_group = ""
quietly foreach v of varlist demo_1 demo_2 demo_3 demo_4 demo_5 demo_6 demo_7  {    
    replace demo_70_group = demo_70_group + " " + "`v'"  if (`v' == share_demo & demo_70==1)
}  

*generate demo variable 
gen demo_extd = substr(demo_70_group,7,.)
destring demo_extd, replace
replace demo_extd = 5 if demo_extd==7
replace demo_extd = 6 if demo_extd==.
lab def demo_extd ///
	1 "Pashtun" ///
	2 "Tajik" ///
	3 "Uzbek" ///
	4 "Hazara" ///
	5 "Nuristani" ///
	6 "Others + Mixed Area"
lab val demo_extd demo_extd
gen demo = demo_extd
replace demo =  4 if demo_extd==5
replace demo =  5 if (demo_extd==4|demo_extd==6) 
*re: combine Hazara + Others as mean outcomes 3.11 vs 3.14
lab def demo ///
	1 "Pashtun" ///
	2 "Tajik" ///
	3 "Uzbek" ///
	4 "Nuristani" ///
	5 "Others + Mixed Area"
lab val demo demo

*adjust geo coding
ren geo_level_* geo_level_*_wb
keep geo_level_1_wb geo_level_2_wb demo demo_extd
merge 1:1 geo_level_2_wb using "$raw/auxiliary/geo_level/AFG_geo_level_2_wb_mapping.dta", nogen keepusing(geo_level_2)
drop geo_level_2_wb
save "$raw/auxiliary/geo_level/AFG_geo_level_2_demo_mapping.dta", replace

********************************************************************************
********************************************************************************
**#1. IELFS 2019-20
********************************************************************************
********************************************************************************

********************************************************************************
**##1.1 individual income + employment
********************************************************************************
use "$raw/HHS/AFG/IELFS/labour_male.dta", clear
ren HH_ID hh_id
ren Rst_I member_id

**employment in agriculture
gen agri_activity = (q305==1) if q305!=. 
*industry-based
destring q319, gen(industry_code)
replace industry_code = industry_code*100 if industry_code<10
replace industry_code = industry_code*10 if industry_code<100
gen agri_industry = (industry_code>0&industry_code<200) if industry_code!=. //lower coverage
*occupation-based
destring q320, gen(occu_code)
replace occu_code = occu_code*100 if occu_code<10
replace occu_code = occu_code*10 if occu_code<100
*re: ignore error recoding 0 category b/c not relevant for agri
gen agri = ((occu_code>=600&occu_code<700)|(occu_code>=920&occu_code<930)) if occu_code!=.

gen q308 = (q304==1 | q305==1 | q306==1 | q307==1) if q304!=. & q305!=. & q306!=. & q307!=. //worked last week: business/agri/non-ag own-account+hh/production of durable goods
gen lstatus = 1 if q308==1 | q313==6 | q313==7 | q313==9 
*worked last week OR apprentice/military service/temporary lay-off
replace lstatus = 2 if q312==1 | q313==4 | q313==8 | q313==10 | q313==12 
*available for work last week OR illness/work already found/waiting for busy season/no jobs available
replace lstatus = 3 if q308==0 & lstatus==. //not available (only asked for those non-participating)

*re: no direct employment type question
*day labourer income
ren q323 daily_emp //wrong label in dataset
ren q324 daily_months_worked 
ren q325 days_worked_month
ren q326 inc_inkind_month
ren q328 inc_inkind_year

ren q329 salary_emp
ren q330 salary_months_worked
ren q331_1 salary_inc_month
ren q331_4 salary_tot_inc_month

ren q332 self_emp
ren q333 self_months_worked
gen self_inc_month = q334_2 * 6 * 4 if q334_1==1
replace self_inc_month = q334_2 * 4 if q334_1==2
replace self_inc_month = q334_2 if q334_1==3

*no distinction paid + unpaid (5/6)
ren q335 emp_hh_agri
ren q336 emp_hh_nonagri //work in a business owned by the household or a member of the household

gen emp_stat = 1 if daily_emp==1  //Day labourer
replace emp_stat = 2 if salary_emp==1 //Salaried worker (no differentiate private(2) & public(3))
replace emp_stat = 1 if daily_months_worked>salary_months_worked & daily_months_worked!=. & salary_months_worked!=. //233 cases od both emp types
replace emp_stat = 4 if self_emp==1 // Self-employed without paid employees (e.g. own-account farmer, share cropper, shop owner, street vendor, tailor)
replace emp_stat = 6 if (emp_hh_agri==1 | emp_hh_nonagri==1) & emp_stat==.  // Self-employed with paid employees (5) & Unpaid family worker (6)

*individual income
replace inc_inkind_month = 0 if inc_inkind_month==.
replace salary_inc_month = 0 if salary_inc_month==.
replace self_inc_month = 0 if self_inc_month==.
gen inc_month = inc_inkind_month + salary_inc_month + self_inc_month
replace inc_month=. if inc_month==0
ren salary_inc_month wage

destring member_id, replace
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

keep hh_id child_id father_id mother_id agri emp_stat inc_month lstatus wage
save "$interim/ielfs_2020_wage.dta", replace
*re: inc info on 3,680 of 9,754 obs child_coresident men (18-65)

********************************************************************************
**##1.2 education
********************************************************************************
use "$raw/HHS/AFG/IELFS/roster_male.dta", clear
ren HH_ID hh_id
ren Rst_I member_id
destring member_id, replace

gen literate = (q213==1) if q213!=.
gen educ_stat = (q214==1) if q214!=.
ren q215e educ_cat_og
ren q215g educ_og

gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)  
gen mother_id = hh_id + "-" + string(member_id) 

keep child_id father_id mother_id literate educ_*
save "$interim/ielfs_2020_education.dta", replace

********************************************************************************
**##1.3 HH roster (data identical for female/male) => HH level questions + urbanity
********************************************************************************
use "$raw/HHS/AFG/IELFS/household_male.dta", clear
ren HH_ID hh_id
ren q11 geo_level_1
ren q12 geo_level_2
ren q14 geo_level_3
gen urban = (q15==1) if q15!=.
gen displace = (q105==1) if q105!=.
keep hh_id geo_level* urban displace
save "$interim/ielfs_2020_urban.dta", replace

********************************************************************************
**##1.4 weights
********************************************************************************
use "$raw/HHS/AFG/IELFS/clusters.dta", clear 
gen hh_id = string(HH_ID,"%06.0f")
tostring hh_id, replace
ren ea_code psu
ren weight2 wt_hh //weight adjusted for entire population
replace wt_hh = round(wt_hh)
ren hhsize hh_size
keep hh_id psu wt_hh hh_size
save "$interim/ielfs_2020_weights.dta", replace

********************************************************************************
**##1.5 male roster (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/AFG/IELFS/roster_male.dta", clear
ren HH_ID hh_id
ren Rst_I member_id

*generate country/survey/year
gen country = "Afghanistan"
gen survey = "IELFS"
gen survey_name = "Income and Expenditure & Labor Force Survey"
gen year = 2020
gen coresident = "yes"

*add additional variables
merge m:1 hh_id using "$interim/ielfs_2020_weights.dta", nogen
merge m:1 hh_id using "$interim/ielfs_2020_urban.dta", nogen

*rename variables
*re: no info on religion & demo & language
ren q202 age
gen female = (q203==2)
ren q206 father_home
ren q208 mother_home
ren q207 father_num
ren q209 mother_num

**HH relation & co-residence status
gen hh_rel = 0 if q201r==1
replace hh_rel = 1 if q201r==2
replace hh_rel = 2 if q201r==3
replace hh_rel = 3 if q201r==6
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"  2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*create a unique IDs
destring member_id, replace
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num)

*add education
merge m:1 father_id using "$interim/ielfs_2020_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate father_literate
ren educ_* father_educ_*
merge m:1 mother_id using "$interim/ielfs_2020_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate mother_literate
ren educ_* mother_educ_*
merge m:1 child_id using "$interim/ielfs_2020_education.dta", ///
	nogen keep(master match) keepusing(child_id literate educ_*)
ren literate child_literate
ren educ_* child_educ_*

*add parental occu & income
merge m:1 father_id using "$interim/ielfs_2020_wage.dta", ///
	nogen keep(master match) keepusing(father_id agri emp_*)
ren agri* father_agri*
ren emp_* father_emp_*
merge m:1 mother_id using "$interim/ielfs_2020_wage.dta", ///
	nogen keep(master match) keepusing(mother_id agri emp_*)
ren agri* mother_agri*
ren emp_* mother_emp_*
merge m:1 child_id using "$interim/ielfs_2020_wage.dta", ///
	nogen keep(master match) keepusing(child_id agri emp_* inc_month lstatus wage)
ren emp_* child_emp_*
ren agri* child_agri*

*re: no SARMD consumption data available
keep $var_main $var_cores $var_indiv urban lstatus *emp* wage
save "$interim/ielfs_2020.dta", replace

********************************************************************************
********************************************************************************
**#2. ALCS 2016-17
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
**##2.1 agriculture
********************************************************************************
use "$raw/HHS/AFG/ALCS/2016-17/H_12.dta", clear
gen agri_activity = (q12_1==1) if q12_1!=. //any farm work last 7 days (=ALCS 2013-14) NOT representative
gen agri_industry = (q12_16_b==1) if q12_16_b!=. 
gen agri = (q12_17_b==6) if q12_17_b!=. 

gen lstatus = 1 if q12_6==1 | q12_10==6 | q12_10==7 | q12_10==9 
*worked last week: business/agri/non-ag own-account+hh/production of durable goods OR apprentice/military service/temporary lay-off
replace lstatus = 2 if q12_10==1 | q12_10==4 | q12_10==8 | q12_10==10 | q12_10==12 
*available for work last week OR illness/work already found/waiting for busy season/no jobs available
replace lstatus = 3 if q12_6==2 & lstatus==. //not available (only asked for those non-participating)
*re: reason for no job search in line with definition of activity_status BUT activity_status appears to overstate LFP

ren q12_13 emp_stat

ren q12_1 member_id
gen child_id = ind_id
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

keep child_id father_id mother_id agri* emp* lstatus
save "$interim/alcs_2017_employment.dta", replace

********************************************************************************
**##2.2 education
********************************************************************************
use "$raw/HHS/AFG/ALCS/2016-17/H_11.dta", clear

gen literate = (q11_2==1) if q11_2!=.
gen educ_stat = (q11_5==1) if q11_5!=.
ren q11_7 educ_cat_og
ren q11_8 educ_og

ren q11_1 member_id
gen child_id = ind_id
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

keep child_id father_id mother_id literate educ_*
save "$interim/alcs_2017_education.dta", replace

********************************************************************************
**##2.3 urbanity status
*re: only province of birth BUT no clear urban/rural distinction possible
********************************************************************************
use "$raw/HHS/AFG/ALCS/2016-17/H_01.dta", clear
gen urban = (q_1_5==1) if q_1_5!=.
keep hh_id urban
save "$interim/alcs_2017_urban_raw.dta", replace

use "$raw/HHS/AFG/ALCS/2016-17/H_13.dta", clear
gen geo_level_1_birth = q_13_2 if q_13_2!=.
gen migration_geo_level_1 = (q_13_2!=q_1_1) if (q_1_1!=.&q_13_2!=.)
gen migration_ever = (q_13_3==1) if q_13_3!=.
merge m:1 hh_id using "$interim/alcs_2017_urban_raw.dta", nogen
keep hh_id ind_id urban* migration* *_birth
save "$interim/alcs_2017_urban.dta", replace

********************************************************************************
**##2.4 HH roster (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/AFG/ALCS/2016-17/H_03.dta", clear

*generate country/survey/year
gen country = "Afghanistan"
gen survey = "ALCS"
gen survey_name = "Afghanistan Living Conditions Survey"
gen year = 2017
gen coresident = "yes"

*add additional variables
merge m:1 hh_id using "$raw/HHS/AFG/ALCS/2016-17/weight_file.dta", nogen
merge 1:1 hh_id ind_id using "$interim/alcs_2017_urban.dta", nogen

*rename variables
ren q_3_1 member_id
ren hh_weight wt_hh
ren ind_weight wt_ind //re: not varying on HH level
ren q_1_3 psu
ren q_1_1a geo_level_1
ren q_1_2 geo_level_2
ren q_1_4 geo_level_3
*re: no info on religion & demo & disab
ren q_3_4 age
gen female = (q_3_5==2)
ren q_3_8 father_home
ren q_3_10 mother_home
ren q_3_9 father_num
ren q_3_11 mother_num

**HH relation & co-residence status
gen hh_rel = 0 if q_3_3==1
replace hh_rel = 1 if q_3_3==2
replace hh_rel = 2 if q_3_3==3
replace hh_rel = 3 if q_3_3==6
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"  2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*create a unique IDs
gen child_id = hh_id + "0" + string(member_id) if member_id<10
replace child_id = hh_id + string(member_id) if member_id>=10
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num)

*add education
merge m:1 father_id using "$interim/alcs_2017_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate father_literate
ren educ_* father_educ_*
merge m:1 mother_id using "$interim/alcs_2017_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate mother_literate
ren educ_* mother_educ_*
merge m:1 child_id using "$interim/alcs_2017_education.dta", ///
	nogen keep(master match) keepusing(child_id literate educ_*)
ren literate child_literate
ren educ_* child_educ_*

*add occupation 
merge m:1 father_id using "$interim/alcs_2017_employment.dta", ///
	nogen keep(master match) keepusing(father_id agri* emp_*)
ren agri* father_agri*
ren emp_* father_emp_*
merge m:1 mother_id using "$interim/alcs_2017_employment.dta", ///
	nogen keep(master match) keepusing(mother_id agri* emp_*)
ren agri* mother_agri*
ren emp_* mother_emp_*
merge m:1 child_id using "$interim/alcs_2017_employment.dta", ///
	nogen keep(master match) keepusing(child_id agri* emp_* lstatus)
ren agri* child_agri*
ren emp_* child_emp_*

*add SARMD consumption data
gen idh = hh_id
gen idp = child_id
merge 1:1 idp using "$raw/HHS/AFG/SARMD/AFG_2016_LCS_v01_M_v01_A_SARMD_IND.dta", nogen keepusing(welfarenat) keep(master match)
ren welfarenat hh_cons_month_wb

keep $var_main $var_cores $var_indiv $var_outcome urban migration* hh_cons_month* *emp* lstatus
save "$interim/alcs_2017.dta", replace

********************************************************************************
********************************************************************************
**#3. ALCS 2013-14
********************************************************************************
********************************************************************************

********************************************************************************
**##3.1 individual income
********************************************************************************
use "$raw/HHS/AFG/ALCS/2013-14/H_11.dta", clear

ren q_11_14 wage_daily
ren q_11_15 wage_monthly
ren q_11_16 profit_monthly
ren q_11_17 days_worked_week
replace wage_daily = 0 if wage_daily==.
replace wage_monthly = 0 if wage_monthly==.
replace profit_monthly = 0 if profit_monthly==.
gen inc_month = (wage_daily  * days_worked_week *4) + wage_monthly + profit_monthly
replace inc_month = . if inc_month==0
ren wage_monthly wage

keep ind_id inc_month wage
duplicates drop
save "$interim/alcs_2014_wage.dta", replace
*re: inc info on 5,794 of 11,421 child_coresident men (18-65)

********************************************************************************
**##3.2 agriculture
********************************************************************************
use "$raw/HHS/AFG/ALCS/2013-14/H_11.dta", clear

**employment in agriculture
gen agri_activity = (q_11_3==1) if q_11_3!=.  //any farm work last 7 days
gen agri_industry = (q_11_19_b==1) if q_11_19_b!=.
gen agri = (q_11_20_b==6) if q_11_20_b!=.
*compare alternative definitions
*occu/indus: low coverage (37145 vs 84605) BUT share matches official stats (49% vs. 44%)
*activity: broad coverage BUT share too low compared to official stats (24.3% vs. 44%)
tab agri agri_industry
tab agri agri_activity


gen lstatus = 1 if q_11_6==1 | q_11_12==6 | q_11_12==7 | q_11_12==9 
*worked last week: business/agri/non-ag own-account+hh/production of durable goods OR apprentice/military service/temporary lay-off
replace lstatus = 2 if q_11_10==1 | q_11_12==4 | q_11_12==8 | q_11_12==10 | q_11_12==12 
*available for work last week OR illness/work already found/waiting for busy season/no jobs available
replace lstatus = 3 if q_11_6==2 & lstatus==. //not working and not UE

ren q_11_13 emp_stat

ren q_11_1 member_id
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

keep hh_id child_id father_id mother_id agri* emp_* lstatus
duplicates drop
save "$interim/alcs_2014_employment.dta", replace

********************************************************************************
**##3.4 education
********************************************************************************
use "$raw/HHS/AFG/ALCS/2013-14/H_10.dta", clear

gen literate = (q_10_2==1) if q_10_2!=.
gen educ_stat = (q_10_4==1) if q_10_4!=.
ren q_10_5 educ_cat_og
ren q_10_6 educ_og

ren q_10_1 member_id
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)  
gen mother_id = hh_id + "-" + string(member_id) 

keep child_id father_id mother_id literate educ_*
duplicates drop
duplicates drop father_id, force // 99=member_id
save "$interim/alcs_2014_education.dta", replace

********************************************************************************
**##3.5 urbanity status
********************************************************************************
use "$raw/HHS/AFG/ALCS/2013-14/H_01.dta", clear
gen urban = (q_1_5==1) if q_1_5!=.
keep hh_id urban
save "$interim/alcs_2014_urban_raw.dta", replace 

use "$raw/HHS/AFG/ALCS/2013-14/H_12.dta", clear
gen urban_birth = (q_12_3==2) if q_12_3!=.
gen geo_level_1_birth = q_12_2
gen migration_geo_level_1 = (q_12_2!=q_1_1) if (q_1_1!=.&q_12_3!=.)
merge m:1 hh_id using "$interim/alcs_2014_urban_raw.dta", nogen
gen migration_urban = (urban!=urban_birth) if (urban!=.&urban_birth!=.)
keep hh_id ind_id urban* migration* *_birth
save "$interim/alcs_2014_urban.dta", replace 

********************************************************************************
**##3.6 HH roster (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/AFG/ALCS/2013-14/H_03.dta", clear

*generate country/survey/year
gen country = "Afghanistan"
gen survey = "ALCS"
gen survey_name = "Afghanistan Living Conditions Survey"
gen year = 2014
gen coresident = "yes"

*add additional variables
merge m:1 hh_id using "$raw/HHS/AFG/ALCS/2013-14/H_01.dta", nogen keepusing(ind_weight)
merge m:1 ind_id using "$interim/alcs_2014_urban.dta", nogen
merge m:1 ind_id using "$interim/alcs_2014_wage.dta", nogen

*rename variables
ren q_3_1 member_id
ren hh_weight wt_hh
ren ind_weight wt_ind //re: not varying on HH level
ren q_1_3 psu
ren q_1_1a geo_level_1
ren q_1_2 geo_level_2
ren q_1_4 geo_level_3
*re: no info on religion & demo & disability
ren q_3_4 age
gen female = (q_3_5==2)
ren q_3_8 father_home
ren q_3_10 mother_home
ren q_3_9 father_num
ren q_3_11 mother_num

**HH relation & co-residence status
gen hh_rel = 0 if q_3_3==1
replace hh_rel = 1 if q_3_3==2
replace hh_rel = 2 if q_3_3==3
replace hh_rel = 3 if q_3_3==6
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"  2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*create a unique IDs
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num)

*add education
merge m:1 father_id using "$interim/alcs_2014_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate father_literate
ren educ_* father_educ_*
merge m:1 mother_id using "$interim/alcs_2014_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate mother_literate
ren educ_* mother_educ_*
merge m:1 child_id using "$interim/alcs_2014_education.dta", ///
	nogen keep(master match) keepusing(child_id literate educ_*)
ren literate child_literate
ren educ_* child_educ_*

*add occupation 
merge m:1 father_id using "$interim/alcs_2014_employment.dta", ///
	nogen keep(master match) keepusing(father_id agri* emp_*)
ren agri* father_agri*
ren emp_* father_emp_*
merge m:1 mother_id using "$interim/alcs_2014_employment.dta", ///
	nogen keep(master match) keepusing(mother_id agri* emp_*)
ren agri* mother_agri*
ren emp_* mother_emp_*
merge m:1 child_id using "$interim/alcs_2014_employment.dta", ///
	nogen keep(master match) keepusing(child_id agri* emp_* lstatus)
ren agri* child_agri*
ren emp_* child_emp_*

*re: no SARMD consumption data available
keep $var_main $var_cores $var_indiv urban *_birth migration* *emp* lstatus wage
save "$interim/alcs_2014.dta", replace

********************************************************************************
********************************************************************************
**#4. NRVA 2011-12
********************************************************************************
********************************************************************************

********************************************************************************
**##4.1 agriculture
********************************************************************************
use "$raw/HHS/AFG/NRVA/2011-12/M_08", clear
ren Q* q*

gen agri = (q_8_10==1|q_8_10==2) if q_8_10!=.
gen agri_industry = (q_8_9==1) if q_8_9!=.
*re: no agri_activity question

gen lstatus = 1 if q_8_2==1 | q_8_7==6 | q_8_7==7 | q_8_7==9 
*worked last week OR apprentice/military service/temporary lay-off
replace lstatus = 2 if q_8_5==1 | q_8_7==4 | q_8_7==8 | q_8_7==10 | q_8_7==12 
*available for work last week OR illness/work already found/waiting for busy season/no jobs available
replace lstatus = 3 if q_8_2==2 & lstatus==. //not working and not UE

ren q_8_11 emp_stat

ren Household_Code hh_id
ren HH_Mem_ID member_id
destring member_id, replace
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

duplicates tag child_id, gen(dup)
drop if dup==1 & agri==. & emp_stat==.
duplicates drop child_id, force //10 obs

keep child_id father_id mother_id agri* emp_* lstatus
save "$interim/nrva_2012_employment.dta", replace

********************************************************************************
**4.2 education
********************************************************************************
use "$raw/HHS/AFG/NRVA/2011-12/M_12", clear
ren Q* q*

gen educ_stat = (q_12_5==1) if q_12_5!=.

gen literate = (q_12_3==1) if q_12_3!=. 
replace literate = 0 if educ_stat==0  & literate==.

tab q_12_6 q_12_7
*re: years of schooling appears reliable

*categorical variable
ren q_12_6 educ_cat_og

*years of schooling variable
ren q_12_7 educ_og 
replace educ_og = 0 if literate==0 & educ_og==.

ren Household_Code hh_id
ren HH_Mem_ID member_id
destring member_id, replace
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

duplicates tag child_id, gen(dup)
drop if dup==1 & literate==.
duplicates drop child_id, force //4 obs

keep child_id father_id mother_id literate educ_*
save "$interim/nrva_2012_education.dta", replace

********************************************************************************
**##4.3 HH roster (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/AFG/NRVA/2011-12/M_03", clear

*generate country/survey/year
gen country = "Afghanistan"
gen survey = "NRVA"
gen survey_name = "National Risk and Vulnerability Assessment"
gen year = 2012
gen coresident = "yes"

*add geography data 
merge m:1 Household_Code using "$raw/HHS/AFG/NRVA/2011-12/Core household", keepusing(Province_Code District_Code Resident_Location_Code hh_size) nogen keep(match)
merge m:1 Household_Code using "$raw/HHS/AFG/NRVA/2011-12/M_1_2", keepusing(Cluster_Code) nogen keep(match)

*rename variables
ren Household_Code hh_id
tostring hh_id, replace
ren HH_Mem_ID member_id
destring member_id, replace
ren hh_weight wt_hh
ren Province_Code geo_level_1 // already inline with ALCS
ren District_Code geo_level_2
destring Cluster_Code, gen(psu)
ren Q_3_5 age
gen female = (Q_3_4==2)
gen married = (Q_3_6==1) if Q_3_6!=.
gen urban = (Resident_Location_Code==1)
ren Q_3_8 father_home
ren Q_3_10 mother_home
ren Q_3_9 father_num
ren Q_3_11 mother_num

**HH relation & co-residence status
gen hh_rel = 0 if Q_3_3==1
replace hh_rel = 1 if Q_3_3==2
replace hh_rel = 2 if Q_3_3==3
replace hh_rel = 3 if Q_3_3==6
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"  2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*create a unique IDs
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num)

*add education
merge m:1 father_id using "$interim/nrva_2012_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate father_literate
ren educ_* father_educ_*
merge m:1 mother_id using "$interim/nrva_2012_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate mother_literate
ren educ_* mother_educ_*
merge m:1 child_id using "$interim/nrva_2012_education.dta", ///
	nogen keep(master match) keepusing(child_id literate educ_*)
ren literate child_literate
ren educ_* child_educ_*

*add occupation 
merge m:1 father_id using "$interim/nrva_2012_employment.dta", ///
	nogen keep(master match) keepusing(father_id agri* emp_*)
ren agri* father_agri*
ren emp_* father_emp_*
merge m:1 mother_id using "$interim/nrva_2012_employment.dta", ///
	nogen keep(master match) keepusing(mother_id agri* emp_*)
ren agri* mother_agri*
ren emp_* mother_emp_*
merge m:1 child_id using "$interim/nrva_2012_employment.dta", ///
	nogen keep(master match) keepusing(child_id agri* emp_* lstatus)
ren agri* child_agri*
ren emp_* child_emp_*

*add WB hh_cons
gen pid = Unique_Mem_ID
merge 1:1 pid using "$raw/HHS/AFG/SARMD/AFG_2012_NRVA_v01_M_v01_A_SARMD_IND.dta", nogen keepusing(welfarenat educat7) keep(master match)
ren welfarenat hh_cons_month_wb
ren educat7 educ_cat_wb

keep $var_main $var_cores $var_indiv urban hh_cons_month* educ_cat_wb lstatus
save "$interim/nrva_2012.dta", replace

********************************************************************************
********************************************************************************
**#5. NRVA 2007-08
*re: disability data available
********************************************************************************
********************************************************************************

********************************************************************************
**##5.1 agriculture & income
********************************************************************************
use "$raw/HHS/AFG/NRVA/2007-08/S9B", clear

*agri as sector of main occpation
*gen agri_activity = (q12_1==1) if q12_1!=. //any farm work last 30 days
gen agri_industry = (q_9_18==1) if q_9_18!=.
gen agri = (q_9_18==1) if q_9_18!=. //no occupation-based question

*re: all other surveys asked last week BUT here monthly
gen lstatus = 1 if q_9_12==1 | q_9_17==5 | q_9_17==7 | q_9_13==1
*worked last week OR military service/temporary lay-off OR long term job but temp absent
replace lstatus = 2 if q_9_16==1 | q_9_17==6 | q_9_17==8 | q_9_17==10
*search for work OR work already found/waiting for busy season/no chances to get job (potentialy incl. 11 no jobs, +2%)
replace lstatus = 3 if q_9_12==2 & lstatus==. //not working and not UE

ren q_9_19 emp_stat

ren hhid hh_id
tostring hh_id, replace
ren hhmemid member_id
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

*wage
ren q_9_20 inc_month_primary //not defined for day labourers
ren q_9_21 daily_wage
ren q_9_23 days_worked_month
replace inc_month_primary = daily_wage*days_worked_month if inc_month_primary==.
ren inc_month_primary wage

keep child_id father_id mother_id agri* emp* lstatus wage
save "$interim/nrva_2008_employment_wage.dta", replace

********************************************************************************
**##5.2 education
********************************************************************************
use "$raw/HHS/AFG/NRVA/2007-08/S6", clear

gen educ_stat = (q_6_3==1) if q_6_3!=.

gen literate = (q_6_2==1) if q_6_2!=. 
replace literate = 0 if educ_stat==0  & literate==.

tab q_6_5_l   q_6_5_y
*re: high discrepancy between categorical and years variable 
*=> use categorical as presumably less noisy

*categorical variable 
ren q_6_5_l educ_og
replace educ_og = 0 if literate==0 & educ_og==.

*years of schooling variable (quality too bad)
*ren q_6_5_y educ_og 
*replace educ_og = 0 if literate==0 & educ_og==.

ren hhid hh_id
tostring hh_id, replace
ren hhmemid member_id
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(member_id)
gen mother_id = hh_id + "-" + string(member_id)

keep child_id father_id mother_id literate educ_*
save "$interim/nrva_2008_education.dta", replace

********************************************************************************
**##5.3 HH roster (i.e., start build_up dataset)
********************************************************************************
use "$raw/HHS/AFG/NRVA/2007-08/S1", clear
merge m:1 hhid using "$raw/HHS/AFG/NRVA/2007-08/S_M", keepusing(hhmebcnt) nogen
ren hhmebcnt hh_size
ren hhid hh_id

*generate country/survey/year
gen country = "Afghanistan"
gen survey = "NRVA"
gen survey_name = "National Risk and Vulnerability Assessment"
gen year = 2008
gen coresident = "yes"

*add geography data 
merge m:1 cid using "$raw/HHS/AFG/NRVA/2007-08/Area_Name", keepusing(provincen districtn villagen urk) nogen keep(match)

*adjust province variables to ALCS
gen province_adj = .
replace province_adj = 1 if provincen=="Kabul"
replace province_adj = 2 if provincen=="Kapisa"
replace province_adj = 3 if provincen=="Parwan"
replace province_adj = 4 if provincen=="Wardak"
replace province_adj = 5 if provincen=="Logar"
replace province_adj = 6 if provincen=="Nangarhar"
replace province_adj = 7 if provincen=="Laghman"
replace province_adj = 8 if provincen=="Panjsher"
replace province_adj = 9 if provincen=="Baghlan"
replace province_adj = 10 if provincen=="Bamyan"
replace province_adj = 11 if provincen=="Ghazni"
replace province_adj = 12 if provincen=="Paktika"
replace province_adj = 13 if provincen=="Paktya"
replace province_adj = 14 if provincen=="Khost"
replace province_adj = 15 if provincen=="Kunarha"
replace province_adj = 16 if provincen=="Nooristan"
replace province_adj = 17 if provincen=="Badakhshan"
replace province_adj = 18 if provincen=="Takhar"
replace province_adj = 19 if provincen=="Kunduz"
replace province_adj = 20 if provincen=="Samangan"
replace province_adj = 21 if provincen=="Balkh"
replace province_adj = 22 if provincen=="Sar-I-Pul"
replace province_adj = 23 if provincen=="Ghor"
replace province_adj = 24 if provincen=="Daykundi"
replace province_adj = 25 if provincen=="Urozgan"
replace province_adj = 26 if provincen=="Zabul"
replace province_adj = 27 if provincen=="Kandahar"
replace province_adj = 28 if provincen=="Jawzjan"
replace province_adj = 29 if provincen=="Faryab"
replace province_adj = 30 if provincen=="Helmand"
replace province_adj = 31 if provincen=="Badghis"
replace province_adj = 32 if provincen=="Herat"
replace province_adj = 33 if provincen=="Farah"
replace province_adj = 34 if provincen=="Nimroz"

*rename variables
tostring hh_id, replace
ren hhmemid member_id
ren hh_weight wt_hh
ren mem_weight wt_ind
ren province_adj geo_level_1
encode districtn, gen(geo_level_2)
encode villagen, gen(geo_level_3)
ren cid psu
ren q_1_3 age
gen female = (q_1_2==2)
gen married = (q_1_4==1) if q_1_4!=.
gen urban = (urk==1)
ren q_1_6 father_home
ren q_1_8 mother_home
ren q_1_7 father_num
ren q_1_9 mother_num

**HH relation & co-residence status
gen hh_rel = 0 if q_1_1==1
replace hh_rel = 1 if q_1_1==2
replace hh_rel = 2 if q_1_1==3
replace hh_rel = 3 if q_1_1==7
lab def l_hh_rel 0 "HH Head" 1 "Spouse/Partner"  2 "Son/Daughter" 3 "Father/Mother" 
lab val hh_rel l_hh_rel
gen child_coresident = (hh_rel==2)

*create a unique IDs
gen child_id = hh_id + "-" + string(member_id)
gen father_id = hh_id + "-" + string(father_num)
gen mother_id = hh_id + "-" + string(mother_num)

*add education
merge m:1 father_id using "$interim/nrva_2008_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate father_literate
ren educ_* father_educ_*
merge m:1 mother_id using "$interim/nrva_2008_education.dta", ///
	nogen keep(master match) keepusing(father_id literate educ_*)
ren literate mother_literate
ren educ_* mother_educ_*
merge m:1 child_id using "$interim/nrva_2008_education.dta", ///
	nogen keep(master match) keepusing(child_id literate educ_*)
ren literate child_literate
ren educ_* child_educ_*

*add occupation 
merge m:1 father_id using "$interim/nrva_2008_employment_wage.dta", ///
	nogen keep(master match) keepusing(father_id agri* emp_*)
ren agri* father_agri*
ren emp_* father_emp_*
merge m:1 mother_id using "$interim/nrva_2008_employment_wage.dta", ///
	nogen keep(master match) keepusing(mother_id agri* emp_*)
ren agri* mother_agri*
ren emp_* mother_emp_*
merge m:1 child_id using "$interim/nrva_2008_employment_wage.dta", ///
	nogen keep(master match) keepusing(child_id agri* emp_* lstatus wage)
ren agri* child_agri*
ren emp_* child_emp_*

*assign years to categories
foreach var in mother_educ father_educ child_educ {
  ren `var'_og `var'_cat_og
  gen `var'_og = 5 if `var'_cat_og == 1
  replace `var'_og = 8 if `var'_cat_og == 2
  replace `var'_og = 11 if `var'_cat_og == 3
  replace `var'_og = 13 if `var'_cat_og == 4
  replace `var'_og = 14 if `var'_cat_og == 5
  replace `var'_og = 16 if `var'_cat_og == 6
  replace `var'_og = 0 if `var'_cat_og == 0
} 

*add SARMD consumption data
gen pid = hh_id + "-" + string(member_id)
merge 1:1 pid using "$raw/HHS/AFG/SARMD/AFG_2008_NRVA_v01_M_v01_A_SARMD_IND.dta", nogen keepusing(welfarenat) keep(master match)
ren welfarenat hh_cons_month_wb

keep $var_main $var_cores $var_indiv hh_cons_month* urban lstatus wage
save "$interim/nrva_2008.dta", replace

********************************************************************************
********************************************************************************
**#6. Combine datasets + adjust variables
********************************************************************************
********************************************************************************
use "$interim/ielfs_2020.dta", clear
append using "$interim/alcs_2017.dta"
append using "$interim/alcs_2014.dta"
append using "$interim/nrva_2012.dta"
append using "$interim/nrva_2008.dta"

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*re: geo_level_1 is harmonized; not 2&3
drop geo_level_2 geo_level_3
ren geo_level_1 geo_level_2
gen geo_level_1 = .
*group provinces into UN regions 
replace geo_level_1 =	1	if geo_level_2==1	//	Kabul
replace geo_level_1 =	1	if geo_level_2==2	//	Kapisa
replace geo_level_1 =	1	if geo_level_2==3	//	Parwan
replace geo_level_1 =	1	if geo_level_2==4	//	Wardak
replace geo_level_1 =	1	if geo_level_2==5	//	Logar
replace geo_level_1 =	1	if geo_level_2==8	//	Panjsher
replace geo_level_1 =	2	if geo_level_2==23	//	Ghor
replace geo_level_1 =	2	if geo_level_2==31	//	Badghis
replace geo_level_1 =	2	if geo_level_2==32	//	Herat
replace geo_level_1 =	2	if geo_level_2==33	//	Farah
replace geo_level_1 =	2	if geo_level_2==10	//	Bamyan
replace geo_level_1 =	3	if geo_level_2==6	//	Nangarhar
replace geo_level_1 =	3	if geo_level_2==7	//	Laghman
replace geo_level_1 =	3	if geo_level_2==15	//	Kunarha
replace geo_level_1 =	3	if geo_level_2==16	//	Nooristan
replace geo_level_1 =	4	if geo_level_2==9	//	Baghlan
replace geo_level_1 =	4	if geo_level_2==17	//	Badakhshan
replace geo_level_1 =	4	if geo_level_2==18	//	Takhar
replace geo_level_1 =	4	if geo_level_2==19	//	Kunduz
replace geo_level_1 =	5	if geo_level_2==20	//	Samangan
replace geo_level_1 =	5	if geo_level_2==21	//	Balkh
replace geo_level_1 =	5	if geo_level_2==22	//	Sar-e-Pul
replace geo_level_1 =	5	if geo_level_2==28	//	Jawzjan
replace geo_level_1 =	5	if geo_level_2==29	//	Faryab
replace geo_level_1 =	6	if geo_level_2==11	//	Ghazni
replace geo_level_1 =	6	if geo_level_2==12	//	Paktika
replace geo_level_1 =	6	if geo_level_2==13	//	Paktya
replace geo_level_1 =	6	if geo_level_2==14	//	Khost
replace geo_level_1 =	7	if geo_level_2==25	//	Urozgan
replace geo_level_1 =	7	if geo_level_2==26	//	Zabul
replace geo_level_1 =	7	if geo_level_2==27	//	Kandahar
replace geo_level_1 =	7	if geo_level_2==30	//	Helmand
replace geo_level_1 =	7	if geo_level_2==34	//	Nimroz
replace geo_level_1 =	7	if geo_level_2==24	//	Daykundi

ren geo_level_1_birth geo_level_2_birth
gen geo_level_1_birth = .
replace geo_level_1_birth =	1	if geo_level_2_birth==1		//	Kabul
replace geo_level_1_birth =	1	if geo_level_2_birth==2		//	Kapisa
replace geo_level_1_birth =	1	if geo_level_2_birth==3		//	Parwan
replace geo_level_1_birth =	1	if geo_level_2_birth==4		//	Wardak
replace geo_level_1_birth =	1	if geo_level_2_birth==5		//	Logar
replace geo_level_1_birth =	1	if geo_level_2_birth==8		//	Panjsher
replace geo_level_1_birth =	2	if geo_level_2_birth==23	//	Ghor
replace geo_level_1_birth =	2	if geo_level_2_birth==31	//	Badghis
replace geo_level_1_birth =	2	if geo_level_2_birth==32	//	Herat
replace geo_level_1_birth =	2	if geo_level_2_birth==33	//	Farah
replace geo_level_1_birth =	2	if geo_level_2_birth==10	//	Bamyan
replace geo_level_1_birth =	3	if geo_level_2_birth==6		//	Nangarhar
replace geo_level_1_birth =	3	if geo_level_2_birth==7		//	Laghman
replace geo_level_1_birth =	3	if geo_level_2_birth==15	//	Kunarha
replace geo_level_1_birth =	3	if geo_level_2_birth==16	//	Nooristan
replace geo_level_1_birth =	4	if geo_level_2_birth==9		//	Baghlan
replace geo_level_1_birth =	4	if geo_level_2_birth==17	//	Badakhshan
replace geo_level_1_birth =	4	if geo_level_2_birth==18	//	Takhar
replace geo_level_1_birth =	4	if geo_level_2_birth==19	//	Kunduz
replace geo_level_1_birth =	5	if geo_level_2_birth==20	//	Samangan
replace geo_level_1_birth =	5	if geo_level_2_birth==21	//	Balkh
replace geo_level_1_birth =	5	if geo_level_2_birth==22	//	Sar-e-Pul
replace geo_level_1_birth =	5	if geo_level_2_birth==28	//	Jawzjan
replace geo_level_1_birth =	5	if geo_level_2_birth==29	//	Faryab
replace geo_level_1_birth =	6	if geo_level_2_birth==11	//	Ghazni
replace geo_level_1_birth =	6	if geo_level_2_birth==12	//	Paktika
replace geo_level_1_birth =	6	if geo_level_2_birth==13	//	Paktya
replace geo_level_1_birth =	6	if geo_level_2_birth==14	//	Khost
replace geo_level_1_birth =	7	if geo_level_2_birth==25	//	Urozgan
replace geo_level_1_birth =	7	if geo_level_2_birth==26	//	Zabul
replace geo_level_1_birth =	7	if geo_level_2_birth==27	//	Kandahar
replace geo_level_1_birth =	7	if geo_level_2_birth==30	//	Helmand
replace geo_level_1_birth =	7	if geo_level_2_birth==34	//	Nimroz
replace geo_level_1_birth =	7	if geo_level_2_birth==24	//	Daykundi

lab def geo_level_1 ///
	1 "Central" ///
	2 "West" ///
	3 "East" ///
	4 "North East" ///
	5 "North West" ///
	6 "South East" ///
	7 "South West"
lab val geo_level_1 geo_level_1
lab val geo_level_1_birth geo_level_1

ren migration_geo_level_1 migration_geo_level_2
gen migration_geo_level_1 = (geo_level_1!=geo_level_1_birth) if (geo_level_1!=.&geo_level_1_birth!=.)

*adjust years of education for non-attendence literacy
*re: 2007 only categorical mapped into years
foreach var in child father mother {
gen `var'_educ = `var'_educ_og
replace `var'_educ = 0 if `var'_educ_og==. & `var'_literate==0 
replace `var'_educ = 0 if `var'_educ_og==. & `var'_educ_stat==0 
replace `var'_educ = `var'_educ if inrange(`var'_educ, 1, 19)
replace `var'_educ = 1 if `var'_educ_og==. & `var'_literate==1 
replace `var'_educ = 16 if `var'_educ_og>=16 &  `var'_educ_og!=.
}

*correct years of education based on categorical variable for ALCS
foreach var in child father mother {
replace `var'_educ = 10 if (`var'_educ==9&`var'_educ_cat==3)
replace `var'_educ = 13 if (`var'_educ==12&`var'_educ_cat==4)
replace `var'_educ = 13 if (`var'_educ==12&`var'_educ_cat==5)
}

*correct 0 years in line with categories (ass:categorical variable more trustworthy)
*tab year if child_educ==0 & child_educ_cat!=0 // mainly 2011/2016
foreach var in child father mother {
	replace `var'_educ = 5 if (`var'_educ==0&`var'_educ_cat==1)
	replace `var'_educ = 8 if (`var'_educ==0&`var'_educ_cat==2)
	replace `var'_educ = 11 if (`var'_educ==0&`var'_educ_cat==3)
	replace `var'_educ = 13 if (`var'_educ==0&`var'_educ_cat==4)
	replace `var'_educ = 14 if (`var'_educ==0&`var'_educ_cat==5)
	replace `var'_educ = 16 if (`var'_educ==0&`var'_educ_cat==6)
}

*adjust LM variables 
gen empstat = 1 if child_emp_stat==2 | child_emp_stat==3 // Paid Employee = salaried worker
replace empstat = 2 if child_emp_stat==6 // Non-paid Employee
replace empstat = 3 if child_emp_stat==5 // Employer
replace empstat = 4 if child_emp_stat==4 // Self-Employed
replace empstat = 5 if child_emp_stat==1 // Others = day labourer 

*add demo variable based on geo_level_2
merge m:1 geo_level_2 using "$raw/auxiliary/geo_level/AFG_geo_level_2_demo_mapping.dta", nogen

drop *_og
lab var geo_level_1 "UN Region" //7
lab var geo_level_2 "Province" //34
compress
save "$clean/HHS_AFG_dataset.dta", replace