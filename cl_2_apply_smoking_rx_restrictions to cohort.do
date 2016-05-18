log using "Z:\stata_logs\cl_2_apply_smoking_rx_restrictions.smcl", replace
///UPDATE 18/11/15 Gemma Taylor + Neil Davies 14-10-15
///This .do file checks smoking event files against ISAC and published protocol restrictions (Davies et al. 2015, BMJ Open 2015;5:e009665)

set more off
cd "/Volumes/varenicline_cprd/"

//Open files that we will use and ensure that the sorting order will be consistent each time the file is recalled. Use random variable.
use "rawdata/nihr/stata/practice_1.dta", clear
set seed 1369841
gen double random1=runiform()
sort pracid uts lcd random1
drop random1
save "rawdata/nihr/stata/practice_1.dta", replace 
 
use "rawdata/nihr/stata/staff_1.dta", clear
set seed 1369841
gen double random1=runiform()
sort staffid gender role random1
drop random1
save "rawdata/nihr/stata/staff_1.dta", replace

use "tempdata/registration_period.dta", clear
set seed 1369841
gen double random1=runiform()
sort patid pracid from_date end_date random1
drop random1
save "tempdata/registration_period.dta", replace

use "rawdata/nihr/stata/patient.dta", clear
set seed 1369841
gen double random1=runiform()
sort patid frd crd random1
drop random1
gen pracid =real(substr(string(patid,"%11.0g"),-3,3))

//extract the UTS date and last collection date:
joinby pracid using "rawdata/nihr/stata/practice_1.dta", unmatched(master)
sum

//replace to_date equal to last collection date if missing
//patient file - documentation directory
gen from_date=crd
replace from_date=uts if uts>crd
gen end_date=tod
replace end_date=lcd if end_date==.
keep patid from_date end_date pracid yob
compress

//set random order before saving
set seed 1369841
gen double random1=runiform()
sort patid from_date end_date pracid yob random1
drop random1
save "tempdata/registration_period.dta",replace

use "tempdata/eventlist/eventlist_prod_nrt.dta" ,clear
///generate dummy variable for drug type
gen dr_varenicline=0
append using "tempdata/eventlist/eventlist_prod_varenicline.dta"
replace  dr_varenicline=1 if dr_varenicline==.
label define dr_varenicline 0 "nrt" 1 "varenicline" 2 "bupropion"
label values dr_varenicline dr_varenicline
label variable dr_varenicline "smoking cessation drug"
append using "tempdata/eventlist/eventlist_prod_buproprion.dta"
replace dr_varenicline=2 if dr_varenicline==.
compress
codebook patid 

//set order before using joinby
set seed 1369841
gen double random1=runiform()
sort patid  clinical_eventdate random1
joinby patid using "tempdata/registration_period.dta",unmatched(master)
sum

///format dates
replace yob= yob+1800
gen min_dob=(yob-1960)*365.25+1
gen max_dob=(yob-1960)*365.25+365.25
format %td min_dob max_dob
gen year_regstart=year(from_date)
gen year_regend=year(end_date) 

///drop patients if their maximum age was 15 at time of prescription
gen max_age_Rx=(clinical_eventdate-min_dob)/365.25
drop if max_age_Rx<16
codebook patid 
**How many observations and patients were dropped? n records=670, n patients=0

//drop if patient was prescribed after registration period:
drop if clinical_eventdate>end_date
codebook patid
**How many observations and patients were dropped? n=242, n patients=0

//generate variable indicating if smoking rx occurred before registration period, 
gen exclude =(clinical_eventdate<from_date) 
tab exclude 
codebook patid if exclude==0
**How many observations and patients were dropped? n=53,294, n patients=0

//exclude all prescriptions whereby the patient was 16/17 at time of prescription
replace exclude=1 if max_age_Rx<18
codebook patid if exclude==0
**How many observations and patients were dropped? n=3,705, n patients=0

//exclude all prescriptions which occurred before 1st September 2006:
replace exclude=1 if clinical_eventdate<date("01/09/2006", "DMY")
codebook patid if exclude==0
**How many observations and patients were dropped? n=355,547, n patients=0

//exclude prescriptions when both varenicline and NRT were issued on the same day:
bys patid clinical_eventdate: egen sd=sd(dr_varenicline)
replace exclude=1 if sd!=0 & sd!=.
codebook patid if exclude==0
drop sd
codebook patid 

**How many observations and patients were dropped? n prescriptions=6,986, n patients=193

//check whether the staff member issuing the prescription was a GP:
drop _merge
sort patid clinical_eventdate random1, stable

joinby staffid using "rawdata/nihr/stata/staff_1.dta", unmatched(master)
sum
tab _m
drop _m
replace exclude=1 if !inlist(role,1,2,5,6,7,8,9,10,47,50)
drop role gender
replace exclude=1 if staffid==0
codebook patid if exclude==0

**How many observations and patients were dropped? n=118,316, n patients=11840

//check if the most recent ineligible prescription was within 18 months of the first prescription.
//to do this we must create the difference in time between each prescription:
bys patid (clinical_eventdate exclude staffid random1):gen diff=clinical_eventdate-clinical_eventdate[_n-1]

//generate follow_up and history
gen follow_up=end_date-clinical_eventdate
gen history=clinical_eventdate-from_date

//exclude prescriptions with less than one year of historical follow-up prior to prescription
replace exclude=1 if history<365.25
codebook patid if exclude==0
**How many observations and patients were dropped? n prescriptions =40,487 , n patients =342

//exclude bupropion prescriptions
replace exclude=1 if dr_varenicline==2
codebook patid if exclude==0
**How many observations and patients were dropped? n=17,058, n patients =274

//exclude any prescription which had a prior prescription within 18 months:
replace exclude=1 if diff<365.25*1.5 & diff!=.
tab exclude
codebook patid if exclude==0

**How many observations and patients were dropped?  n prescriptions =979,056, n patients= n= 25057

save "tempdata/temp.dta", replace
use  "tempdata/temp.dta", clear

**How many observations and patients were dropped? n=
//create variable which indicates the order of the prescription through time, for both the ineligible prescriptions and the eligible prescriptions:
bys patid exclude (clinical_eventdate staffid random1): gen n=_n
sum

//drop all the ineligible prescriptions and all but the first eligible prescription
drop if n!=1 | exclude==1
codebook patid 

**How many prescriptions were dropped? n=51,246
rename clinical_eventdate Rx_eventdate
compress
drop yob-diff n
codebook patid 

//drop if n_physician<10

gen exclude=.
replace exclude=0
bys staffid: gen n_physician=_N
replace exclude=1 if n_physician<10
codebook patid if exclude==0
drop random1
**How many observations and patients were dropped? n= 17239

/*
//NMD: This restriction does not apply in the safety paper because we want to include all individuals who were allocated to treatment.
//NMD: For example, this statement would exclude patients who die within the follow-up period. 

//Keep if follow_up is greater than 180 days to account for a full course of treatment.
replace exclude=1 if follow_up<180
codebook patid if exclude==0
*/
**how many observations and patients were dropped? 

drop if exclude==1
codebook patid 
sum 

***final individual level sample should be  n= 

notes _dta: cohort of patients for the SAFETY PAPER prescribed varenicline and NRT. Patients not meeting restriction criteria have been dropped from this dataset. 
label data "cohort of patients prescribed nrt and varenicline, restrictions applied for SAFETY PAPER. Includes individuals who died."
save "6_servicehealth/working_data/first_eligible_smoking_cessation_Rx.dta", replace

log close
clear
