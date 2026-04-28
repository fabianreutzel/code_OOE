/******************************************************************************\
#title: "1.10_LFS_raw"
#author: "Lynn Hu & Fabian Reutzel"
*re: Pakistan omitted due to missing language variable in LFS datasets
\******************************************************************************/
********************************************************************************
**#1. BGD (GLD)
********************************************************************************
********************************************************************************
**##1.1 recover demo variable from raw data 
********************************************************************************
//2005
use "$raw/LFS/BGD/LFS/2005/BGD_2005_LFS_V01_M/LFS05_06_Final.dta", clear
drop hhid
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%03.0f")
egen hhid = concat(psu_str hh_str)
gen lineno_str = string(line_no, "%02.0f")
egen pid = concat(hhid lineno_str)
ren relg religion
keep pid religion
gen year = 2005
save "$interim/BGD_demographics_2005.dta", replace

//2010
use "$raw/LFS/BGD/LFS/2010/BGD_2010_LFS_V01_M/LFS_2010_Final.dta", clear
gen psu_str = string(psu_no, "%04.0f")
gen hh_str = string(hhno, "%03.0f")
egen hhid = concat(psu_str hh_str)
gen lineno_str = string(lineno, "%02.0f")
egen pid = concat(hhid lineno_str)
ren s3_5 religion
keep pid religion
gen year = 2010
save "$interim/BGD_demographics_2010.dta", replace

//2013
use "$raw/LFS/BGD/LFS/2013/BGD_2013_LFS_V01_M/LFS 2013 Microdata.dta", clear
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%04.0f")
egen hhid = concat(psu_str hh_str)
gen lineno_str = string(line, "%02.0f")
egen pid = concat(hhid lineno_str)
ren q22 religion
keep pid religion
gen year = 2013
save "$interim/BGD_demographics_2013.dta", replace

//2015
use "$raw/LFS/BGD/QLFS/2015/BGD_2015_QLFS_V01_M/Annual QLF2015-16 Final.dta", clear
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%04.0f")
egen hhid = concat(psu_str hh_str)
gen lineno_str = string(ln, "%02.0f")
egen pid = concat(hhid lineno_str)
ren q19 religion
keep pid religion
gen year = 2015
save "$interim/BGD_demographics_2015.dta", replace

//2016
use "$raw/LFS/BGD/QLFS/2016/BGD_2016_QLFS_V01_M/Bangladesh QLFS 2016-17 Microdata.dta", clear
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%04.0f")
gen qtr_str = string(qtr, "%02.0f")
keep if qtr_str == "01" //keep Q1 only
egen hhid = concat(psu_str hh_str)
gen lineno_str = string(ln, "%02.0f")
egen pid = concat(hhid qtr_str lineno_str)
ren q19 religion
keep pid religion
gen year = 2016
save "$interim/BGD_demographics_2016.dta", replace

//2022
use "$raw/LFS/BGD/QLFS/2022/BGD_LFS_2022_all.dta", clear
gen psu_str = string(PSU, "%04.0f")
gen eaum_str  = string(EAUM, "%03.0f")
gen hh_str  = string(HHNO, "%03.0f")
egen hhid = concat(psu_str eaum_str hh_str)
gen lineno_str = string(EMP_HRLN, "%02.0f")
gen mgt_str  = string(MGT_LN, "%03.0f")
gen mlab = "m"
egen mgt_ln = concat(mgt_str mlab)
replace lineno_str = mgt_ln if missing(EMP_HRLN)
egen pid = concat(hhid lineno_str)
keep if qtr == 1 //keep Q1 only
drop mgt_str mlab mgt_ln
keep pid religion
gen year = 2022
save "$interim/BGD_demographics_2022.dta", replace
*re: keep all QLFS duplicate pid for merging purposes 

*append survey years
clear
foreach y in 2005 2010 2013 2015 2016 2022 {
	append using "$interim/BGD_demographics_`y'.dta", force
}
gen demo = religion == 1 if religion != .
keep year pid demo
bys year pid: keep if _n == 1 //keep only first obs for 2022
save "$interim/BGD_demographics.dta", replace

********************************************************************************
**##1.2 append GLD files
********************************************************************************
local m = 1
foreach n in 2005 2010 2013 {
	if "$GLD_local" == "no" use "$GLD_WB/BGD/BGD_`n'_LFS/BGD_`n'_LFS_V01_M_V01_A_GLD/Data/Harmonized/BGD_`n'_LFS_V01_M_V01_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/BGD/GLD/BGD_`n'_LFS_V01_M_V01_A_GLD_ALL.dta", replace
	tostring subnatid1 subnatid2 subnatidsurvey, replace
	isid pid
	tempfile bgd_`m'
	save `bgd_`m''
local ++m
}

//for quarterly LFS, use Q1 only (i.e., no need to adjust for weights)
if "$GLD_local" == "no" use "$GLD_WB/BGD/BGD_2016_QLFS/BGD_2016_QLFS_V02_M_V01_A_GLD/Data/Harmonized/BGD_2016_QLFS_V02_M_V01_A_GLD_ALL.dta", clear
if "$GLD_local" == "yes" use "$raw/LFS/BGD/GLD/BGD_2016_QLFS_V02_M_V01_A_GLD_ALL.dta", replace
tostring subnatid1 subnatidsurvey, replace
keep if wave == 1
isid pid
tempfile bgd_4
save `bgd_4'
merge 1:1 pid using "$interim/BGD_demographics_2016.dta"

//GLD still preparing BGD 2015 data, use the preliminary version with "wave" to filter Q1
use "$raw/LFS/BGD/GLD/BGD_2015_QLFS_V02_M_V01_A_GLD_ALL.dta", clear
tostring subnatid1 subnatidsurvey, replace
keep if wave == 1
isid pid
tempfile bgd_5
save `bgd_5'

//GLD doesn't have BGD 2022 data so we use SARLAB 2022 BGD data
use "$raw/LFS/BGD/GLD/BGD_2022_QLFS_v01_M_v01_A_SARLD_Q1.dta", clear
gen survey = "LFS"
isid pid
tempfile bgd_6
save `bgd_6'
*merge 1:1 pid using "$interim/BGD_demographics_2022.dta"

clear
append using `bgd_1'  `bgd_2' `bgd_3' `bgd_4' `bgd_5' `bgd_6', force

//harmonize state IDs for BGD
gen 	subnatid1_new = subnatid1 
gen 	subnatid1_merge = subnatid1 
replace subnatid1_new = "Barishal" if subnatid1_new == "10 - Barisal" & countrycode == "BGD"
replace subnatid1_new = "Chattogram" if subnatid1_new == "20 - Chittagong" & countrycode == "BGD"
replace subnatid1_new = "Dhaka" if subnatid1_new == "30 - Dhaka" & countrycode == "BGD"
replace subnatid1_new = "Khulna" if subnatid1_new == "40 - Khulna" & countrycode == "BGD"
replace subnatid1_new = "Rajshahi" if subnatid1_new == "50 - Rajshahi" & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if subnatid1_new == "55 - Rangpur" & countrycode == "BGD"
replace subnatid1_new = "Sylhet" if subnatid1_new == "60 - Sylhet" & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"27 - 27. Dinajpur", "27 - Dinajpur") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"49 - 49. Kurigram", "49 - Kurigram") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"32 - 32. Gaibandha", "32 - Gaibandha") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"52 - 52. Lalmonirhat", "52 - Lalmonirhat") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"73 - 73. Nilphamari", "73 - Nilphamari") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"77 - 77. Panchagarh", "77 - Panchagarh") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"85 - 85. Rangpur", "85 - Rangpur") & countrycode == "BGD"
replace subnatid1_new = "Rangpur" if inlist(subnatid2,"94 - 94. Thakurgaon", "94 - Thakurgaon") & countrycode == "BGD"
replace subnatid1_new = "Dhaka" if subnatid1_new == "45 - Mymensingh" & countrycode == "BGD" //putting small division back to Dhaka
replace subnatid1_merge = subnatid1_new if countrycode == "BGD"
//merge newly separated states back to the older region
replace subnatid1_merge = "Rajshahi" if inlist(subnatid1_new,"Rangpur") & countrycode == "BGD"

save "$interim/GLD_BGD.dta", replace

********************************************************************************
**##1.3 merge GLD with demographics
********************************************************************************
use "$interim/GLD_BGD.dta", clear
merge 1:1 year pid using "$interim/BGD_demographics.dta", keep(match) nogen

*outcomes
gen work_age = (age >= 15 & age <= 64)
keep if work_age == 1 & lstatus!=.
gen lfp = (lstatus == 1|lstatus == 2) 
gen paidwage = (empstat == 1 & wage_no_compen != .) if lfp == 1
replace paidwage = 1 if (empstat == 1 & wage_nc_week != . & lfp == 1) //different var names for 2022 data!
gen wage_weekly = wage_no_compen if unitwage == 2 & paidwage == 1
replace wage_weekly = wage_no_compen/4 if unitwage == 5 & paidwage == 1
replace wage_weekly = wage_nc_week if wage_weekly == . //different var names for 2022 data!

*deflate wage to 2005
//BGD CPI: 2005 69.2 2010 100 2013 127.2 2015 144.6 2016 152.5 2022 215.9 (https://data.worldbank.org/indicator/FP.CPI.TOTL?locations = BD)
gen wage = wage_weekly if year == 2005
replace wage = wage_weekly/(100/69.2) if year == 2010
replace wage = wage_weekly/(127.2/69.2) if year == 2013
replace wage = wage_weekly/(144.6/69.2) if year == 2015
replace wage = wage_weekly/(152.5/69.2) if year == 2016
replace wage = wage_weekly/(215.9/69.2) if year == 2022

*adjust coding geo_level for harmonization
ren subnatid1_new geo_level_1_og_raw
gen geo_level_1_og = .
replace geo_level_1_og = 10 if geo_level_1_og_raw == "Barishal"
replace geo_level_1_og = 20 if geo_level_1_og_raw == "Chattogram"
replace geo_level_1_og = 30 if geo_level_1_og_raw == "Dhaka"
replace geo_level_1_og = 40 if geo_level_1_og_raw == "Khulna"
replace geo_level_1_og = 50 if geo_level_1_og_raw == "Rajshahi"
replace geo_level_1_og = 55 if geo_level_1_og_raw == "Rangpur"
replace geo_level_1_og = 60 if geo_level_1_og_raw == "Sylhet"
gen geo_level_1 = geo_level_1_og/10
replace geo_level_1 = 6 if geo_level_1_og == 55
replace geo_level_1 = 7 if geo_level_1_og == 60

keep country survey year pid relationharm weight age male geo_level_1 urban demo lfp lstatus empstat paidwage wage educat_orig
save "$clean/LFS_BGD.dta", replace

