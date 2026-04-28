/******************************************************************************\
#title: "1.3_HHS_BTN_dataset"
#author: "Fabian Reutzel"
#structure: 1. BLSS 2022 2017 2012 2007 2003 (raw + SARMD) 
			   + BLFS 2022 for employment (SARLAB)
			2. Combine datasets + adjust variables
\******************************************************************************/

********************************************************************************
**#1. BLSS 2022 2017 2012 2007 2003 + BLFS 2022 for employment
********************************************************************************
foreach year in 2022_2 2022 2017 2012 2007 2003 {
	*load data
	if "`year'"=="2022_2" {
		use "$raw/HHS/BTN/SARLAB/BTN_2022_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
	}
	if "`year'"=="2022" {
		use "$raw/HHS/BTN/SARMD/BTN_2022_BLSS_v01_M_v02_A_SARMD_COR.dta", clear
		merge 1:1 hhid pid using "$raw/HHS/BTN/BLSS/2022/BTN_2022_BLSS_v01_M.dta"
	}
	if "`year'"=="2017"{
		use "$raw/HHS/BTN/BLSS/2017/block1_demography_educ_puf.dta", clear
		merge 1:1 houseid slno using "$raw/HHS/BTN/BLSS/2017/block1_employment_puf.dta"
	}
	if "`year'"=="2012" use "$raw/HHS/BTN/BLSS/2012/block1.dta", clear
	if "`year'"=="2007" use "$raw/HHS/BTN/BLSS/2007/block1.dta", clear
	if "`year'"=="2003"{
		import spss using "$raw/HHS/BTN/BLSS/2003/Weight.sav", case(lower) clear
		save "$interim/blss_2003_weights.dta", replace
		import spss using "$raw/HHS/BTN/BLSS/2003/Block2_edited.sav", case(lower) clear
		merge m:1 stratum dzongkha town block using "$interim/blss_2003_weights.dta"
	}
	
	*generate country/survey/year
	gen country = "Bhutan"
	if "`year'"!="2022_2" {
		gen survey = "BLSS"
		gen survey_name = "Bhutan Living Standards Survey"
	}
	if "`year'"=="2022_2" {
		gen survey = "BLFS"
		gen survey_name = "Bhutan Labor Force Survey"
	}
	if "`year'"!="2022"&"`year'"!="2022_2" gen year = `year'
	gen coresident = "yes"
	if "`year'"=="2003" replace coresident = "no"

	*adjust geo variables
	if "`year'"=="2022_2" {
		ren pid member_id
		gen geo_level_1 = real(substr(subnatid1, 1, 2))
		ren subnatid2 geo_level_2
	}
	if "`year'"=="2022" {
		ren pid member_id
		gen dzongkha = real(substr(subnatid, 1, 2))
		ren subnatid2 geo_level_2
	}
	if ("`year'"=="2017"|"`year'"=="2012") {
		ren slno member_id
		ren hh1 geo_level_1
		ren hh2 geo_level_2
	}
	if "`year'"=="2007" {
		ren slnp member_id
		ren dcode geo_level_1
		ren tgcode geo_level_2
	}
	if ("`year'"=="2012"|"`year'"=="2007") replace geo_level_1 = geo_level_1 - 10 //adjust coding in line with 2017
	if "`year'"=="2003" gen geo_level_2 = block
	*adjust coding in line with 2007/2012/2017
	if "`year'"=="2003"|"`year'"=="2022"{
		gen geo_level_1 = 1 if dzongkha==21 // Bumthang
		replace geo_level_1 = 2  if dzongkha==11 //Chukha
		replace geo_level_1 = 3  if dzongkha==44 //Dagana
		replace geo_level_1 = 4  if dzongkha==16 //Gasa
		replace geo_level_1 = 5  if dzongkha==12 //Haa
		replace geo_level_1 = 6  if dzongkha==31 //Lhuntse
		replace geo_level_1 = 7  if dzongkha==32 //Mongar
		replace geo_level_1 = 8  if dzongkha==13 //Paro
		replace geo_level_1 = 9  if dzongkha==35 //Pema Gatshel
		replace geo_level_1 = 10  if dzongkha==15 //Punakha
		replace geo_level_1 = 11  if dzongkha==36 //Samdrup Jongkhar
		replace geo_level_1 = 12  if dzongkha==41 //Samtse
		replace geo_level_1 = 13  if dzongkha==42 //Sarpang
		replace geo_level_1 = 14  if dzongkha==14 //	
		replace geo_level_1 = 15  if dzongkha==33 //Trashigang
		replace geo_level_1 = 16  if dzongkha==34 //Trashi Yangtse
		replace geo_level_1 = 17  if dzongkha==22 //Trongsa
		replace geo_level_1 = 18  if dzongkha==43 //Tsirang
		replace geo_level_1 = 19  if dzongkha==17 //Wangdue Phodrang
		replace geo_level_1 = 20  if dzongkha==23 //Zhemgang
	}
	
	if "`year'"=="2003"|"`year'"=="2007" gen psu = string(geo_level_1) + string(geo_level_2) 

	*adjust to SARMD IDs
	if "`year'"=="2022_2" {
		ren hhid idh
		gen idp = idh + "-" + string(member_id)
	}
	if "`year'"=="2022" {
		destring member_id, replace
		ren hhid idh
		gen idp = idh + "-" + string(member_id)
	}
	if "`year'"=="2017"{ 
		ren houseid idh
		gen idp = idh + "-" + string(member_id)
		*drop idh 
		*gen idh = substr(idp, 1, 32)
	}
	if "`year'"=="2012" {
		gen slno = string(member_id) 
		gen double idh=houseid
		format idh %12.0f
		tostring idh, replace
		egen idp = concat(idh slno)
	}
	if "`year'"=="2007"{
		gen double idh=houseid
		tostring idh, replace
		gen str8 HID_str = string(houseid,"%08.0f")
		gen str2 pno= string(member_id,"%02.0f") 
		gen str15 indiv=HID_str+pno
		destring indiv, generate(idp)
		format idp %15.0f
		tostring idp, replace
	}
	if "`year'"=="2003"{
		gen stratum_	= string(stratum,"%02.0f")
		gen dzongkha_	= string(dzongkha,"%02.0f")
		gen town_		= string(town,"%02.0f")
		gen block_		= string(block,"%02.0f")
		replace block_	="00" if block==.
		gen houseno_	= string(houseno,"%02.0f")
		egen houseid_str=concat(stratum_ dzongkha_ town_ block_ houseno_)
		destring houseid_str , generate(idh)
		format idh %10.0f
		tostring idh, replace
		gen ind_str	= string(idno,"%02.0f")
		egen idp	= concat(idh ind_str)
		ren idno member_id
	}
	*HH & child ic
	gen hh_id = idh
	gen child_id = hh_id + string(member_id)
		
	*rename weights
	if "`year'"=="2022" ren weight_h wt_hh
	if "`year'"=="2017" ren weights wt_hh
	if "`year'"!="2017"&"`year'"!="2022" ren weight wt_hh

	*other variables
	if "`year'"=="2022"|"`year'"=="2022_2" gen female = (male==0)
	if "`year'"=="2017"|"`year'"=="2012" {
		gen female = (d1==2)
		gen urban = (area==1) if area!=.
	}
	if "`year'"=="2007" {
		ren b11q3 age
		gen female = (b11q1==2)
		gen urban = (area==1) if area!=.
	}
	if "`year'"=="2003" {
		ren b21_q3ag age
		gen female = (b21_q1==2)
		gen urban = (stratum==1) if stratum!=.
	}
	*re: no info on religion & demo 

	*employment
	if "`year'"=="2022_2"{
		*re: paid employee consistent with previous BLSS BUT NOT distinction self-employed/non-paid
		ren empstat emp_stat_og
		gen emp_salary = (emp_stat_og==1) if emp_stat_og!=.
		gen emp_stat =		1 if emp_stat_og==1 				//paid employee
		replace emp_stat = 	2 if emp_stat_og==4 				//self-employed
		replace emp_stat = 	3 if emp_stat_og==3 				//employer
		replace emp_stat = 	4 if emp_stat_og==2 				//unpaid employee
	}
	if "`year'"=="2022" gen emp_stat = empstat //no question
	*re:2007/2012/2017 exact same question; 2003 similar 
	if "`year'"=="2017"{
		ren e7 emp_stat_og
		gen emp_salary = (emp_stat_og==1) if emp_stat_og!=.
		gen emp_stat =		1 if emp_stat_og==1|emp_stat_og==2 	//regular + causal paid
		replace emp_stat = 	2 if emp_stat_og==4 				//self-employed
		replace emp_stat = 	3 if emp_stat_og==3 				//employer
		replace emp_stat = 	4 if emp_stat_og==5 				//unpaid family worker
		replace emp_stat = 	5 if emp_stat_og==6 				//other
	}
	if "`year'"=="2012" ren e6 emp_stat_og
	if "`year'"=="2007" ren b14q43 emp_stat_og
	if "`year'"=="2012"|"`year'"=="2007"{ 
		gen emp_salary = (emp_stat_og==1) if emp_stat_og!=.
		gen emp_stat =		1 if emp_stat_og==1|emp_stat_og==2 	//regular + causal paid
		replace emp_stat = 	2 if emp_stat_og==4 				//self-employed
		replace emp_stat = 	3 if emp_stat_og==5 				//employer
		replace emp_stat = 	4 if emp_stat_og==3 				//unpaid family worker
		replace emp_stat = 	5 if emp_stat_og==6 				//other
	}
	if "`year'"=="2003"{
		ren b24_q38 emp_stat_og
		gen emp_salary = (emp_stat_og==1) if emp_stat_og!=.
		gen emp_stat =		1 if emp_stat_og==1|emp_stat_og==2 	//employee + member of cooperative 
		replace emp_stat = 	2 if emp_stat_og==3 				//self-employed
		replace emp_stat = 	3 if emp_stat_og==4 				//employer
		replace emp_stat = 	4 if emp_stat_og==5 				//family worker 
		replace emp_stat = 	5 if emp_stat_og==7|emp_stat_og==6 	//other + collective farmer
	}
	
	*lm status
	if "`year'"=="2022_2" gen l_stat = lstatus
	if "`year'"=="2022" gen l_stat = lstatus  //no question
	*re: WB code of working based on any type of employment in last 7 yields similar results
	if "`year'"=="2017"{
		ren e10 job_search
		ren e11 available_work
		gen 	l_stat = 1 if job_search==. & emp_stat!=. //not asked whether searching work (work last week to generate income or help family business)
		replace l_stat = 2 if job_search==1|(job_search==0&available_work==1) //searching|ready to start within 2 weeks
		replace l_stat = 3 if job_search==0&available_work!=1 // not searching & not available 	
	}
	if "`year'"=="2012"{
		ren e4 job_search
		ren e5 reason 
	}
	if "`year'"=="2007"{ 
		ren b14q40 job_search
		ren b14q41 reason
	}
	if "`year'"=="2012"|"`year'"=="2007"{ 
		gen 	l_stat = 1 if job_search==. & emp_stat!=. //not asked whether searching work (either agri/paid/unpaid work in last 7 days)
		replace l_stat = 2 if job_search==1|(job_search==2&(reason==2|reason==5)) //waiting for result/previous work recall 
		replace l_stat = 3 if job_search==2&(reason!=2&reason!=5) // not searching
	}	
	if "`year'"=="2003"{
		ren b24_q36 job_search
		ren b24_q37 reason 
		gen 	l_stat = 1 if job_search==. & emp_stat!=. //not asked whether searching work (either agri/paid/unpaid work in last 7 days)
		replace l_stat = 2 if job_search==1|(job_search==2&(reason==1|reason==2)) //searching|Waiting to start job/employers reply
		replace l_stat = 3 if job_search==2&reason!=1&reason!=2 // not searching 
	}

	*agriculture (main variable based on any agri work in last 7 days, i.e., upper bound)
	if "`year'"=="2022_2"{
		gen agri = (industrycat4==1) if industrycat4!=.
	}
	if "`year'"=="2022" gen agri = . // no question
	if "`year'"=="2017"{
		gen agri = (e1==1) if (e1==1|e1==2) 
		gen agri_occu = ((e9>6000 & e9<7000)|(e9>9199 & e9<9300)) if e9!=. & e9>0
		*gen agri_sector = if e6!=. & e6>0 //coding unclear
	}
	if "`year'"=="2012"{
		gen agri = (e1==1) if e1!=. 
		gen agri_occu = ((e7>6000 & e7<7000)|(e7>9199 & e7<9300)) if e7!=. & e7>0 
		gen agri_place = (e8>10 & e8<100) if e8!=. 
	}
	if "`year'"=="2007"{
		gen agri = (b14q37d==1) if b14q37d!=.
		gen agri_occu = (b14q44==61|b14q44==62|b14q44==92) if b14q44!=. & b14q44>0 
		gen agri_sector = (b14q46==4|b14q46==9) if b14q46!=. 
	}
	if "`year'"=="2003"{
		gen agri = (b24_q33w==1) if b24_q33w!=.
		gen agri_occu = ((b24_q39>600 & b24_q39<700)|b24_q39==921) if b24_q39!=.
		gen agri_sector = (b24_q40==1) if b24_q40!=. 
	}

	*education
	if "`year'"=="2022_2" { //only categorical
		gen educ_stat = (educat7!=1) if educat7!=.
		gen literate = literacy
		gen educ_og = .
		replace educ_og = 0 	if educat7==1
		replace educ_og = 4 	if educat7==2 //primary incomplete
		replace educ_og = 7 	if educat7==3
		replace educ_og = 9 	if educat7==4 //secondary incomplete
		replace educ_og = 12 	if educat7==5
		replace educ_og = 13 	if educat7==6
		replace educ_og = 15 	if educat7==7 //university incomplete/complete 14-15
	}
	if "`year'"=="2022" {
		gen educ_stat = (ed2==1|ed2==2) if ed2!=.
		gen literate = (ed1__1==1|ed1__2==1|ed1__3==1|ed1__4==1) if (ed1__1!=.|ed1__2!=.|ed1__3!=.|ed1__4!=.)
		*re: 1:Dzongkha 2:Lotsham 3:English 4:other
		ren ed11 educ_og
		replace educ_og = ed3 if educ_og==. //use current level
		replace educ_og = 0 if educ_stat==0 & educ_og==.
	}
	if "`year'"=="2017" {
		gen educ_stat = (ed2==1|ed2==2) if ed2!=.
		gen literate = (ed1__1==1|ed1__2==1|ed1__3==1|ed1__4==1) if (ed1__1!=.|ed1__2!=.|ed1__3!=.|ed1__4!=.)
		*tab  ed1_4 if ed1_1==0 & ed1_2==0 & ed1_3==0 //1.56% who are only literate in other langauge
		*re: 1:Dzongkha 2:Lotsham 3:English 4:other
		ren ed11 educ_og
		replace educ_og = ed3 if educ_og==. //use current level
		replace educ_og = 0 if educ_stat==0 & educ_og==.
	}
	if "`year'"=="2012"{
		gen educ_stat = (ed2==1|ed2==2) if ed2!=.
		gen literate = (ed1dz==1|ed1lot==1|ed1eng==1|ed1oth==1) if (ed1dz!=.|ed1lot!=.|ed1eng!=.|ed1oth!=.)
		tab ed1oth if ed1dz==0 & ed1lot==0 & ed1eng==0 // no obs who are only literate in other langauge
		ren ed11 educ_og
		replace educ_og = ed3 if educ_og==.
	}
	if "`year'"=="2007"{
		gen educ_stat = (b12q11==1|b12q11==2) if b12q11!=.
		gen literate = (b12q10d==1|b12q10l==1|b12q10e==1|b12q10o==1) if (b12q10d!=.|b12q10l!=.|b12q10e!=.|b12q10o!=.)
		tab b12q10o if b12q10d==0 & b12q10l==0 & b12q10e==0 // no obs who are only literate in other langauge
		ren b12q20 educ_og
		replace educ_og = b12q12 if educ_og==. 
	}
	if "`year'"=="2003"{ 
		gen educ_stat = (b22_q8==1)
		gen literate = (b22_q7dz==1|b22_q7en==1|b22_q7ot==1|b22_q7lo==1)
		ren b22_q16 educ_og
		replace educ_og = b22_q10 if educ_og==.
		*adjust for other training
		ren b22_q17 train
		ren b22_q19 train_years
		replace train_years = 2 if train_years>2
		replace educ_og = 21 if train==1 //academic
		*replace educ_og = 41 if train==2 //professional/vocational
		*replace educ_og = 31 if train==3 //religious
		replace educ_og = educ_og + train_years if train==2 & educ_stat!=0 //professional/vocational
		*topcode additional years to keep university max
		replace educ_og = 14 if educ_og>14 & train==2 & educ_og!=.
	}

	**HH relation 
	if "`year'"=="2022"|"`year'"=="2022_2"{
		ren relationharm hh_rel_og
		gen hh_rel 		= 0 if hh_rel_og==1
		replace hh_rel 	= 1 if hh_rel_og==2
		replace hh_rel 	= 2 if hh_rel_og==3
		replace hh_rel 	= 3 if hh_rel_og==4
	}
	if ("`year'"=="2017"|"`year'"=="2012") ren d2 hh_rel_og
	if "`year'"=="2007" ren b11q2 hh_rel_og
	if "`year'"!="2003"&"`year'"!="2022"&"`year'"!="2022_2"{
		gen hh_rel 		= 0 if hh_rel_og==1
		replace hh_rel 	= 1 if hh_rel_og==2
		replace hh_rel 	= 2 if hh_rel_og==3
		replace hh_rel 	= 3 if hh_rel_og==6
	}
	if "`year'"=="2003"{
	gen hh_rel = 0 if b21_q2==1
	replace hh_rel = 1 if b21_q2==2
	replace hh_rel = 2 if b21_q2==3
	replace hh_rel = 3 if b21_q2==4
	}
	gen child_coresident = (hh_rel==2)
	if "`year'"!="2022"&"`year'"!="2022_2" egen hh_size = max(member_id), by(hh_id) 
	if "`year'"=="2022"|"`year'"=="2022_2" ren  hsize hh_size 

	***parent_merge (manual due to direct parental background question in 2003)
	**save roster dataset
	preserve
	foreach x in emp_* agri* literate educ_stat educ_og {
	ren `x' child_`x'
	} 
	save "$interim/roster.dta", replace
	restore 

	**generate parental dataset
	foreach x in emp_stat agri literate educ_stat educ_og {
		gen mother_`x' = `x' if female==1
		gen father_`x' = `x' if female==0
	}
	gen father_id = hh_rel
	gen mother_id = hh_rel
	keep if inlist(hh_rel, 0, 1, 3, 4)
	duplicates drop hh_id hh_rel female, force //58 obs
	ren female parent_gender
	keep hh_id parent_gender mother_* father_* 
	if "`year'"=="2003" keep hh_id parent_gender mother_id father_id
	save "$interim/parents.dta", replace

	**build dataset
	use "$interim/roster.dta", clear

	*generate parental identfiers 
	gen mother_id = 3 if hh_rel==0
	gen father_id = 3 if hh_rel==0
	replace mother_id = 1 if hh_rel==2
	replace father_id = 0 if hh_rel==2
	tempvar temp
	gen `temp' = (hh_rel==1 & female==1)
	bys hh_id: egen f_head = max(`temp')
	replace mother_id = 0 if hh_rel==3 & f_head==1
	replace father_id = 1 if hh_rel==3 & f_head==1
	drop f_head
	replace mother_id = 4 if hh_rel==4
	replace father_id = 4 if hh_rel==4

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

	*format education variable
	if "`year'"!="2003" local educ_vars "child father mother"
	if "`year'"=="2003" local educ_vars "child"
	foreach var in `educ_vars' {
	  if "`year'"=="2022_2" gen `var'_educ = `var'_educ_og 
	  if "`year'"!="2003"&"`year'"!="2022_2" gen `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 1, 12)
	  if "`year'"=="2003" gen `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 1, 15)

	  if "`year'"=="2022" replace `var'_educ = 13 if (`var'_educ_og==13|`var'_educ_og==14) // Certificates & Diploma to 13y 
	  if "`year'"=="2017" replace `var'_educ = 13 if (`var'_educ_og==13|`var'_educ_og==14|`var'_educ_og==15|`var'_educ_og==16) // VTI & TTI & RTI & Diploma to 13y 
	  if "`year'"=="2012" replace `var'_educ = 13 if (`var'_educ_og==13|`var'_educ_og==14) // VTI & Diploma to 13y
	  if "`year'"=="2007" replace `var'_educ = 13 if `var'_educ_og==13 // Diploma to 13y 
	  
	  if "`year'"=="2022" replace `var'_educ = 14 if `var'_educ_og==15
	  if "`year'"=="2022" replace `var'_educ = 15 if `var'_educ_og==16|`var'_educ_og==17
	  if "`year'"=="2022" replace `var'_educ = 16 if `var'_educ_og==18
	  if "`year'"=="2017" replace `var'_educ = `var'_educ_og - 3 if inrange(`var'_educ_og, 17, 19)
	  if "`year'"=="2012" replace `var'_educ = `var'_educ_og - 1 if inrange(`var'_educ_og, 15, 18)
	  if "`year'"=="2007" replace `var'_educ = `var'_educ_og if inrange(`var'_educ_og, 14, 16)
	  *if "`year'"=="2003" replace `var'_educ = 16 if `var'_educ_og==15 //harmonize topcoding BUT in all other surveys 16 less than 10% of 15+16 

	  if "`year'"=="2022" replace `var'_educ = 0 if `var'_educ_og == 19 // ECCD/day care
	  if "`year'"=="2017" replace `var'_educ = 0 if (`var'_educ_og==20|`var'_educ_og==21) // ECCD/day care
	  if "`year'"=="2012" replace `var'_educ = 0 if `var'_educ_og == 18 // ECCD/day care

	  replace `var'_educ = 0 if `var'_educ_og==0
	  replace `var'_educ = 0 if `var'_educ_og==. & `var'_educ_stat==0
	  replace `var'_educ = 1 if `var'_literate==1 & `var'_educ==.
	}
	
	*parental background question
	if "`year'"=="2003"{ //use only direct background question with literacy or educ_stat
		ren b25_q50f father_educ_og
		ren b25_q50m mother_educ_og
		gen father_agri = (b25_q51f==1) if b25_q51f!=. & b25_q51f!=99
		gen mother_agri = (b25_q51m==1) if b25_q51m!=.  & b25_q51m!=99
		foreach var in father mother {
		  gen `var'_educ = `var'_educ_og + 1 if inrange(`var'_educ_og, 1, 15)
		  replace `var'_educ = 0 if `var'_educ_og==0
		}
	}

	*add HH consumption (SAMRD)
	cap duplicates drop idh idp, force //only 2003 exhibts duplicates 
	if "`year'"!="2022"&"`year'"!="2022_2"{
		if "`year'"=="2003" merge 1:1 idh idp using "$raw/HHS/BTN/SARMD/BTN_2003_BLSS_v01_M_v05_A_SARMD_IND.dta", nogen keep(match) keepusing(welfshprosperity wgt pop_wgt lstatus empstat* psu) force
		if "`year'"=="2007" merge 1:1 idh idp using "$raw/HHS/BTN/SARMD/BTN_2007_BLSS_v01_M_v05_A_SARMD_IND.dta", nogen keep(match) keepusing(welfshprosperity wgt pop_wgt lstatus empstat* psu) force
		if "`year'"=="2012" merge 1:1 idh idp using "$raw/HHS/BTN/SARMD/BTN_2012_BLSS_v01_M_v06_A_SARMD_IND.dta", nogen keep(match) keepusing(welfshprosperity wgt pop_wgt lstatus empstat* psu) force
		if "`year'"=="2017" merge 1:1 idh idp using "$raw/HHS/BTN/SARMD/BTN_2017_BLSS_v01_M_v03_A_SARMD_IND.dta", nogen keep(match) keepusing(welfshprosperity wgt pop_wgt lstatus empstat* psu) force
		*re: 2022 already merged during read-in
		ren wgt wt_hh_wb
		ren pop_wgt wt_pop
	}
	*re: in 2017  1,145 HHids cannot be matched from original data to SAMRD
	if "`year'"=="2022_2" gen hh_cons_month_wb = .
	if "`year'"=="2022" ren welfare hh_cons_month_wb
	if "`year'"!="2022_2"&"`year'"!="2022" ren welfshprosperity hh_cons_month_wb

	if "`year'"=="2012" drop ageclass
	if "`year'"=="2012" ren d3 age

	drop geo_level_2 // not harmonized
	tostring psu, replace 
	
	keep $var_main $var_cores $var_indiv lstatus empstat* urban hh_cons_month* idp idh l_stat *agri*
	save "$interim/blss_`year'.dta", replace
}

