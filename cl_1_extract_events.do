//UPDATE 18/11/15// Neil Davies 13/11/15
//This cleans the varenicline therapy files to get all the varenicline prescription events:

cap prog drop extract_events
prog def extract_events
cap ssc install fs
if "`1'"=="med"{
	local files ""
	foreach j in clinical referral test{
		cd "`2'`3'"
		fs "`j'*"		
		foreach f in `r(files)' {
			cd "`2'"
			use "`3'/`f'",clear
			joinby medcode using "codelists/statalists/`4'.dta" 
			compress
			rename eventdate clinical_eventdate
			keep patid medcode clinical_eventdate
			save "tempdata/`f'_eventlist_`4'.dta", replace
			local files : list  f | files
			di "`files'"
			}
		}
	foreach i in `files'{
		append using "tempdata/`i'_eventlist_`4'.dta"
		rm "tempdata/`i'_eventlist_`4'.dta"
		}
	}
	
if "`1'"=="prod"{
	cd "`2'`3'/
	local files ""
	foreach j in therapy{
		fs "`j'*"	
		
		foreach f in `r(files)' {
			cd "`2'"
			use "`3'/`f'",clear
			joinby prodcode using "codelists/statalists/`4'" 
			compress
			rename eventdate clinical_eventdate
			keep patid prodcode staffid clinical_eventdate
			save "tempdata/`f'_eventlist_`4'.dta", replace
			local files : list  f | files		
			}
		}
	foreach i in `files'{
		append using "tempdata/`i'_eventlist_`4'.dta"
		rm "tempdata/`i'_eventlist_`4'.dta"
		}
	}
duplicates drop
save "tempdata/eventlist_`1'_`4'.dta", replace
end 

//The syntax of the program is:

//extract_events [med|prod] [main project directory] [raw data directory] [drug or medical type]

//You need to have a stata code list called event.dta in the codelist directory. E.g. in the example below it's "smoke", this extracts all the smoking events.
//In future we may be able to get rid of drug type.

//For this dataset to extract other clinical events, all we need to do is change "smoke" to "dementia"
//To extract other therapy events, all we need to do is change med to prod and "smoke" to "varenicline".

//example* extract_events med "z:/" "old files/raw_mhra_data/"  varenicline smoke
//example* extract_events med "z:/" "old files/raw_mhra_data/"  nrt smoke

//Update med files - replace any missing medcodes by matching with readcodes from medical.txt

//Extract all of the events:

foreach i in /* lithium nrt varenicline buproprion antidepres antipsyc cns_stim dementiameds hyp_anxioly */ antihypertensives statins diabeticmeds{
	extract_events prod "/Volumes/Varenicline_CPRD/" "rawdata/stata" `i'
	}
	
foreach i in /*  current_smokers alcohol_misuse smoke autism bipolar current_smokers dementia depression eatingdis hyperkineticdis learningdis neuroticdis otherbehavdis persondis schizop fractures selfharm mi charlson*/ mi{
	
	extract_events med  "/Volumes/Varenicline_CPRD/" "rawdata/stata"  `i'
	}
