//Gemma Taylor 23/10/15
//This cleans the smoking outcome and creates an individual level smoking file.
cd "Z:\"
set more off
log using "stata_logs\cl_4_clean_smoking_status.smcl", replace
use "tempdata\first_eligible_smoking_cessation_Rx.dta", clear
codebook patid
///this joinby file is from the c1_3_additional_smoking_data.do
joinby patid using  "tempdata/smoking_status",unmatch(master)

bys patid (clinical_eventdate):drop if clinical_eventdate==. & _N!=1
codebook patid
bys patid (clinical_eventdate): drop if clinical_eventdate<=Rx_eventdate & !(clinical_eventdate==.|_N==_n)
codebook patid
replace clinical_eventdate=. if clinical_eventdate<=Rx_eventdate
foreach i in 1460 730 365 270 180 90{

	bys patid (clinical_eventdate): drop if clinical_eventdate-Rx_eventdate>`i' & _n!=1
	replace smoker_final=. if clinical_eventdate-Rx_eventdate>`i'
	replace clinical_eventdate=. if clinical_eventdate-Rx_eventdate>`i'
	bys patid (clinical_eventdate):drop if smoker_final==. & _n!=_N
	codebook patid
	bys patid (clinical_eventdate): gen temp_out_smoke_`i'=(smoker_final==1|smoker_final==.)
	bys patid (clinical_eventdate): gen out_smoke_`i'=temp_out_smoke_`i'[_N]
	drop temp_out_smoke_`i'
	
	}
	
bys patid: keep if _n==1	
keep patid out_*
compress
codebook patid

//inverse coding so quit=1 and smoker=0
label define out_quit 0 "smoker" 1 "quitter"
foreach i in 1460 730 365 270 180 90{
gen out_quit_`i'=.
replace out_quit_`i'=1 if out_smoke_`i'==0
replace out_quit_`i'=0 if out_smoke_`i'==1
label values out_quit_`i' out_quit
drop out_smoke_`i'
}

sum out_quit_*
save "tempdata\individual_level_smoke.dta",replace
log close



