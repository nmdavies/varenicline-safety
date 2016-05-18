//Neil Davies 16/02/16
//This runs the propensity score regression analysis.

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

//Generate mi and copd covariates
gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)


//Program used to create logit analysis	
cap prog drop psm_logit_analysis
prog def psm_logit_analysis

preserve

//For the MI and COPD primary care diagnoses, limit to incident cases:
if "`1'"=="mi"|"`1'"=="copd"{
	drop if cov_`1'==1
	}
	
//logit regression
logit out_`1'_`2' dr_varenicline _pscore if _mi_m==0 & _weight==1,cluster(staffid)

tabstat out_`1'_`2' if e(sample), stats(sum N) noseparato c(s) save
local num_events=el(r(StatTotal),1,1)
regsave dr_varenicline using "6_servicehealth/results/PSM_logit_full_adjusted_`1'_`2'", detail(all) pval ci replace addlabel(num_events,`num_events')

restore
end

//Program used to create frequency analysis	
cap prog drop psm_freq_analysis
prog def psm_freq_analysis

preserve

//For the MI and COPD primary care diagnoses, limit to incident cases:
if "`1'"=="mi"|"`1'"=="copd"{
	drop if cov_`1'==1
	}
	
gen out_ln_freq_`1'_`2'=ln(out_`1'_`2'+0.05)

//Linear regression
reg out_ln_freq_`1'_`2' dr_varenicline _pscore if _mi_m==0 & _weight==1,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/PSM_reg_`1'_`2'", detail(all) pval ci replace 

restore
end

//Label covariates
label variable cov_male "Male sex"
label variable cov_bmi "BMI (kg/m2)"
label variable cov_age "Age (years)"
label variable cov_mi "Myocardial infarction"
label variable cov_copd "Chronic obstructive pulmonary disease"
label variable cov_gp_visit "Number of GP visits in prior year"
label variable cov_charlson_ever "Chronic disease (Charlson)"
label variable cov_alcohol_misuse_ever "Misuses alcohol"
label variable cov_bipolar_ever "Bipolar"
label variable cov_depression_ever "Depression"
label variable cov_drug_misuse_ever  "Misuses drugs"
label variable cov_selfharm_ever "Self-harm"
label variable cov_mi "Myocardial infarction"
label variable cov_mi "Chronic obstructive pulmonary disease"
label variable cov_antidepres_ever "Anti-depressants"
label variable cov_antipsyc_ever "Anti-psychotics"
label variable cov_hypnotics_ever "Hypnotics"
label variable cov_statins_ever "Statins"
label variable cov_diabeticmeds_ever "Diabetic medications"
label variable cov_anti_ht_ever "Anti-hypertensive medications"
label variable cov_imd_most_deprived "Most deprived quintile IMD"
label variable cov_imd_least_deprived "Least deprived quintile IMD"
label variable cov_imd_miss "Missing IMD data"

//Ensure observations are randomly sorted before calling PSMATCH2

set seed 3488717
gen u=uniform()
sort u

//Update IMD variables to replace missing data
replace cov_imd_least_deprived=0 if  cov_imd_least_deprived==.
replace cov_imd_most_deprived=0 if   cov_imd_most_deprived==.

//Replace missing IMD and BMI at the mean
replace cov_imd=11.55853 if cov_imd==.
gen cov_bmi_miss=(cov_bmi==.)
replace cov_bmi=26.4508 if cov_bmi==.

//Create propensity score using psmatch2
psmatch2 dr_varenicline history cov_gp_visit cov_male rx_year_2-rx_year_9 cov_age ///
	cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd  cov_imd_miss cov_bmi cov_bmi_miss ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever ///
	cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever cov_selfharm_ever cov_mi cov_copd cov_charlson_ever ///
	if _mi_m==0, ///
	common noreplace logit odds neighbor(1)
	
regsave using "6_servicehealth/results/proscore",detail(all) pval ci replace
	
//PSM model adequacy check - Covariate balance
compress

pstest history cov_male cov_age cov_bmi cov_bmi_miss rx_year_2-rx_year_9 cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd cov_imd_miss  ///
 cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever cov_selfharm_ever cov_mi cov_copd ///
 cov_charlson_ever, both    labe

//Copy in the results of the pstest into a stata data set and run the following code to clean it:

/*

drop if var1==""

gen treated=word(var2,1)
gen control=word(var2,2)

order treated control var3 var4
*/

//How many patients were available for PSM?
tab dr_varenicline if _mi_m==0 & _weight==1
	
//PSM model adequacy check - Kernal density plots of treatment groups' propensity score distributions before and after matching 
//Before matching
twoway (kdensity _pscore if dr_varenicline==1 )  ///
	(kdensity _pscore if dr_varenicline==0 ),   ///
	legend( label(1 "Varenicline") label( 2 "NRT" ) subtitle  ///
	("Treatment groups' propensity score distributions before matching"))  xtitle("Propensity score") ytitle("Density") graphregion(color(white))  
graph save Graph "6_servicehealth/results/ps_dist_before.gph", replace
graph use "6_servicehealth/results/ps_dist_before.gph",	
graph export "6_servicehealth/results/efigure_2_ps_dist_before.eps", as(eps) replace

//After matching
twoway (kdensity _pscore if _treated==1 & _weight==1 )  ///
	(kdensity _pscore if _treated==0 & _weight==1  ),  ///
	legend( label(1 "Varenicline") label( 2 "NRT" ) subtitle   ///
	("Treatment groups' propensity score distributions after matching")) xtitle("Propensity score") ytitle("Density") graphregion(color(white)) 
graph save Graph "6_servicehealth/results/ps_dist_after.gph", replace
graph use "6_servicehealth/results/ps_dist_after.gph",	
graph export "6_servicehealth/results/efigure_3_ps_dist_after.ps", as(ps) replace

//Run the survival analysis on the propensity score matched sample.

save "6_servicehealth/working_data/effectabstinence_imputed_proscore_1",replace
use  "6_servicehealth/working_data/effectabstinence_imputed_proscore_1",clear

foreach i in ons_allcause ons_cvd ons_resp hes hes_resp hes_cvd mi copd {
	foreach j in 3 6 9 12 24 48{
		psm_logit_analysis `i' `j'
		}
	}

foreach i in hospitalisations  hes_resp hes_cvd gp_visit {
	foreach j in  3 6 9 12  24 48{
		psm_freq_analysis `i' `j'
		}
	}

//Cleaning the results:

cap prog drop clean_psm_logit_results
prog def clean_psm_logit_results
args outcome
foreach method in psm_logit_full_adjusted{
	foreach follow_up in 3 6 9 12 24 48{
		use "6_servicehealth/results/`method'_`outcome'_`follow_up'",clear

		gen outcome="`outcome'"
		gen follow_up="`follow_up'"

		gen results=string(exp(coef), "%9.2f")+" ("+string(exp(ci_lower), "%9.2f")+" to "+string(exp(ci_upper), "%9.2f") + ")"
		
		order outcome num_events N results 
		keep  outcome num_events N results

		save "6_servicehealth/results/cleaned_`method'_`outcome'_`follow_up'",replace
		}
	use "6_servicehealth/results/cleaned_`method'_`outcome'_3",clear
	rm  "6_servicehealth/results/cleaned_`method'_`outcome'_3.dta"
	foreach follow_up in 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_`method'_`outcome'_`follow_up'"
		rm "6_servicehealth/results/cleaned_`method'_`outcome'_`follow_up'.dta"
		}
	save "6_servicehealth/results/cleaned_`method'_`outcome'",replace
	}
