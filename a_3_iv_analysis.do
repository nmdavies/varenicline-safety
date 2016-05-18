//Neil Davies 26/01/16
//This runs the IV analysis for the clinical outcomes paper.

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

//Generate mi and copd covariates

gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)

//Log the frequency of GP attendance:

foreach j in  3 6 9 12 24 48{
	gen out_ln_gp_visit_`j'=ln(out_gp_visit_`j'+0.05) if Rx_eventdate<19813-`j'/12*365.25
	}
	
//Program for IV analysis	
cap prog drop iv_analysis
prog def iv_analysis

preserve

//For the MI and COPD primary care diagnoses, limit to incident cases:
if "`1'"=="mi"|"`1'"=="copd"{
	drop if cov_`1'==1
	}

//IV regression minimal adjustment
ivreg2 out_`1'_`2' (dr_varenicline=iv) cov_male  rx_year_2-rx_year_9 cov_age if _mi_m==0,cluster(staffid) endog(dr_varenicline) first partial(cov_male  rx_year_2-rx_year_9 cov_age )
regsave dr_varenicline using "6_servicehealth/results/ivreg_basic_adjusted_`1'_`2'", detail(all) pval ci replace 
restore
end

cap prog drop lpm_analysis
prog def lpm_analysis
preserve

//For the MI and COPD primary care diagnoses, limit to incident cases:
if "`1'"=="mi"|"`1'"=="copd"{
	drop if cov_`1'==1
	}

//LPM regression 
reg out_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age  if iv!=. & _mi_m==0,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/lpm_full_adjusted_`1'_`2'", detail(all) pval ci replace 

restore

end

foreach i in ln_gp_visit /* hes  hes_resp hes_cvd ons_allcause ons_cvd ons_resp mi copd*/{
	foreach j in  3 6 9 12 24 48{
		iv_analysis `i' `j'
		lpm_analysis `i' `j'
		}
	}

	
//Cleaning the IV results:

cap prog drop clean_iv_results
prog def clean_iv_results

use "6_servicehealth/results/`3'_`1'_`2'",clear

di "use 6_servicehealth/results/ivreg_basic_adjusted_ln_gp_visit_48.dta"
di "6_servicehealth/results/`3'_`1'_`2'"

gen outcome="`1'"
gen follow_up="`2'"

gen results=string(coef*100, "%9.2f")+" ("+string(ci_lower*100, "%9.2f")+" to "+string(ci_upper*100, "%9.2f") + ")"
if "`1'"=="ln_gp_visit"{
	replace results=string(100*(exp(coef)-1), "%9.2f")+" ("+string(100*(exp(ci_lower)-1), "%9.2f")+" to "+string(100*(exp(ci_upper)-1), "%9.2f") + ")"
	}
order outcome follow_up N results pval cdf estatp 
cap keep  outcome follow_up N results pval cdf estatp

save "6_servicehealth/working_data/cleaned_`3'_`1'_`2'",replace
end

foreach i in ln_gp_visit hes hes_resp hes_cvd ons_allcause ons_cvd ons_resp mi copd {
	foreach j in 3 6 9 12 24 48{
		di "Outcome= `i' follow-up==`j'"
		clean_iv_results `i' `j' ivreg_basic_adjusted
		}
	}

use "6_servicehealth/working_data/cleaned_ivreg_basic_adjusted_hospitalisations_3",clear
foreach i in ons_allcause ons_cvd ons_resp   hes hes_cvd hes_resp  ln_gp_visit  mi copd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/working_data/cleaned_ivreg_basic_adjusted_`i'_`j'"
		}
	}

//Cleaning the LPM results:

cap prog drop clean_freq_results
prog def clean_freq_results

use "6_servicehealth/results/`3'_`1'_`2'",clear

gen outcome="`1'"
gen follow_up="`2'"

gen results=string(coef*100, "%9.2f")+" ("+string(ci_lower*100, "%9.2f")+" to "+string(ci_upper*100, "%9.2f") + ")"
if "`1'"=="ln_gp_visit"{
	replace results=string(100*(exp(coef)-1), "%9.2f")+" ("+string(100*(exp(ci_lower)-1), "%9.2f")+" to "+string(100*(exp(ci_upper)-1), "%9.2f") + ")"
	}
	
order outcome follow_up N results pval
cap keep  outcome follow_up N results pval

save "6_servicehealth/working_data/cleaned_`3'_`1'_`2'",replace
end

foreach i in ln_gp_visit   hes  hes_resp hes_cvd  ln_gp_visit  ons_allcause ons_cvd ons_resp mi copd {
	foreach j in 3 6 9 12 24 48{
		clean_freq_results `i' `j' lpm_full_adjusted
		}
	}

use "6_servicehealth/working_data/cleaned_lpm_full_adjusted_hospitalisations_3",clear
foreach i in   ons_allcause ons_cvd ons_resp   hes hes_cvd hes_resp  ln_gp_visit  mi copd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/working_data/cleaned_lpm_full_adjusted_`i'_`j'"
		}
	}

//Finally get the risk difference and range of F-stats

use "6_servicehealth/results/ivreg_basic_adjusted_ons_allcause_3",clear
foreach i in ln_gp_visit    hes  hes_resp hes_cvd ons_allcause ons_cvd ons_resp mi copd{
	foreach j in 3 6 9 12 24 48{
		append using  "6_servicehealth/results/ivreg_basic_adjusted_`i'_`j'",
		}
	}