********************************************************************************
********************************************************************************
**#2. Combine datasets + adjust variables
********************************************************************************
********************************************************************************
use "$interim/blss_2022.dta", clear
append using "$interim/blss_2022_2.dta" //LFS
append using "$interim/blss_2017.dta"
append using "$interim/blss_2012.dta"
append using "$interim/blss_2007.dta"
append using "$interim/blss_2003.dta"

*adjusting empstat coding 2003
replace empstat = empstat_v2 if year==2003
replace empstat_2 = empstat_2_v2 if year==2003
drop *v2

*adjusting emp_stat coding for WB labels
foreach var in child father mother {
	ren `var'_emp_stat `var'_emp_stat_raw
	gen 	`var'_emp_stat = 1 if `var'_emp_stat_raw==1 //Paid employee
	replace `var'_emp_stat = 2 if `var'_emp_stat_raw==4 //Non-paid employee
	replace `var'_emp_stat = 3 if `var'_emp_stat_raw==3 //employer
	replace `var'_emp_stat = 4 if `var'_emp_stat_raw==2 //self-employed
	replace `var'_emp_stat = 5 if `var'_emp_stat_raw==5 //others
	lab val `var'_emp_stat  lblempstat
	drop `var'_emp_stat_raw
}
*re: non-paid/self-employed distinction varies a lot despite same question

