//Neil Davies 25/02/16
//This gets the meta-analysis plot

use "/Volumes/varenicline_CPRD/6_servicehealth/results/ivreg_basic_adjusted_ons_cvd_24.dta",clear
append using "/Volumes/varenicline_CPRD/6_servicehealth/results/ivreg_basic_adjusted_hes_cvd_24.dta"
append using  "/Volumes/varenicline_CPRD/6_servicehealth/results/ivreg_basic_adjusted_mi_24.dta"
gen outcome="Cardiovascular mortality (ONS)" in 1
replace outcome = "Hospitalization due to cardiovascular disease (HES)" in 2
replace outcome = "Primary care diagnosis of myocardial infarction (Read codes)" in 3
order outcome coef ci_lower ci_upper 
set obs 4

gen mills=("Mills et al. (2014) meta-analysis of RCTs") if _n==4
replace mills="Davies et al. (2016) instrumental variable analysis" if mills==""

//See below for simulations to derive the Mills estimate
replace outcome ="Major cardiovascular adverse event"  in 4
replace coef=-0.000746800 in 4
replace ci_lower=-0.002761000 in 4
replace ci_upper=0.001267400 in 4
replace coef =coef*100 
replace ci_lower =ci_lower*100
replace ci_upper =ci_upper*100

//reorder
gen order=0 if _n==4
replace order=_n if order==.
sort order

metan coef ci_lower ci_upper ,  xtitle("NRT vs. varenicline")  graphregion(color(white) lwidth(large)) ///
	label(namevar=outcome) texts(300) by(mills) nosubgroup effect("Risk difference")  nowt nohet
	 
