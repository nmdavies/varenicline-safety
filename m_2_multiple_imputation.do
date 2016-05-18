//Neil Davies 20/01/2016
//This runs the imputation on the IMD and BMI variables:

use  "6_servicehealth/working_data/analysis_dataset",clear

//Need to impute the IMD and BMI variables.

mi set mlong

mi misstable sum

order iv cov_bmi cov_imd
ice history follow_up  cov_gp_visit-cov_anti_ht_ever rx_year_1-rx_year_9  cov_bmi o.cov_imd, saving("6_servicehealth/working_data/effectabstinence_imputed_1",replace) m(20) seed(12345) 

use "6_servicehealth/working_data/effectabstinence_imputed_1", clear
mi unset
mi import ice, automatic clear 

mi unregister iv-_Icov_imd_20
mi register regular iv patid-out_ons_resp_3
mi register imputed _Icov_imd_2-_Icov_imd_20 cov_imd cov_bmi 
mi describe

compress
save "6_servicehealth/working_data/effectabstinence_imputed_1",replace
