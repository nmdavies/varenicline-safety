//Neil Davies 19/01/16
//This runs the analysis for Table 2 of the service use paper.

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

renpfix out_gp_visit out_freq_gp_visit
	
//Clear stset used in survival analysis
mi stset, clear
//Generate mi and copd covariates
gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)

//Program used to create frequency analysis	
cap prog drop freq_analysis
prog def freq_analysis

gen out_ln_freq_`1'_`2'=ln(out_freq_`1'_`2'+0.05)

//Complete data linear regression minimal adjustment
reg out_ln_freq_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age if cov_bmi!=. & cov_imd!=. & _mi_m==0,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/reg_basic_adjusted_`1'_`2'", detail(all) pval ci replace 

//Complete data linear regression full adjustment
reg out_ln_freq_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever cov_mi cov_copd cov_gp_visit ///
	cov_charlson_ever  cov_bmi if cov_bmi!=. & _mi_m==0,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/reg_full_adjusted_`1'_`2'", detail(all) pval ci replace

//MI linear regression minimal adjustment
reg out_ln_freq_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age if  _mi_m==0,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/MI_reg_basic_adjusted_`1'_`2'", detail(all) pval ci replace 
//MI linear regression full adjustment
mi est: reg out_ln_freq_`1'_`2' dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever  cov_mi cov_copd  cov_gp_visit ///
	cov_charlson_ever  cov_bmi ,cluster(staffid)
regsave dr_varenicline using "6_servicehealth/results/MI_reg_full_adjusted_`1'_`2'", detail(all) pval ci replace 

end

foreach i in hospitalisations hes_resp hes_cvd gp_visit {
	foreach j in  3 6 9 12  24 48{
		freq_analysis `i' `j'
		}
	}

//Cleaning the results:

cap prog drop clean_freq_results
prog def clean_freq_results

use "6_servicehealth/results/`3'_`1'_`2'",clear

gen outcome="`1'"
gen follow_up="`2'"

gen results=string(100*(exp(coef)-1), "%9.2f")+" ("+string(100*(exp(ci_lower)-1), "%9.2f")+" to "+string(100*(exp(ci_upper)-1), "%9.2f") + ")"

order outcome follow_up N results 
cap keep  outcome follow_up N results

save "6_servicehealth/results/cleaned_`3'_`1'_`2'",replace

end

foreach i in gp_visit hospitalisations hes_resp hes_cvd {
	foreach j in 3 6 9 12 24 48{
		foreach k in MI_reg_full_adjusted MI_reg_basic_adjusted reg_full_adjusted reg_basic_adjusted{
			clean_freq_results `i' `j' `k'
			}
		}
	}

use "6_servicehealth/results/cleaned_MI_reg_full_adjusted_hospitalisations_3",clear
foreach i in gp_visit hospitalisations hes_resp hes_cvd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_MI_reg_full_adjusted_`i'_`j'"
		}
	}
gen n=_n
save "6_servicehealth/results/cleaned_MI_reg_full_adjusted", replace

use "6_servicehealth/results/cleaned_MI_reg_basic_adjusted_hospitalisations_3",clear
foreach i in gp_visit hospitalisations hes_resp hes_cvd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_MI_reg_basic_adjusted_`i'_`j'"
		}
	}

rename N N_basic 
rename results	results_basic
gen n=_n
joinby n using "6_servicehealth/results/cleaned_MI_reg_full_adjusted",

use "6_servicehealth/results/cleaned_reg_full_adjusted_hospitalisations_3",clear
foreach i in gp_visit hospitalisations hes_resp hes_cvd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_reg_full_adjusted_`i'_`j'"
		}
	}
gen n=_n
save "6_servicehealth/results/cleaned_reg_full_adjusted", replace

use "6_servicehealth/results/cleaned_reg_basic_adjusted_hospitalisations_3",clear
foreach i in gp_visit hospitalisations hes_resp hes_cvd{
	foreach j in 3 6 9 12 24 48{
		append using "6_servicehealth/results/cleaned_reg_basic_adjusted_`i'_`j'"
		}
	}

rename N N_basic 
rename results	results_basic
gen n=_n
joinby n using "6_servicehealth/results/cleaned_reg_full_adjusted",

//Get mean number of events
use "6_servicehealth/working_data/effectabstinence_imputed_1", clear
sum out_freq_*_24 if _mi_m==2
