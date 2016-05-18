//Neil Davies 15/03/16
//This creates the logistic regression results for the NIHR-MRC safety paper

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear
	
//Clear stset used in survivial analysis
mi stset, clear

//Generate mi and copd covariates
gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)

//Program used to create logit analysis	
cap prog drop logit_analysis
prog def logit_analysis

preserve

//For the MI and COPD primary care diagnoses, limit to incident cases:
if "`1'"=="mi"|"`1'"=="copd"{
	drop if cov_`1'==1
	}
/*
//Complete data logit regression minimal adjustment
logit out_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age if cov_bmi !=. & cov_imd!=. &  _mi_m==0,cluster(staffid)
tabstat out_`1'_`2' if e(sample), stats(sum N) noseparato c(s) save
local num_events=el(r(StatTotal),1,1)
regsave dr_varenicline using "6_servicehealth/results/logit_basic_adjusted_`1'_`2'", detail(all) pval ci replace addlabel(num_events,`num_events')

//Complete data logit regression full adjustment
logit out_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever cov_copd cov_mi cov_gp_visit ///
	cov_charlson_ever  cov_bmi if cov_bmi!=. & _mi_m==0,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/logit_full_adjusted_`1'_`2'", detail(all) pval ci replace
*/
//MI logit regression minimal adjustment
logit out_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age if  _mi_m==0,cluster(staffid)
tabstat out_`1'_`2' if e(sample) & _mi_m==0, stats(sum N) noseparato c(s) save
local num_events=el(r(StatTotal),1,1)
regsave dr_varenicline using "6_servicehealth/results/MI_logit_basic_adjusted_`1'_`2'", detail(all) pval ci replace addlabel(num_events,`num_events')
/*
//MI logit regression full adjustment
mi est:logit out_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever cov_copd cov_mi cov_gp_visit ///
	cov_charlson_ever  cov_bmi ,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/MI_logit_full_adjusted_`1'_`2'", detail(all) pval ci replace 
*/
restore
end

foreach i in ons_allcause ons_cvd ons_resp hes hes_resp hes_cvd mi copd {
	foreach j in  3 6 9 12  24 48{
		logit_analysis `i' `j'
		}
	}
	
	

//Cleaning the results:

cap prog drop clean_logit_results
prog def clean_logit_results
args outcome
foreach method in logit_basic_adjusted MI_logit_full_adjusted MI_logit_basic_adjusted logit_full_adjusted{
	foreach follow_up in 3 6 9 12 24 48{
		use "6_servicehealth/results/`method'_`outcome'_`follow_up'",clear

		gen outcome="`outcome'"
		gen follow_up="`follow_up'"

		gen results=string(exp(coef), "%9.2f")+" ("+string(exp(ci_lower), "%9.2f")+" to "+string(exp(ci_upper), "%9.2f") + ")"
		
		if "`method'"=="logit_basic_adjusted"{
			order outcome num_events N results 
			keep  outcome num_events N results
			}
		if "`method'"=="MI_logit_basic_adjusted"{
			order outcome follow_up num_events N results 
			keep  outcome follow_up num_events N results
			}		
		if "`method'"!="logit_basic_adjusted"&"`method'"!="MI_logit_basic_adjusted" { 
			order outcome follow_up N results  
			keep  outcome follow_up N results 
			}
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

foreach i in ons_allcause ons_cvd ons_resp hes hes_resp hes_cvd mi copd {
	clean_logit_results `i'
	}

foreach method in MI_logit_full_adjusted MI_logit_basic_adjusted logit_full_adjusted logit_basic_adjusted{	
	use "6_servicehealth/results/cleaned_`method'_ons_allcause"
	foreach i in ons_cvd ons_resp hes hes_resp hes_cvd mi copd {
		append using  "6_servicehealth/results/cleaned_`method'_`i'"
		rm "6_servicehealth/results/cleaned_`method'_`i'.dta"
		}
	gen n=_n
	save "6_servicehealth/results/cleaned_`method'",replace
	}

use "6_servicehealth/results/cleaned_logit_basic_adjusted",clear
rename N N_basic
rename results results_basic
joinby n using "6_servicehealth/results/cleaned_logit_full_adjusted",unmatched(master)
drop _m
assert N==N_basic 
drop N n

use "6_servicehealth/results/cleaned_MI_logit_basic_adjusted",clear
rename N N_basic
rename results results_basic
joinby n using "6_servicehealth/results/cleaned_MI_logit_full_adjusted",unmatched(master)
drop _m
assert N==N_basic 
drop N n
