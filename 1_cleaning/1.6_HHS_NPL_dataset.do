/******************************************************************************\
#title: "1.6_HHS_NPL_dataset"
#author: "Fabian Reutzel"
#structure: 1. NLSS 1995 2003 2010 2022 (raw + SARMD)
			2. NPHC 2011 (Census)
			3. Combine datasets + adjust variables
\******************************************************************************/

********************************************************************************
********************************************************************************
**#1. NLSS 1995 2003 2010 2022
*re: change recall period consumption 1995/2003 vs. 2010/2022 (last 7 days) 
*=> BUT 2010/2022 not comparable according to PIP
*re: empstat / lstatus 2022 non-comparable to previous waves
********************************************************************************
********************************************************************************
foreach year in 1995 2003 2010 2022 {
	*generate wage income in main occupation (excl. 2022)
	if `year'==1995 local id 1
	if `year'==2003 local id 2
	if `year'==1995 local id_wage 1
	if `year'==2003 local id_wage 0
	if `year'==1995|`year'==2003 {
		*identify main occupation (i.e., worked the most in last 12m)
		use "$raw/HHS/NPL/NLSS/`year'/R`id'_Z01A_HHRoster", clear
		merge 1:m WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z01C_Activities", keep(master match) nogen
		sort WWWHH r`id'_IDC -r`id'_12moswrkt
		by WWWHH r`id'_IDC : gen n_occu = _n 
		keep if n_occu==1|n_occu==.
		*agricultural employment
		merge 1:m WWWHH r`id'_IDC r`id'_activcode using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z1`id_wage'A1_WgEmplmntAgri", keep(master match) nogen
		merge m:1 WWWHH r`id'_activcode using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z1`id_wage'A2_WgEmplmntAgri2", keep(master match) nogen
		gen day_wage_agr = r`id'_agpdycash
		replace day_wage_agr = 0 if r`id'_agpdycash==.
		gen day_ink = r`id'_agpdinkvl 
		replace day_ink = 0 if r`id'_agpdinkvl==.
		gen day_wage_ink_agri = day_wage_agr + day_ink
		gen year_wage_agr = r`id'_agpyycash
		replace year_wage_agr = 0 if r`id'_agpyycash==.
		gen year_ink = r`id'_agpyinkvt 
		replace year_ink = 0 if r`id'_agpyinkvt==.
		replace year_ink = r`id'_agpyinkvl if year_ink==. //daily ink payment for longterm employment
		replace year_ink = r`id'_agpdinkvt if year_ink==. //yearly ink payment for shortterm employment (197 obs)
		gen year_wage_agr_ink = year_wage_agr + year_ink
		gen wage_agr = year_wage_agr/12 //144
		replace wage_agr = day_wage_agr*20 if day_wage_agr*20>wage_agr  //1,741
		*re: only 1,832 with non-zero wage_agr payments, i.e. 53 of 144 have higher daily than annualy pay per day

		*non-agricultural employment
		merge 1:m WWWHH r`id'_IDC r`id'_activcode using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z1`id_wage'B1_WgEmplmntNAgri", keep(master match) nogen
		merge m:1 WWWHH r`id'_activcode using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z1`id_wage'B2_WgEmplmntNAgri2", keep(master match) nogen
		gen 	day_wage_nagr = r`id'_napdycash
		replace day_wage_nagr = 0 	if r`id'_napdycash==.
		gen 	day_ink_nagr = r`id'_napdinkvl 
		replace day_ink_nagr = 0 	if r`id'_napdinkvl==.
		gen 	day_wage_ink_nagr = day_wage_nagr + day_ink_nagr
		gen 	month_wage_nagr = r`id'_na30salar
		replace month_wage_nagr = 0	if r`id'_na30salar==.
		*yearly in-kind + other payments 
		replace r`id'_na12bonus = 0 	if r`id'_na12bonus==.
		replace r`id'_na12cloth = 0 	if r`id'_na12cloth==.
		replace r`id'_na12other = 0 	if r`id'_na12other==.	
		gen year_ink_nagr = r`id'_na12bonus + r`id'_na12cloth + r`id'_na12other
		gen 	month_wage_ink_nagr = month_wage_nagr + year_ink_nagr/12
		replace month_wage_ink_nagr = r`id'_nacntrtpm if r`id'_nacntrtpm!=. //piecerate work(cash + inkindpayments)
		gen 	wage_nagr = month_wage_nagr //607
		replace wage_nagr = day_wage_nagr*25 if day_wage_nagr*25>wage_nagr //281
		*re: 884 with non-zero wage_nagr payments
		
		*wage incl. in-kind payments
		gen 	wage_month_all = year_wage_agr_ink/121756
		replace wage_month_all = day_wage_ink_agri*20 	if day_wage_ink_agri*20>wage_month_all 
		replace wage_month_all = month_wage_ink_nagr 	if month_wage_ink_nagr>wage_month_all
		replace wage_month_all = day_wage_ink_nagr*20 	if day_wage_ink_nagr*20>wage_month_all
		
		*wage cash-payment only
		gen wage_month = wage_agr //580
		replace wage_month = wage_nagr if wage_nagr>wage_month //884
		*1995: 1,460

		*wage income only => disregard in-kind payment (WB coding)
		gen		wage = .
		replace wage = r`id'_na30salar	if r`id'_na30salar!=.
		replace wage = r`id'_napdycash if r`id'_napdycash!=.
		replace wage = r`id'_agpyycash if r`id'_agpyycash!=.
		replace wage = r`id'_agpdycash if r`id'_agpdycash!=.
		gen		unitwage = .
		replace unitwage = 1 if r`id'_agpdycash!=.|r`id'_napdycash!=. //Daily
		replace unitwage = 5 if r`id'_na30salar!=. //Monthly
		replace unitwage = 8 if r`id'_agpyycash!=. //Annually
		*1995: 1,459 obs
		
		keep WWWHH r`id'_IDC wage unitwage wage_month wage_month_all
		duplicates drop WWWHH r`id'_IDC, force //1 obs
		save "$interim/nepal_wages", replace 
	}
	if `year'==2010 {
		use "$raw/HHS/NPL/NLSS/2010/xH01_S01", clear
		ren v01_idc v10_02
		merge 1:m xhpsu xhnum v10_02 using "$raw/HHS/NPL/NLSS/2010/xH17_S10B", keep(master match) nogen
		ren v10_02 v12_01
		ren v10_02_job v12_01_job
		merge 1:m xhpsu xhnum v12_01 v12_01_job using "$raw/HHS/NPL/NLSS/2010/xH19_S12", nogen 
		gen hours_month = v10_05a * v10_05b
		sort xhpsu xhnum v12_01 -hours_month
		by xhpsu xhnum v12_01 : gen n_occu = _n 
		keep if n_occu==1
		
		*daily wage payment (for both sectors)
		gen day_wage = v12_04
		replace day_wage = 0 if v12_04
		gen day_ink = v12_06a 
		replace day_ink = 0 if v12_06a==.
		gen day_wage_ink = day_wage + day_ink
		*re: disregard yearly ink payment for shortterm employment (4 obs)
		
		*longterm agricultural employment
		gen year_wage_agr 	= v12_08
		replace year_wage_agr = 0 if v12_08
		gen year_ink = v12_10b 
		replace year_ink = 0 if v12_10b==.
		replace year_ink = v12_10a if year_ink==. //daily ink payment for longterm employment
		gen year_wage_agr_ink = year_wage_agr + year_ink
		gen wage_agr = year_wage_agr/12
		
		*longterm non-agricultural employment
		gen 	month_wage_nagr = v12_15a
		replace month_wage_nagr = 0	if v12_15a
		*yearly in-kind + other payments 
		replace v12_15b = 0 	if v12_15b==.
		replace v12_15c = 0 	if v12_15c==.
		replace v12_15d = 0 	if v12_15d==.
		gen year_ink_nagr = v12_15b + v12_15c + v12_15d
		gen 	month_wage_ink_nagr = month_wage_nagr + year_ink_nagr/12
		replace month_wage_ink_nagr = v12_21 if v12_21!=. //piecerate work(cash + inkindpayments)
		gen 	wage_nagr = month_wage_nagr
		
		*wage incl. in-kind payments
		gen 	wage_month_all = year_wage_agr_ink/12
		replace wage_month_all = month_wage_ink_nagr 	if month_wage_ink_nagr>wage_month_all
		replace wage_month_all = day_wage_ink*20 		if day_wage_ink*20>wage_month_all
		
		*wage cash-payment only
		gen wage_month = wage_agr
		replace wage_month = wage_nagr if wage_nagr>wage_month 
	
		*wage incomem only => diregard in-kind payment (WB coding)
		gen		wage = .
		replace wage = v12_15a	if v12_15a!=.
		replace wage = v12_08 	if v12_08!=.
		replace wage = v12_21	if v12_21!=.
		replace wage = v12_04 	if v12_04!=.
		gen		unitwage = .
		replace unitwage = 1 if v12_04!=. //Daily
		replace unitwage = 5 if v12_15a!=. //Monthly
		replace unitwage = 8 if v12_08!=. //Annually
		replace unitwage = 8 if v12_21!=. //Annually
		
		keep xhpsu xhnum v12_01 wage unitwage wage_month wage_month_all
		save "$interim/nepal_wages", replace 
	}
	*load data
	if `year'==1995|`year'==2003 {
		use "$raw/HHS/NPL/NLSS/`year'/R`id'_Z00_SurveyInfo", clear
		if `year'==1995 merge 1:m WWWHH using "$raw/HHS/NPL/NLSS/1995/R1_Z01B_Parents", keepusing(r1_fathrlhm r1_fathrsch r1_mothrlhm r1_mothrsch r1_IDC r1_father_ID r1_mother_ID r1_fathrlit r1_mothrlit) keep(match) nogen
		if `year'==2003 merge 1:m WWWHH using "$raw/HHS/NPL/NLSS/2003/R2_Z01B_Parents", keepusing(r2_fathrlhm r2_fathrsch r2_mothrlhm r2_mothrsch r2_IDC r2_father_ID r2_mother_ID) keep(match) nogen
		merge 1:1 WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z07A_Literacy", keepusing(r`id'_canread r`id'_canwrite r`id'_educbckr) keep(master match) nogen
		merge 1:1 WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z07B_PastEnroll", keepusing(r`id'_edlevcmpl) keep(master match) nogen
		merge 1:1 WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z01D_Unemployment", keep(master match) nogen
		if `year'==1995{
			merge 1:1 r`id'_IDC WWWHH using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z01A_HHRoster", keepusing(r`id'_sex r`id'_relation r`id'_age r`id'_urbrurborn) keep(match) nogen
			merge 1:1 WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z07C1_CurrEnroll", keepusing(r`id'_attendcls) keep(master match) nogen
			merge m:1 WWWHH using "$raw/HHS/NPL/NLSS/1995/SAS_NPL_1995_96_NLSS1", keepusing(c1_totcons c1_hhsize) nogen
			merge m:1 WWW using "$raw/HHS/NPL/NLSS/1995/sample_hh", keepusing(urbrural region district wname weight) keep(match) nogen
		}
		if `year'==2003{
			merge 1:m WWWHH r2_IDC using "$raw/HHS/NPL/NLSS/2003/R2_Z01A_HHRoster", keepusing(r2_sex r2_relation r2_age *ethncity) keep(match) nogen
			merge 1:1 WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/2003/R2_Z07C_CurrEnroll", keepusing(r`id'_attendcls) keep(master match) nogen
			merge m:1 WWW using "$raw/HHS/NPL/NLSS/2003/sample", keepusing(urbrural region district vdcname weight) keep(match) nogen
			merge m:1 WWWHH using "$raw/HHS/NPL/NLSS/2003/SAS_NPL_2003_04_NLSS2", keepusing(c2_totcons c2_hhsize) nogen
		}
		merge 1:1 WWWHH r`id'_IDC using "$interim/nepal_wages", keep(master match) nogen
		merge 1:m WWWHH r`id'_IDC using "$raw/HHS/NPL/NLSS/`year'/R`id'_Z01C_Activities", keep(master match) nogen
	}
	if `year'==2010{
		use "$raw/HHS/NPL/NLSS/2010/xH00_S00", clear 
		merge 1:m xhpsu xhnum using "$raw/HHS/NPL/NLSS/2010/xH01_S01", nogen
		ren v01_idc v07_idc
		merge 1:1 xhpsu xhnum v07_idc using "$raw/HHS/NPL/NLSS/2010/xH10_S07", keepusing(v07_08 v07_02 v07_03 v07_11 v07_18) keep(master match) nogen
		ren v07_idc v11_idc
		merge 1:1 xhpsu xhnum v11_idc using "$raw/HHS/NPL/NLSS/2010/xH18_S11", keep(master match) nogen
		ren v11_idc v10_02
		merge 1:m xhpsu xhnum v10_02 using "$raw/HHS/NPL/NLSS/2010/xH17_S10B", keep(master match) nogen
		ren v10_02 v12_01
		merge m:1 xhpsu xhnum v12_01 using "$interim/nepal_wages", keep(master match) nogen
	}
	if `year'==2022 {
		use "$raw/HHS/NPL/SARMD/NPL_2022_LSS-IV_V01_M_V02_A_GMD_ALL", clear
		merge 1:1 pid using "$raw/HHS/NPL/NLSS/2022/NPL_2022_LSS-IV_v02_M_v01_A_SARMD_INC", nogen keepusing(q01_07)
		merge m:1 hhid using "$raw/HHS/NPL/NLSS/2022/NPL_2022_LSS-IV_v02_M_RAW/99_NLSSIV_hhdata", nogen keepusing(dist_code)
		drop survey
	}
	*generate country/survey/year
	gen survey = "NLSS"
	gen survey_name = "Nepal Living Standards Survey"
	gen country = "Nepal"
	if `year'!=2022 gen year = `year'
	if `year'==1995|`year'==2010 gen coresident = "no"
	if `year'==2003|`year'==2022 gen coresident = "yes"
 
	*rename variables
	if `year'==1995|`year'==2003{
		ren WWWHH hh_id
		ren *_IDC member_id
		ren *RELI religion_og
		ren weight wt_hh
		ren district geo_level_3

		gen urban = urbrural==1
		gen female = (r`id'_sex==2)
		ren *hhsize hh_size
		ren *totcons hh_cons_month 
		ren r`id'_relation relationharm
		ren r`id'_age age
	}
	if `year'==2010{
		gen hh_id  = string(xhpsu) + "-" + string(xhnum)
		ren v12_01 member_id
		ren v00_e religion_og
		ren v00_f language_og
		ren v00_dist geo_level_3 //districts 
		gen female = (v01_02==2)
		gen urban_birth = (v01_05b==1) if v01_05b!=.  //asked for all members directly
		ren v01_05a geo_level_3_birth
		egen hh_size = max(member_id), by(hh_id) 
		ren v01_04 relationharm
		ren v01_03 age
	}
	if `year'==2022{
		ren hhid hh_id  
		ren pid child_id
		gen female = (male==0)
		ren welfare hh_cons_month_wb
		ren hsize hh_size 
		ren weight wt_hh
		gen religion_og = .
		gen language_og = language 
		gen wage = wage_total_year/12 //annualized despite uniwage==5=monthly
		decode dist_code, gen(geo_level_3_str)
		replace geo_level_3_str = lower(geo_level_3_str)
		replace geo_level_3_str = "rukum" if geo_level_3_str=="rukum east"|geo_level_3_str=="rukum west"
		replace geo_level_3_str = "nawalparasi" if geo_level_3_str=="nawalparasi east"|geo_level_3_str=="nawalparasi west"
		merge m:1 geo_level_3_str using "$raw/auxiliary/geo_level/NPL_district_province_mapping.dta", nogen keepusing(geo_level_3)
	}
	
	*demographic group
	if `year'==1995 {
		ren R1_V00_LANG language_og_1995
		gen language_og = language_og_1995 
		replace language_og = language_og_1995+1 if language_og_1995>3 & language_og_1995!=.
		 *adjust 1995 to common coding scheme
		ren *ETHN demo_og_1995
		gen demo_og = demo_og_1995
		replace	demo_og =	6	if	demo_og_1995==	5	//Newar
		replace	demo_og =	5	if	demo_og_1995==	6	//Tamang
		replace	demo_og =	8	if	demo_og_1995==	7	//Kami
		replace	demo_og =	9	if	demo_og_1995==	8	//Yadav
		replace	demo_og =	7	if	demo_og_1995==	9	//Muslim
		gen demo_harm = demo_og
		gen urban_birth = (r1_urbrurborn==1) if r1_urbrurborn!=.
	}
	if  `year'==2003 {
		ren R2_V00_LANG language_og
		ren r2_ethncity demo_og
		gen demo_harm = demo_og
		replace demo_harm = 14 if demo_og==15
		replace demo_harm = 15 if ((demo_og>15|demo_og==14)&demo_og!=.)
		gen demo_full = demo_og
	}
	if `year'==2010 {
		ren v01_08 demo_og
		replace demo_og = 999 if demo_og>101 & demo_og!=. //others
		gen demo_harm = demo_og
		replace demo_harm = 14 if demo_og==15
		replace demo_harm = 15 if ((demo_og>15|demo_og==14)&demo_og!=.)
		gen demo_full = demo_og
	}
	if `year'==2022 {
		ren q01_07 demo_og_2022
		gen demo_lim = .
		replace	demo_lim =	1 if demo_og_2022==21|demo_og_2022==22	//"Janajati"
		replace	demo_lim =	2 if demo_og_2022==11					//"Khas"=="Hill"
		replace	demo_lim =	3 if demo_og_2022==40					//"Muslim"=="Religions/Linguistic group"
		replace	demo_lim =	4 if demo_og_2022!=. & demo_lim==.		//"Others" 
	}
	
	*employment status
	if `year'==1995 {
		*identify main occupation (i.e., worked the most in last 12m)
		sort hh_id member_id -r1_12moswrkt
		by hh_id member_id : gen n_occu = _n 
		keep if n_occu==1|n_occu==.
		gen 	emp_stat = 1 if r1_wgemplagr==1
		replace emp_stat = 2 if r1_wgemplnag==1
		replace emp_stat = 3 if r1_slemplagr==1
		replace emp_stat = 4 if r1_slemplnag==1
		gen 	l_stat = 1 if emp_stat!=.
		replace l_stat = 2 if r1_undm_avwr==1 //available for work/more work
		replace l_stat = 3 if r1_undm_avwr==2&(r1_12hourdwr<5|r1_12hourdwr==.) //not available for work/more than part-time 
		gen 	l_stat_0 = 1 if emp_stat!=.
		replace l_stat_0 = 2 if r1_undm_avwr==1 //available for work/more work
		replace l_stat_0 = 3 if r1_undm_avwr==2&(r1_12hourdwr<1|r1_12hourdwr==.) //not available for work
	}
	if `year'==2003 {
		*identify main occupation (i.e., worked the most in last 12m)
		sort hh_id member_id -r2_12moswrkt
		by hh_id member_id : gen n_occu = _n 
		keep if n_occu==1|n_occu==.
		gen 	emp_stat = 1 if r2_wgemplagr==1
		replace emp_stat = 2 if r2_wgemplnag==1
		replace emp_stat = 3 if r2_slemplagr==1
		replace emp_stat = 4 if r2_slemplnag==1
		gen 	l_stat = 1 if emp_stat!=.
		replace l_stat = 2 if r2_und_avwkr==1|r2_unm_avwkr==1 //available for work/more
		replace l_stat = 3 if (r2_und_avwkr==2|r2_unm_avwkr==2)&(r2_7hrperwek<20|r2_7hrperwek==.) //not available for work/more than part-time
		gen 	l_stat_0 = 1 if emp_stat!=.
		replace l_stat_0 = 2 if r2_und_avwkr==1|r2_unm_avwkr==1 //available for work/more
		replace l_stat_0 = 3 if (r2_und_avwkr==2|r2_unm_avwkr==2)&(r2_7hrperwek<1|r2_7hrperwek==.) //not available for work
	}
	if `year'==2010 {
		*identify main occupation (i.e., worked the most hours in last month)
		gen hours_month = v10_05a * v10_05b
		sort hh_id member_id -hours_month
		by hh_id member_id : gen n_occu = _n 
		keep if n_occu==1
		gen 	emp_stat =  v10_07
		gen 	l_stat = 1 if emp_stat!=. 
		replace l_stat = 2 if v11_02==1|v11_05==1 //available for work/more work
		replace l_stat = 3 if (v11_02==2|v11_05==2)&(v11_01<20|v11_01==.) //not available for work/more than part-time
		gen 	l_stat_0 = 1 if emp_stat!=. & v11_01!=0 //worked >0 hours 
		replace l_stat_0 = 2 if v11_02==1|v11_05==1 //available for work/more work
		replace l_stat_0 = 3 if (v11_02==2|v11_05==2)&(v11_01<1|v11_01==.) //not available for work
	}
	if `year'==2022{ //use 7day reference period
		gen emp_stat = empstat
		gen l_stat = lstatus
		gen educ_stat_og = (educy!=0) if educy!=.
		gen literate_og = literacy
		gen educ_og = educy
		gen father_home = . 
		gen mother_home = . 
	}
	*parental id (omit parent_merge for 2022 as not used in analysis)
	if `year'!=2022{
		if `year'==1995|`year'==2003{ 
			ren *father_ID fid
			ren *mother_ID mid
			ren r`id'_fathrlhm father_home
			ren r`id'_mothrlhm mother_home
			ren *fathrsch father_educ_og
			ren *mothrsch mother_educ_og
		}		
		if `year'==2010 {
			ren v01_12 fid
			ren v01_15 mid
			gen father_home = (fid!=.)
			gen mother_home = (mid!=.)
			ren v01_16 mother_educ_og
			ren v01_13 father_educ_og
		}
		
		*parental education
		*directly recorded parental education vars
		if `year'==1995{
		gen father_literate_og = (r`id'_fathrlit==1) if r`id'_fathrlit!=.
		gen mother_literate_og = (r`id'_mothrlit==1) if r`id'_mothrlit!=.
		foreach var in father mother { 
			replace `var'_educ_og = 0 if `var'_educ_og==1    
			replace `var'_educ_og = 4 if `var'_educ_og==2
			replace `var'_educ_og = 7 if `var'_educ_og==3
			replace `var'_educ_og = 10 if `var'_educ_og==4
			replace `var'_educ_og = 12 if `var'_educ_og==5
			replace `var'_educ_og = 14 if `var'_educ_og==6
			}
		gen father_educ_stat_og = (father_educ_og>0 |father_literate_og==1)	if father_educ_og!=.|father_literate_og!=.
		gen mother_educ_stat_og = (mother_educ_og>0|mother_literate_og==1) 	if mother_educ_og!=.&mother_literate_og!=.
		}  
		if `year'==2003{
		foreach var in father mother { 
			gen `var'_literate_og =  0 if `var'_educ_og==17
			replace `var'_literate_og =  1 if `var'_educ_og==16
			replace `var'_educ_og = 0 if `var'_educ_og==17
			replace `var'_educ_og = 1 if `var'_educ_og==16
			replace `var'_literate_og =  1 if `var'_educ_og>0 &`var'_educ_og!=.
			gen `var'_educ_stat_og = (`var'_educ_og>0 &`var'_educ_og!=.)
			}
		}
		if `year'==2010{ //no direct literacy question
			gen father_literate_og = .
			gen mother_literate_og = .
			gen father_educ_stat_og = (father_educ_og>0 |father_literate_og==1)	if father_educ_og!=.|father_literate_og!=.
			gen mother_educ_stat_og = (mother_educ_og>0|mother_literate_og==1) 	if mother_educ_og!=.|mother_literate_og!=.
		}  
		
	*respondent education
	if `year'==1995|`year'==2003{ 
		gen literate_og = 1 if r`id'_canread==1 & r`id'_canwrite==1
		replace literate_og = 0 if r`id'_canread==2
		replace literate_og = 0 if r`id'_canwrite==2
		replace literate_og = 0 if r`id'_educbckr==1 & literate_og==.
		gen educ_stat_og = (r`id'_educbckr==3|r`id'_educbckr==3)
		ren r`id'_edlevcmpl highest_educ_og
		ren r`id'_attendcls current_educ_og
		gen educ_og = highest_educ_og
		replace educ_og = current_educ_og-1 if educ_og==.
	}
	if `year'==2010{ 
		gen educ_stat_og = (v07_08==2|v07_08==3) if v07_08!=.
		gen literate_og = (v07_02==1 & v07_03==1) if (v07_02!=.|v07_03!=.)
		gen educ_og = v07_11 
		replace educ_og = v07_18 -1 if educ_og==.
		replace educ_og = 0 if educ_stat==0 & educ_og==.
	}

	**parent_merge (manual due to direct parental background question in 1995 +2010)
	*save intermediate dataset
	save "$interim/working.dta", replace

	*extract father education using roster
	gen merge_id = member_id
	gen father_emp_stat = emp_stat
	gen father_educ_roster = educ_og
	gen father_literate_roster = literate_og
	gen father_educ_stat_roster = educ_stat_og
	preserve
	keep if female==0
	keep hh_id merge_id father_emp_stat father_educ_roster father_literate_roster father_educ_stat_roster 
	save "$interim/fathers.dta", replace
	restore
	drop merge_id father_educ_roster
	gen merge_id = fid

	*merge to bring in father education
	merge m:1 hh_id merge_id using "$interim/fathers.dta", keepusing(father_emp_stat father_educ_roster father_literate_roster father_educ_stat_roster) keep(master match) nogen

	*fill in father education id when missing
	replace father_educ_og = father_educ_roster if father_educ_og==.
	replace father_literate_og = father_literate_roster if father_educ_og==.
	replace father_educ_stat_og = father_educ_stat_roster if father_educ_stat_og==.

	*extract mother education using roster
	drop merge_id
	gen merge_id = member_id
	gen mother_emp_stat = emp_stat
	gen mother_educ_roster = educ_og
	gen mother_literate_roster = literate_og
	gen mother_educ_stat_roster = educ_stat_og
	preserve
	keep if female==1
	keep hh_id merge_id mother_emp_stat mother_educ_roster mother_literate_roster mother_educ_stat_roster
	save "$interim/mothers.dta", replace
	restore
	drop merge_id mother_educ_roster
	gen merge_id = mid

	*merge to bring in mother education
	merge m:1 hh_id merge_id using "$interim/mothers.dta", keepusing(mother_emp_stat mother_educ_roster mother_literate_roster mother_educ_stat_roster) keep(master match) nogen

	*fill in mother education id when missing
	replace mother_educ_og = mother_educ_roster if mother_educ_og==.
	replace mother_literate_og = mother_literate_roster if mother_educ_og==.
	replace mother_educ_stat_og = mother_educ_stat_roster if mother_educ_stat_og==.
	
	*rename education vars
	ren emp_stat child_emp_stat
	ren educ_og child_educ_og
	ren literate_og child_literate_og
	ren educ_stat_og child_educ_stat_og
  
	*adjust educ vars
	if `year'==1995|`year'==2003{ 
		foreach var in father mother child {
			gen `var'_educ_stat =`var'_educ_stat_og    
			gen `var'_literate = `var'_literate_og  
			gen `var'_educ = 0 if `var'_educ_og==0    
			replace `var'_educ = 0 if `var'_literate==0  & `var'_educ_og==.
			*replace `var'_educ = `var'_educ_og + 1 if inrange(`var'_educ_og, 1, 15)
			replace `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 1, 12)
			replace `var'_educ = 14 if (`var'_educ_og==13|`var'_educ_og==15) //BSc OR profesional degree
			replace `var'_educ = 16 if `var'_educ_og==14
			*replace `var'_educ = `var'_educ_og if inlist(`var'_educ_og, 11, 12)
			replace `var'_educ = 1 if `var'_educ_og==16 & `year'==2003 //literate,non-formal 
			replace `var'_educ = . if `var'_educ_og==16 & `year'==1995 //other
			replace `var'_educ = 1 if `var'_literate==1 & `var'_educ_og==.
		}
	}
	if `year'==2010{ 
		foreach var in child father mother {
			gen `var'_educ_stat =`var'_educ_stat_og    
			gen `var'_literate = `var'_literate_og  
			gen `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 1, 12)
			replace `var'_educ = 14 if inlist(`var'_educ_og, 13,15) //Bachelor & Professional degree
			replace `var'_educ = 16 if `var'_educ_og==14
			*recode `var'_educ (13 = 15) (14 15 = 17) //World Bank adjustment
			replace `var'_educ = 1 if `var'_educ_og==16 //literate but levelless
			replace `var'_educ = 0 if `var'_educ_og==17 //illiterate
			replace `var'_educ = 0 if `var'_educ_og==0 
			replace `var'_educ = 0 if `var'_educ_og==998
		}
	}
	}
	if `year'==2022{ 
		foreach var in child {
			gen `var'_emp_stat = emp_stat    
			gen `var'_educ_stat = educ_stat_og    
			gen `var'_literate = literate_og  
			gen `var'_educ = educ_og 
			replace `var'_educ = 16 if educ_og==17 //top-code
		}
	}
			
	*HH relation & co-residence status
	gen hh_rel = 0 if relationharm==1
	replace hh_rel = 1 if relationharm==2
	replace hh_rel = 2 if relationharm==3
	if `year'!=2022 replace hh_rel = 3 if relationharm==5
	if `year'==2022 replace hh_rel = 3 if relationharm==4
	gen child_coresident = (hh_rel==2)
	if `year'==2010 gen child_id = hh_id + "-" + string(member_id)
	if `year'==1995|`year'==2003 gen child_id = string(hh_id) + "-" + string(member_id)

	
	*add "harmonized" hh_cons from WB
	if `year'!=2022 gen idp = child_id
	if `year'==1995 merge 1:1 idp using "$raw/HHS/NPL/SARMD/NPL_1995_LSS-I_v01_M_v03_A_SARMD.dta", nogen keep(match master) keepusing(welfshprosperity_v2 wgt pop_wgt empstat* lstatus*)
	if `year'==2003 merge 1:1 idp using "$raw/HHS/NPL/SARMD/NPL_2003_LSS-II_v01_M_v04_A_SARMD.dta", nogen keep(match master) keepusing(welfshprosperity_v2 wgt pop_wgt empstat* lstatus*)
	if `year'==2010 merge 1:1 idp using "$raw/HHS/NPL/SARMD/NPL_2010_LSS-III_v01_M_v05_A_SARMD.dta", nogen keep(match master) keepusing(welfshprosperity wgt pop_wgt empstat* lstatus* subnatid1 urban)
	if `year'!=2022 {
		if `year'!=2010 ren *_v2 *
		if `year'!=2010 tostring hh_id, replace 
		ren welfshprosperity hh_cons_month_wb
		ren wgt wt_hh_wb
		ren pop_wgt wt_pop
	}
	if `year'==2010| `year'==2022{
		gen geo_level_2 = substr(subnatid1,1,1)
		destring geo_level_2, replace
	}
	if `year'==1995|`year'==2003 gen psu = .
	if `year'==2010 ren xhpsu psu 

	keep $var_main $var_cores $var_indiv $var_outcome hh_cons_month* urban* demo* religion_og language_og wage l_stat* empstat lstatus
	compress
	save "$interim/nlss_`year'.dta", replace
}