********************************************************************************
**#2. BHT (SARLAB)
********************************************************************************
use "$raw/LFS/BHT/SARLAB/BTN_2018_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
append using "$raw/LFS/BHT/SARLAB/BTN_2019_LFS_v01_M_v01_A_SARLAB_IND.dta"
append using "$raw/LFS/BHT/SARLAB/BTN_2020_LFS_v01_M_v01_A_SARLAB_IND.dta"
decode occup, gen(occup_str)
drop occup
ren occup_str occup
append using "$raw/LFS/BHT/SARLAB/BTN_2022_LFS_v01_M_v01_A_SARLAB_IND.dta"
gen survey = "LFS"

*adjust id
tostring pid, replace
replace pid = hhid + pid

*adjust geo_level 
gen geo_level_2 = real(substr(subnatid1, 1, 2))
gen geo_level_1 = .
replace geo_level_1 = 	3	if geo_level_2 == 1	//	Bumthang
replace geo_level_1 = 	1	if geo_level_2 == 2	//	Chukha
replace geo_level_1 = 	2	if geo_level_2 == 3	//	Dagana
replace geo_level_1 = 	2	if geo_level_2 == 4	//	Gasa
replace geo_level_1 = 	1	if geo_level_2 == 5	//	Haa
replace geo_level_1 = 	4	if geo_level_2 == 6	//	Lhuntse
replace geo_level_1 = 	4	if geo_level_2 == 7	//	Mongar
replace geo_level_1 = 	1	if geo_level_2 == 8	//	Paro
replace geo_level_1 = 	4	if geo_level_2 == 9	//	Pema Gatshel
replace geo_level_1 = 	2	if geo_level_2 == 10	//	Punakha
replace geo_level_1 = 	4	if geo_level_2 == 11	//	Samdrup Jongkhar
replace geo_level_1 = 	1	if geo_level_2 == 12	//	Samtse
replace geo_level_1 = 	3	if geo_level_2 == 13	//	Sarpang
replace geo_level_1 = 	1	if geo_level_2 == 14	//	Thimphu
replace geo_level_1 = 	4	if geo_level_2 == 15	//	Trashigang
replace geo_level_1 = 	4	if geo_level_2 == 16	//	Trashi Yangtse
replace geo_level_1 = 	3	if geo_level_2 == 17	//	Trongsa
replace geo_level_1 = 	2	if geo_level_2 == 18	//	Tsirang
replace geo_level_1 = 	2	if geo_level_2 == 19	//	Wangdue Phodrang
replace geo_level_1 = 	3	if geo_level_2 == 20	//	Zhemgang

save "$clean/LFS_BTN.dta", replace

********************************************************************************
**#3. IND (GLD)
********************************************************************************
********************************************************************************
**##3.1 recover demo variable from raw data
********************************************************************************
//1983
use "$raw/LFS/IND/EUS/1983/IND_1983_EUS_V01_M/Block-1-3-Household-records.dta", clear
egen hhid = concat(Sector State Region FSU_Slno Hhold_Slno)
ren B3_q5_hh_grup caste
ren B3_q4_relgn religion
keep hhid caste religion
gen year = 1983
save "$interim/IND_demographics_1983.dta", replace

//1987
use "$raw/LFS/IND/EUS/1987/IND_1987_EUS_V01_M/Block-1-3-Household-records.dta", clear
gen hamlet = substr(Vill_Blk_No, -1, 1)
gen psu_helper = FSU_SlNo
egen hhid = concat(psu_helper hamlet Sub_stratum Hhold_No)
drop psu_helper
ren B3_q5_Hgrup caste
ren B3_q4_Relgn religion
replace caste = "9" if caste == "8" | caste == ";"
replace religion = "9" if religion == "8" 
keep hhid caste religion
gen year = 1987
save "$interim/IND_demographics_1987.dta", replace

//1993
use "$raw/LFS/IND/EUS/1993/IND_1993_EUS_V01_M/Block-1-3-Household-records.dta", clear
replace Stage2_Stratum = "2" if Stage2_Stratum == "0"
egen str9 hhid = concat(Vill_Blk_Slno SubRound Stage2_Stratum Hhold_no)
ren B3_q5_sgrup_Cd caste
ren B3_q4_relgn_cd religion
keep hhid caste religion
gen year = 1993
save "$interim/IND_demographics_1993.dta", replace

//1999
use "$raw/LFS/IND/EUS/1999/IND_1999_EUS_V01_M/Block3-sch10--Household-Characteristics-records.dta", clear
egen hhid =  concat(fsu_no Visit_no Seg_no Stg2_stratm Hhhold_Slno)
ren B3_q2 caste
ren B3_q3 religion
replace religion = "9" if religion == "0"
keep hhid caste religion
gen year = 1999
save "$interim/IND_demographics_1999.dta", replace

//2004
use "$raw/LFS/IND/EUS/2004/IND_2004_EUS_V01_M/Block_1_2_and_3_level_01.dta", clear
egen str9 hhid = concat(FSU Hamlet Second_stage_stratum Sample_hhld_no)
ren SOCIAL_GRP caste
ren RELIGION religion
keep hhid caste religion
gen year = 2004
save "$interim/IND_demographics_2004.dta", replace

//2005
use "$raw/LFS/IND/EUS/2005/IND_2005_EUS_V01_M/Block-3-Household-Characteristics-records.dta", clear
egen str9 hhid = concat(FSU Segment stage2stratum Hhhld_SlNo)
ren B3_q5 religion
ren B3_q6 caste
keep hhid caste religion
gen year = 2005
save "$interim/IND_demographics_2005.dta", replace

//2007
use "$raw/LFS/IND/EUS/2007/IND_2007_EUS_V01_M/Block-3-household-characteristics-ecords.dta", clear
egen str9 hhid = concat(FSU sub_block Ss_stratum Sample_hhold_No)
ren B3_q5 religion
ren B3_q6 caste
keep hhid caste religion
gen year = 2007
save "$interim/IND_demographics_2007.dta", replace

//2009
use "$raw/LFS/IND/EUS/2009/IND_2009_EUS_V01_M/Block_3_Household characteristics.dta", clear
egen str9 hhid = concat(FSU_Serial_No Hamlet_Group_Sub_Block_No Second_Stage_Stratum_No Sample_Hhld_No)
ren Social_Group caste
ren Religion religion
replace caste = "9" if caste == "0"
replace religion = "9" if religion == "0"
keep hhid caste religion
gen year = 2009
save "$interim/IND_demographics_2009.dta", replace

//2011
use "$raw/LFS/IND/EUS/2011/IND_2011_EUS_V01_M/Block_3_Household characteristics.dta", clear
egen str9 hhid = concat(FSU_Serial_No Hamlet_Group_Sub_Block_No Second_Stage_Stratum_No Sample_Hhld_No)
ren Social_Group caste
ren Religion religion
keep hhid caste religion
gen year = 2011
save "$interim/IND_demographics_2011.dta", replace

//2017
use "$raw/LFS/IND/PLFS/2017/IND_2017_PLFS_V01_M/IND_2017_PLFS_raw_HH_Stata.dta", clear
destring fsu, replace
gen fsu_repaired = 0
forvalues i = 0/4 {
gen fsu_digit_place`i' = floor(mod(fsu, 10^(`i'+1)) / 10^(`i'))
recode fsu_digit_place`i' (0 = 6) (6 = 8) (8 = 9) (9 = 3) (3 = 0) (1 = 4) (4 = 7) (7 = 2) (2 = 5) (5 = 1)
replace fsu_repaired = fsu_repaired + fsu_digit_place`i' * 10^(`i')
}
replace fsu = fsu_repaired
tostring fsu, replace
gen str1 h_1 = string(sample_sg_b_no,"%01.0f")
gen str1 h_2 = string(ss_stratum,"%01.0f")
gen str2 h_3 = string(hh_num,"%02.0f")
egen hhid = concat(fsu h_1 h_2 h_3)
ren social_group caste
keep hhid caste religion
gen year = 2017
save "$interim/IND_demographics_2017.dta", replace

foreach y in 2018 2019 2020 2021 2022 {
	use "$raw/LFS/IND/PLFS/`y'/IND_`y'_PLFS_V01_M/IND_`y'_PLFS_raw_HH_Stata.dta", clear
	gen str1 h_1 = string(sample_sg_b_no,"%01.0f")
	gen str1 h_2 = string(ss_stratum,"%01.0f")
	gen str2 h_3 = string(hh_num,"%02.0f")
	egen hhid = concat(fsu h_1 h_2 h_3)
	drop h_1 h_2 h_3
	ren social_group caste
	keep hhid caste religion
	gen year = `y'
	save "$interim/IND_demographics_`y'.dta", replace
}

*append survey years
clear
foreach y in 1983 1987 1993 1999 2004 2005 2007 2009 2011 {
	append using "$interim/IND_demographics_`y'.dta"
}
destring caste, replace
destring religion, replace
foreach y in 2017 2018 2019 2020 2021 2022 {
	append using "$interim/IND_demographics_`y'.dta"
}

*generate composite variable
gen 	demo = .
replace demo = 1 if caste == 2 //Scheduled Caste 
replace demo = 2 if caste == 1 //Scheduled Tribe
replace demo = 5 if caste == 3 & inlist(year, 1983, 1987, 1993) //Other Backward Class, different codes for earlier years
replace demo = 3 if caste == 3 & demo != 5 //Other Backward Class  
replace demo = 4 if religion == 2 //Muslims
replace demo = 5 if (caste == 9 & religion != 2) //others (no + other class/tribe)

duplicates drop hhid year religion caste, force
keep year hhid demo
save "$interim/IND_demographics.dta", replace

