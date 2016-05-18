//This do file extracts all covariates (Davies et al. BMJ Open 2015;5:e009665) and merges them into an individual level dataset
//Gemma Taylor 18/12/2015. Edited by Neil Davies 13/01/2016
clear
set max_memory .
cd "/Volumes/varenicline_CPRD/"
set more off

//AGE - age in years at time of prescription & YEAR OF 1ST NRT/VAR PRESCRIPTION
	//extract yob and gender from patient.dta
		use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
		codebook patid
		merge 1:1 patid using "rawdata/stata/patient.dta", keepusing(yob gender)
		drop if _merge==2
		codebook patid
		drop _merge
	//generate and label year of birth
		rename yob cov_yob
		replace cov_yob=cov_yob+1800
		label variable cov_yob "year of birth"
	//generate YEAR OF PRESCRIPTION
		gen cov_Rx_year=year(Rx_eventdate)
		label variable cov_Rx_year "year of first smoking cessation Rx prescription"
	//generate age at time of first smoking cessation rx  prescription
		generate cov_age = .
		label variable cov_age "age at time of 1st smoking cessation Rx prescription"
		replace cov_age=  cov_Rx_year-cov_yob
		
	
		
//SEX
	//label sex
		rename gender cov_sex
		label variable cov_sex "sex"
		replace cov_sex=0 if cov_sex==1
		replace cov_sex=1 if cov_sex==2
		replace cov_sex=1 if cov_sex==3
		label define cov_sex 0 "male" 1 "female" 
		label values cov_sex cov_sex
	//save individual level data for age and sex and year of first prescription
		notes _dta: age, sex and year of first valid prescription of varenicline/nrt
		keep cov_sex cov_Rx_year cov_yob cov_age patid
		save "6_servicehealth/working_data/indiv_cov_age_sex_year.dta", replace
		codebook patid
		clear
	
	
//PREVIOUS PSYCHIATRIC ILLNESS, SELF HARM, ALCOHOL MISUSE, CHONIC ILLNESS(CHARLSTON), OR PREVIOUS USE OF PSYCHOTROPIC MEDICATIONS
	//define 'j' (medcode event)
		foreach j in charlson alcohol_misuse autism bipolar dementia depression drug_misuse eatingdis hyperkineticdis learningdis neuroticdis otherbehavdis persondis schizop selfharm{
			use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
			joinby patid using "tempdata/eventlist/eventlist_med_`j'.dta",unmatched(master)
			drop _merge
			compress
			gen cov_`j'_ever=(Rx_eventdate-clinical_eventdate>0 & clinical_event!=.)
			bys patid : egen cov_`j'_ever2=max(cov_`j'_ever)
			drop cov_`j'_ever
			rename cov_`j'_ever2 cov_`j'_ever
			bys patid:keep if _n==1
			keep patid cov_`j'_ever 
			compress
			save "6_servicehealth/working_data/indiv_cov_`j'.dta",replace
			}
		

	//extract all historical psychoactive medication prescription events
	//define 'j' (prodcode event)
		foreach j in  antidepres antipsyc cns_stim dementiameds hypnotics statins diabeticmeds anti_ht{
			use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
			joinby patid using "tempdata/eventlist/eventlist_prod_`j'.dta",unmatched(master)
			drop _merge
			compress
			gen cov_`j'_ever=(Rx_eventdate-clinical_eventdate>0 & clinical_event!=.)
			bys patid : egen cov_`j'_ever2=max(cov_`j'_ever)
			drop cov_`j'_ever
			rename cov_`j'_ever2 cov_`j'_ever
			bys patid:keep if _n==1
			keep patid cov_`j'_ever 
			compress
			save "6_servicehealth/working_data/indiv_cov_`j'.dta",replace
			}
		clear


//MEAN OR MEDIAN NUMBER OF GP VISITS PER YEAR
	//extract all eligble consultation types from consultation.dta files
		forvalues i=1(1)10{
			use  patid constype eventdate using "rawdata/stata/consultation_`i'.dta" ,clear
			keep patid constype eventdate
			rename eventdate consult_eventdate
			drop if consult_eventdate==.
			keep if inlist(constype, 1,9)
			compress
			save "6_servicehealth/working_data/consult_eventdate_`i'",replace
			}
			clear
	//append eligible consultation data and calculate mean number of gp visits per year, and drop if consultation date is after first eligible_smoking_cessation prescription
		
		forvalues i=1(1)10 {
			use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
			keep patid Rx_eventdate
			joinby patid using "tempdata/consult_eventdate_`i'", unmatched(master)			
			//drop consultations which occurred after prescription of varen/nrt, and drop consultations which occurred more than 1 year prior to first prescription of varen/nrt
			drop if consult_eventdate>=Rx_eventdate 
			keep if consult_eventdate >= Rx_eventdate-365.25
			drop _m
			compress
			save "6_servicehealth/working_data/consult_eventdate_`i'_rx.dta", replace
			}
	//append "consult_eventdate_eligible_`i'_rx.dta" files
		clear
		forvalues i=1(1)10 {		
			append using "tempdata/consult_eventdate_`i'_rx.dta"
			}	
		bys patid consult_eventdate:keep if _n==1	
		bys patid : gen cov_gp_visit=_N
		bys patid: keep if _n==1
		keep patid cov_gp_visit
		
	//merge with first eligible prescription patient data and replace missing gp visits with "0" to indicate that patients had no consultations within 1 year prior to varen/nrt prescription.
		joinby patid using "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", unmatched(using)
		replace cov_gp_visit=0 if cov_gp_visit==.
		keep patid cov_gp_visit*
	//save individual level data file
		label variable cov_gp_visit "average num of gp visits/year before first eligible nrt/varenic prescription"
		notes _dta: average num of gp visits/year before first prescription of varenicline
		save "6_servicehealth/working_data/indiv_cov_gpvisits.dta", replace
		codebook patid
		clear

		