end

foreach i in  ons_allcause ons_cvd ons_resp hes hes_resp hes_cvd mi copd {
	foreach j in 3 6 9 12 24 48{
		clean_psm_logit_results `i' `j' `k'
		}
	}

//Load up tables:	
//Basic adjusted results	
use "6_servicehealth/results/cleaned_psm_logit_full_adjusted_ons_allcause",clear
foreach i in ons_cvd ons_resp hes hes_resp hes_cvd mi copd{
	append using "6_servicehealth/results/cleaned_psm_logit_full_adjusted_`i'"
	}

gen n=_n
save "6_servicehealth/results/survival_psm_logit_full_adjusted",replace

export excel using "6_servicehealth/results/logit_proscore.xls",replace

//Clean frequency results

cap prog drop clean_freq_results
prog def clean_freq_results

use "6_servicehealth/results/PSM_reg_`1'_`2'",clear

gen outcome="`1'"
gen follow_up="`2'"

gen results=string(100*(exp(coef)-1), "%9.2f")+" ("+string(100*(exp(ci_lower)-1), "%9.2f")+" to "+string(100*(exp(ci_upper)-1), "%9.2f") + ")"

order outcome follow_up N results 
cap keep  outcome follow_up N results

save "6_servicehealth/results/cleaned_PSM_`1'_`2'",replace
end

foreach i in gp_visit hospitalisations hes_resp hes_cvd {
	foreach j in 3 6 9 12 24 48{
		clean_freq_results `i' `j' 
		}
	}

use "6_servicehealth/results/cleaned_PSM_gp_visit_3",clear
foreach i in gp_visit hospitalisations hes_resp hes_cvd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_PSM_`i'_`j'"
		}
	}
gen n=_n
drop in 1
save "6_servicehealth/results/cleaned_PROSCORE_reg_full_adjusted", replace

export excel using "/Volumes/varenicline_CPRD/6_servicehealth/results/freq_proscore.xls",replace