********************************************************************************
********************************************************************************
**#2. NPHC (Census) 2011
*re: no info on income/consumption
********************************************************************************
********************************************************************************
use "$raw/HHS/NPL/NPHC/2011/Household.dta", clear //HH 
merge 1:m DIST VDCMUN WARD EA HNO HHNO using "$raw/HHS/NPL/NPHC/2011/Individual01.dta", nogen //education
merge 1:1 DIST VDCMUN WARD EA HNO HHNO IDCODE using "$raw/HHS/NPL/NPHC/2011/Individual02.dta", nogen //occupation
merge m:1 DIST VDCMUN using "$raw/HHS/NPL/NPHC/2011/BatchId.dta", nogen //urbanity

*generate country/survey/year
gen survey = "NPHC"
gen country = "Nepal"
gen survey_name = "National Population and Housing Census"
gen year = 2011
gen coresident = "yes"

*rename variables
gen VDCMUN_adj = string(VDCMUN)
replace VDCMUN_adj = "0" + string(VDCMUN) if VDCMUN<10
gen WARD_adj = string(WARD)
replace WARD_adj = "0" + string(WARD) if WARD<10
gen EA_adj = string(EA)
replace EA_adj = "0" + string(EA) if EA<10
gen HNO_adj = string(HNO)
replace HNO_adj = "0" + string(HNO) if HNO<10
gen psu = . //string(DIST) + VDCMUN_adj + WARD_adj + EA_adj
gen hh_id = string(DIST) + VDCMUN_adj + WARD_adj + EA_adj + HNO_adj + string(HHNO)
ren IDCODE member_id
gen child_id = hh_id + string(member_id)
gen wt_hh = 1 //census, i.e. fully representative sample
gen female = (Q04==2)
ren Q05 age
egen hh_size = max(member_id), by(hh_id) 
gen urban = (URB_RUR==1) if URB_RUR!=.
gen urban_birth = (Q16C==2) if (Q16C==1|Q16C==2) //only asked to movers
replace urban_birth = 1 if Q19A==1 & urban==1
replace urban_birth = 0 if Q19A==1 & urban==0
gen geo_level_3_birth = Q16B 
replace geo_level_3_birth = DIST if Q16A==1 
gen disability = (Q12!=0) if (Q12!=. & Q12!=99)
ren Q09 religion_og
ren Q10_1 language_og

