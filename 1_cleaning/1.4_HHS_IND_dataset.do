/******************************************************************************\
#title: "1.4_HHS_IND_dataset"
#author: "Fabian Reutzel"
#structure: 1. IHDS 2005 2011 (raw)
			2. NSS Consumption 1993 2004 2009 2011 (raw + SARMD)
			3. NSS Employment 1993 2004 2009 2011 (raw)
			4. HCES 2022 (raw + SARMD)
			5. Combine datasets + adjust variables
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. IHDS 2005 2011
********************************************************************************
********************************************************************************
use "$raw/HHS/IND/IHDS/2005/DS0002/22626-0002-Data.dta", clear 
gen SURVEY=1
save "$raw/HHS/IND/IHDS/2005/DS0002/22626-0002-Data_adj.dta", replace

use "$raw/HHS/IND/IHDS/2005_2011/DS0001/37382-0001-Data.dta", clear //individual file
destring IDHH, replace 
drop ID13
merge m:1 IDHH SURVEY using "$raw/HHS/IND/IHDS/2005/DS0002/22626-0002-Data_adj.dta", ///
nogen keepusing(ID13) //Caste 2005
tostring IDHH, replace 
merge m:1 IDPERSON SURVEY using "$raw/HHS/IND/IHDS/2011/DS0001/36151-0001-Data.dta", ///
nogen keepusing(ID13) update //Caste 2011
merge m:1 IDHH using "$raw/HHS/IND/IHDS/2005_2011/DS0007/37382-0007-Data.dta", nogen //individual income
merge m:1 IDHH IDPERSON using "$raw/HHS/IND/IHDS/2011/DS0003/36151-0003-Data.dta", ///
nogen keep (master match) keepusing(EW14A EW15A EW16A EW14B EW15B EW16B) //background women (2011 only)
ren *, lower

*generate country/survey/year
ren survey year_raw
gen survey = "IHDS"
gen survey_name = "India Human Development Survey"
gen country = "India"
gen year = 2005 if year_raw==1
replace year = 2011 if year_raw==2
gen coresident = "no"

*rename variables
ren idpsu psu
ren fwt wt_hh
drop wt
ren stateid geo_level_1
ren distid geo_level_2
ren psuid geo_level_3
replace age = int(age/12) //age definition in months 
gen female = (ro3==2)

ren id11 religion_og
gen religion = religion_og
replace religion = 7 if (religion_og==8|religion_og==9) //tribal + others + none

ren id13 caste_og
gen caste = .
replace caste = 1 if year_raw==2 & caste_og==4 //scheduled caste
replace caste = 2 if year_raw==2 & caste_og==5 //scheduled tribe
replace caste = 3 if year_raw==2 & caste_og==3 //other backward class
replace caste = 4 if year_raw==2 & (caste_og==1|caste_og==2|caste_og==6) //other 
replace caste = 1 if year_raw==1 & caste_og==3 //scheduled caste
replace caste = 2 if year_raw==1 & caste_og==4 //scheduled tribe
replace caste = 3 if year_raw==1 & caste_og==2 //other backward class
replace caste = 4 if year_raw==1 & (caste_og==1|caste_og==5) //other 
*others=(IHDS: Brahmin, Forward, Others)=(DHS: other class/tribe + no class/tribe)		
   
ren groups6 demo_og

gen urban_birth = 1 if (urban==1 & id16==0) //stayers
replace urban_birth = 0 if (urban==0 & id16==0) //stayers
replace urban_birth = 1 if id17==2 //only defined for movers
replace urban_birth = 0 if id17==1 //only defined for movers
gen migration_urban = (urban_birth!=urban)  if (urban_birth!=.&urban!=.)
gen migration_geo_level_2 = (id16==3|id16==4) if id16!=. //migration to other state/country
tab id17 if migration_urban==1
tab migration_geo_level_2
*re: migration_urban 10.5% with 93.2% rural-to-urban 
*re: migration_geo_level_2 5.2%
*re: migration_geo_level_1 not possible as we do not know exact state of birth

*adjust IDs
ren idhh hh_id 
tostring hh_id, replace 
ren personid member_id
*generate child & parent ids
gen child_id = hh_id + "-" + string(member_id)
ren ro9 father_num //75=dead
replace father_num = . if father_num>38 //38=max num in sample
ren ro10 mother_num
replace mother_num = . if mother_num>38 //38=max num in sample
gen father_id = hh_id + "-" + string(father_num)  
gen mother_id = hh_id + "-" + string(mother_num)
*HH relationship
gen hh_rel = 0 if ro4==1
replace hh_rel = 1 if ro4==2
replace hh_rel = 2 if ro4==3
replace hh_rel = 3 if ro4==6
gen child_coresident = (hh_rel==2)
gen hh_size = npersons

*individual income
gen inc_month_wage = wsearn/12 //only defined for wage income
gen inc_month = wkearnplus/12  //incl. estimated earnings from agriculture
replace inc_month_wage = . if inc_month_wage<=0
replace inc_month = . if inc_month<=0

*HH income
gen hh_inc_month = income / 12
replace hh_inc_month = . if hh_inc_month<=0

*HH consumption
gen hh_cons_month = cototal /12

*education
gen educ_stat = (ed4==1) if (ed4==0|ed4==1)
gen literate = (ed2==1) if (ed2==0|ed2==1)
ren ed6 educ_og //topcoded at 15 (Bachelor)
replace educ_og = . if educ_og<0
replace educ_og = 16 if educ_og==15 & ed12==5

*occupation
gen agri = (ws4>=60 & ws4<70) if ws4>0 //direct occupation question 
gen emp_salary = (wksalary==4) if wkany!=0 //assign only full time 
gen emp_stat = 1 if emp_salary==1
*replace emp_stat = 2 if emp_self==1
*replace emp_stat = 3 if (emp_stat_og==3) //employer
replace emp_stat = 4 if (wkanimal==4|wkaglab==4|wknonag==4) //wage (non-ag+agri) + animal care
replace emp_stat = 5 if (wkfarm==4|wkbusiness==4) //family worker (agri+business)
gen lstatus = (wkanyplus>0) if wkanyplus!=.

***parent_merge (manual due to direct parental background question)
**save roster dataset
preserve
foreach x in emp_* agri* educ_stat literate educ_og {
ren `x' child_`x'
} 
save "$interim/roster.dta", replace
restore 

**generate parental dataset
foreach x in emp_stat agri educ_stat literate educ_og {
gen mother_`x' = `x' if female==1
gen father_`x' = `x' if female==0
}
drop father_id mother_id 
gen father_id = child_id
gen mother_id = child_id
ren female parent_gender
duplicates drop hh_id child_id, force //2 obs
keep hh_id parent_gender mother_* father_* 
save "$interim/parents.dta", replace

**build dataset
use "$interim/roster.dta", clear

*add mother
gen parent_gender = 1
merge m:1 hh_id mother_id parent_gender using "$interim/parents.dta", ///
keepusing(mother_*) keep(master match) gen(mother_merge)
gen mother_home = 1 if mother_merge==3
replace mother_home = 0 if mother_merge==1

*add father 
replace parent_gender = 0
merge m:1 hh_id father_id parent_gender using "$interim/parents.dta", ///
keepusing(father_*) keep(master match) gen(father_merge)
gen father_home = 1 if father_merge==3
replace father_home = 0 if father_merge==1

*add direct question on HH head parental background (hh roster)
gen head_father_agri = (id18a>=60 & id18a<70) if id18a>0 
ren id18c head_father_educ
replace head_father_educ = . if head_father_educ<0
replace father_agri = 1 if head_father_agri==1 & hh_rel==0 
replace father_agri = 0 if head_father_agri==0 & hh_rel==0 
replace father_educ_og = head_father_educ if hh_rel==0 & head_father_educ!=. 

*add direct question on female parental background (2011 only)
gen female_mother_educ_stat = (ew14a==1) if (ew14a==0|ew14a==1)
gen female_mother_literate = (ew16a==1) if (ew16a==0|ew16a==1)
ren ew15a female_mother_educ_og
gen female_father_educ_stat = (ew14b==1) if (ew14b==0|ew14b==1)
gen female_father_literate = (ew16b==1) if (ew16b==0|ew16b==1)
ren ew15b female_father_educ_og
replace mother_educ_stat = female_mother_educ_stat if mother_educ_stat==. 
replace father_educ_stat = female_father_educ_stat if father_educ_stat==. 
replace mother_literate = female_mother_literate if mother_literate==. 
replace father_literate = female_father_literate if father_literate==. 
replace mother_educ_og = female_mother_educ_og if mother_educ_og==. 
replace father_educ_og = female_father_educ_og if father_educ_og==. 
*re: additional info on male spouse parents BUT should be included in roster already

*adjust education variables
foreach var in child father mother {
	*gen `var'_educ = `var'_educ_og + 1 if inrange(`var'_educ_og, 1, 15)
	gen `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 1, 16)
	replace `var'_educ = 0 if `var'_educ_og==0
	replace `var'_educ = 0 if `var'_educ_og==. & `var'_educ_stat==0
	replace `var'_educ = 0 if `var'_educ_og==. & `var'_literate==0
	replace `var'_educ = 1 if `var'_educ_og==. & `var'_literate==1
	gen `var'_educ_cat_wb = 1 if `var'_educ==0 
	replace `var'_educ_cat_wb = 2 if `var'_educ>=1 & `var'_educ<=4
	replace `var'_educ_cat_wb = 3 if `var'_educ==5 | `var'_educ==6
	replace `var'_educ_cat_wb = 4 if `var'_educ>=7 & `var'_educ<=10
	replace `var'_educ_cat_wb = 5 if `var'_educ>=11 & `var'_educ<=12
	replace `var'_educ_cat_wb = 6 if `var'_educ>=13 & `var'_educ<=14
	replace `var'_educ_cat_wb = 7 if `var'_educ==15 | `var'_educ==16
}

drop head_father* female_*
ren child_emp_stat emp_stat
keep $var_main $var_cores $var_indiv hh_inc inc_month hh_cons_month urban urban_birth migration* religion* demo* caste* emp_stat lstatus
compress
save "$interim/idhs_2005_2011.dta", replace

********************************************************************************
********************************************************************************
**#2. NSS consumption 1993 2004 2009 2011
*re: schedules employment & consumption are asked to different HH with same ID
********************************************************************************
********************************************************************************
foreach year in 1993 2004 2009 2011 {
	*combine raw data (roster + demographic variables)
	if `year'==1993{
		use "$raw/HHS/IND/NSS/consumption/1993/Block 4 - Person records.dta", clear 
		merge m:1 HHID using "$raw/HHS/IND/NSS/consumption/1993/Blocks 1,2,3,10,11,12,13_Household characteristics.dta", nogen keepusing(B3_1_q5 B3_1_q4 B3_1_q1) 
	}
	if `year'==2004{
		use "$raw/HHS/IND/NSS/consumption/2004/Block 4_Person records.dta", clear 
		merge m:1 HHID using "$raw/HHS/IND/NSS/consumption/2004/Block 3 Part 1_Household Characteristics.dta", nogen keepusing(B3_q6 B3_q5 B3_q1) 
	}
	if `year'==2009{
		use "$raw/HHS/IND/NSS/consumption/2009/Demographic and other particulars of household members.dta", clear 
		merge m:1 HH_ID using "$raw/HHS/IND/NSS/consumption/2009/Household Characteristics.dta", nogen keepusing(Social_Group Religion HH_Size) 
	}
	if `year'==2011{
		use "$raw/HHS/IND/NSS/consumption/2011/Demographic and other particulars of household members - Block 4  - Level 4 - Type 2 - 68.dta", clear 
		merge m:1 HHID using "$raw/HHS/IND/NSS/consumption/2011/Household characteristics - Block 3 - Level2 - type2 - 68.dta", nogen keepusing(Social_Group Religion hh_size) 
	}

	*education (re: adjust Wb coding as inconsistent across waves wrt educ_cat_og=1)
	ren *, lower
	*re for all waves: not literate -01, literate without formal schooling: EGS/ NFEC/ AEC -02, TLC -03, others -04
	if `year'==1993{
		destring b4_q7, gen(educ_raw)
		gen educ_cat_og = educ_raw
		recode educ_cat_og (1 2 3 4=1) (5=2) (6=3) (7=4) (8 9=5) (10 11 12 13=7) (0=.)
		*re: 10-13 graduate and above (by fields)
		gen educ_og = 0 if educ_cat_og==1
		replace educ_og = 2 	if educ_cat_og==2 	//below primary -05
		replace educ_og = 5 	if educ_cat_og==3 	//primary -06
		replace educ_og = 8 	if educ_cat_og==4 	//middle -07
		replace educ_og = 10 	if educ_cat_og==5	//secondary -08
		replace educ_og = 12 	if educ_raw==9 		//higher secondary -09
		replace educ_og = 15 	if educ_cat_og==7 	//graduate and above
	}	
	if `year'==2004{
		destring b4_q7, gen(educ_raw)
		gen educ_cat_og = educ_raw
		recode educ_cat_og (2 3=2) (4=3) (5=4) (8 10=5) (11=6) (12 13=7) (0 1=.)
		gen educ_og = 0 if educ_cat_og==1
		replace educ_og = 2 	if educ_cat_og==2 	//below primary -03
		replace educ_og = 5 	if educ_cat_og==3 	//primary -04
		replace educ_og = 8 	if educ_cat_og==4 	//middle -05
		replace educ_og = 10 	if educ_cat_og==5 	//secondary -06
		replace educ_og = 12 	if educ_raw==10 	//higher secondary -07
		replace educ_og = 13 	if educ_cat_og==6 	//diploma/certificate course -08
		replace educ_og = 15 	if educ_raw==12 	//graduate -10
		replace educ_og = 17 	if educ_raw==13 	//postgraduate and above -11
	}
	if `year'==2009 replace education = "" if education=="NN"
	if `year'==2009|`year'==2011 {
		destring education, gen(educ_raw)
		gen educ_cat_og = educ_raw
		recode educ_cat_og (1 2 3 4=1) (5=2) (6=3) (7=4) (8 10=5) (11=6) (12 13=7) (0=.)
		gen educ_og = 0 if educ_cat_og==1
		replace educ_og = 2 	if educ_cat_og==2 	//below primary -05
		replace educ_og = 5 	if educ_cat_og==3 	//primary -06
		replace educ_og = 8 	if educ_cat_og==4 	//middle -07
		replace educ_og = 10 	if educ_cat_og==5 	//secondary -08
		replace educ_og = 12 	if educ_raw==10 	//higher secondary -10
		replace educ_og = 13 	if educ_cat_og==6 	//diploma/certificate course -11
		replace educ_og = 15 	if educ_raw==12 	//graduate -12
		replace educ_og = 17 	if educ_raw==13 	//postgraduate and above -13
	}
	recode educ_raw (1 2 3 4= 0) (5 6 7 8 9 10 11 12 13=1) (0=.), gen (educ_stat)
	recode educ_raw (2/13 = 1) (1=0) (0=.), gen(literate) //illiteracy=1 in educ_raw (see above)
	lab def educ_cat_wb ///
		1 "No education" /// 
		2 "Primary incomplete" ///
		3 "Primary complete" ///
		4 "Secondary incomplete" /// 
		5 "Secondary complete" /// 
		6 "Higher than secondary but not university" /// 
		7 "University incomplete or complete"
	lab val educ_cat_og educ_cat_wb

	*demographic/HH variables
	if `year'==1993{
		ren b3_1_q5 			caste
		ren b3_1_q4				religion_og
		ren b3_1_q1				hh_size
		ren b4_q3				relation_raw
		ren b4_q5				age
		gen female = (b4_q4=="2") if b4_q4!=""
	}
	if `year'==2004{
		ren b3_q6 				caste
		ren b3_q5				religion_og
		ren b3_q1				hh_size
		ren b4_q3				relation_raw
		gen female = (b4_q4=="2") if b4_q4!=""
		ren b4_q5				age
	}
	if (`year'==2009|`year'==2011){
		destring age, replace
		ren social_group 		caste
		ren religion			religion_og
		ren relation			relation_raw
		gen female = (sex=="2") if sex!=""
	}
	if `year'==2009 replace caste = "" if caste=="N"
	destring caste, replace
	replace caste = 4 if caste==9
	destring relation_raw, replace
	gen 	hh_rel 	= 0 if relation_raw==1
	replace hh_rel 	= 1 if relation_raw==2
	replace hh_rel 	= 2 if relation_raw==3|relation_raw==5
	replace hh_rel 	= 3 if relation_raw==7
	gen child_coresident = (hh_rel==2)
	if `year'==2009 replace religion_og = "" if religion_og=="N"
	destring religion_og, replace
	gen 	religion = 1 if religion_og==1 // Hindu 
	replace religion = 2 if religion_og==2 // Muslim 
	replace religion = 3 if religion_og==3 // Christian 
	replace religion = 4 if religion_og==4 // Sikh 
	replace religion = 5 if religion_og==6 // Buddhist 
	replace religion = 6 if religion_og==5 // Jain 
	replace religion = 7 if religion==. & religion_og!=. // Tribal + others + none

	save "$interim/roster", replace
	*add SARMD data with adjusted identifiers + harmonized consumption estimates (GPWG)
	
	if `year'==2011{ //issue in pid coding; re: welfare does not vary on hhid level 
		use "$raw/HHS/IND/SARMD/IND_2011_NSS-SCH2_v02_M_v01_A_GMD_ALL", clear
		duplicates drop hhid welfare subnatid1, force
		save "$interim/IND_2011_NSS-SCH2_v02_M_v01_A_GMD_ALL_hhid", replace
		use "$raw/HHS/IND/GPWG/IND_2011_NSS-SCH1_V01_M_V06_A_GMD_GPWG", clear
		duplicates drop hhid welfare subnatid1, force
		save "$interim/IND_2011_NSS-SCH1_V01_M_V06_A_GMD_GPWG_hhid", replace
	}
	if `year'==1993{ // mapping of individuals members possible
		use "$raw/HHS/IND/SARMD/IND_1993_NSS50-SCH1.0_v01_M_v04_A_SARMD_IND.dta", clear
		keep wgt welfare subnatid1 urban idh idp psu
		gen hhid = substr(idh,6,5)+substr(idh,12,3)
		gen member_id = substr(idp, strpos(idp, "-")+1,.)  
		destring member_id, replace
		tostring member_id, format(%03.0f) replace
		gen person_key =  hhid + member_id
		merge 1:1 hhid person_key using "$interim/roster", nogen keep(match)
		*re: all SARMD obs matched; non-matched from raw data 260 HH
		ren idp pid
		replace welfare = welfare * 12 //adjustment made in latest SARMD revision to 2004
		ren welfare hh_cons_wb_old
		merge 1:1 pid using "$raw/HHS/IND/GPWG\IND_1993_NSS-SCH1_V01_M_V05_A_GMD_GPWG", nogen keep(match) keepusing(welfare)
		}
	if `year'==2004{
		use "$raw/HHS/IND/SARMD/IND_2004_NSS61-SCH1.0_v01_M_v05_A_SARMD_IND_GMD_ALL.dta", clear
		keep weight welfare subnatid1 urban hhid pid psu
		ren weight wgt
		gen member_id = substr(pid, strpos(pid, "-")+1,.)  
		destring member_id, replace
		tostring member_id, format(%02.0f) replace
		gen person_key =  hhid + member_id
		merge 1:1 person_key hhid using "$interim/roster", nogen
		ren welfare hh_cons_wb_old
		merge 1:1 pid using "$raw/HHS/IND/GPWG\IND_2004_NSS-SCH1_V01_M_V05_A_GMD_GPWG", nogen keep(match) keepusing(welfare)
	}
	if `year'==2009{
		use "$raw/HHS/IND/SARMD/IND_2009_NSS66-SCH1.0-T1_v01_M_v05_A_SARMD_IND_GMD_ALL.dta", clear
		keep pop_wgt welfare subnatid1 urban hhid pid psu
		ren pop_wgt wgt
		tostring hhid, format(%09.0f) gen(hh_id)
		gen person_serial_no = substr(pid, strpos(pid, "-")+1,.)  
		destring person_serial_no, replace
		tostring person_serial_no, format(%02.0f) replace
		merge 1:1 hh_id person_serial_no  using "$interim/roster", nogen
		ren welfare hh_cons_wb_old
		merge 1:1 pid using "$raw/HHS/IND/GPWG\IND_2009_NSS-SCH1_V01_M_V05_A_GMD_GPWG", nogen keep(match) keepusing(welfare)
	}
	if `year'==2011{ 
		use "$raw/HHS/IND/SARMD/IND_2011_NSS-SCH1_V01_M_V06_A_GMD_ALL", clear
		keep weight_h welfare subnatid1 urban hhid pid psu
		ren welfare hh_cons_wb_old
		ren weight_h wgt
		merge m:1 hhid using "$interim/IND_2011_NSS-SCH2_v02_M_v01_A_GMD_ALL_hhid", keepusing(welfare) nogen keep(using match)
		*re: 1,477 indiv (307 HH) of old measure not match & 307 hh not matched but no clear pattern
		ren welfare hh_cons_wb_new
		*ren hh_cons_wb_old welfare
		duplicates drop wgt hhid hh_cons_wb_old subnatid1, force
		merge 1:m hhid using "$interim/roster", nogen
		merge m:1 hhid using "$interim/IND_2011_NSS-SCH1_V01_M_V06_A_GMD_GPWG_hhid", nogen keepusing(welfare) keep(master match)
		*re: same 307 HH as in SCH2 that are not matched
	}
	
	*generate country/survey/year
	gen country = "India"
	gen survey = "NSS"
	gen survey_name = "National Sample Survey"
	gen year = `year'
	gen coresident = "yes"

	*rename variables
	ren wgt wt_hh
	if `year'!=2009 ren hhid hh_id
	ren pid child_id
	ren welfare hh_cons_month_wb //marked as expenditure (in line with the extended consumption definition)
	
	*geo_level coding
	gen geo_level_1 = substr(subnatid1,1,2) 
	destring geo_level_1, replace

	*add parental background 
	gen agri=. //to be recovered if needed
	gen emp_stat=. //
	parent_merge
	ren *educ_cat_og *educ_cat_wb
	ren *educ_og *educ //harmonized already at initial stage
	
	keep $var_main $var_cores $var_indiv hh_cons_* urban religion caste
	compress
	save "$interim/nss_cons_`year'.dta", replace
}

********************************************************************************
********************************************************************************
**#3. NSS employment 1993 2004 2009 2011
********************************************************************************
********************************************************************************
foreach year in 1993 2004 2009 2011 {
	*combine raw data (roster + employment status + demographic variable)
	if `year'==1993{
		use "$raw/HHS/IND/NSS/employment/1993/Block-4-Persons-Records.dta", clear 
		merge m:1 Hhold_Key using "$raw/HHS/IND/NSS/employment/1993/Block-1-3-Household-Records.dta", nogen keepusing(B3_q5_sgrup_Cd B3_q4_relgn_cd B3_q1_hh_size) keep(match)
	}
	if `year'==2004{
		use "$raw/HHS/IND/NSS/employment/2004/Block_4_level_03", clear 
		merge 1:1 PID using "$raw/HHS/IND/NSS/employment/2004/Block_5pt1_level_04", nogen keepusing(Usual_principal_activity_status)
		merge m:1 HHID using "$raw/HHS/IND/NSS/employment/2004/Block_1_2_and_3_level_01", nogen keep(match) keepusing (SOCIAL_GRP RELIGION HH_SIZE WEIGHT_COMBINED) //1 HH not identified
	}
	if `year'==2009{
		use "$raw/HHS/IND/NSS/employment/2009/Block_4_Demographic particulars of household members", clear 
		merge 1:1 PID using "$raw/HHS/IND/NSS/employment/2009/Block_5_1_Usual principal activity particulars of household members", nogen keepusing(Usual_Principal_Activity_Status)
		merge m:1 HHID using "$raw/HHS/IND/NSS/employment/2009/Block_3_Household characteristics", nogen keepusing(Social_Group Religion Religion HH_Size WEIGHT)
	}
	if `year'==2011 {
		use "$raw/HHS/IND/NSS/employment/2011/Block_4_Demographic particulars of household members", clear 
		merge 1:1 HHID Person_Serial_No using "$raw/HHS/IND/NSS/employment/2011/Block_5_1_Usual principal activity particulars of household members", nogen keepusing(Usual_Principal_Activity_Status)
		merge m:1 FSU_Serial_No Hamlet_Group_Sub_Block_No Second_Stage_Stratum_No Sample_Hhld_No using "$raw/HHS/IND/NSS/employment/2011/Block_3_Household characteristics.dta", nogen keepusing(Social_Group Religion Religion HH_Size Multiplier_comb)
	}

	*education
	ren *, lower
	*re for all waves: not literate -01, literate without formal schooling: EGS/ NFEC/ AEC -02, TLC -03, others -04
	if `year'==1993{
		destring b4_q7, gen(educ_raw)
		gen educ_cat_og = educ_raw
		recode educ_cat_og (1 2 3 4=1) (5=2) (6=3) (7=4) (8 9=5) (10 11 12 13=7) (0=.) //10-13 graduate and above (by fields)
		*adjust years of education for technical degree (only asked in EMPL)
		gen tech_degree = (b4_q8!="1")
		replace educ_cat_og = 6 if tech_degree==1 & educ_cat_og==5
		gen educ_og = 0 if educ_cat_og==1
		replace educ_og = 2 	if educ_cat_og==2 	//below primary -05
		replace educ_og = 5 	if educ_cat_og==3 	//primary -06
		replace educ_og = 8 	if educ_cat_og==4 	//middle -07
		replace educ_og = 10 	if educ_cat_og==5	//secondary -08
		replace educ_og = 12 	if educ_raw==9 		//higher secondary -09
		replace educ_og = 13 	if educ_cat_og==6 	//secondary + degree
		replace educ_og = 15 	if educ_cat_og==7 	//graduate and above
	}	
	if `year'!=1993{
		destring general_education, gen(educ_raw)
		gen educ_cat_og = educ_raw
		recode educ_cat_og (1 2 3 4=1) (5=2) (6=3) (7=4) (8 10=5) (11=6) (12 13=7) (0=.)
		*adjust years of education for technical degree (only asked in EMPL)
		gen tech_degree = (technical_education!="01") if technical_education!=""
		replace educ_cat_og = 6 if tech_degree==1 & educ_cat_og==5
		gen educ_og = 0 if educ_cat_og==1
		replace educ_og = 2 	if educ_cat_og==2 	//below primary -05
		replace educ_og = 5 	if educ_cat_og==3 	//primary -06
		replace educ_og = 8 	if educ_cat_og==4 	//middle -07
		replace educ_og = 10 	if educ_cat_og==5 	//secondary -08
		replace educ_og = 12 	if educ_raw==10 	//higher secondary -10
		replace educ_og = 13 	if educ_cat_og==6 	//diploma/certificate course -11
		replace educ_og = 15 	if educ_raw==12 	//graduate -12
		replace educ_og = 17 	if educ_raw==13 	//postgraduate and above -13
	}
	recode educ_raw (1 2 3 4= 0) (5 6 7 8 9 10 11 12 13=1) (0=.), gen (educ_stat)
	recode educ_raw (2/13 = 1) (1=0) (0=.), gen(literate) //literacy based on school attendance
	lab def educ_cat_wb ///
		1 "No education" /// 
		2 "Primary incomplete" ///
		3 "Primary complete" ///
		4 "Secondary incomplete" /// 
		5 "Secondary complete" /// 
		6 "Higher than secondary but not university" /// 
		7 "University incomplete or complete"
	lab val educ_cat_og educ_cat_wb
	
	*employment status
	if `year'==1993 ren b4_q12 emp_stat_og
	if `year'!=1993 ren usual_principal_activity_status emp_stat_og
	destring emp_stat_og, replace
	gen 	emp_stat = 1 if emp_stat_og==31 //Paid employee
    replace emp_stat = 2 if emp_stat_og==21 //Non-paid employee
    replace emp_stat = 3 if emp_stat_og==12 //Employer
    replace emp_stat = 4 if emp_stat_og==11 //Self-employed
    replace emp_stat = 5 if emp_stat_og==41|emp_stat_og==51 //Other: casual wage labour: in public works/in other types of work
	gen 	l_stat = 1 if emp_stat!=.
	replace l_stat = 2 if emp_stat_og==81 //did not work but was seeking and/or available for work
	replace l_stat = 3 if emp_stat_og>90&emp_stat_og<100 //out of LF
	
	*demographic/HH variables
	if `year'==1993{
		ren b3_q5_sgrup_cd 		caste
		ren b3_q4_relgn_cd		religion_og
		ren b3_q1_hh_size		hh_size
		ren b4_q3				relation_raw
		ren b4_q5				age
		gen female = (b4_q4=="2") if b4_q4!=""
	}
	if `year'==2004 ren social_grp	social_group
	if `year'!=1993{
		ren social_group 		caste
		ren religion			religion_og
		ren relation_to_head	relation_raw
		gen female = (sex=="2") if sex!=""
	}
	destring caste, replace
	replace caste = 4 if caste==9
	destring relation_raw, replace
	gen 	hh_rel 	= 0 if relation_raw==1
	replace hh_rel 	= 1 if relation_raw==2
	replace hh_rel 	= 2 if relation_raw==3|relation_raw==5
	replace hh_rel 	= 3 if relation_raw==7
	gen child_coresident = (hh_rel==2)
	destring religion_og, replace
	gen 	religion = 1 if religion_og==1 // Hindu 
	replace religion = 2 if religion_og==2 // Muslim 
	replace religion = 3 if religion_og==3 // Christian 
	replace religion = 4 if religion_og==4 // Sikh 
	replace religion = 5 if religion_og==6 // Buddhist 
	replace religion = 6 if religion_og==5 // Jain 
	replace religion = 7 if religion==. & religion_og!=. // Tribal + others + none

	save "$interim/roster", replace

	*generate country/survey/year
	gen country = "India"
	gen survey = "NSS - Employment"
	gen survey_name = "National Sample Survey"
	gen year = `year'
	gen coresident = "yes"

	*rename variables
	if `year'==1993 ren wgt_pooled wt_hh
	if `year'==2004 ren weight_combined wt_hh
	if `year'==2009 ren weight wt_hh
	if `year'==2011 ren multiplier_comb wt_hh
	if `year'==1993 ren (hhold_key prsn_slno vill_blk_slno) (hhid person_serial_no fsu)
	gen hh_id = "1" + hhid //adjust to differentiate survey schedules
	if `year'==1993|`year'==2011 gen pid = hh_id + person_serial_no
	ren pid child_id
	ren emp_stat empstat
	ren l_stat lstatus
	ren fsu psu
	*geo_level coding
	gen urban = (sector=="2")
	if `year'==2004 gen geo_level_1 = state_code
	if `year'!=2004 gen geo_level_1 = state
	destring geo_level_1, replace

	*add parental background 
	gen agri=. //to be recovered if needed
	parent_merge
	ren *educ_cat_og *educ_cat_wb
	ren *educ_og *educ //harmonized already at initial stage
	
	keep $var_main $var_cores $var_indiv urban religion caste empstat lstatus
	compress
	save "$interim/nss_empl_`year'.dta", replace
}

********************************************************************************
********************************************************************************
**#4. HCES 2022
*re: no labor data in GMD file
********************************************************************************
********************************************************************************
use "$raw/HHS/IND/SARMD/IND_2022_HCES_v02_M_v01_A_GMD_ALL", clear
gen fsu = substr(hhid, 1, 5)
gen b1q1pt11 = substr(hhid, 6, 1)
gen b1q1pt12 = substr(hhid, 7, 2)

*add harmonized consumption estimates
ren welfare hh_cons_wb_new //marked as expenditure (in line with the extended consumption definition)
merge 1:1 pid using "$raw/HHS/IND/GPWG/IND_2022_HCES_v02_M_v01_A_GMD_GPWG", nogen keep(match) keepusing(welfare)
ren welfare hh_cons_month_wb

*add religion from raw-data
*raw data .dta files generation based on https://github.com/advaitmoharir/hces_2022
merge m:1 fsu b1q1pt11 b1q1pt12 using "$raw/HHS/IND/HCES/2022/LEVEL - 03", nogen keep(match) keepusing(b4q4pt11)
destring b4q4pt11, gen(religion_og)
gen 	religion = 1 if religion_og==1 // Hindu 
replace religion = 2 if religion_og==2 // Muslim 
replace religion = 3 if religion_og==3 // Christian 
replace religion = 4 if religion_og==4 // Sikh 
replace religion = 5 if religion_og==6 // Buddhist 
replace religion = 6 if religion_og==5 // Jain 
replace religion = 7 if religion==. & religion_og!=0 // Tribal + others + none

*recode caste
replace soc = substr(soc, 1, 1)
destring soc, replace 
gen caste = .
replace caste = 1  if soc==2 //scheduled caste 
replace caste = 2  if soc==1 //scheduled tribe 
replace caste = 3  if soc==3 //other backward class 
replace caste = 4  if soc==9 //other 

*generate country/survey/year
gen country = "India"
gen survey_name = "Household Consumption Expenditure Survey"
gen coresident = "yes"

*rename variables
ren weight_h wt_hh
ren hhid hh_id
ren pid child_id
gen female = (male==0) if male!=.
ren hsize hh_size

*geo_level coding
gen geo_level_1 = substr(subnatid1,1,2) 
destring geo_level_1, replace
	
*add parental background 
ren relationharm hh_rel_og
gen hh_rel = 0 if hh_rel_og==1
replace hh_rel = 1 if hh_rel_og==2
replace hh_rel = 2 if hh_rel_og==3
replace hh_rel = 3 if hh_rel_og==4
gen child_coresident = (hh_rel==2)
gen agri = . //to be recovered if needed
gen emp_stat = . //no current info on empstat lstatus in SARMD data
gen educ_stat = .
gen literate =. 
ren educy educ_og 
ren educat7 educ_cat_og

parent_merge
ren *educ_cat_og *educ_cat_wb
ren *educ_og *educ 

gen psu = .
keep $var_main $var_cores $var_indiv hh_cons_wb_new hh_cons_month_wb urban religion caste 
compress
save "$interim/hces_2022.dta", replace

********************************************************************************
********************************************************************************
**#5. Combine datasets + adjust variables
********************************************************************************
********************************************************************************
*IHDS
use "$interim/idhs_2005_2011", clear

*NSS
foreach year in 1993 2004 2009 2011 {
	append using "$interim/nss_cons_`year'.dta", force
	append using "$interim/nss_empl_`year'.dta", force
}
*HCES
append using "$interim/hces_2022.dta", force

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*adjust education variables for categorial variable underlying NSS
foreach var in child father mother {
	replace `var'_educ = 10 if (`var'_educ_og==11) //secondary 
	replace `var'_educ = 13 if (`var'_educ_og==14) //higher non-tertitary - diploma/certificate course
	replace `var'_educ = 16 if (`var'_educ>16 &`var'_educ!=.) //top-code education 
	replace `var'_educ_cat_wb = 4 if `var'_educ==10 //recode NSS secondary as secondary incomplete for higher secondary=secondaryWB 
}
*re: while NSS idenfies degrees IHDS are coded in years

**adjust state-level geo-coding
*2019 merge of dadra & nagar haveli (25) and daman & diu (26) 
replace geo_level_1 = 25 if geo_level_1==26
*re: geo_level_2 not matched (68 vs 640)
drop geo_level_2 geo_level_3
drop if (geo_level_1==31|geo_level_1==35) //Lakshadweep + Anadman/Nicobar = Islands not covered in IHDS
	
gen geo_level_2_harm = geo_level_1
replace geo_level_2_harm = 9 if geo_level_1==5 //uttarakhand formerly part of uttar pradesh
replace geo_level_2_harm = 10 if geo_level_1==20 // jharkhand formerly part of bihar
replace geo_level_2_harm = 23 if geo_level_1==22 // chhattisgarh formerly part of madhya pradesh
replace geo_level_2_harm = . if geo_level_1==4|geo_level_1==25|geo_level_1==34 //Chandigarh/Daman+Diu & Dadra+Nagar Haveli/Pondicherry = union territories not surveyed prior 2005 
lab val geo_level_2_harm STATEID

*add geographical regions (Singh 2012)
ren geo_level_1 geo_level_2
gen geo_level_1 = 1 if (geo_level_2==1|geo_level_2==2|geo_level_2==3|geo_level_2==5|geo_level_2==6|geo_level_2==7|geo_level_2==8)
replace geo_level_1 = 2 if (geo_level_2==4|geo_level_2==9|geo_level_2==23|geo_level_2==22)
replace geo_level_1 = 3 if (geo_level_2==10|geo_level_2==19|geo_level_2==20|geo_level_2==21)
replace geo_level_1 = 4 if (geo_level_2==12|geo_level_2==17|geo_level_2==18|geo_level_2==14|geo_level_2==16|geo_level_2==13|geo_level_2==11|geo_level_2==15)
replace geo_level_1 = 5 if (geo_level_2==24|geo_level_2==27|geo_level_2==30|geo_level_2==25)
replace geo_level_1 = 6 if (geo_level_2==28|geo_level_2==29|geo_level_2==32|geo_level_2==33|geo_level_2==34)

lab def geo_level_1 ///
	1 "North" /// Jammu & Kashmir, Himachal Pradesh, Punjab, Uttaranchal, Haryana, Delhi, Rajasthan
	2 "Central" //// Chattisgarh, Uttar Pradesh, Madhya Pradesh, Chhattisgarh 
	3 "Eastern" /// Bihar, West Bengal, Jharkhand, Orissa
	4 "North-East" //// Arunachal Pradesh, Meghalaya, Assam, Manipur, Tripura, Nagaland, Sikkim, Mizoram
	5 "Western" /// Gujarat, Maharashtra, Goa, Dadra & nagar haveli + daman & diu
	6 "South" // Andhra Pradesh, Karnataka, Kerala, Tamil Nadu, Pondicherry
lab val geo_level_1 geo_level_1 

*adjust circumstance variables
gen demo = .
replace demo = 1 if caste==1 //scheduled caste 
replace demo = 2 if caste==2 //scheduled tribe 
replace demo = 3 if caste==3 //other backward class 
replace demo = 4 if religion==2 //Muslims
replace demo = 5 if (caste==4 & religion!=2) //others (no + other class/tribe) 
lab def demo ///
	1 "Scheduled Caste" ///
    2 "Scheduled Tribe" ///
    3 "Other backward Class" ///
    4 "Muslim" ///
	5 "Others"  
lab val demo demo 
*re: OBC part of OTHERS in NSS 1993 => NEED to adjust when pooling 

lab def religion ///
	1 "Hindu" ///
	2 "Muslim" ///
	3 "Christian" ///
	4 "Sikh" ///
	5 "Buddhist" ///
	6 "Jain" ///
	7 "Tribal + others + none"
lab val religion religion

*aggregate religion coding (Singh 2012)
gen religion_lim = religion
replace religion_lim = 3 if religion>3
lab def religion_lim ///
	1 "Hindu" ///
	2 "Muslim" ///
	3 "Others" 
lab val religion_lim religion_lim

lab var geo_level_1 "Region" //6
lab var geo_level_2 "State" //35 (27 states + 6 union territories as prior 2014)
lab var geo_level_2_harm "State" //27 (26 states + 1 union territory (Delhi))
*harm: disregards the following states (jharkhand, established in 2000) and union territories (Lakshadweep, Anadman/Nicobar, Ladakh, Chandigarh, Daman+Diu & Dadra+Nagar Haveli/Pondicherry)
*re: 2019: state "Jammu and Kashmir" split into two union territories, "Jammu and Kashmir" + "Ladakh" 

*use harmonized states for geo_level_2
ren geo_level_2 geo_level_2_raw
ren geo_level_2_harm geo_level_2

*get state names for splitted analysis
decode geo_level_2, gen(state)

*exclude obs with only hh_cons_wb_new measure (2011)
replace hh_cons_wb_new = . if hh_cons_month_wb==.

compress
save "$clean/HHS_IND_dataset.dta", replace