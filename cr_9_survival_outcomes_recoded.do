//Neil Davies 29/02/16
//This recreates the survival outcomes for the varenicline data

use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx",clear
joinby patid using "rawdata/nihr/stata/patient",unmatched(master)
gen pracid =real(substr(string(patid,"%11.0g"),-3,3))
tab _m
drop _m
joinby pracid using "rawdata/nihr/stata/practice_1",unmatched(master)
drop _m

//Merge in date of death

joinby patid using "6_servicehealth/working_data/ONS_death", unmatched(master)

egen follow_up_start=rowmax(Rx_eventdate uts crd)
egen follow_up_end=rowmin(lcd tod eventdate_death)

//The study begins on the 1st of September 2006 and ends on the 31st of March 2014.
replace follow_up_start=mdy(09,01,2006) if follow_up_start<mdy(09,01,2006)
replace follow_up_end=mdy(03,31,2014) if follow_up_end>mdy(03,31,2014)

drop _m vmid mob marital famnum chsreg prescr capsup ses regstat reggap internal toreason accept chsdate crd tod deathdate

//Match in the CPRD diagnosis of MI/COPD:
foreach i in mi copd{
	joinby patid using "tempdata/eventlist/eventlist_med_`i'", unmatched(master)
	
	//Drop events that occur after the end of follow-up
	replace clinical_eventdate=. if clinical_eventdate>follow_up_end
	
	//Keep first diagnosis

	bys patid (clinical_eventdate): keep if _n==1
	rename clinical_eventdate first_`i'_eventdate
	gen out_`i'=(first_`i'_eventdate!=.)
	rename medcode `i'_medcode
	drop _m
	}

//Match in the HES outcomes
joinby patid using "6_servicehealth/working_data/out_HES",unmatched(master)	

//Clean the HES eventdates
//If the HES eventdate is less than 3 days after date of death, replace with date of death
gen diff=eventdate_death-eventdate_HES 
replace eventdate_HES=eventdate_death if diff<0 & diff>-4

//drop HES records which occured more than 3 days after death:
foreach i in eventdate_HES out_HES_resp out_HES_cvd out_HES_allcause{
	replace `i'=. if diff<-3
	}
drop diff
rename eventdate_HES eventdate_hes

//Keep first diagnosis after first prescription
replace eventdate_hes=. if eventdate_hes<=Rx_eventdate
bys patid (eventdate_hes): gen first_hes_eventdate=eventdate_hes[1]
gen xeventdate_hes=eventdate_hes
replace eventdate_hes=. if out_HES_cvd!=1
bys patid (eventdate_hes): gen first_hes_cvd_eventdate=eventdate_hes[1]
drop eventdate_hes
replace xeventdate_hes=. if out_HES_resp!=1
bys patid (xeventdate_hes): gen first_hes_resp_eventdate=xeventdate_hes[1]
drop xeventdate_hes
drop _merge out_HES_resp out_HES_cvd out_HES_allcause
duplicates drop

foreach i in hes hes_cvd hes_resp{
	gen out_`i'=(first_`i'_eventdate!=.)
	}

//Gen follow-dates for ONS death
foreach i in ONS_resp ONS_cvd ONS_allcause{
	gen first_`i'_eventdate=follow_up_end
	}
	
//Generate length of follow up:
foreach i in mi copd hes hes_cvd hes_resp ONS_resp ONS_cvd ONS_allcause{
	//Follow equal to the number of days after first Rx
	gen out_fu_`i'=first_`i'_eventdate-Rx_eventdate // if first_`i'_eventdate<Rx_eventdate
	//Replace follow-up equal to max follow-up for those who had no event
	replace out_fu_`i'=follow_up_end-Rx_eventdate if out_fu_`i'==.
	//For individuals whose follow-up ends on the day they were prescribed with half a day of follow up
	replace out_fu_`i'=0.5 if out_fu_`i'==0
	}

//Set non-dead individuals to have a zero outcome:
foreach i in out_ONS_resp  out_ONS_allcause  out_ONS_cvd{
	replace `i'=0 if `i'==.
	}

foreach i in  mi copd hes hes_cvd hes_resp ONS_resp ONS_cvd ONS_allcause{
	stset out_fu_`i' ,failure(out_`i') scale(365.25)
	}
	
keep patid out_* 
sum out_*
compress
save "6_servicehealth/working_data/survival_outcomes",replace