*demography
ren Q06 demo_og
gen demo_full = demo_og
replace demo_full = demo_og +1 if demo_og>80 & demo_og!=. 
replace demo_full = 999 if demo_og>100 & demo_og!=. //others
gen demo_harm = demo_og
replace demo_harm = 14 if demo_og==15
replace demo_harm = 15 if ((demo_og>15|demo_og==14)&demo_og!=.)
ren DIST geo_level_3
*re: geo_level 1 & 2 cannot be recovered; only comparable on district level

*occupation
gen agri = (Q23==5) if (Q23!=.&Q23!=99) //direct occupation question 
*gen agri_work = (Q22_1>0) if (Q22_1!=.&Q22_1!=99) //worked at least 1 month as wage employee
gen emp_salary = (Q22_2>0) if Q22_2!=. //worked at least 1 month as wage employee
gen 	emp_stat = 1 if (Q25==2) //employees
replace emp_stat = 4 if (Q25==3) //Own-account worker
replace emp_stat = 3 if (Q25==1) //employer
replace emp_stat = 2 if (Q25==4) //Contributing family worker
*replace emp_stat = 2 if (Q22_6==12) //worked 12M in HH (coded as NA)
gen 	l_stat = 1 if Q25!=. //some form of employment
replace l_stat = 2 if Q22_5>0 & Q26==. //looked for work and not inactive
replace l_stat = 3 if Q26!=. //reporting a reason for being inactive/<6m (incl. HH work) 

