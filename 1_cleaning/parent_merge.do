/******************************************************************************\
#title: "parent_merge.do"
#author: "Fabian Reutzel"
\******************************************************************************/
cap prog drop parent_merge
prog def parent_merge
	**save roster dataset
	preserve
	foreach x in emp_* agri* educ_stat literate educ_og educ_cat_og {
	ren `x' child_`x'
	}
	save "$interim/roster.dta", replace
	restore 

	**generate parental dataset
	foreach x in emp_stat agri educ_stat literate educ_og educ_cat_og {
	gen mother_`x' = `x' if female==1
	gen father_`x' = `x' if female==0
	}
	gen father_id = hh_rel
	gen mother_id = hh_rel
	keep if inlist(hh_rel, 0, 1, 3, 4)
	duplicates drop hh_id hh_rel female, force //58 obs
	ren female parent_gender
	keep hh_id parent_gender mother_* father_* 
	save "$interim/parents.dta", replace

	**build dataset
	use "$interim/roster", clear
	
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
	
	drop *_merge
end