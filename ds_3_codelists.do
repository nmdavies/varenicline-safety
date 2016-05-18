//Neil Davies 27/04/16
//This creates the code lists for the paper


import delimited "/Volumes/varenicline_CPRD/rawdata/nihr/Code_Browser/medical.txt", encoding(ISO-8859-1)clear
rename _09 medcode
joinby medcode using "codelists/statalists/mi.dta", unmatched(using)

import delimited "/Volumes/varenicline_CPRD/rawdata/nihr/Code_Browser/medical.txt", encoding(ISO-8859-1)clear
rename _09 medcode
joinby medcode using "codelists/statalists/copd.dta", unmatched(using)
sort medcode
browse medcode readterm

import delimited "/Volumes/varenicline_CPRD/rawdata/nihr/Code_Browser/product.txt", encoding(ISO-8859-1)clear
rename _09 prodcode
joinby prodcode using "codelists/statalists/statins.dta", unmatched(using)
sort prodcode
order prodcode v4
browse prodcode v4

import delimited "/Volumes/varenicline_CPRD/rawdata/nihr/Code_Browser/product.txt", encoding(ISO-8859-1)clear
rename _09 prodcode
joinby prodcode using "codelists/statalists/antihypertensives.dta", unmatched(using)
sort prodcode
order prodcode v4
browse prodcode v4

import delimited "/Volumes/varenicline_CPRD/rawdata/nihr/Code_Browser/product.txt", encoding(ISO-8859-1)clear
rename _09 prodcode
joinby prodcode using "codelists/statalists/diabeticmeds.dta", unmatched(using)
sort prodcode
order prodcode v4
browse prodcode v4
