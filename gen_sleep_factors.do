*Get Daily survey
use "C:/Users/pedro/Dropbox (Personal)/Sleep Data/01. main study/cleaning/Output/individual cleaned data/c05_dailysurvey_cleaned.dta" , clear

** Keep mental health variables; physical health;   stimulants;	   Pain;   Sleep Factors

#delimit ;
keep 
	pid date day_in_study

	ds_g1_satisfaction
	ds_g2_life_possibility
	ds_g3_life_worthwhile
	ds_g4_anger
	ds_g5_enjoyment
	ds_g6_sadness
	ds_g7_stress
	ds_g8_feel_energetic
	ds_g9_feeling_down
	ds_g10_peaceful
	ds_g11_feel_exhausted
	ds_g12_hungry_right_now
	ds_g13a_upset
	ds_g13b_outof_control
	ds_g13c_stressed
	ds_g13d_confidence
	ds_g13e_things_onyourway
	ds_g13f_notcopingwith
	ds_g13g_control_irritation
	ds_g13h_ontop_ofthings
	ds_g13i_angry
	ds_g13j_difficulties	
	
	ds_h7_fever
	ds_h8_cough
	ds_h9_cold
	ds_h10_headache
	ds_h11_nausea
	ds_h12_vomiting
	ds_h13_diarrhea
	ds_h14_dizziness
	ds_h15_rash

	ds_i1a_tea_yest
	ds_i1b_coffee_yest
	ds_i1c_filter_coffee_yest
	ds_i1d_cool_drinks_yest
	ds_i2_drunk
	ds_i3_drink_alcohol
	ds_i7_alcohol_yest
	ds_i8a_liquor_yest
	ds_i8b_smallbeer_yest
	ds_i8c_largebeer_yest
	ds_i8d_arrack_yest
	ds_i8d_arrack_yest
	ds_i14_lasttime_drunk_dby

	ds_j1_eyestrain_level
	ds_j2_affects_eyestrain
	ds_j3_pain_back_neck
	ds_j4_pain_affects
	ds_j5_level_pain_lastday
	ds_j6_pain_partofbody_lastday
	ds_j7_pain_lastnight
	ds_j8_pain_partofbody_lastnight
	ds_j9_pain_morning
	ds_j10_pain_partofbody_morning
	ds_j11_pain_30mins
	ds_j12_pain_partofbody_30min
	ds_j13_pain_now
	ds_j14_pain_partofbody_now
	ds_j15_tablet_last3days

	ds_k2_difficulty_sleep_factor
	ds_k3_lights_yest
	ds_k4_noise_yest
	ds_k5_mosquitoes_yest
	ds_k6_people_yest
	ds_k7_heat_yest
	ds_k8_cold_yest
	ds_k9_floodwet_yest
	ds_k10_uncomfortable_sleep
	ds_k11_phypain_yest
	ds_k12_disease_yest
	ds_k13_insomnia_yest
	ds_k14_stress_yest
	ds_k15_baddream_yest
	ds_k16_usingbathroom_yest
	ds_k17_hungry_thirsty_yest
	ds_k18_childcare_yest
	ds_k19_noise_yest
	ds_k20_lights_yest
	ds_k21_lights_level_yest
	ds_k22_lights_morning
	ds_k23_lights_level_morning
	ds_k24_temperature_yesterday
	ds_k26_num_people_sleeplocation
	ds_k28_rain_protection
	ds_k29_rain_yest
;

#delimit cr

** Drop variables with too few observations
quietly describe , varlist
local vars = r(varlist)
foreach x of varlist `vars' {
    qui summ `x'
	if `r(N)' < 2000 { 
		drop `x'
	}
}

* Generate postline treat
drop if day_in_study > 28
gen post_treatment = day_in_study > 8

*** Table Sleep Factor Variables
* table sleep factor variables
*foreach v of varlist ds_k* {
*	table `v'
*}

* Drop stuff with small variation and hard to classify
drop ds_k9_floodwet_yest ds_k28_rain_protection ds_k13_insomnia_yest

gen dum_hot = ds_k24_temperature_yesterday >=4 if ds_k24_temperature_yesterday != .
gen dum_cold = ds_k24_temperature_yesterday <=2 if ds_k24_temperature_yesterday != .
drop ds_k24_temperature_yesterday

replace ds_k21_lights_level_yest = . if ds_k21_lights_level_yest == 998
replace ds_k23_lights_level_morning = . if ds_k23_lights_level_morning == 998

replace ds_k26_num_people_sleeplocation = 5 if ds_k26_num_people_sleeplocation >= 6 & ds_k26_num_people_sleeplocation != .

*** Pre-classify variables in stuff we can affect vs. stuff we cannot affect
* Note: Idea is to create an index of stuff we can help and stuff we cannot help with
* normalize variables by setting them in 0-1 uniform scale.
* values closer to 1 = more problem sleeping; closer to 0 = less problem sleeping 

#delim ;
	local fcts_impact = "
		ds_k4_noise_yest
		ds_k7_heat_yest
		ds_k8_cold_yest
		ds_k10_uncomfortable_sleep
		ds_k3_lights_yest
		ds_k21_lights_level_yest
		ds_k23_lights_level_morning
		dum_hot
		dum_cold
	"
;
	local fcts_no_impact = "
		ds_k5_mosquitoes_yest
		ds_k6_people_yest
		ds_k11_phypain_yest
		ds_k12_disease_yest
		ds_k14_stress_yest
		ds_k15_baddream_yest
		ds_k16_usingbathroom_yest
		ds_k17_hungry_thirsty_yest
		ds_k18_childcare_yest
		ds_k26_num_people_sleeplocation
	"
;
	
#delim cr

* Normalize variables
foreach x of varlist `fcts_impact' `fcts_no_impact'{
	cap drop `x'_norm 
	qui summ `x'
	cap gen `x'_norm = (`x' - `r(min)')/(`r(max)'-`r(min)')
}
	
	x
* collapse data set on pid baseline/post level

collapse (mean) ds_k4_noise_yest_norm-ds_k18_childcare_yest_norm, by (pid post_treatment)

*aggregate on factors we can impact versus factor we cannot impact
cap egen index_impact 	 = rowmean(ds_k4_noise_yest_norm ds_k7_heat_yest_norm ds_k8_cold_yest_norm ds_k10_uncomfortable_sleep_norm ds_k3_lights_yest_norm ds_k21_lights_level_yest_norm ds_k23_lights_level_morning_norm dum_hot_norm dum_cold_norm)
cap egen index_no_impact = rowmean(ds_k5_mosquitoes_yest_norm ds_k6_people_yest_norm ds_k11_phypain_yest_norm ds_k12_disease_yest_norm ds_k14_stress_yest_norm ds_k15_baddream_yest_norm ds_k16_usingbathroom_yest_norm ds_k17_hungry_thirsty_yest_norm ds_k18_childcare_yest_norm)	

save "C:/Users/pedro/Dropbox (MIT)/Papers/Sleep Project/heterogeneous treatment effects/sleep_factors.dta", replace