*education
gen literate = (Q13==1) if (Q13!=9 & Q13!=.)
ren Q15_1 educ_og
gen educ_stat = (educ_og>10 & educ_og<16) if educ_og!=.
gen educ_cat_og = .

**HH relation & co-residence status
gen hh_rel = 0 if Q03==1
replace hh_rel = 1 if Q03==2
replace hh_rel = 2 if Q03==3 & female==0 //Son/Daughter-in-law
replace hh_rel = 2 if Q03==4 & female==1 //Daughter/Son-in-law
replace hh_rel = 3 if Q03==5
gen child_coresident = (hh_rel==2)

parent_merge

foreach var in child father mother {
	gen 	`var'_educ = `var'_educ_og  if inrange(`var'_educ_og, 1, 12)
	replace `var'_educ = 14 if inlist(`var'_educ_og, 13) //Bachelor degree or equivalent
	replace `var'_educ = 16 if inlist(`var'_educ_og, 14, 15) //Master OR PhD
	replace `var'_educ = . if (`var'_educ_og==90|`var'_educ_og==99) //other + not stated
	replace `var'_educ = 0 if (`var'_educ_og==92|`var'_educ_og==91) //illiterate + Non-formal education 
	replace `var'_educ = 0 if `var'_educ_og==0 
	replace `var'_educ = 0 if `var'_literate==0 & `var'_educ_og==.
	replace `var'_educ = 1 if `var'_literate==1 & `var'_educ_og==.
}

