//Neil Davies 11/02/16
//This produces the bias plots

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

//Generate mi and copd covariates
gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)


//*********************************
//Code to run the GMM hetero tests
//*********************************

//Syntax hetero_test outcome exposure instrument covar1 [covar2.....]
//Note I also included cluster robust standard errors, see the vce(cluster staffid). You will need to change this for your data.


cap prog drop hetero_test
prog def hetero_test

args outcome exposure iv 

macro shift 3
local covar="`*'"

cap drop _const
cap gen _const  = 1

di "outcome=`outcome'"
di "exposure=`exposure'"
di "instrumen=`iv'"
di "covariates=`covar'"

gmm (`outcome' - {xb1:`exposure' `covar' _const})  ///
	(`outcome' - {xb2:`exposure' `covar' _const}) if _mi_m==0, ///
	instruments(1:`exposure' `covar') ///
	instruments(2:`iv' `covar') ///
	winit(unadjusted,independent) onestep  ///
	vce(cluster staffid) ///
	deriv(1/xb1 = -1) ///
	deriv(2/xb2 = -1)
drop _const

local outcome2=substr("`outcome'",1,16)
est sto results_`outcome2'

lincom _b[xb1:`exposure']-_b[xb2:`exposure']
local het_p=2*(1-normal(abs(r(estimate)/r(se))))

regsave `exposure' using "6_servicehealth/results/bias_plots_basic_adjusted_`outcome'", detail(all) pval ci replace addvar(het_p,`het_p')

end

//Running each of the tests:

hetero_test cov_male dr_varenicline iv rx_year_1 rx_year_2 rx_year_3 rx_year_4 rx_year_5 rx_year_6 rx_year_7 rx_year_8 rx_year_9
hetero_test cov_age dr_varenicline iv rx_year_1 rx_year_2 rx_year_3 rx_year_4 rx_year_5 rx_year_6 rx_year_7 rx_year_8 rx_year_9 cov_male

ds cov_bmi cov_mi cov_copd cov_gp_visit cov_charlson_ever cov_alcohol_misuse_ever cov_bipolar_ever cov_depression_ever cov_drug_misuse_ever  ///
	cov_selfharm_ever cov_antidepres_ever cov_antipsyc_ever cov_hypnotics_ever cov_statins_ever cov_diabeticmeds_ever cov_anti_ht_ever cov_imd_most_deprived cov_imd_least_deprived
	
foreach i in `r(varlist)'{
	hetero_test `i' dr_varenicline iv rx_year_1 rx_year_2 rx_year_3 rx_year_4 rx_year_5 rx_year_6 rx_year_7 rx_year_8 rx_year_9 cov_male cov_age
	}

	
//Plot the regression results for gender and year of first prescription:
//Label the variables for inclusion in the figures
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
label variable cov_antidepres_ever "Anti-depressants"
label variable cov_antipsyc_ever "Anti-psychotics"
label variable cov_hypnotics_ever "Hypnotics"
label variable cov_statins_ever "Statins"
label variable cov_diabeticmeds_ever "Diabetic medications"
label variable cov_anti_ht_ever "Anti-hypertensive medications"
label variable cov_imd_most_deprived "Most deprived quintile IMD"
label variable cov_imd_least_deprived "Least deprived quintile IMD"
label variable cov_rx_before_2009 "Prescribed before 2009"

foreach i in cov_male  cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd_most_deprived cov_imd_least_deprived  ///
	  cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever  cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever  ///
	 cov_selfharm_ever cov_mi cov_copd cov_charlson_ever{
	
	local var="`i'"
	local name_var: variable label `var'  /* <- save variable label in local `lab' */
	
	di "`name_var'"

	local outcome2=substr("`i'",1,16)
	di "`outcome2'"
	local n=`n'+1
	local reg=`"(results_`outcome2' ,keep(xb1:dr_varenicline) ms(S) mc(gs5) ciopts(lc(gs5)) offset(0.05) rename(xb1:dr_varenicline="`name_var'"))"'
	local ivreg=`"(results_`outcome2',keep(xb2:dr_varenicline) ms(T) mc(gs10) ciopts(lc(gs10)) offset(-0.05) rename(xb2:dr_varenicline="`name_var'"))"'
	
	local combined=`"`combined'"'+" "+`"`reg'"'+" "+`"`ivreg'"'
	di `"`combined'"'
	
	}
di `"`combined'"'
coefplot `"`combined'"' , legend(off) xline(0) byopts(yrescale)  xtitle("Difference in absolute risk of outcome") graphregion(color(white)) 
graph save "6_servicehealth/results/graph_2_bias_plot_binary",replace 
graph use  "6_servicehealth/results/graph_2_bias_plot_binary"
graph export "6_servicehealth/results/figure_1a_ps_dist_before.eps", as(eps) replace
 
foreach i in cov_age cov_gp_visit  {
	
	local var="`i'"
	local name_var: variable label `var'  /* <- save variable label in local `lab' */
	
	di "`name_var'"

	local outcome2=substr("`i'",1,16)
	di "`outcome2'"
	local n=`n'+1
	local reg=`"(results_`outcome2' ,keep(xb1:dr_varenicline) ms(S) mc(gs5) ciopts(lc(gs5)) offset(0.05) rename(xb1:dr_varenicline="`name_var'"))"'
	local ivreg=`"(results_`outcome2',keep(xb2:dr_varenicline) ms(T) mc(gs10) ciopts(lc(gs10)) offset(-0.05) rename(xb2:dr_varenicline="`name_var'"))"'
	
	local combined=`"`combined'"'+" "+`"`reg'"'+" "+`"`ivreg'"'
	di `"`combined'"'
	}

coefplot `combined' , legend(off) xline(0) byopts(yrescale)  xtitle("Mean differences in outcome") graphregion(color(white)) 
graph save "6_servicehealth/results/graph_2_bias_plot_continious",replace 
graph use "6_servicehealth/results/graph_2_bias_plot_continious"
graph export "6_servicehealth/results/figure_1b_ps_dist_before.eps", as(eps) replace
 
 
//Cleaning and saving the bias plot tables:

cap prog drop bias_results
prog def bias_results
use "6_servicehealth/results/bias_plots_basic_adjusted_`1'",  clear
gen results_ols=string(coef[1]*100, "%9.2f")+" ("+string(ci_lower[1]*100, "%9.2f")+" to "+string(ci_upper[1]*100, "%9.2f") + ")"
gen results_iv=string(coef[2]*100, "%9.2f")+" ("+string(ci_lower[2]*100, "%9.2f")+" to "+string(ci_upper[2]*100, "%9.2f") + ")"
gen results_phet=coef[3]
gen variable="`1'"
keep variable N results*
keep in 1
save "6_servicehealth/working_data/cleaned_`1'",replace
end

foreach i in cov_age cov_male cov_bmi cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd_most_deprived cov_imd_least_deprived cov_gp_visit ///
	  cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever  cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever  ///
	 cov_selfharm_ever cov_mi cov_copd cov_charlson_ever{
	bias_results `i'
	}
 
use  "6_servicehealth/working_data/cleaned_cov_male",clear
foreach i in cov_age cov_bmi cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd_most_deprived cov_imd_least_deprived cov_gp_visit ///
	  cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever  cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever  ///
	 cov_selfharm_ever cov_mi cov_copd cov_charlson_ever{
	append using "6_servicehealth/working_data/cleaned_`i'",
	}
 order variable
 
 



		 
		 
