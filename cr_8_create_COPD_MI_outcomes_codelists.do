//Neil Davies 12/02/16
//This combines the list of cardiovascular disease codes used in Davies et al. (2013) with newer codes downloaded from https://clinicalcodes.rss.mhs.man.ac.uk

//Convert CPRD medical browser to Stata format:

import delimited "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical.txt", encoding(ISO-8859-1)clear
rename _09 medcode 
rename v2 readcode	
rename v3 clinicalevents	
rename v4 	immunisationevents
rename v5 	referralevents
rename v6 	testevents
rename v7 readterm	
rename v8 databasebuild
save "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical", replace

//Load old code list (taken from codes_davies_et_al_nmd_160113.xlsx), original worksheet codebook_13_05_11.xlxs, worksheet ischaemic heart disease.

use "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/codes_davies_et_al_nmd_160113.dta",clear
//Merge with latest code list to update terms:

keep medcode

joinby medcode using "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical", unmatched(master)

save "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/codes_davies_et_al_updated_nmd_160113.dta",replace

//Match codelist from clinical codes to the code browser:

use "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/mi_readcodes_rss.dta",clear

joinby readcode using "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical", unmatched(master)
tab _m

//Two non-OXMIS codes are not in the latest version of the medical browser. Will keep all matched codes:

keep if _me==3

keep readcode medcode clinicalevents-databasebuild

joinby medcode using "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/codes_davies_et_al_updated_nmd_160113.dta",unmatched(both) _merge(_merge2)

keep if _merge2!=1
drop _m*

//Four additional codes.
/*
readterm
Cardiac syndrome X
Postoperative transmural myocardial infarction unspec site
[X]Subsequent myocardial infarction of other sites
Asystole
*/
//Will save matched codes and update using search terms indicated in codebook_13_05_11.xlxs.

save "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/cvd_codes_merged_nmd_160113.dta",replace

/* Will use the following search terms in the latest code browser */
/*
*angina*	
*cardi*
*electromechanical dissociation*
*coronary*
*scleroti*
*dressler*	
*heart*
*thrombosis*
*infarct*
*atheroma*
*ischaemi*
*carotid*
*myocard*	
*atrial*
*/

use "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical",clear
replace readterm=lower(readterm)
gen poss_cvd=0
foreach i in angina cardi coronary scleroti dressler heart thrombosis infarct atheroma ischaemi ischemi carotid myocard atrial electromechanical{
	gen X=strpos(readterm, "`i'")
	replace poss_cvd=1 if X!=0
	drop X
	}
keep if poss_cvd!=1
save  "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/new_cvd_codes_merged_nmd_160113.dta",replace
//The max medcode in the previous list is 99991. Therefore will review all possible codes which are higher than this.
//This results in 223 possible additional codes

//Next I update the code list reported in Quint et al. (2014) They report the following codes are specific for COPD:
/*
18476
45771
4084
794
998
1001
5710
9520
9876
10802
10863
10980
11287
14798
18621
18792
23492
26018
26306
28755
33450
34202
34215
37247
37371
44525
45998
93568
12166
38074
42258
45777
42313
45770 
*/
use "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/copd_medcodes_quint_nmd_160113.dta",clear
joinby medcode using "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical",unmatched(master)
save "/Volumes/varenicline_CPRD/codelists/clinicalcodes.rss/cardiac/copd_readterms_quint_nmd_160113.dta",replace

//Below I search the medical dictionary for codes indicating COPD. I use the following terms, which would pick up all codes
//reported by Quint et al: "COPD" "chronic obstr" "emphysema"

use "/Volumes/varenicline_CPRD/rawdata/Code_Browser/medical",clear
replace readterm=lower(readterm)
gen poss_copd=0
replace poss_copd=1 if strpos(readterm, "copd")!=0
replace poss_copd=1 if strpos(readterm, "chronic obstr")!=0
replace poss_copd=1 if strpos(readterm, "emphysema")!=0

keep if poss_copd==1

//This finds 106 codes. The max medcode reported by Quint et al. is 93568. Therefore will limit search to codes higher than this.

sort medcode

keep if medcode>93568

//Save this to spreadsheet of codelists.
