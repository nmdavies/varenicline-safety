//Neil Davies 13/01/16
//This runs the descriptive statistics and analysis for the service use paper:


use  "6_servicehealth/working_data/analysis_dataset",clear

//Generate mi and copd covariates
gen cov_mi=(out_fu_mi<=0)
gen cov_copd=(out_fu_copd<=0)

//Create a program for adding results to the matrix

cap prog drop table1
prog def table1
if "`2'"=="median"{
	local options="median iqr"
	}
if "`2'"=="count"{
	local options="sum mean"
	}
tabstat `1' if dr_varenicline==0,save stats(`options')
matrix R1=R1\r(StatTotal)'
tabstat `1' if dr_varenicline==1,save stats(`options')
matrix R2=R2\r(StatTotal)'
tabstat `1' ,save stats(`options')
matrix R3=R3\r(StatTotal)'

end

//Create basic statistics for Table 1
//Create results matrix


//Male
tabstat cov_male if dr_varenicline==0 ,save stats(sum mean)
matrix R1=r(StatTotal)'
tabstat cov_male if dr_varenicline==1,save stats(sum mean)
matrix R2=r(StatTotal)'
tabstat cov_male ,save stats(sum mean)
matrix R3=r(StatTotal)'

//Age

table1 cov_age median
table1 cov_bmi median
foreach i in cov_alcohol_misuse_ever cov_drug_misuse_ever cov_imd_least_deprived cov_imd_most_deprived {
	table1 `i' count
	}

table1 cov_gp_visit median

foreach i in cov_rx_before_2009 cov_hypnotics_ever cov_antipsyc_ever cov_antidepres_ever cov_statins_ever cov_anti_ht_ever cov_diabeticmeds_ever cov_selfharm_ever cov_mi cov_copd cov_charlson_ever{
	table1 `i' count
	}
tab dr_varenicline
matrix R=R1,R2,R3

svmat R

foreach i in R2 R4 R6{
	replace `i'=`i'*100 if `i'<1
	}

matrix li R

export excel R? using "6_servicehealth/results/table_1" if _n<20, firstrow(variables) replace

//Create supplementary Table 2, comparison of imputed and non-imputed data

//Create table comparing observed and imputed datasets.
use "6_servicehealth/working_data/effectabstinence_imputed_1", clear

mean cov_bmi if _mi_m==0
mean cov_imd if _mi_m==0

mi stset, clear

mi est: mean cov_bmi cov_imd 
compress
