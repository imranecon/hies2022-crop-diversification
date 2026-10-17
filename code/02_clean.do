*==============================================================================
* 02_clean.do
* Builds analysis variables and flags the analysis sample.
*
* Input : $derived/hh_merged.dta
* Output: $derived/hh_analysis.dta
*
*==============================================================================

use "$derived/hh_merged.dta", clear

*-- Location -----------------------------------------------------------------
gen byte rural = (rural_urban == 1) if !missing(rural_urban)

*-- Income -------------------------------------------------------------------
rename S8BQ08 other_income
foreach v in wage_income enterprise_inc crop_income other_income {
    replace `v' = 0 if missing(`v')
}
gen double total_income = wage_income + enterprise_inc + crop_income + other_income
count if total_income < 0
display as text "Households with negative total income: " r(N)

*-- Farm and household controls ---------------------------------------------
replace crop_count = 0 if missing(crop_count)
* NOTE: missing land is treated as no land owned
gen land_owned = S7AQ01
replace land_owned = 0 if missing(land_owned)
replace credit_access = 0 if missing(credit_access)
drop S7AQ01

*-- Analysis sample: rural households that cultivated at least one crop -------
gen byte insample = rural == 1 & crop_count > 0 & total_income >= 0 & ///
    !missing(head_educ, head_age, head_female, hh_size, land_owned, hh_wgt)
count if insample
display as text "Analysis sample: " r(N) " rural farming households"

*-- Top-code income at the weighted 99th percentile, within the sample -------
foreach v in total_income crop_income {
    _pctile `v' [pw=hh_wgt] if insample, p(99)
    gen double `v'_w = min(`v', r(r1)) if insample
}
gen ln_income      = ln(total_income_w + 1)
gen ln_crop_income = ln(crop_income_w + 1)

*-- Groups -------------------------------------------------------------------
gen byte multi_crop = (crop_count > 1) if insample
label define multi_lbl 0 "Single crop" 1 "Multi crop"
label values multi_crop multi_lbl

gen byte crop_group = min(crop_count, 4) if insample
label define cropgrp_lbl 1 "1 crop" 2 "2 crops" 3 "3 crops" 4 "4+ crops"
label values crop_group cropgrp_lbl

*-- Labels -------------------------------------------------------------------
label var ln_income      "Log total household income"
label var ln_crop_income "Log crop sales income"
label var total_income_w "Total household income (top-coded)"
label var crop_income_w  "Crop sales income (top-coded)"
label var crop_count     "Number of crops cultivated"
label var multi_crop     "Cultivates more than one crop"
label var crop_group     "Crop count group"
label var land_owned     "Cultivable land owned"
label var head_educ      "Head's education"
label var head_age       "Head's age (years)"
label var head_female    "Female head"
label var hh_size        "Household size"
label var credit_access  "Bank or MFI account"
label var rural          "Rural household"
label var insample       "In analysis sample"

compress
save "$derived/hh_analysis.dta", replace