//BODY MASS INDEX
	//create temporary files which contain all of the dates and adid from the clinical files
		forvalues i=1(1)14{
			use  patid adid eventdate using "rawdata/stata/clinical_`i'.dta" ,clear
			sort patid adid
			compress
			save "tempdata/adid_bmi_eventdate_`i'",replace
			}

	//merge in the adid and eventdate data into the bmi data from the additional table
		use patid enttype data3 adid if enttype==13 using "rawdata/stata/additional_1.dta" ,clear
		append using "rawdata/stata/additional_2.dta", keep(patid enttype data3 adid) 
		keep if enttype==13 
		destring data3, generate(data_3)
		keep if data_3!=.
	//drop BMIs which are abnormally low or high (Health Survey for England - http://www.noo.org.uk/uploads/doc/vid_11515_Adult_Weight_Data_Briefing.pdf)
		drop if data_3<12
		drop if data_3>50
		drop data3 enttype
		compress
		gen _merge_final=.
		forvalues i=1(1)14{
			joinby patid adid using "tempdata/adid_bmi_eventdate_`i'.dta" ,unmatched(master) update
			replace _merge_final=3 if _merge==3
			drop _merge
			}
		drop _merge_final
		rename data_3 cov_bmi
		rename eventdate bmi_eventdate
		compress
		save "tempdata/bmi_additional_data_eventdate",replace
		
	//joinby bmi data with eligible patients data
		use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
		codebook patid
		joinby patid using  "tempdata/bmi_additional_data_eventdate",  unmatched(both)
		codebook patid
	//drop missing dates
		drop if bmi_eventdate==.
		drop if Rx_eventdate==. 
	//drop if bmi was recorded after varencilince/nrt prescription
		drop if bmi_eventdate>=Rx_eventdate 
	//drop all bmi recordings except the recording closest to first prescription of varenicline/nrt
		codebook patid
		bys patid (bmi_eventdate) : generate bmieventdate_n = _n
		by patid (bmi_eventdate) : drop if _n !=_N
		codebook patid
		keep patid cov_bmi
		notes _dta: bmi before first prescription of varenicline
	//link to first eligible smoking preciption file
		joinby patid using "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", unmatched(using)
		keep patid cov_bmi
	//save individual level bmi data file
		save "6_servicehealth/working_data/indiv_cov_bmi.dta", replace
		codebook patid
		clear
	
	
//INDEX OF MULTIPLE DEPRIVATION SCORE (IMD)

	//extract Index of Multiple Deprivation from linked data
		import delimited "rawdata/all_smokers_dta/disk1/Linked_Data/15_107RMnA_Request 1_Smoking Cessation/Results/patient_imd2010_15_107RMnA_Request 1_Smoking Cessation.txt"
		keep patid imd2010_20
		save "tempdata/tempSES.dta",replace
		use "6_servicehealth/working_data/HES_first_eligible_smoking_cessation_Rx", clear
		codebook patid
		merge 1:1 patid using "tempdata/tempSES.dta"
		drop if _merge==2
		codebook patid
		keep patid imd2010_20
	//label IMD
		rename imd2010_20 cov_imd
		label variable cov_imd "index of multiple deprivation score 20=most deprived, 1=least deprived"
		save "6_servicehealth/working_data/indiv_cov_imd.dta", replace
		codebook patid
		clear
	


//CREATE ONE INDIVIDAL LEVEL DATA SET FOR ALL COVARIATES
		set more off
		use  "6_servicehealth/working_data/indiv_cov_autism.dta", clear
		foreach j in age_sex_year imd gpvisits bmi charlson alcohol_misuse bipolar dementia depression drug_misuse eatingdis hyperkineticdis learningdis neuroticdis otherbehavdis persondis schizop selfharm charlson antidepres antipsyc cns_stim dementiameds hypnotics statins diabeticmeds anti_ht{
			joinby patid using "6_servicehealth/working_data/indiv_cov_`j'.dta", unmatched(both)
			tab _m
			drop _m
			}

		notes _dta: all covariates for valid cohort
		save "6_servicehealth/working_data/indiv_cov_all.dta", replace
		
