//Neil Davies 11/02/16
//This creates the survival plots for the clinical outcomes paper

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

replace follow_up=0.5 if follow_up<1
rename eventdate_ons_cvd_death eventdate_ons_CVD_death
rename out_eventdate_ons_cvd_death out_eventdate_ons_CVD_death
	
gen follow_up_analysis=follow_up

//First, if patient is followed-up for longer than the max follow-up period limit at max: 
replace follow_up_analysis=100*365.25/12 if follow_up_analysis>100*365.25/12
sum follow_up*
//Second if patient has a event before the end of follow-up end follow-up with the event date:
replace follow_up_analysis=eventdate_ons_death-Rx_eventdate if eventdate_ons_death-Rx_eventdate<100*365.25/12 & eventdate_ons_death!=. & eventdate_ons_death-Rx_eventdate<follow_up

//Two individuals die on the same day as they we're issued with prescriptions:
replace follow_up_analysis=0.5 if follow_up_analysis==0

gen outcome_analysis=(out_eventdate_ons_death==1&eventdate_ons_death-Rx_eventdate<100*365.25/12)
sum follow*	

di "******************************"
di "**************ons_death**************"

tab outcome_analysis if cov_bmi!=. & cov_imd!=. & _mi_m==0
tab outcome_analysis if  _mi_m==0

mi stset follow_up , fail(outcome_analysis)  sc(365.25)	

stcox dr_varenicline cov_male  rx_year_2-rx_year_9 cov_age  cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever cov_gp_visit ///
	cov_charlson_ever  cov_bmi if _mi_m==0 ,cluster(staffid)
		
sts graph if _mi_m==0, by(dr_varenicline ) ci ylabel(0.85 0.90 0.95 1) xtitle("Years after first prescription") ciop(lw(vvthin)) graphregion(color(white)) bgcolor(white) ///
	legend(pos(6) order(6 5 ) label(6 "Prescribed varenicline") lab(5 "Prescribed NRT")) title("Linear regression") ytitle("Cumulative survival")
		
graph save Graph "/Volumes/varenicline_CPRD/6_servicehealth/results/ons_death_24_cox_survival.gph",replace
graph use "6_servicehealth/results/ons_death_24_cox_survival.gph",


stcox iv cov_male  rx_year_2-rx_year_9 cov_age  cov_alcohol_misuse_ever  cov_imd ///
	cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_selfharm_ever cov_gp_visit ///
	cov_charlson_ever  cov_bmi  if _mi_m==0,cluster(staffid)
	
sts graph if _mi_m==0, by(iv ) ci ylabel(0.85 0.90 0.95 1) xtitle("Years after first prescription") ciop(lw(vvthin)) graphregion(color(white)) bgcolor(white) ///
	legend(pos(6) order(6 5 ) label(6 "GP preferred varenicline") lab(5 "GP preferred NRT")) title("Instrumental variable") ytitle("Cumulative survival")
		
graph save Graph "/Volumes/varenicline_CPRD/6_servicehealth/results/ons_death_24_cox_iv_survival.gph",replace
graph combine "/Volumes/varenicline_CPRD/6_servicehealth/results/ons_death_24_cox_survival.gph" "/Volumes/varenicline_CPRD/6_servicehealth/results/ons_death_24_cox_iv_survival.gph"

graph save Graph "/Volumes/varenicline_CPRD/6_servicehealth/results/ons_death_24_cox_survival_combined.gph",replace
graph use "6_servicehealth/results/ons_death_24_cox_survival_combined.gph",
graph save "6_servicehealth/results/figure2_ons_death_24_cox_survival_combined.gph",

