//Neil Davies 18/11/15
//This merges in the covariates and outcomes:

use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx",clear
drop _m
joinby patid using "rawdata/nihr/stata/patient",unmatched(master)
drop _m vmid mob marital famnum chsreg prescr capsup ses regstat reggap internal toreason accept chsdate crd tod deathdate

//Male:
gen cov_male=(gender==1)
drop gender

//Match in the HES outcomes:
joinby patid using "6_servicehealth/working_data/out_hospitalisations", unmatched(master)
drop _m
drop out_hes_*

//Match in number of GP visits
joinby patid using "6_servicehealth/working_data/out_gp_visits", unmatched(master)
drop _m

//Age at first prescription
gen cov_age=year(Rx_eventdate)-yob-1800
// Age (using age categories 18-20, 21-30, 31-40, 41-50, 51-60, and >60 years)

gen cov_age_18_20=(cov_age<21)
gen cov_age_21_30=(cov_age<31&cov_age>20)
gen cov_age_31_40=(cov_age<41&cov_age>30)
gen cov_age_41_50=(cov_age<51&cov_age>40)
gen cov_age_51_60=(cov_age<61&cov_age>50)
gen cov_age_61=(cov_age>60)

drop yob
compress

//Merge in the individual level covariates:
joinby patid using "6_servicehealth/working_data/indiv_cov_all.dta",unmatched(master)
drop _m

//Generate indicators for year of first prescription
gen rx_year=year(Rx_eventdate)
tab rx_year, gen(rx_year_)

bys staffid (Rx_eventdate patid): gen iv=dr_varenicline[_n-1]

compress

//Create indicators for being in the least and most deprived IMD quintiles and in having missing IMD:

gen cov_imd_most_deprived=(cov_imd>16) if cov_imd!=. 
gen cov_imd_least_deprived=(cov_imd<5) if  cov_imd!=.
gen cov_imd_miss=(cov_imd==.)
gen cov_rx_before_2009=(cov_Rx_year<2009)

//Drop irrelvant covariates:
drop cov_autism_ever cov_dementia_ever cov_hyperkineticdis_ever cov_eatingdis_ever cov_learningdis_ever cov_neuroticdis_ever cov_otherbehavdis_ever cov_persondis_ever cov_schizop_ever

//Match in the outcomes
joinby patid using "6_servicehealth/working_data/survival_outcomes",unmatched(master)
drop _m

renpfix out_ONS out_ons
renpfix out_fu_ONS out_fu_ons

//Need to create binary outcomes at each follow-up period
//Generate outcome

foreach outcome in mi copd hes hes_cvd hes_resp ons_allcause ons_cvd ons_resp{
	foreach i in 48 24 12 9 6 3{
		gen out_`outcome'_`i'=(out_`outcome'==1)
		//Drop individuals with no outcome and insufficient follow-up
		replace out_`outcome'_`i'=. if (out_fu_`outcome'<365.25*`i'/12 & out_`outcome'==0)
		//Replace indiviudals equal to zero if they have an event after the follow-up period
		replace out_`outcome'_`i'=0 if (out_fu_`outcome'>365.25*`i'/12 & out_`outcome'==1)
		//Replace people equal to missing if they are an prevalent case
		replace out_`outcome'_`i'=. if out_fu_`outcome'<0
		}
	}

	
//Update the follow-up period with date of death for the minority of individuals who died before the end of their registration.
ds *fu*
foreach i in `r(varlist)'{
	di "**************************"
	di "`i'"
	gen diff=`i'-out_fu_ons_allcause
	sum diff if diff>0.5
	//replace `i'=out_fu_ons_allcause if `i'>out_fu_ons_allcause & `i'!=. & out_fu_ons_allcause!=.
	drop diff
	}
	
//Censor individuals who were prescribed too close to the end of follow-up
foreach i in 48 24 12 9 6 3{
		foreach outcome in mi copd hes hes_cvd hes_resp ons_allcause ons_cvd ons_resp gp_visit{
		replace out_`outcome'_`i'=. if Rx_eventdate>19813-`i'/12*365.25
		}
	}

compress	
save "6_servicehealth/working_data/analysis_dataset",replace

