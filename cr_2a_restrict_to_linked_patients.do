//Neil Davies 19/01/16
//This restricts the sample to individuals with linkage data.
//We also limit follow-up to the end of linkage (31/03/2014)

use "6_servicehealth/working_data/first_eligible_smoking_cessation_Rx.dta", clear

//Match in each patient's linkdate
joinby patid using "6_servicehealth/working_data/linkage_elig",unmatched(master)
keep if _m==3&hes_e==1
**How many observations and patients were dropped? n=99,931

//Drop if patient prescribed after 31/03/2014
drop if Rx_eventdate>date("31/03/2014","DMY")
**How many observations and patients were dropped? n= 5,485

//Replace follow-up with end of follow-up with linkage:

replace follow_up =date("31/03/2014","DMY")-Rx_eventdate if date("31/03/2014","DMY")-Rx_eventdate<follow_up
compress

save "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx",replace