tostring hh_id, replace 
keep $var_main $var_cores $var_indiv $var_outcome urban* demo* religion* language* disability* l_stat
compress
save "$interim/nphc_2011.dta", replace

********************************************************************************
********************************************************************************
**#3.0 Combine datasets + adjust variables
********************************************************************************
********************************************************************************
use "$interim/nlss_2022.dta", clear
append using "$interim/nlss_2010.dta"
append using "$interim/nlss_2003.dta"
append using "$interim/nlss_1995.dta"
append using "$interim/nphc_2011.dta"

*adjust emp_stat for WB definition
gen 	emp_stat = .
replace emp_stat = 1 if (child_emp_stat==1|child_emp_stat==2)	&survey=="NLSS" //wage employment non-/agri
replace emp_stat = 4 if (child_emp_stat==3|child_emp_stat==4)	&survey=="NLSS" //self-employment non-/agri
replace emp_stat = 1 if (child_emp_stat==1) 					&survey=="NPHC" //paid employee
replace emp_stat = 2 if (child_emp_stat==2) 					&survey=="NPHC" //contributing family worker
replace emp_stat = 3 if (child_emp_stat==3) 					&survey=="NPHC" //employer
replace emp_stat = 4 if (child_emp_stat==4)						&survey=="NPHC" //self-employed

