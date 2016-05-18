//Neil Davies 12/01/16
//This creates the outcomes using the ONS and HES data:

use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear

//The linkage coverage for the HES and ONS linkage are:
/*
hes	01/04/1997	31/03/2014
ons_death	01/01/1998	30/04/2014
*/

gen HES_follow_up=date("31/03/2014","DMY")-Rx_eventdate 

//19 Patients were prescribed on 31/03/2014. Replace these patients' follow-up with 0.5 day.

replace HES_follow_up=0.5 if HES_follow_up==0

//Match in HES outcomes
joinby patid using "6_servicehealth/working_data/out_HES",unmatched(master) _merge(_merge2)

//Omit admissions before or on the day of the 1st prescription
replace eventdate_HES=. if eventdate_HES<=Rx_eventdate

//Drop irrelvant variables:
drop prodcode staffid dr_varenicline history n_physician _merge2

//Collapse so that is only one record per patient per day:
foreach i in cvd resp{
	bys patid eventdate_HES: egen max=max(out_HES_`i')
	replace out_HES_`i'=max
	drop max
	}
bys patid eventdate_HES:keep if _n==1
	
//Create date of first any hospitalisation, cvd hospitalisation, and resp hospitalisation 
bys patid (eventdate): egen out_first_hospitalisations=min(eventdate_HES)
bys patid (eventdate): egen out_first_hes_cvd=min(eventdate_HES) if out_HES_cvd==1
bys patid (eventdate): egen out_first_hes_resp=min(eventdate_HES) if out_HES_resp==1

foreach i in hospitalisations hes_cvd hes_resp{
	bys patid: egen X=min(out_first_`i')
	sum X out_first_`i'
	replace out_first_`i'=X
	drop X
	}

format out_f* %td

//Generate the count of number of and indicator for any hospitalisations during each follow periods
foreach i in 48 24 12 9 6 3{
	foreach j in hospitalisations hes_cvd hes_resp{
		gen eventdate_HES_`j'=eventdate_HES
		bys patid:replace eventdate_HES_`j'=. if eventdate_HES_`j'>Rx_eventdate+365.25/12*`i'
		di "XXXXXXXX"
		replace eventdate_HES_`j'=. if ("`j'"=="hes_cvd" & out_HES_cvd!=1)|("`j'"=="hes_resp" & out_HES_resp!=1)
		bys patid:egen out_freq_`j'_`i'=count(eventdate_HES_`j') if HES_follow_up>365.25/12*`i' 
		bys patid:egen X=max(out_freq_`j'_`i') 
		replace out_freq_`j'_`i'=X 
		bys patid: gen out_`j'_`i'=(out_freq_`j'_`i'!=0) if out_freq_`j'_`i'!=. 
		drop X eventdate_HES_`j'
		}
	}	

//Generate the follow-up time for any hospitalisations during each follow periods
foreach i in 48 24 12 9 6 3{
	foreach j in hospitalisations hes_cvd hes_resp{
		gen out_fu_`j'_`i'=out_first_`j'-Rx_eventdate
		replace  out_fu_`j'_`i'=365.25/12*`i' if out_fu_`j'_`i'>365.25/12*`i' & HES_follow_up>365.25/12*`i'
		replace  out_fu_`j'_`i'=HES_follow_up if out_fu_`j'_`i'==.
		}
	}

//Limit to one observation per patient:

bys patid:keep if _n==1

drop eventdate_HES follow_up
compress
save "6_servicehealth/working_data/out_hospitalisations",replace

//**********************************
//Repeat for mortality
//**********************************

use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear

//The linkage coverage for the HES and ONS linkage are:
/*
hes	01/04/1997	31/03/2014
ons_death	01/01/1998	30/04/2014
*/

gen ONS_follow_up=date("31/03/2014","DMY")-Rx_eventdate

//19 Patients were prescribed on 31/03/2014. Replace these patients' follow-up with 0.5 day.

replace ONS_follow_up=0.5 if ONS_follow_up==0

//Match in ONS outcomes
joinby patid using "6_servicehealth/working_data/ONS_death",unmatched(master) _merge(_merge2)

//Replace all 83 deaths after follow-up equal to missing
replace eventdate_death=. if eventdate_death>date("31/03/2014","DMY")

//Generate max follow-up
gen out_fu_max=eventdate_death-Rx_eventdate

//Generate the follow-up time for any mortality during each follow period
foreach i in 48 24 12 9 6 3{
	foreach j in ONS_death ONS_cvd ONS_resp{
		gen out_fu_`j'_`i'=eventdate_death-Rx_eventdate
		replace  out_fu_`j'_`i'=365.25/12*`i' if out_fu_`j'_`i'>365.25/12*`i'
		
		//Replace follow-up equal to 0.5 day for individuals who died on day of first Rx (1 or 2 patients).
		replace out_fu_`j'_`i'=0.5 if out_fu_`j'_`i'==0
		
		gen out_`j'_`i'=(eventdate_death!=.& eventdate_death-Rx_eventdate<365.25*`i'/12)
		}
	}	

keep patid out_*  Rx_eventdate
drop out_ONS_resp out_ONS_allcause out_ONS_cvd
compress

replace out_fu_max=0.5 if out_fu_max==0

compress	
save "6_servicehealth/working_data/out_ons_death",replace
