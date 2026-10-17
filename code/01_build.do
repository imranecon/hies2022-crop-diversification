*==============================================================================
* 01_build.do
*
* Input : $data/x.dta  (raw HIES 2022 files from BBS)
* Output: $derived/hh_merged.dta
*
* Households are identified by PSU and HHID.
*==============================================================================

*-- 1. Crops cultivated and crop sales (Section 7B, one row per crop) --------
use "$data/HH_SEC_7B.dta", clear
gen byte cultivated = (s7bq02 == 1)
collapse (sum) crop_count = cultivated crop_income = s7bq06, by(PSU HHID)
tempfile sec7b
save `sec7b'

*-- 2. Wage and salary income (Section 4) ------------------------------------
use "$data/HH_SEC_4A.dta", clear
gen double wage_ann = s4bq16 * 12
replace wage_ann = s4bq10c * s4aq03 * s4aq02 if missing(wage_ann)
collapse (sum) wage_income = wage_ann, by(PSU HHID)
tempfile sec4a
save `sec4a'

*-- 3. Non-agricultural enterprise income (Section 5) ------------------------
use "$data/HH_SEC_05.dta", clear
collapse (sum) enterprise_inc = s5q20, by(PSU HHID)
tempfile sec05
save `sec05'

*-- 4. Household head: sex, age and education (Sections 1A1 and 2A) ----------
use "$data/HH_SEC_1A1.dta", clear
bysort PSU HHID: egen n_heads = total(S1AQ02 == 1)
display as text "Number of heads reported per household:"
tab n_heads
keep if S1AQ02 == 1 & n_heads == 1

gen byte head_female = (S1AQ01 == 2) if !missing(S1AQ01)
gen head_age = S1AQ03
rename S1AQ00 S2AQ00                       // member ID, named as in Section 2A
keep PSU HHID S2AQ00 head_female head_age

* 1:1 merge fails if Section 2A has more than one row per member
merge 1:1 PSU HHID S2AQ00 using "$data/HH_SEC_2A.dta", ///
    keepusing(S2AQ04) keep(master match)
display as text "Heads matched to education records:"
tab _merge
drop _merge
rename S2AQ04 head_educ
drop S2AQ00
tempfile heads
save `heads'

*-- 5. Land owned (Section 7A) -----------------------------------------------
use "$data/HH_SEC_7A.dta", clear
capture isid PSU HHID
if _rc {
    display as error "HH_SEC_7A has more than one row per household. " ///
        "Decide how to aggregate it (e.g. sum over plots) before merging."
    exit 459
}
keep PSU HHID S7AQ01
tempfile sec7a
save `sec7a'

*-- 6. Other household income (Section 8B) -----------------------------------
use "$data/HH_SEC_8B.dta", clear
capture isid PSU HHID
if _rc {
    display as error "HH_SEC_8B has more than one row per household. " ///
        "Decide how to aggregate it before merging."
    exit 459
}
keep PSU HHID S8BQ08
tempfile sec8b
save `sec8b'

*-- 7. Bank or MFI account (Section 8D1) -------------------------------------
use "$data/HH_SEC_8D1.dta", clear
gen byte any_account = (S8D1Q01 == 1 | S8D1Q02 == 1)
collapse (max) credit_access = any_account, by(PSU HHID)
tempfile sec8d1
save `sec8d1'

*-- 8. Survey weights --------------------------------------------------------
use "$data/weight_final_2022.dta", clear
isid PSU HHID
keep PSU HHID hh_wgt stratum16
tempfile weights
save `weights'

*-- 9. Base file and merges --------------------------------------------------
use "$data/HH_SEC_1A.dta", clear
isid PSU HHID
rename MEMBER     hh_size
rename urbrural   rural_urban
rename ID_01_CODE division
keep PSU HHID hh_size rural_urban division

foreach f in weights sec7b sec4a sec05 heads sec7a sec8b sec8d1 {
    merge 1:1 PSU HHID using ``f'', keep(master match) gen(_m)
    display as text "Merge with `f':"
    tab _m
    drop _m
}

compress
save "$derived/hh_merged.dta", replace
