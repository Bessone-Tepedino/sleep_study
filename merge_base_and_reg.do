clear all
	set more off
	*set matsize 800
	
*Specify specific subfolder:
	global dir "$sleep_data/01. Main Study"		
	global aux "$sleep_data/01. Main Study/Analysis/Savings/Code/_aux"
	global output_dropbox "$dir/Analysis/savings/Output"
	
* Get sleep factors data set
use "C:/Users/pedro/Dropbox (MIT)/Papers/Sleep Project/heterogeneous treatment effects/sleep_factors.dta", clear	
* Keep only baseline info
keep if post_treatment == 0
save "temp.dta", replace

* Get base data set
	use "$dir/Cleaning/Output/Merged Cleaned Data/analysis_base.dta", clear
	rename treat_pool treat
	
	bys pid: egen _treatment_group = max(treatment_group)
	replace treatment_group = _treatment_group if missing(treatment_group)
	
	drop if dropout_category == 2
	drop if day_in_study == 1

merge m:1 pid using "temp.dta", keep (1 3) nogen
erase "temp.dta"

* rename indexes
rename index_impact index_impact_baseline 
rename index_no_impact index_no_impact_baseline

* Generate baseline sleep
egen _bsl_sleep = mean(sleep_night) if post_treatment == 0, by(pid)
egen bsl_sleep = max(_bsl_sleep), by(pid)
drop _bsl_sleep

* Generate interaction variables
gen treat_ind_impact = treat*index_impact_baseline
gen treat_ind_no_impact = treat*index_no_impact_baseline 

**************************
*** REGS *****************
**************************

* Correlation sleep and factors without baseline sleep
reg sleep_night index_impact_baseline index_no_impact_baseline if post_treatment == 1, ///
 cluster(pid)

* Correlation sleep and factors control demographics
reg sleep_night index_impact_baseline index_no_impact_baseline female age if post_treatment == 1, ///
 cluster(pid)
 
* Correlation sleep and factors with baseline sleep + demographics
reg sleep_night index_impact_baseline index_no_impact_baseline bsl_sleep female age ///
if post_treatment == 1, cluster(pid)

**************************
*** REGS TREAT EFX *******
**************************

reg sleep_night treat treat_nap index_impact_baseline index_no_impact_baseline bsl_sleep female age ///
 if post_treatment == 1, cluster(pid)

xi: reg sleep_night treat_ind_impact treat_ind_no_impact ///
treat treat_nap index_impact_baseline index_no_impact_baseline bsl_sleep female age ///
 if post_treatment == 1, cluster(pid)

qui summ index_impact_baseline, det
gen cat_ind_impact = 1 if index_impact_baseline <= `r(p25)' 
 replace cat_ind_impact = 2 if index_impact_baseline > `r(p25)' & index_impact_baseline <= `r(p50)' 
 replace cat_ind_impact = 3 if index_impact_baseline > `r(p50)' & index_impact_baseline <= `r(p75)' 
 replace cat_ind_impact = 4 if index_impact_baseline > `r(p75)'

reg sleep_night i.cat_ind_impact#c.treat treat i.cat_ind_impact bsl_sleep female age treat_nap ///
 if post_treatment == 1, cluster(pid)


qui summ index_no_impact_baseline, det
gen cat_ind_no_impact = 1 if index_no_impact_baseline <= `r(p25)' 
 replace cat_ind_no_impact = 2 if index_no_impact_baseline > `r(p25)' & index_no_impact_baseline <= `r(p50)' 
 replace cat_ind_no_impact = 3 if index_no_impact_baseline > `r(p50)' & index_no_impact_baseline <= `r(p75)' 
 replace cat_ind_no_impact = 4 if index_no_impact_baseline > `r(p75)'

reg sleep_night i.cat_ind_no_impact#c.treat treat i.cat_ind_no_impact bsl_sleep female age treat_nap ///
 if post_treatment == 1, cluster(pid)
