//Neil Davies 13/11/15
//This gives a basic clean to all the CPRD GOLD files for the NIHR project

cd "/Users/ecnmd/Desktop/untitled folder"

cap prog drop date
prog def date
foreach k in eventdate sysdate chsdate frd crd tod deathdate uts lcd{
	cap{
		gen `k'2 = date(`k', "DMY")
		format %td `k'2
		drop `k'
		rename `k'2 `k'
		replace `k'=. if `k'>150000
		}
	}
end 

//Loop for the clinical, consultation, immunisation, referral, test and therapy files
foreach i in Clinical Consultation Immunisation Refferral Test Therapy Patient Practice Additional Staff{
	local n=1
	fs "*`i'*"	
	foreach f in `r(files)' {
		import delimited "`f'",clear
		date
		compress
		save "stata/`i'_`n'",replace
		local n=`n'+1
		}
	}
