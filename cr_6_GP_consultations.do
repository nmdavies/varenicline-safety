//Neil Davies 12/01/16
//This creates the number of GP visits in the four years after first Rx

//This uses the files extracted in cr_5_add_covariates.do
clear
forvalues i=1(1)10 {
	append using  "tempdata/consult_eventdate_`i'"
	}
compress

joinby patid using "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", unmatched(using)


//drop consultations which occured after prescription of varen/nrt, and drop consultations which occurred before the first prescription of varen/nrt
drop if consult_eventdate<=Rx_eventdate

//Keep one consultation per day:
bys patid consult_eventdate:keep if _n==1

//Drop consultations after end of follow-up
drop if consult_eventdate>date("31/03/2014","DMY")
drop if consult_eventdate-Rx_eventdate>follow_up 

//Readd individuals who have no consultations:
drop _m
joinby patid using "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", unmatched(using) update

save "6_servicehealth/working_data/consultations",replace
use  "6_servicehealth/working_data/consultations",clear

//Need to create outcomes within 3, 6, 9, 12, 24 and 48 months of first prescription.
//drop if consultation occurs more than 4 years after first Rx

foreach i in 48 24 12 9 6 3{
	bys patid:replace consult_eventdate=. if consult_eventdate>Rx_eventdate+365.25/12*`i'
	bys patid:egen out_gp_visit_`i'=count(consult_eventdate) if follow_up>365.25/12*`i'
	bys patid: egen X=max(out_gp_visit_`i')
	replace out_gp_visit_`i'=X 
	replace out_gp_visit_`i'=. if follow_up<365.25/12*`i'
	drop X
	}
	
bys patid: keep if _n==1

keep patid out_*
compress
save "6_servicehealth/working_data/out_gp_visits",replace
