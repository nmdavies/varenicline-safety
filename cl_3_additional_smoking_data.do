//UPDATE 23/11/15//Neil Davies 20/10/15
//This extracts all of the smoking status codes from the additional clinical details table

//Point towards the CPRD drive:
cd "Z:\"
log using "stata_logs\cl_3_additional_smoking_data.smcl", replace
//The additional data table has no dates in it. So we have to match the dates in from the clinical table.
//Each event in the clinical and additional tables is indexed by the adid - which is unique within individual.

//First we create some temporary files which contain all of the dates and adid from the clinical files for the nrt and varenicline sample.
forvalues i=1(1)14{
	use patid adid eventdate using "rawdata/stata/clinical_`i'.dta" ,clear
	sort patid adid
	save "tempdata/adid_eventdate_`i'",replace
	}

//Then we merge in the adid and eventdate data into the smoking data from the additional table.
use patid enttype data1 adid if enttype==4 using "rawdata/stata/additional_1.dta" ,clear
append using "rawdata/stata/additional_2.dta", keep(patid enttype data1 adid) 
keep if enttype==4 
destring data1, generate(data_1)
keep if data_1!=0
drop data1
compress
gen _merge_final=.
forvalues i=1(1)14{
	joinby patid adid using "tempdata/adid_eventdate_`i'.dta" ,unmatched(master) update
	replace _merge_final=3 if _merge==3
	drop _merge
	}
drop _merge
compress
save "tempdata/smoking_additional_data_eventdate",replace

//CLEANING THE CLINICAL SMOKING DATA
//Add the smoking status variable
use "tempdata/eventlist_med_smoke.dta",clear
joinby medcode using  "Z:\codelists\statalists\smoke.dta", unmatched(master)
tab _m
drop medcode _merge
//drop unwanted smoking codes
drop if smokestat>3
gen smoker_final=(smokestat==2)
append using  "tempdata/smoking_additional_data_eventdate"

//Update smoker_final with the additional clinical details data:
replace smoker_final=(data_1==1) if smoker_final==. 
replace clinical_eventdate=eventdate if clinical_eventdate==.
drop if clinical_eventdate==.
keep patid clinical_eventdate smoker_final
compress
mdesc  smoker_final
log close
save "tempdata/smoking_status",replace
clear