*re: NLSS splits wage/self-employment by non/-agri 
*re: NPHC has full 4 cat WB definition but no split by agri 
lab def emp_stat 1 "paid employee" 4 "self-employed"
lab val emp_stat emp_stat
drop empstat lstatus
ren (emp_stat l_stat) (empstat lstatus)

*re: defintion of self-employment/sector differs 2022 from previous  
*e.g., self-emp in agri  1.9 (Table 13.15 nlss-iv.pdf) vs 61.3 (Box 12.1: Indicators on employment status, 1995/96 – 2010/11 Statistical_Report_Vol2.pdf)
replace empstat = . if year==2022

*re: defintion of LFP differs 2022 from previous  
*e.g., LFP 37.1 UE 12.6 (p.213 nlss-iv.pdf) vs LFP 80 UE 2 (p50 Statistical_Report_Vol2.pdf)
*=> exclude from cohort analysis but not cross-section

*adjust child_id to be unique 
replace child_id = string(year) + child_id

********************************************************************************
********************************************************************************
**##3.1 adjust demography 
********************************************************************************
********************************************************************************
**(Wikipedia mapping)
*prepare 1995/2003 (limited granularity) for mapping 
replace demo_full = demo_harm if year==1995
replace demo_full = 15 if (year==2003|year==1995) & demo_harm==14
replace demo_full = 999 if (year==2003|year==1995) & demo_harm==15
*apply mapping
merge m:1 demo_full using "$raw/auxiliary/demo/NPL_demo.dta", keepusing(demo_extd) keep(master match)
encode(demo_extd), gen(demo_group_raw) label(demo_group_raw)
levelsof demo_group_raw, local(n_d)
foreach i of local n_d {
	di `i'
	sum child_educ if demo_group_raw==`i'
}
gen demo_group = demo_group_raw
*Khas (Dalit) and  Madhesi (Dalit) belong both to lowest class  (5.52 vs. 5.85)
replace demo_group = 3 if demo_group_raw==4 
*Madhesi (low) and Madhesi (middle) exhibt similar mean education (3.66 vs. 3.93)
replace demo_group = 6 if demo_group_raw==7 
*Maithil Brahmin (High) are considered part of Madhesh people (https://en.wikipedia.org/wiki/Madhesh_Province)
*+ exhibit similar mean education as Madhesi (High), i.e. 8.94 vs. 8.57
replace demo_group = 5 if demo_group_raw==8 
*Tibetans are most strongly disfavored (4.66) followed by Dalit (5.62) but too marginal (0.3%)
replace demo_group = 3 if demo_group_raw==12 
*Royal people are somehow similar to Others (7.11 vs. 3.5) and cannot be attributed somewhere else
replace demo_group = 7 if (demo_group_raw==10|demo_group_raw==11)
*recode Muslim for beauty 
replace demo_group = 4 if demo_group_raw==9
lab def demo_group ///
	1 "Janajati" ///
	2 "Khas" ///
	3 "Dalit (Khas + Madhesi) + Tibetans" ///
	4 "Muslim" ///
	5 "Madhesi (High) + Maithil Brahmin (High)" /// => only in census
	6 "Madhesi (Low + Middle)" /// => to dalit 
	7 "Others" 
lab val demo_group demo_group
*limit Wikipedia mapping for COMPARABILITY 
ren demo_lim demo_2022
gen demo_lim = 1 if demo_group==1
replace demo_lim = 2 if demo_group==2
replace demo_lim = 3 if demo_group==4
replace demo_lim = 4 if (demo_group==3|demo_group==5|demo_group==6|demo_group==7)
replace demo_lim = demo_2022 if demo_lim==.
lab def demo_lim ///
	1 "Janajati" ///
	2 "Khas" ///
	3 "Muslim" ///
	4 "Others" 
lab val demo_lim demo_lim
ren demo_lim demo

*aggregate small groups in language + religion 
gen religion = religion_og
replace religion = 4 if (religion_og>3) //>1.000 respondents (4%) => for 1995 only 4 categories
gen language = language_og
replace language = 6 if language_og==4 //Tharu (Dagaura/Rana) missing category in 1995
replace language = 4 if language_og==5 //Tamang
replace language = 5 if language_og==6 //Newar
replace language = 6 if language_og>6 //>1.000 respondents (4%)
lab def l_religion ///
	1 "Hindu" ///
	2 "Bouddha" ///
	3 "Islam" ///
	4 "Others"
lab def l_language ///
	1 "Nepali" ///
	2 "Maithili" ///
	3 "Bhojpuri" ///
	4 "Tamang" ///
	5 "Newar" ///
	6 "Others"
lab val religion l_religion
lab val language l_language

********************************************************************************
********************************************************************************
**##3.2 adjust geo-level 
********************************************************************************
********************************************************************************
*re: The country is divided into 75 administrative districts. 
* These 75 districts are grouped into three ecological belts running from north to south: the mountains, the hills and the Tarai. 
* Each ecological belt is further divided into five development regions – eastern, central, western, mid-western and farwestern region. 
* Thus 15 eco-development regions (or inter-regions) are formed by the crosscombination of three ecological belts and five development regions 
* (source: Statitistical_Report_vol1.pdf - NLSS 2003)
*=> geo_level_1 =  ecological belts with split of hill into urban/rural
*=> geo_level_2 =  development regions (1-5)
*=> geo_level_3 =  districts

**add province mapping (alternative geo_level_2)
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_district_province_mapping.dta", nogen 
*adjust Manang (Province of Gandaki; see https://en.wikipedia.org/wiki/Manang_District,_Nepal)
replace geo_level_2_adj = 4 if geo_level_3==41
*replace old geo_level 1+2 by province & districts 
replace geo_level_2_adj = geo_level_2 if year==2022
drop geo_level_2 //geo_level_1
ren geo_level_2_adj geo_level_1 //provinces
lab def geo_level_2 ///
	1 "Koshi" ///
	2 "Madhesh" ///
	3 "Bāgmatī" ///
	4 "Gandaki" ///
	5 "Lumbini" ///
	6 "Karnali" ///
	7 "Sudūr Pashchim"
lab val geo_level_1 geo_level_2
ren geo_level_3 geo_level_2 //districts

**add province mapping for birth district to generate migration
ren geo_level_3_birth geo_level_3
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_district_province_mapping.dta", nogen 
ren geo_level_2_adj geo_level_1_birth
ren geo_level_3 geo_level_2_birth
gen migration_urban = (urban!=urban_birth) if (urban_birth!=.&urban!=.)
gen migration_geo_level_1 = (geo_level_1!=geo_level_1_birth) if (geo_level_1_birth!=.&geo_level_1!=.)
gen migration_geo_level_2 = (geo_level_2!=geo_level_2_birth) if (geo_level_2_birth!=.&geo_level_2!=.)

**add region mapping
ren geo_level_2 geo_level_3
ren geo_level_1 geo_level_2
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_district_region_mapping.dta", nogen
lab var geo_level_1 "Region" //5
lab var geo_level_2 "Province" //7
lab var geo_level_3 "District" //75 of which 74 are present in sample
	
drop *_og
compress
save "$clean/HHS_NPL_dataset.dta", replace