********************************************************************************
**##3.2 append GLD files
********************************************************************************
local m = 1
foreach n in 1983 2009 2011 {
if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_EUS/IND_`n'_EUS_V01_M_V07_A_GLD/Data/Harmonized/IND_`n'_EUS_V01_M_V07_A_GLD_ALL.dta", clear
if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_EUS_V01_M_V07_A_GLD_ALL.dta.dta", replace
	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 4
foreach n in 1987 1993  {
if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_EUS/IND_`n'_EUS_V01_M_V06_A_GLD/Data/Harmonized/IND_`n'_EUS_V01_M_V06_A_GLD_ALL.dta", clear
if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_EUS_V01_M_V06_A_GLD_ALL.dta", replace
	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 6
foreach n in 2004 2005 2007 {
	if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_EUS/IND_`n'_EUS_V01_M_V05_A_GLD/Data/Harmonized/IND_`n'_EUS_V01_M_V05_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_EUS_V01_M_V05_A_GLD_ALL.dta", replace
	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 9
foreach n in 2020 {
	if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_PLFS/IND_`n'_PLFS_V01_M_V04_A_GLD/Data/Harmonized/IND_`n'_PLFS_V01_M_V04_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_PLFS_V01_M_V04_A_GLD_ALL.dta", replace

	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 10
foreach n in 2021 {
	if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_PLFS/IND_`n'_PLFS_V01_M_V05_A_GLD/Data/Harmonized/IND_`n'_PLFS_V01_M_V05_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_PLFS_V01_M_V05_A_GLD_ALL.dta", replace
	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 11
foreach n in 2017 2018 2019 {
	if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_PLFS/IND_`n'_PLFS_V02_M_V04_A_GLD/Data/Harmonized/IND_`n'_PLFS_V02_M_V04_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_PLFS_V02_M_V04_A_GLD_ALL.dta", replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

local m = 14
foreach n in 2022 {
	if "$GLD_local" == "no" use "$GLD_WB/IND/IND_`n'_PLFS/IND_`n'_PLFS_V01_M_V02_A_GLD/Data/Harmonized/IND_`n'_PLFS_V01_M_V02_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/IND/GLD/IND_`n'_PLFS_V01_M_V02_A_GLD_ALL.dta", replace

	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

//GLD IND 1999 EUS GLD data is incorrect. Constructed the alt_99 dataset using the code Mario shared. 
local m = 15
foreach n in 1999 {
use "$raw/LFS/IND/EUS/1999/IND_1999_EUS_V01_M/alt_99.dta", clear
	tostring subnatid1 subnatidsurvey, replace
	tempfile ind_`m'
	save `ind_`m''
	isid pid
local ++m
}

clear
append using  `ind_1' `ind_2' `ind_3' `ind_4' `ind_5' `ind_6' `ind_7' `ind_8' `ind_9' `ind_10' `ind_11' `ind_12' `ind_13' `ind_14'  `ind_15' , force

//harmonize state IDs for IND
gen subnatid1_new = subnatid1 
gen subnatid1_merge = subnatid1 

replace subnatid1_new = strltrim(subnatid1) if countrycode == "IND"
replace subnatid1_new = usubstr(subnatid1_new, 5, .) if countrycode == "IND"
replace subnatid1_new = strltrim(subnatid1_new) if countrycode == "IND"
replace subnatid1_new = "Andaman and Nicobar Islands" if inlist(subnatid1_new, "A & N Islands", "Andaman & Nicober", "Andaman & Nicobar") & countrycode == "IND"
replace subnatid1_new = "Gujarat" if inlist(subnatid1_new, "Gujrat", "jarat") & countrycode == "IND"
replace subnatid1_new = "Maharashtra" if inlist(subnatid1_new, "Maharashtra", "Maharastra") & countrycode == "IND" 
replace subnatid1_new = "Odisha" if inlist(subnatid1_new, "Orissa") & countrycode == "IND"
replace subnatid1_new = "Puducherry" if inlist(subnatid1_new, "Pondicheri", "Pondicherry") & countrycode == "IND"
replace subnatid1_new = "Lakshadweep" if inlist(subnatid1_new, "Lakshdweep") & countrycode == "IND"
replace subnatid1_new = "Uttarakhand" if inlist(subnatid1_new, "Uttaranchal") & countrycode == "IND"
replace subnatid1_new = "Jammu and Kashmir" if inlist(subnatid1_new, "Jammu & Kashmir") & countrycode == "IND"
//combine the two states that is newly merged into one
replace subnatid1_new = "Dadra and Nagar Haveli and Daman and Diu" if inlist(subnatid1_new, "Dadra & Nagar Haveli", "Daman & Diu", "Dadra & Nagar Haveli and Daman & Diu") & countrycode == "IND" 

replace subnatid1_merge = subnatid1_new if countrycode == "IND"

//merge newly separated states back to the older region
replace subnatid1_merge = "Andhra Pradesh" if inlist(subnatid1_merge, "Telangana") & countrycode == "IND"
replace subnatid1_merge = "Jammu and Kashmir" if inlist(subnatid1_merge, "Ladakh") & countrycode == "IND"
replace subnatid1_merge = "Madhya Pradesh" if inlist(subnatid1_merge, "Chhattisgarh") & countrycode == "IND"
replace subnatid1_merge = "Uttar Pradesh" if inlist(subnatid1_merge, "Uttarakhand") & countrycode == "IND"
replace subnatid1_merge = "Bihar" if inlist(subnatid1_merge, "Jharkhand") & countrycode == "IND"

save "$interim/GLD_IND.dta", replace

********************************************************************************
**##3.2 merge GLD with demographics
********************************************************************************
use "$interim/GLD_IND.dta", clear
merge m:1 year hhid using "$interim/IND_demographics.dta", keep(match) nogen

destring educat_orig, replace
replace lstatus = lstatus_year if year == 1999
gen work_age = (age >= 15 & age <= 64)
keep if work_age == 1 & lstatus != .
gen lfp = (lstatus == 1|lstatus == 2) 
gen paidwage = (empstat == 1 & wage_no_compen != .) if lfp == 1 & year != 1999 //excluding year 1999 since it has no data on wage
gen 	wage_weekly = wage_no_compen if unitwage == 2 & paidwage == 1
replace wage_weekly = wage_no_compen/4 if unitwage == 5 & paidwage == 1
	
*deflate wage to 1987
gen 	wage = wage_weekly if year == 1987
replace wage = wage_weekly/(31.1 /18) if year == 1993
*replace wage = wage_weekly/(52.2 /18) if year == 1999 // no obs
replace wage = wage_weekly/(63.4 /18) if year == 2004
replace wage = wage_weekly/(66   /18) if year == 2005
replace wage = wage_weekly/(74.3 /18) if year == 2007
replace wage = wage_weekly/(89.3 /18) if year == 2009
replace wage = wage_weekly/(108.9/18) if year == 2011
replace wage = wage_weekly/(159.2/18) if year == 2017
replace wage = wage_weekly/(165.5/18) if year == 2018
replace wage = wage_weekly/(171.6/18) if year == 2019
replace wage = wage_weekly/(183  /18) if year == 2020
replace wage = wage_weekly/(192.4/18) if year == 2021
replace wage = wage_weekly/(205.3/18) if year == 2022

ren subnatid1_merge geo_level_2_raw
gen 	geo_level_2 = .
replace geo_level_2 = 1	if geo_level_2_raw == "Jammu and Kashmir"
replace geo_level_2 = 2	if geo_level_2_raw == "Himachal Pradesh"
replace geo_level_2 = 3	if geo_level_2_raw == "Punjab"
replace geo_level_2 = 4	if geo_level_2_raw == "Chandigarh"
replace geo_level_2 = 5	if geo_level_2_raw == "Uttarakhand"
replace geo_level_2 = 6	if geo_level_2_raw == "Haryana"
replace geo_level_2 = 7	if geo_level_2_raw == "Delhi"
replace geo_level_2 = 8	if geo_level_2_raw == "Rajasthan"
replace geo_level_2 = 9	if geo_level_2_raw == "Uttar Pradesh"
replace geo_level_2 = 10	if geo_level_2_raw == "Bihar"
replace geo_level_2 = 11	if geo_level_2_raw == "Sikkim"
replace geo_level_2 = 12	if geo_level_2_raw == "Arunachal Pradesh"
replace geo_level_2 = 13	if geo_level_2_raw == "Nagaland"
replace geo_level_2 = 14	if geo_level_2_raw == "Manipur"
replace geo_level_2 = 15	if geo_level_2_raw == "Mizoram"
replace geo_level_2 = 16	if geo_level_2_raw == "Tripura"
replace geo_level_2 = 17	if geo_level_2_raw == "Meghalaya"
replace geo_level_2 = 18	if geo_level_2_raw == "Assam"
replace geo_level_2 = 19	if geo_level_2_raw == "West Bengal"
replace geo_level_2 = 20	if geo_level_2_raw == "Jharkhand"
replace geo_level_2 = 21	if geo_level_2_raw == "Odisha"
replace geo_level_2 = 22	if geo_level_2_raw == "Chhattisgarh"
replace geo_level_2 = 23	if geo_level_2_raw == "Madhya Pradesh"
replace geo_level_2 = 24	if geo_level_2_raw == "Gujarat"
*replace geo_level_2 = 25	if geo_level_2_raw == "Daman & Diu"
replace geo_level_2 = 26	if geo_level_2_raw == "Dadra and Nagar Haveli and Daman and Diu"
replace geo_level_2 = 27	if geo_level_2_raw == "Maharashtra"
replace geo_level_2 = 28	if geo_level_2_raw == "Andhra Pradesh"
replace geo_level_2 = 29	if geo_level_2_raw == "Karnataka"
replace geo_level_2 = 30	if geo_level_2_raw == "Goa"
replace geo_level_2 = 31	if geo_level_2_raw == "Lakshadweep"
replace geo_level_2 = 32	if geo_level_2_raw == "Kerala"
replace geo_level_2 = 33	if geo_level_2_raw == "Tamil Nadu"
replace geo_level_2 = 34	if geo_level_2_raw == "Puducherry"
replace geo_level_2 = 35	if geo_level_2_raw == "Andaman and Nicobar Islands"

*add geographical regions India (Singh 2012)
gen geo_level_1 = .
replace geo_level_1 = 1 if (geo_level_2 == 1|geo_level_2 == 2|geo_level_2 == 3|geo_level_2 == 5|geo_level_2 == 6|geo_level_2 == 7|geo_level_2 == 8)
replace geo_level_1 = 2 if (geo_level_2 == 4|geo_level_2 == 9|geo_level_2 == 23|geo_level_2 == 22)
replace geo_level_1 = 3 if (geo_level_2 == 10|geo_level_2 == 19|geo_level_2 == 20|geo_level_2 == 21)
replace geo_level_1 = 4 if (geo_level_2 == 12|geo_level_2 == 17|geo_level_2 == 18|geo_level_2 == 14|geo_level_2 == 16|geo_level_2 == 13|geo_level_2 == 11|geo_level_2 == 15)
replace geo_level_1 = 5 if (geo_level_2 == 24|geo_level_2 == 27|geo_level_2 == 30|geo_level_2 == 26)
replace geo_level_1 = 6 if (geo_level_2 == 28|geo_level_2 == 29|geo_level_2 == 32|geo_level_2 == 33|geo_level_2 == 34|geo_level_2 == 35|geo_level_2 == 31)

save "$clean/LFS_IND.dta", replace

********************************************************************************
**#4. NPL 
*re: 1998 2008 fully based on GLD; 2017 based on raw data + wage from GLD
********************************************************************************
********************************************************************************
**##4.1 recover demo variable
********************************************************************************
//1998
use "$raw/LFS/NPL/LFS/1998/NPL_1998_LFS_V01_M/NPL_LFS_1998_raw.dta", clear
tostring hid, gen(hhid) format(%05.0f)
tostring idcode, gen(id_str) format(%02.0f)
egen pid = concat(hhid id_str), punct("-")
gen year = 1998
save "$interim/NPL_demographics_1998.dta", replace

//2008
use "$raw/LFS/NPL/LFS/2008/NPL_2008_LFS_V01_M/NPL_LFS_2008_raw.dta", clear
ren hhid hhid_orig
gen hhid = string(psu,"%02.0f")+string(hhid_orig,"%04.0f")
gen pid = hhid+" - "+string(idcode,"%02.0f")
ren q11 ethnic 
gen year = 2008
save "$interim/NPL_demographics_2008.dta", replace

//2017
use "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/NPL_LFS_2017_raw.dta", clear
tostring hhld, gen(hid) format(%02.0f)
tostring psu, gen(psu_str) format(%04.0f)
egen hhid = concat(psu_str hid)
tostring id, gen(id_str) format(%02.0f)
egen pid = concat(hhid id_str), punct("-")
ren caste ethnic
gen year = 2017
save "$interim/NPL_demographics_2017.dta", replace

*append survey years
clear
foreach y in 1998 2008 2017 {
	append using "$interim/NPL_demographics_`y'.dta", force
}

*recode ethnic groups (compound classification of caste and religion)
gen demo = ""
gen demo_ = ""
replace demo_ = "Khas"					if ethnic == 1 & year == 1998
replace demo_ = "Khas"					if ethnic == 2 & year == 1998
replace demo_ = "Janajati"				if ethnic == 3 & year == 1998
replace demo_ = "Janajati"				if ethnic == 4 & year == 1998
replace demo_ = "Janajati"				if ethnic == 5 & year == 1998
replace demo_ = "Janajati"				if ethnic == 6 & year == 1998
replace demo_ = "Khas (Dalit)"			if ethnic == 7 & year == 1998
replace demo_ = "Madhesi (Middle)"		if ethnic == 8 & year == 1998
replace demo_ = "Muslim"				if ethnic == 9 & year == 1998
replace demo_ = "Janajati"				if ethnic == 10 & year == 1998
replace demo_ = "Janajati"				if ethnic == 11 & year == 1998
replace demo_ = "Khas (Dalit)"			if ethnic == 12 & year == 1998
replace demo_ = "Janajati"				if ethnic == 13 & year == 1998
replace demo_ = "Khas (Dalit)"			if ethnic == 14 & year == 1998
replace demo_ = "Others"				if ethnic == 15 & year == 1998

replace demo_ = "Khas"					if ethnic == 1 & year == 2008
replace demo_ = "Khas"					if ethnic == 2 & year == 2008
replace demo_ = "Janajati"				if ethnic == 3 & year == 2008
replace demo_ = "Janajati"				if ethnic == 4 & year == 2008
replace demo_ = "Janajati"				if ethnic == 5 & year == 2008
replace demo_ = "Janajati"				if ethnic == 6 & year == 2008
replace demo_ = "Muslim"				if ethnic == 7 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 8 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 9 & year == 2008
replace demo_ = "Janajati"				if ethnic == 10 & year == 2008
replace demo_ = "Janajati"				if ethnic == 11 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 12 & year == 2008
replace demo_ = "Janajati"				if ethnic == 13 & year == 2008
replace demo_ = "Royal People"			if ethnic == 14 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 15 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 16 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 17 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 18 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 19 & year == 2008
replace demo_ = "Khas"					if ethnic == 20 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 21 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 22 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 23 & year == 2008
replace demo_ = "Janajati"				if ethnic == 24 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 25 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 26 & year == 2008
replace demo_ = "Maithil Brahmin (High)"	if ethnic == 27 & year == 2008
replace demo_ = "Janajati"				if ethnic == 28 & year == 2008
replace demo_ = "Janajati"				if ethnic == 29 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 30 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 31 & year == 2008
replace demo_ = "Janajati"				if ethnic == 32 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 33 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 34 & year == 2008
replace demo_ = "Janajati"				if ethnic == 35 & year == 2008
replace demo_ = "Janajati"				if ethnic == 36 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 37 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 38 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 39 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 40 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 41 & year == 2008
replace demo_ = "Janajati"				if ethnic == 42 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 43 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 44 & year == 2008
replace demo_ = "Janajati"				if ethnic == 45 & year == 2008
replace demo_ = "Tibetans"				if ethnic == 46 & year == 2008
replace demo_ = "Janajati"				if ethnic == 47 & year == 2008
replace demo_ = "Madhesi (High)"		if ethnic == 48 & year == 2008
replace demo_ = "Madhesi (High)"		if ethnic == 49 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 50 & year == 2008
replace demo_ = "Others"				if ethnic == 51 & year == 2008
replace demo_ = "Janajati"				if ethnic == 52 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 53 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 54 & year == 2008
replace demo_ = "Madhesi (Middle)"		if ethnic == 55 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 56 & year == 2008
replace demo_ = "Janajati"				if ethnic == 57 & year == 2008
replace demo_ = "Madhesi (High)"		if ethnic == 58 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 59 & year == 2008
replace demo_ = "Janajati"				if ethnic == 60 & year == 2008
replace demo_ = "Janajati"				if ethnic == 61 & year == 2008
replace demo_ = "Tibetans"				if ethnic == 62 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 63 & year == 2008
replace demo_ = "Madhesi (High)"		if ethnic == 64 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 65 & year == 2008
replace demo_ = "Janajati"				if ethnic == 66 & year == 2008
replace demo_ = "Janajati"				if ethnic == 67 & year == 2008
replace demo_ = "Janajati"				if ethnic == 68 & year == 2008
replace demo_ = "Janajati"				if ethnic == 69 & year == 2008
replace demo_ = "Janajati"				if ethnic == 70 & year == 2008
replace demo_ = "Janajati"				if ethnic == 71 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 72 & year == 2008
replace demo_ = "Others"				if ethnic == 73 & year == 2008
replace demo_ = "Janajati"				if ethnic == 74 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 75 & year == 2008
replace demo_ = "Janajati"				if ethnic == 77 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 79 & year == 2008
replace demo_ = "Janajati"				if ethnic == 80 & year == 2008
replace demo_ = "Janajati"				if ethnic == 81 & year == 2008
replace demo_ = "Janajati"				if ethnic == 82 & year == 2008
replace demo_ = "Muslim"				if ethnic == 83 & year == 2008
replace demo_ = "Khas (Dalit)"			if ethnic == 84 & year == 2008
replace demo_ = "Janajati"				if ethnic == 85 & year == 2008
replace demo_ = "Janajati"				if ethnic == 86 & year == 2008
replace demo_ = "Madhesi (Dalit)"		if ethnic == 87 & year == 2008
replace demo_ = "Others"				if ethnic == 88 & year == 2008
replace demo_ = "Janajati"				if ethnic == 89 & year == 2008
replace demo_ = "Janajati"				if ethnic == 90 & year == 2008
replace demo_ = "Janajati"				if ethnic == 91 & year == 2008
replace demo_ = "Janajati"				if ethnic == 92 & year == 2008
replace demo_ = "Madhesi (Low)"			if ethnic == 94 & year == 2008
replace demo_ = "Others"				if ethnic == 96 & year == 2008
replace demo_ = "Tibetans"				if ethnic == 99 & year == 2008
replace demo_ = "Janajati"				if ethnic == 100 & year == 2008
replace demo_ = "Others"				if ethnic == 102 & year == 2008
replace demo_ = "Others"				if ethnic == 103 & year == 2008
replace demo_ = "Khas"					if ethnic == 1  & year == 2017
replace demo_ = "Khas"					if ethnic == 2  & year == 2017
replace demo_ = "Janajati"				if ethnic == 3  & year == 2017
replace demo_ = "Janajati"				if ethnic == 4  & year == 2017
replace demo_ = "Janajati"				if ethnic == 5  & year == 2017
replace demo_ = "Janajati"				if ethnic == 6  & year == 2017
replace demo_ = "Muslim"				if ethnic == 7  & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 8  & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 9  & year == 2017
replace demo_ = "Janajati"				if ethnic == 10 & year == 2017
replace demo_ = "Janajati"				if ethnic == 11 & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 12 & year == 2017
replace demo_ = "Janajati"				if ethnic == 13 & year == 2017
replace demo_ = "Royal People"			if ethnic == 14 & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 15 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 16 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 17 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 18 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 19 & year == 2017
replace demo_ = "Khas"					if ethnic == 20 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 21 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 22 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 23 & year == 2017
replace demo_ = "Janajati"				if ethnic == 24 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 25 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 26 & year == 2017
replace demo_ = "Maithil Brahmin (High)" 	if ethnic == 27 & year == 2017
replace demo_ = "Janajati"				if ethnic == 28 & year == 2017
replace demo_ = "Janajati"				if ethnic == 29 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 30 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 31 & year == 2017
replace demo_ = "Janajati"				if ethnic == 32 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 33 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 34 & year == 2017
replace demo_ = "Janajati"				if ethnic == 35 & year == 2017
replace demo_ = "Janajati"				if ethnic == 36 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 37 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 38 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 39 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 40 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 41 & year == 2017
replace demo_ = "Janajati"				if ethnic == 42 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 43 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 44 & year == 2017
replace demo_ = "Janajati"				if ethnic == 45 & year == 2017
replace demo_ = "Tibetans"				if ethnic == 46 & year == 2017
replace demo_ = "Janajati"				if ethnic == 47 & year == 2017
replace demo_ = "Madhesi (High)"		if ethnic == 48 & year == 2017
replace demo_ = "Madhesi (High)"		if ethnic == 49 & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 50 & year == 2017
replace demo_ = "Others"				if ethnic == 51 & year == 2017
replace demo_ = "Janajati"				if ethnic == 52 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 53 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 54 & year == 2017
replace demo_ = "Madhesi (Middle)"		if ethnic == 55 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 56 & year == 2017
replace demo_ = "Janajati"				if ethnic == 57 & year == 2017
replace demo_ = "Madhesi (High)"		if ethnic == 58 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 59 & year == 2017
replace demo_ = "Janajati"				if ethnic == 60 & year == 2017
replace demo_ = "Janajati"				if ethnic == 61 & year == 2017
replace demo_ = "Tibetans"				if ethnic == 62 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 63 & year == 2017
replace demo_ = "Madhesi (High)"		if ethnic == 64 & year == 2017
replace demo_ = "Janajati"				if ethnic == 66 & year == 2017
replace demo_ = "Janajati"				if ethnic == 67 & year == 2017
replace demo_ = "Janajati"				if ethnic == 68 & year == 2017
replace demo_ = "Janajati"				if ethnic == 69 & year == 2017
replace demo_ = "Janajati"				if ethnic == 71 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 72 & year == 2017
replace demo_ = "Others"				if ethnic == 73 & year == 2017
replace demo_ = "Janajati"				if ethnic == 74 & year == 2017
replace demo_ = "Madhesi (Dalit)"		if ethnic == 75 & year == 2017
replace demo_ = "Janajati"				if ethnic == 77 & year == 2017
replace demo_ = "Janajati"				if ethnic == 78 & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 79 & year == 2017
replace demo_ = "Janajati"				if ethnic == 81 & year == 2017
replace demo_ = "Khas (Dalit)"			if ethnic == 83 & year == 2017
replace demo_ = "Janajati"				if ethnic == 85 & year == 2017
replace demo_ = "Others"				if ethnic == 87 & year == 2017
replace demo_ = "Janajati"				if ethnic == 88 & year == 2017
replace demo_ = "Janajati"				if ethnic == 89 & year == 2017
replace demo_ = "Janajati"				if ethnic == 90 & year == 2017
replace demo_ = "Janajati"				if ethnic == 91 & year == 2017
replace demo_ = "Janajati"				if ethnic == 92 & year == 2017
replace demo_ = "Madhesi (Low)"			if ethnic == 93 & year == 2017
replace demo_ = "Janajati"				if ethnic == 96 & year == 2017
replace demo_ = "Others"					if ethnic == 98 & year == 2017
replace demo_ = "Others"					if ethnic == 115 & year == 2017
replace demo_ = "Others"					if ethnic == 117 & year == 2017
replace demo_ = "Others"					if ethnic == 118 & year == 2017
replace demo_ = "Others"					if ethnic == 119 & year == 2017
replace demo_ = "Others"					if ethnic == 120 & year == 2017
replace demo_ = "Others"					if ethnic == 121 & year == 2017
replace demo_ = "Others"					if ethnic == 122 & year == 2017
replace demo_ = "Others"					if ethnic == 128 & year == 2017
replace demo_ = "Others"					if ethnic == 129 & year == 2017
replace demo_ = "Others"					if ethnic == 131 & year == 2017
replace demo_ = "Others"					if ethnic == 136 & year == 2017
replace demo_ = "Others"					if ethnic == 991 & year == 2017
replace demo_ = "Others"					if ethnic == 992 & year == 2017
replace demo_ = "Others"					if ethnic == 993 & year == 2017
replace demo_ = "Others"					if ethnic == 994 & year == 2017
replace demo_ = "Others"					if ethnic == 995 & year == 2017

*limit granualarity
replace demo = "Janajati"				if demo_ == "Janajati"
replace demo = "Khas"					if demo_ == "Khas"
replace demo = "Others"					if demo_ == "Khas (Dalit)"
replace demo = "Others"					if demo_ == "Madhesi (Dalit)"
replace demo = "Others"					if demo_ == "Madhesi (High)"
replace demo = "Others"					if demo_ == "Madhesi (Low)"
replace demo = "Others"					if demo_ == "Madhesi (Middle)"
replace demo = "Others"					if demo_ == "Maithil Brahmin (High)"
replace demo = "Muslim"					if demo_ == "Muslim"
replace demo = "Others"					if demo_ == "Others"
replace demo = "Others"					if demo_ == "Royal People"
replace demo = "Others"					if demo_ == "Tibetans"

keep pid demo year
save "$interim/NPL_demographics.dta", replace

********************************************************************************
**##4.2 append GLD files and merge with demographics
********************************************************************************
local m = 1
foreach n in 1998 2008 {
	if "$GLD_local" == "no" use "$GLD_WB/NPL/NPL_`n'_LFS/NPL_`n'_LFS_V01_M_V01_A_GLD/Data/Harmonized/NPL_`n'_LFS_V01_M_V01_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/NPL/GLD/NPL_`n'_LFS_V01_M_V01_A_GLD_ALL.dta", replace
	tostring subnatid1 subnatid2 subnatidsurvey, replace
	isid pid
	tempfile npl_`m'
	save `npl_`m''
local ++m
}

//adding data file cleaned by the Nepal Statistics Office and Ami Shrestha <ashrestha6@worldbank.org>), in which the %lfp is adjusted. 
local m = 3
use "$raw/LFS/NPL/GLD/NPL_2017_LFS_V01_M_V01_A_GLD_ALL_LH.dta", clear
tostring subnatid1 subnatid2 subnatidsurvey, replace
isid pid
tempfile npl_`m'
save `npl_`m''
//re: empstat is not harmonized! this is based on the "new" definition.

clear
append using `npl_1' `npl_2' `npl_3', force

//harmonize state IDs for NPL
gen subnatid1_new = subnatid1 
gen subnatid1_merge = subnatid1 

replace subnatid1_new = "Koshi" if subnatid2 == "1 - Taplejung"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "10 - Bhojpur"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "11 - Solukhumbu"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "12 - Okhaldhunga"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "13 - Khotang"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "14 - Udayapur"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "15 - Saptari"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "16 - Siraha"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "17 - Dhanusa"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "18 - Mahottari"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "19 - Sarlahi"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "2 - Panchthar"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "20 - Sindhuli"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "21 - Ramechhap"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "22 - Dolakha"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "23 - Sindhupalchok"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "24 - Kavrepalanchok"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "25 - Lalitpur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "26 - Bhaktapur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "27 - Kathmandu"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "28 - Nuwakot"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "29 - Rasuwa"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "3 - Ilam"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "30 - Dhading"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "31 - Makwanpur"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "32 - Rautahat"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "33 - Bara"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "34 - Parsa"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "35 - Chitawan"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "36 - Gorkha"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "37 - Lamjung"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "38 - Tanahu"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "39 - Syangja"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "4 - Jhapa"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "40 - Kaski"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "42 - Mustang"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "43 - Myagdi"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "44 - Parbat"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "45 - Baglung"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "46 - Gulmi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "47 - Palpa"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "48 - Nawalpur"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "49 - Rupandehi"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "5 - Morang"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "50 - Kapilbastu"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "51 - Arghakhanchi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "52 - Pyuthan"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "53 - Rolpa"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "54 - Western Rukum"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "55 - Salyan"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "56 - Dang"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "57 - Banke"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "58 - Bardiya"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "59 - Surkhet"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "6 - Sunsari"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "60 - Dailekh"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "61 - Jajarkot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "62 - Dolpa"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "63 - Jumla"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "64 - Kalikot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "65 - Mugu"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "66 - Humla"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "67 - Bajura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "68 - Bajhang"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "69 - Achham"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "7 - Dhankuta"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "70 - Doti"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "71 - Kailali"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "72 - Kanchanpur"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "73 - Dadeldhura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "74 - Baitadi"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "75 - Darchula"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "76 - Parasi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "77 - Eastern Rukum"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "8 - Terhathum"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "9 - Sankhuwasabha"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 17.Dhanusha"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 18.Mahottari"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 19.Sarlahi"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 20.Sindhuli"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 21.Ramechhap"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 22.Dolakha"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 23.Sindhupalchok"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 24.Kabhrepalanchok"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 25.Lalitpur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 26.Bhaktapur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 27.Kathmandu"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 28.Nuwakot"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 29.Rasuwa"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 30.Dhading"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 31.Makawanpur"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 32.Rautahat"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 33.Bara"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - 34.Parsa"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - 35.Chitwan"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Bara"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Bhaktapur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Chitawan"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Dhading"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Dhanusa"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Dolakha"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Kathmandu"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Kavre"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Lalitpur"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Mahottari"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Makwanpur"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Nuwakot"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Parsa"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Ramechhap"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Rasuwa"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Rautahat"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Central - Sarlahi"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Sindhuli"& countrycode == "NPL"
replace subnatid1_new = "Bagmati" if subnatid2 == "Central - Sindhupalchok"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 1.Taplejung"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 10.Bhojpur"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 11.Solukhumbu"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 12.Okhaldhunga"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 13.Khotang"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 14.Udayapur"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "East - 15.Saptari"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "East - 16.Siraha"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 2.Panchathar"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 3.Ilam"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 4.Jhapa"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 5.Morang"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 6.Sunsari"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 7.Dhankuta"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 8.Terhathum"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "East - 9.Sankhuwasabha"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Bhojpur"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Dhankuta"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Ilam"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Jhapa"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Khotang"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Morang"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Okhaldhunga"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Panchthar"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Sankhuwasabha"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Eastern - Saptari"& countrycode == "NPL"
replace subnatid1_new = "Madhesh" if subnatid2 == "Eastern - Siraha"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Solukhumbu"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Sunsari"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Taplejung"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Terhathum"& countrycode == "NPL"
replace subnatid1_new = "Koshi" if subnatid2 == "Eastern - Udayapur"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 67.Bajura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 68.Bajhang"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 69.Achham"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 70.Doti"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 71.Kailali"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 72.Kanchanpur"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 73.Dadeldhura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 74.Baitadi"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-West - 75.Darchula"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Achham"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Baitadi"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Bajhang"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Bajura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Dadeldhura"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Darchula"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Doti"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Kailali"& countrycode == "NPL"
replace subnatid1_new = "Sudurpashchim" if subnatid2 == "Far-Western - Kanchanpur"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 52.Pyuthan"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 53.Rolpa"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 54.Rukum"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 55.Salyan"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 56.Dang"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 57.Banke"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-West - 58.Bardiya"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 59.Surkhet"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 60.Dailekh"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 61.Jajarkot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 63.Jumla"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 64.Kalikot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 65.Mugu"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-West - 66.Humla"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Banke"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Bardiya"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Dailekh"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Dang"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Humla"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Jajarkot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Jumla"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Kalikot"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Mugu"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Pyuthan"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Rolpa"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Mid-Western - Rukum"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Salyan"& countrycode == "NPL"
replace subnatid1_new = "Karnali" if subnatid2 == "Mid-Western - Surkhet"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 36.Gorkha"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 37.Lamjung"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 38.Tanahu"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 39.Syangja"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 40.Kaski"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 42.Mustang"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 43.Myagdi"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 44.Parbat"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "West - 45.Baglung"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 46.Gulmi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 47.Palpa"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 48.Nawal Parasi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 49.Rupandehi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 50.Kapilbastu"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "West - 51.Arghakhanchi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Arghakhanchi"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Baglung"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Gorkha"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Gulmi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Kapilbastu"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Kaski"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Lamjung"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Mustang"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Myagdi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Nawalparasi"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Palpa"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Parbat"& countrycode == "NPL"
replace subnatid1_new = "Lumbini" if subnatid2 == "Western - Rupandehi"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Syangja"& countrycode == "NPL"
replace subnatid1_new = "Gandaki" if subnatid2 == "Western - Tanahu"& countrycode == "NPL"

replace subnatid1_merge = subnatid1_new

save "$interim/GLD_NPL.dta", replace

*merge with demographics
use "$interim/GLD_NPL.dta", clear
merge 1:1 year pid using "$interim/NPL_demographics.dta", nogen

*outcomes
gen work_age = (age >= 15 & age <= 64)
keep if work_age == 1 & lstatus != .
gen lfp = (lstatus == 1|lstatus == 2)
gen paidwage =  (empstat == 1 & wage_no_compen != .) if lfp == 1
gen wage_weekly = wage_no_compen if unitwage == 2 & paidwage == 1
replace wage_weekly = wage_no_compen/4 if unitwage == 5 & paidwage == 1
replace wage_weekly = wage_no_compen*7 if unitwage == 1 & paidwage == 1 //2017 only

*deflate wage to 1998
gen wage = wage_weekly if year == 1998
replace wage = wage_weekly/(82.3/50.6) if year == 2008
replace wage = wage_weekly/(171.8/50.6) if year == 2017

*demo groups
ren demo demo2
encode demo2, gen (demo)
save "$interim/GLD_NPL_1995_2008_2017.dta", replace

********************************************************************************
**##4.3 NLFS 2017-2018 (raw)
********************************************************************************
********************************************************************************
**###4.3.1 mapping of districts in to provinces formed in 2015
********************************************************************************
use "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S00_rc.dta", clear //header 
merge 1:1 psu hhld using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S01_rc.dta", nogen // HH info
merge 1:m psu hhld using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S02_rc.dta", nogen // roster
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/weights.dta", nogen //weights
drop if dist == 27 & province != 3  //Kathmandu
collapse province, by(dist)
replace province = . if  (dist == 48 | dist == 54)
*re: no clear assignment of 2 districts (Nawalparasi & Rukum)
ren dist geo_level_3
ren province geo_level_2_adj
save "$raw/auxiliary/geo_level/district_province_mapping.dta", replace

********************************************************************************
**###4.3.2 build NLFS 2017-2018 based on raw data
********************************************************************************
use "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S00_rc.dta", clear //header 
merge 1:1 psu hhld using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S01_rc.dta", nogen // HH info
merge 1:m psu hhld using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S02_rc.dta", nogen // roster
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/weights.dta", nogen //weights
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S03_rc.dta", nogen //non-wage activity
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S04_rc.dta", nogen //wage-employment
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S06_rc.dta", nogen //income
merge 1:1 psu personid using "$raw/LFS/NPL/LFS/2017/NPL_2017_LFS_V01_M/S07_rc.dta", nogen //UE

*generate country/survey/year
gen survey = "LFS"
gen country = "Nepal"
gen year = 2017

*ren variables
gen 	hh_id = string(psu) + string(hhld) if hhld >= 10
replace hh_id = string(psu) + "0" + string(hhld) if hhld<10
gen member_id = string(id, "%02.0f")
gen pid = hh_id + "-" + member_id
ren designweight_hh wt_hh
ren wt_prov_ind_year wt_ind
gen female = (sex == 2) if sex != .
ren hhsize hh_size
gen urban = (urbrur753 == 1) if urbrur753 != .
gen 	urban_birth = (birth_urbrur == 1) if birth_urbrur != . //only asked to movers
replace urban_birth = 1 if birth_same == 1 & urban == 1
replace urban_birth = 0 if birth_same == 1 & urban == 0
gen 	geo_level_3_birth = birth_dist
replace geo_level_3_birth = dist if birth_same == 1

*demography
ren caste demo_og
gen		demo_full = demo_og
replace demo_full = demo_og +1 if demo_og>80 & demo_og != . 
replace demo_full = 999 if demo_og>100 & demo_og != . //others
gen 	demo_harm = demo_og
replace demo_harm = 14 if demo_og == 15
replace demo_harm = 15 if ((demo_og>15|demo_og == 14)&demo_og != .)
ren dist geo_level_3
*re: geo_level 1 & 2 cannot be recovered; only comparable on district level

*occupation
gen agri = ((mwrk_nsco4 >= 6000&mwrk_nsco4<7000)|mwrk_nsco4 >= 9200&mwrk_nsco4 <= 9300) if mwrk_nsco4 != . //direct occupation question 
gen emp_salary = (wrk_paid == 1) if wrk_paid != .
gen		empstat = 1 if emp_salary == 1
replace empstat = 1 if (mwrk_status == 1|mwrk_status == 2) //employees + paid apprentice
replace empstat = 4 if mwrk_status == 4 //Own-account worker without regular empl
replace empstat = 3 if mwrk_status == 3 //employer
replace empstat = 2 if mwrk_status == 5 //Contributing family worker
replace empstat = 5 if mwrk_status == 6 //Other

*labor market status 
*gen 	lstatus	 =  1 if (wrk_paid == 1|(wrk_busns == 1|wrk_unpaid == 1)&(wrk_agri_sect == 2|purp_agripdct == 1|purp_agripdct == 2)) //excl. business/unpaid work which is mainly/only for family use
gen 	lstatus	 =  1 if (wrk_paid == 1|wrk_busns == 1|wrk_unpaid == 1) //incl. business/unpaid work which is mainly/only for family use
replace lstatus = 1 if temp_absent == 1&(paidleave == 1|return_prd == 1) //return to work within 3 months
replace lstatus = 2 if (seek30 == 1&whateffort != 13&(avail_time == 1|avail_time == 2))|(jobfixed == 1&(avail_time == 1|avail_time == 2)) //UE 
replace lstatus = 3 if lstatus == . & wrk_paid != . & wrk_busns != . & wrk_unpaid != . //at least asked employment questions
gen work_age = (age >= 15 & age <= 64)
keep if work_age == 1 & lstatus != .

*education
gen educ_stat = (ever_school == 1) if ever_school != .
gen literate = (can_write == 1 & can_read == 1) if (can_read != .|can_write != .)
ren grade_comp educ_og 
replace educ_og = 0 if educ_stat == 0 & educ_og == .
*adjust education variable
gen educ = educ_og if inrange(educ_og, 1, 12)
replace educ = 14 if inlist(educ_og, 13,15) 
replace educ = 16 if inlist(educ_og, 14) 
replace educ = 1 if educ_og == 16 //literate but levelless
replace educ = 0 if educ_og == 17 //illiterate
replace educ = 0 if educ_og == 0 
replace educ = 1 if literate == 1 & educ_og == .

**adjust demography 
*apply mapping
merge m:1 demo_full using "$raw/auxiliary/demo/NPL_demo.dta", keepusing(demo_extd)  keep(master match)
encode(demo_extd), gen(demo_group_raw) label(demo_group_raw)
gen demo_group = demo_group_raw
*Khas (Dalit) and  Madhesi (Dalit) belong both to lowest class  (5.52 vs. 5.85)
replace demo_group = 3 if demo_group_raw == 4
*Madhesi (low) and Madhesi (middle) exhibt similar mean education (3.66 vs. 3.93)
replace demo_group = 6 if demo_group_raw == 7
*Maithil Brahmin (High) are considered part of Madhesh people (https://en.wikipedia.org/wiki/Madhesh_Province)
*+ exhibit similar mean education as Madhesi (High), i.e. 8.94 vs. 8.57
replace demo_group = 5 if demo_group_raw == 8
*Tibetans are most strongly disfavored (4.66) followed by Dalit (5.62) but too marginal (0.3%)
replace demo_group = 3 if demo_group_raw == 12
*Royal people are somehow similar to Others (7.11 vs. 3.5) and cannot be attributed somewhere else
replace demo_group = 7 if (demo_group_raw == 10|demo_group_raw == 11)
*recode Muslim for beauty 
replace demo_group = 4 if demo_group_raw == 9
lab def demo_group ///
	1 "Janajati" ///
	2 "Khas" ///
	3 "Dalit (Khas + Madhesi) + Tibetans" ///
	4 "Muslim" ///
	5 "Madhesi (High) + Maithil Brahmin (High)" ///  = > only in census
	6 "Madhesi (Low + Middle)" ///  = > to dalit 
	7 "Others" 
lab val demo_group demo_group
*limit Wikipedia mapping for COMPARABILITY 
gen demo_lim = 1 if demo_group == 1
replace demo_lim = 2 if demo_group == 2
replace demo_lim = 3 if demo_group == 4
replace demo_lim = 4 if (demo_group == 3|demo_group == 5|demo_group == 6|demo_group == 7)
lab def demo_lim ///
	1 "Janajati" ///
	2 "Khas" ///
	3 "Muslim" ///
	4 "Others" 
lab val demo_lim demo_lim
ren demo_lim demo

**add province mapping (alternative geo_level_2)
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_district_province_mapping.dta", nogen 
*adjust Manang (Province of Gandaki; see https://en.wikipedia.org/wiki/Manang_District,_Nepal)
replace geo_level_2_adj = 4 if geo_level_3 == 41
*replace old geo_level 1+2 by province & districts 
ren geo_level_2_adj geo_level_1 //provinces
lab def geo_level_2 ///
	1 "Province 1" ///
	2 "Province 2" ///
	3 "Bāgmatī" ///
	4 "Gandaki" ///
	5 "Lumbini" ///
	6 "Karnali" ///
	7 "Sudūr Pashchim"
lab val geo_level_1 geo_level_2
ren geo_level_3 geo_level_2 //districts

**add region mapping
ren geo_level_2 geo_level_3
ren geo_level_1 geo_level_2
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_province_region_mapping.dta", nogen
drop if geo_level_1 == .
lab var geo_level_1 "Region" //5
lab var geo_level_2 "Province" //7
lab var geo_level_3 "District" //75 of which 74 are present in sample

*ren variables for LFS merge
drop wt_prov_ind_season
keep survey year country hh_id pid wt* geo_level* educ* female age urban* demo empstat lstatus
compress
save "$interim/LFS_NPL_2017.dta", replace

********************************************************************************
**##4.4 adjust geo-coding & append GLD with 2017 (based on raw)
********************************************************************************
use "$interim/GLD_NPL_1995_2008_2017.dta", clear

*adjust geo-coding to region (5) instead of province (7)
gen 	geo_level_3_raw = substr(subnatid2, strpos(subnatid2, ".") + 1, .) if year == 1998
replace geo_level_3_raw = substr(subnatid2, strpos(subnatid2, "-") + 2, .) if year == 2008 & strpos(subnatid2, "Western -") == 0
replace geo_level_3_raw = substr(subnatid2, strpos(subnatid2, "Western -") + 10, .) if year == 2008 & strpos(subnatid2, "Western -")>0
replace geo_level_3_raw = substr(subnatid2, strpos(subnatid2, "-") + 1, .) if year == 2017
replace geo_level_3_raw = subinstr(geo_level_3_raw, " ", "", .)
gen 	geo_level_3 = .
replace geo_level_3 = 1		if geo_level_3_raw == "Taplejung"
replace geo_level_3 = 2		if geo_level_3_raw == "Panchathar"
replace geo_level_3 = 2		if geo_level_3_raw == "Panchthar"
replace geo_level_3 = 3		if geo_level_3_raw == "Ilam"
replace geo_level_3 = 4		if geo_level_3_raw == "Jhapa"
replace geo_level_3 = 5		if geo_level_3_raw == "Morang"
replace geo_level_3 = 6		if geo_level_3_raw == "Sunsari"
replace geo_level_3 = 7		if geo_level_3_raw == "Dhankuta"
replace geo_level_3 = 8		if geo_level_3_raw == "Terhathum"
replace geo_level_3 = 9		if geo_level_3_raw == "Sankhuwasabha"
replace geo_level_3 = 10	if geo_level_3_raw == "Bhojpur"
replace geo_level_3 = 11	if geo_level_3_raw == "Solukhumbu"
replace geo_level_3 = 12	if geo_level_3_raw == "Okhaldhunga"
replace geo_level_3 = 13	if geo_level_3_raw == "Khotang"
replace geo_level_3 = 14	if geo_level_3_raw == "Udayapur"
replace geo_level_3 = 15	if geo_level_3_raw == "Saptari"
replace geo_level_3 = 16	if geo_level_3_raw == "Siraha"
replace geo_level_3 = 17	if geo_level_3_raw == "Dhanusha"
replace geo_level_3 = 17	if geo_level_3_raw == "Dhanusa"
replace geo_level_3 = 18	if geo_level_3_raw == "Mahottari"
replace geo_level_3 = 19	if geo_level_3_raw == "Sarlahi"
replace geo_level_3 = 20	if geo_level_3_raw == "Sindhuli"
replace geo_level_3 = 21	if geo_level_3_raw == "Ramechhap"
replace geo_level_3 = 22	if geo_level_3_raw == "Dolakha"
replace geo_level_3 = 23	if geo_level_3_raw == "Sindhupalchok"
replace geo_level_3 = 24	if geo_level_3_raw == "Kabhrepalanchok"
replace geo_level_3 = 24	if geo_level_3_raw == "Kavrepalanchok"
replace geo_level_3 = 24	if geo_level_3_raw == "Kavre"
replace geo_level_3 = 25	if geo_level_3_raw == "Lalitpur"
replace geo_level_3 = 26	if geo_level_3_raw == "Bhaktapur"
replace geo_level_3 = 27	if geo_level_3_raw == "Kathmandu"
replace geo_level_3 = 28	if geo_level_3_raw == "Nuwakot"
replace geo_level_3 = 29	if geo_level_3_raw == "Rasuwa"
replace geo_level_3 = 30	if geo_level_3_raw == "Dhading"
replace geo_level_3 = 31	if geo_level_3_raw == "Makawanpur"
replace geo_level_3 = 31	if geo_level_3_raw == "Makwanpur"
replace geo_level_3 = 32	if geo_level_3_raw == "Rautahat"
replace geo_level_3 = 33	if geo_level_3_raw == "Bara"
replace geo_level_3 = 34	if geo_level_3_raw == "Parsa"
replace geo_level_3 = 35	if geo_level_3_raw == "Chitwan"
replace geo_level_3 = 35	if geo_level_3_raw == "Chitawan"
replace geo_level_3 = 36	if geo_level_3_raw == "Gorkha"
replace geo_level_3 = 37	if geo_level_3_raw == "Lamjung"
replace geo_level_3 = 38	if geo_level_3_raw == "Tanahu"
replace geo_level_3 = 39	if geo_level_3_raw == "Syangja"
replace geo_level_3 = 40	if geo_level_3_raw == "Kaski"
replace geo_level_3 = 41	if geo_level_3_raw == "Manang"
replace geo_level_3 = 42	if geo_level_3_raw == "Mustang"
replace geo_level_3 = 43	if geo_level_3_raw == "Myagdi"
replace geo_level_3 = 44	if geo_level_3_raw == "Parbat"
replace geo_level_3 = 45	if geo_level_3_raw == "Baglung"
replace geo_level_3 = 46	if geo_level_3_raw == "Gulmi"
replace geo_level_3 = 47	if geo_level_3_raw == "Palpa"
replace geo_level_3 = 48	if geo_level_3_raw == "NawalParasi"
replace geo_level_3 = 48	if geo_level_3_raw == "Nawalparasi"
replace geo_level_3 = 48	if geo_level_3_raw == "Nawalpur" //2017
replace geo_level_3 = 48	if geo_level_3_raw == "Parasi" //2017
replace geo_level_3 = 49	if geo_level_3_raw == "Rupandehi"
replace geo_level_3 = 50	if geo_level_3_raw == "Kapilbastu"
replace geo_level_3 = 51	if geo_level_3_raw == "Arghakhanchi"
replace geo_level_3 = 52	if geo_level_3_raw == "Pyuthan"
replace geo_level_3 = 53	if geo_level_3_raw == "Rolpa"
replace geo_level_3 = 54	if geo_level_3_raw == "Rukum"
replace geo_level_3 = 54	if geo_level_3_raw == "WesternRukum" //2017
replace geo_level_3 = 54	if geo_level_3_raw == "EasternRukum" //2017
replace geo_level_3 = 55	if geo_level_3_raw == "Salyan"
replace geo_level_3 = 56	if geo_level_3_raw == "Dang"
replace geo_level_3 = 57	if geo_level_3_raw == "Banke"
replace geo_level_3 = 58	if geo_level_3_raw == "Bardiya"
replace geo_level_3 = 59	if geo_level_3_raw == "Surkhet"
replace geo_level_3 = 60	if geo_level_3_raw == "Dailekh"
replace geo_level_3 = 61	if geo_level_3_raw == "Jajarkot"
replace geo_level_3 = 62	if geo_level_3_raw == "Dolpa"
replace geo_level_3 = 63	if geo_level_3_raw == "Jumla"
replace geo_level_3 = 64	if geo_level_3_raw == "Kalikot"
replace geo_level_3 = 65	if geo_level_3_raw == "Mugu"
replace geo_level_3 = 66	if geo_level_3_raw == "Humla"
replace geo_level_3 = 67	if geo_level_3_raw == "Bajura"
replace geo_level_3 = 68	if geo_level_3_raw == "Bajhang"
replace geo_level_3 = 69	if geo_level_3_raw == "Achham"
replace geo_level_3 = 70	if geo_level_3_raw == "Doti"
replace geo_level_3 = 71	if geo_level_3_raw == "Kailali"
replace geo_level_3 = 72	if geo_level_3_raw == "Kanchanpur"
replace geo_level_3 = 73	if geo_level_3_raw == "Dadeldhura"
replace geo_level_3 = 74	if geo_level_3_raw == "Baitadi"
replace geo_level_3 = 75	if geo_level_3_raw == "Darchula"
merge m:1 geo_level_3 using "$raw/auxiliary/geo_level/NPL_province_region_mapping.dta", nogen keep(match)

// *add newly-coded 2017-18 wave
drop if year == 2017
append using "$interim/LFS_NPL_2017.dta", force
replace educy = educ if year == 2017
drop educ
drop wt_hh weight wage
*add wages based on GLD
merge 1:1 pid year using "$interim/GLD_NPL_1995_2008_2017.dta", keep(master match) keepusing(wage weight) nogen
save "$clean/LFS_NPL.dta", replace

********************************************************************************
**#5. LKA (GLD)
********************************************************************************
********************************************************************************
**##5.1 recover demo variable
********************************************************************************
//1992
use "$raw/LFS/LKA/LFS/1992/LKA_1992_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month province sector district{
	tostring `v', replace format(%02.0f)
}	
ren hhid hhid_orig
gen hhno = hh_unit+hhid_orig
egen hhid = concat(month province sector subsector district block hhno)
tostring p1, gen(strp_id) format(%02.0f)
egen pid = concat(hhid strp_id), punct("-")
keep pid ethnic
gen year = 1992
save "$interim/LKA_demographics_1992.dta", replace

//1993
use "$raw/LFS/LKA/LFS/1993/LKA_1993_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month province sector district block{
	tostring `v', gen(`v'_str) format(%02.0f)
}	
ren hhid hhid_orig
egen hhid = concat(month_str province_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 1993
save "$interim/LKA_demographics_1993.dta", replace

//1994
use "$raw/LFS/LKA/LFS/1994/LKA_1994_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month province sector district block{
	tostring `v', gen(`v'_str) format(%02.0f)
}	
ren hhid hhid_orig
egen hhid = concat(month_str province_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 1994
save "$interim/LKA_demographics_1994.dta", replace

//1995
use "$raw/LFS/LKA/LFS/1995/LKA_1995_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month province sector district block{
	tostring `v', gen(`v'_str) format(%02.0f)
}	
ren hhid hhid_orig
egen hhid = concat(month_str province_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 1995
save "$interim/LKA_demographics_1995.dta", replace

//1996
*re: use _orig file as lfsdata.dta misses psu_no variable
use "$raw/LFS/LKA/LFS/1996/LKA_1996_LFS_V01_M/lfs1996_orig.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring psu_no, gen(psu_no_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str psu_no_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic 
replace ethnic = 9 if ethnic == 7 | ethnic == 0
keep pid ethnic
gen year = 1996
save "$interim/LKA_demographics_1996.dta", replace

//1998
use "$raw/LFS/LKA/LFS/1998/LKA_1998_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring block, gen(block_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 1998
save "$interim/LKA_demographics_1998.dta", replace

//1999
use "$raw/LFS/LKA/LFS/1999/LKA_1999_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring block, gen(block_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 1999
save "$interim/LKA_demographics_1999.dta", replace

//2000
use "$raw/LFS/LKA/LFS/2000/LKA_2000_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring block, gen(block_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str block_str hhid_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 2000
save "$interim/LKA_demographics_2000.dta", replace

//2001
use "$raw/LFS/LKA/LFS/2001/LKA_2001_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring block, gen(block_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str block_str hhid_orig)
label var hhid "Household id"
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 2001
save "$interim/LKA_demographics_2001.dta", replace

//2002
use "$raw/LFS/LKA/LFS/2002/LKA_2002_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhid, gen(hhid_orig) format(%03.0f)
tostring block, gen(block_str) format(%03.0f)
ren hhid hid
egen hhid = concat(month_str sector_str district_str block_str hhid_orig)
label var hhid "Household id"
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
keep pid ethnic
gen year = 2002
save "$interim/LKA_demographics_2002.dta", replace

//2003
use "$raw/LFS/LKA/LFS/2003/LKA_2003_LFS_V01_M/lfsdata.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhn, gen(hhn_orig) format(%03.0f)
tostring psu, gen(psu_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str hhn_orig)
gsort hhid -p5
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic
replace ethnic = 9 if ethnic == 7 | ethnic == 8
keep pid ethnic
gen year = 2003
save "$interim/LKA_demographics_2003.dta", replace

//2004
use "$raw/LFS/LKA/LFS/2004/LKA_2004_LFS_V01_M/lfsdata_orig.dta", clear
foreach v of varlist month sector district {
	tostring `v', gen(`v'_str) format(%02.0f)
}	
tostring hhno, gen(hhno_orig) format(%03.0f)
tostring blockno, gen(block_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str block_str hhno_orig)
gsort hhid -age
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
replace ethnic = 9 if ethnic == 0
keep pid ethnic
gen year = 2004
save "$interim/LKA_demographics_2004.dta", replace

//2006
use "$raw/LFS/LKA/LFS/2006/LKA_2006_LFS_V01_M/LFS2006.dta", clear
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring cbno, gen(block_str) format(%03.0f)
tostring hhserno, gen(hh_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str block_str huno_str hh_str hh_str)
gsort hhid -p5
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic
keep pid ethnic
gen year = 2006
save "$interim/LKA_demographics_2006.dta", replace

//2007
use "$raw/LFS/LKA/LFS/2007/LKA_2007_LFS_V01_M/LFS2007.dta", clear
ren household_sample_no huno
ren household_no hhno
ren household_serial_no hhserno
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(hh_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hhno_str hh_str)
tostring p1_person_serial_no, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6_race ethnic
keep pid ethnic
gen year = 2007
save "$interim/LKA_demographics_2007.dta", replace

//2008
use "$raw/LFS/LKA/LFS/2008/LKA_2008_LFS_V01_M/LFS2008.dta", clear
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(hh_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hh_str hh_str)
gsort hhid -p5
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic
keep pid ethnic
gen year = 2008
save "$interim/LKA_demographics_2008.dta", replace

//2011
use "$raw/LFS/LKA/LFS/2011/LKA_2011_LFS_V01_M/LFS2011.dta", clear
ren household_sample_no huno
ren household_no hhno
ren household_serial_no hhserno
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(hh_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hh_str hh_str)
gsort hhid -p5
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic
keep pid ethnic
gen year = 2011
save "$interim/LKA_demographics_2011.dta", replace

//2012
use "$raw/LFS/LKA/LFS/2012/LKA_2012_LFS_V01_M/LFS2012.dta", clear
ren household_sample_no huno
ren household_no hhno
ren household_serial_no hhserno
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psuno, gen(psu_str) format(%03.0f)
tostring hhserno, gen(hh_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hh_str hh_str)
gsort hhid -p5
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p6 ethnic
keep pid ethnic
gen year = 2012
save "$interim/LKA_demographics_2012.dta", replace

//2013
use "$raw/LFS/LKA/LFS/2013/LKA_2013_LFS_V01_M/LFS2013.dta", clear
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(ser_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hhno_str ser_str)
tostring p1_person_serial_no, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p7 ethnic
keep pid ethnic
gen year = 2013
save "$interim/LKA_demographics_2013.dta", replace

//2014
use "$raw/LFS/LKA/LFS/2014/LKA_2014_LFS_V01_M/LFS2014.dta", clear
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(ser_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hhno_str ser_str)
gen byear = .
replace byear = p5y+2000 if inrange(p5y,0,14)
replace byear = p5y+1900 if inrange(p5y,15,99)
gsort hhid byear
bys hhid: gen newp1 = _n
tostring newp1, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p7 ethnic
keep pid ethnic
gen year = 2014
save "$interim/LKA_demographics_2014.dta", replace

//2015
use "$raw/LFS/LKA/LFS/2015/LKA_2015_LFS_V01_M/LFS2015.dta", clear
foreach v of varlist month sector district huno hhno{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
tostring hhserno, gen(ser_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str huno_str hhno_str ser_str)
tostring p1_person_serial_no, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren p7 ethnic
keep pid ethnic
gen year = 2015
save "$interim/LKA_demographics_2015.dta", replace

//2019
use "$raw/LFS/LKA/LFS/2019/LKA_2019_LFS_V01_M/LKA_2019_LFS_SARRAW.dta", clear
foreach v of varlist month sector district hunit hhold{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str hunit_str hhold_str)
tostring serno, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
ren eth ethnic
keep pid ethnic
gen year = 2019
save "$interim/LKA_demographics_2019.dta", replace

//2020
use "$raw/LFS/LKA/LFS/2020/LKA_2020_LFS_V01_M/LKA_2020_LFS_SARRAW.dta", clear
foreach v of varlist month sector district hunit hhold{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str hunit_str hhold_str)
label var hhid "Household id"
tostring serno, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
label var pid "Individual ID"
ren eth ethnic
keep pid ethnic
gen year = 2020
save "$interim/LKA_demographics_2020.dta", replace

//2021
use "$raw/LFS/LKA/LFS/2021/LKA_2021_LFS_V01_M/LKA_2021_LFS_SARRAW.dta", clear
foreach v of varlist month sector district hunit hhold{
	tostring `v', gen(`v'_str) format(%02.0f)
}
tostring psu, gen(psu_str) format(%03.0f)
egen hhid = concat(month_str sector_str district_str psu_str hunit_str hhold_str)
label var hhid "Household id"
tostring serno, gen(str_pid) format(%02.0f)
egen pid = concat(hhid str_pid), punct("-")
label var pid "Individual ID"
ren eth ethnic
keep pid ethnic
gen year = 2021
save "$interim/LKA_demographics_2021.dta", replace

clear
foreach y in 1992 1993 1994 1995 1996 1998 1999 2000 2001 2002 2003 2004 2006 2007 2008 2011 2012 2013 2014 2015 2019 2020 2021 {
	append using "$interim/LKA_demographics_`y'.dta", force
}

*demographic groups
gen 	demo = .
replace demo = 1 if inlist(ethnic,1,5,6,9) //Sinhala, Malay, Burger, Other
replace demo = 2 if ethnic == 2 //Sri Lanka Tamil
replace demo = 3 if ethnic == 3 //Indian Tamil
replace demo = 4 if ethnic == 4 //Sri Lankan Moor
lab def demo ///
	1 "Sinhalese + Others" ///
    2 "Sri Lanka Tamil" ///
    3 "Indian Tamil" ///
    4 "Sri Lankan Moor"
lab val demo demo

keep year pid demo
save "$interim/LKA_demographics.dta", replace

********************************************************************************
**##5.2 append GLD files
********************************************************************************
local m = 1
foreach n in 1992 1993 1994 1995 1998 1999 2000 2001 2002 2003 2004 2006 2007 2008 2011  {
	if "$GLD_local" == "no" use "$GLD_WB/LKA/LKA_`n'_LFS/LKA_`n'_LFS_V01_M_V02_A_GLD/Data/Harmonized/LKA_`n'_LFS_V01_M_V02_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/LKA/GLD/LKA_`n'_LFS_V01_M_V02_A_GLD_ALL.dta", replace

	tostring subnatid1 subnatid2 subnatidsurvey, replace
	isid pid
	tempfile lka_`m'
	save `lka_`m''
local ++m
}

local m = 16
foreach n in 1996 2012 2013 2014 2015 2019 2020 2021 {
	if "$GLD_local" == "no" use "$GLD_WB/LKA/LKA_`n'_LFS/LKA_`n'_LFS_V01_M_V03_A_GLD/Data/Harmonized/LKA_`n'_LFS_V01_M_V03_A_GLD_ALL.dta", clear
	if "$GLD_local" == "yes" use "$raw/LFS/LKA/GLD/LKA_`n'_LFS_V01_M_V03_A_GLD_ALL.dta", replace

	tostring subnatid1 subnatid2 subnatidsurvey, replace
	isid pid
	tempfile lka_`m'
	save `lka_`m''
local ++m
}

clear
append using  `lka_1' `lka_2' `lka_3' `lka_4' `lka_5' `lka_6' `lka_7' `lka_8' `lka_9' `lka_10' `lka_11' `lka_12' `lka_13' `lka_14' `lka_15' `lka_16' `lka_17' `lka_18' `lka_19' `lka_20' `lka_21' `lka_22' `lka_23' , force

//harmonize state IDs for LKA
gen 	subnatid1_new = subnatid1 
gen 	subnatid1_merge = subnatid1 
replace subnatid1_new = "Western" if subnatid1_new == "1 - Western" & countrycode == "LKA"
replace subnatid1_new = "Central" if subnatid1_new == "2 - Central" & countrycode == "LKA"
replace subnatid1_new = "Southern" if subnatid1_new == "3 - Southern" & countrycode == "LKA"
replace subnatid1_new = "Northern" if subnatid1_new == "4 - Northern Area" & countrycode == "LKA"
replace subnatid1_new = "Eastern" if subnatid1_new == "5 - Eastern" & countrycode == "LKA"
replace subnatid1_new = "North-western" if subnatid1_new == "6 - North-western" & countrycode == "LKA"
replace subnatid1_new = "North-central" if subnatid1_new == "7 - North-central" & countrycode == "LKA"
replace subnatid1_new = "Uva" if subnatid1_new == "8 - Uva" & countrycode == "LKA"
replace subnatid1_new = "Sabaragamuwa" if subnatid1_new == "9 - Sabaragamuwa" & countrycode == "LKA"
replace subnatid1_merge = subnatid1_new if countrycode == "LKA"

save "$interim/GLD_LKA.dta", replace

********************************************************************************
**##5.3 merge GLD with demographics
********************************************************************************
use "$interim/GLD_LKA.dta", clear
merge 1:1 year pid using "$interim/LKA_demographics.dta", keep(match) nogen 

*outcomes
gen work_age = (age >= 15 & age <= 64)
keep if work_age == 1 & lstatus != .
gen lfp = (lstatus == 1|lstatus == 2)
gen paidwage =  (empstat == 1 & wage_no_compen != .) if lfp == 1
gen 	wage_weekly = wage_no_compen if unitwage == 2 & paidwage == 1
replace wage_weekly = wage_no_compen/4 if unitwage == 5 & paidwage == 1

*deflate wage to 1992
gen 	wage = wage_weekly if year == 1992
replace wage = wage_weekly/(20.2/18.1) if year == 1993 
replace wage = wage_weekly/(21.9/18.1) if year == 1994 
replace wage = wage_weekly/(23.6/18.1) if year == 1995 
replace wage = wage_weekly/(32.8/18.1) if year == 1998 
replace wage = wage_weekly/(34.4/18.1) if year == 1999 
replace wage = wage_weekly/(36.5/18.1) if year == 2000 
replace wage = wage_weekly/(41.6/18.1) if year == 2001 
replace wage = wage_weekly/(45.6/18.1) if year == 2002 
replace wage = wage_weekly/(48.5/18.1) if year == 2003 
replace wage = wage_weekly/(52.2/18.1) if year == 2004 
replace wage = wage_weekly/(64.1/18.1) if year == 2006 
replace wage = wage_weekly/(74.2/18.1) if year == 2007 
replace wage = wage_weekly/(91.0/18.1) if year == 2008 
replace wage = wage_weekly/(106.7/18.1) if year == 2011 
replace wage = wage_weekly/(114.8/18.1) if year == 2012 
replace wage = wage_weekly/(122.7/18.1) if year == 2013 
replace wage = wage_weekly/(126.6/18.1) if year == 2014 
replace wage = wage_weekly/(131.4/18.1) if year == 2015 
replace wage = wage_weekly/(155.5/18.1) if year == 2019 
replace wage = wage_weekly/(165.1/18.1) if year == 2020 
replace wage = wage_weekly/(176.7/18.1) if year == 2021
	
*recover geo_level_1
gen geo_level_1 = real(substr(subnatid1, 1, 1))

save "$clean/LFS_LKA.dta", replace