*adjust for type of wage payment regular vs causal
*replace child_emp_stat = 5 if child_emp_salary==0& child_emp_stat==1
*=> working age pop: no recode 32/42/36 vs recode 30/33/30 (2003/2012/2017)

*enlarge agri definition (potentially off-season) => consistent across waves (excl. 2007)
replace child_agri = 1 if child_agri_occu==1

*BUT own coding recovers more obs and jumps are less prononuced => disregard WB
drop empstat lstatus
ren (child_emp_stat l_stat) (empstat lstatus)

*adjust child_id to be unique 
replace child_id = string(year) + child_id

*generate regions based on geo_level_1_zones.png (wikipedia)
ren geo_level_1 geo_level_2
gen geo_level_1 = .
replace geo_level_1 = 	3	if geo_level_2==1	//	Bumthang
replace geo_level_1 = 	1	if geo_level_2==2	//	Chukha
replace geo_level_1 = 	2	if geo_level_2==3	//	Dagana
replace geo_level_1 = 	2	if geo_level_2==4	//	Gasa
replace geo_level_1 = 	1	if geo_level_2==5	//	Haa
replace geo_level_1 = 	4	if geo_level_2==6	//	Lhuntse
replace geo_level_1 = 	4	if geo_level_2==7	//	Mongar
replace geo_level_1 = 	1	if geo_level_2==8	//	Paro
replace geo_level_1 = 	4	if geo_level_2==9	//	Pema Gatshel
replace geo_level_1 = 	2	if geo_level_2==10	//	Punakha
replace geo_level_1 = 	4	if geo_level_2==11	//	Samdrup Jongkhar
replace geo_level_1 = 	1	if geo_level_2==12	//	Samtse
replace geo_level_1 = 	3	if geo_level_2==13	//	Sarpang
replace geo_level_1 = 	1	if geo_level_2==14	//	Thimphu
replace geo_level_1 = 	4	if geo_level_2==15	//	Trashigang
replace geo_level_1 = 	4	if geo_level_2==16	//	Trashi Yangtse
replace geo_level_1 = 	3	if geo_level_2==17	//	Trongsa
replace geo_level_1 = 	2	if geo_level_2==18	//	Tsirang
replace geo_level_1 = 	2	if geo_level_2==19	//	Wangdue Phodrang
replace geo_level_1 = 	3	if geo_level_2==20	//	Zhemgang
lab def geo_level_1 ///
	1 "West" ///
	2 "West-Central" ///
	3 "East-Central " ///
	4 "East"
lab val geo_level_1 geo_level_1
*re: oversampling of Thimphu varies across waves (less severe in 2022)

lab var geo_level_1 "Region" //4
lab var geo_level_2 "District" //20

replace psu = "." if year==2022
destring psu, replace 
drop *_og
compress
save "$clean/HHS_BHT_dataset.dta", replace