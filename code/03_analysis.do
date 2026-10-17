*==============================================================================
* 03_analysis.do
* Descriptive statistics, group comparisons, figures and regressions.
*
* Input : $derived/hh_analysis.dta
* Output: $out/tables/*.rtf, $out/figures/*.png
*
*==============================================================================

use "$derived/hh_analysis.dta", clear
svyset PSU [pw=hh_wgt], strata(stratum16) singleunit(scaled)

local controls land_owned head_educ head_age head_female hh_size credit_access
local sumvars  ln_income ln_crop_income crop_count `controls'

*==============================================================================
* Table 1: Weighted means, all households and by crop diversification
*==============================================================================
eststo clear
eststo all:    svy, subpop(insample): mean `sumvars'
estadd scalar n_hh = e(N_sub) : all
eststo single: svy, subpop(insample if multi_crop == 0): mean `sumvars'
estadd scalar n_hh = e(N_sub) : single
eststo multi:  svy, subpop(insample if multi_crop == 1): mean `sumvars'
estadd scalar n_hh = e(N_sub) : multi

esttab all single multi using "$out/tables/table1_descriptives.rtf", replace ///
    cells(b(fmt(2)) se(fmt(2) par)) label nonumbers                          ///
    mtitles("All" "Single crop" "Multi crop")                                ///
    stats(n_hh, labels("Households") fmt(0))                                 ///
    title("Table 1. Weighted means, rural farming households")               ///
    note("Survey-weighted means. Linearised standard errors in parentheses.")

tab crop_count if insample

*==============================================================================
* Table 2: Income differences between multi-crop and single-crop households
*==============================================================================
eststo clear
eststo d1: svy, subpop(insample): regress ln_income      i.multi_crop
eststo d2: svy, subpop(insample): regress ln_crop_income i.multi_crop

esttab d1 d2 using "$out/tables/table2_differences.rtf", replace            ///
    keep(1.multi_crop) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label       ///
    mtitles("Log income" "Log crop income")                                 ///
    title("Table 2. Multi-crop minus single-crop households")               ///
    note("Survey-weighted. Linearised standard errors in parentheses.")

* Unweighted non-parametric check
ranksum ln_income      if insample, by(multi_crop)
ranksum ln_crop_income if insample, by(multi_crop)

*==============================================================================
* Figures
*==============================================================================
*-- Figure 1: Mean log income by crop count group (weighted) ------------------
graph bar (mean) ln_income if insample [aw=hh_wgt],                          ///
    over(crop_group) bar(1, fcolor(navy%75))                                 ///
    ytitle("Mean log household income")                                      ///
    title("Figure 1: Income by number of crops cultivated")                  ///
    note("Survey-weighted means.")                                           ///
    blabel(bar, format(%5.2f)) graphregion(color(white))
graph export "$out/figures/fig1_income_by_cropgroup.png", replace width(1200)

*-- Figure 2: Distribution of crop count (unweighted) -------------------------
histogram crop_count if insample, discrete frequency                         ///
    fcolor(navy%70) lcolor(white)                                            ///
    xtitle("Number of crops cultivated") ytitle("Number of households")      ///
    title("Figure 2: Distribution of crop count")                            ///
    note("Unweighted sample counts.") graphregion(color(white))
graph export "$out/figures/fig2_crop_count_distribution.png", replace width(1200)

*-- Figure 3: Crop count and log income ---------------------------------------
twoway (scatter ln_income crop_count if insample, mcolor(navy%25) msize(small))   ///
       (lfit    ln_income crop_count if insample [aw=hh_wgt],                     ///
                lcolor(maroon) lwidth(medthick)),                                 ///
    xtitle("Number of crops cultivated") ytitle("Log total household income")     ///
    title("Figure 3: Crop count and household income")                            ///
    legend(order(1 "Households" 2 "Weighted linear fit"))                         ///
    graphregion(color(white))
graph export "$out/figures/fig3_scatter_crop_income.png", replace width(1200)

*-- Figure 4: Mean log income by division and crop diversification -----------
graph bar (mean) ln_income if insample [aw=hh_wgt],                          ///
    over(multi_crop) over(division, label(angle(45))) asyvars                ///
    ytitle("Mean log household income")                                      ///
    title("Figure 4: Income by division and crop diversification")           ///
    note("Survey-weighted means.") graphregion(color(white))
graph export "$out/figures/fig4_division_crop_income.png", replace width(1400)

*==============================================================================
* Table 3: Regressions
*==============================================================================
eststo clear

* Model 1: total household income, survey-weighted
eststo m1: svy, subpop(insample): regress ln_income crop_count `controls' i.division
estadd scalar n_hh = e(N_sub) : m1

* Model 2: crop sales income, survey-weighted
eststo m2: svy, subpop(insample): regress ln_crop_income crop_count `controls' i.division
estadd scalar n_hh = e(N_sub) : m2

* Model 3: Model 1 unweighted, standard errors clustered by PSU
eststo m3: regress ln_income crop_count `controls' i.division if insample, vce(cluster PSU)
estadd scalar n_hh = e(N) : m3

esttab m1 m2 m3 using "$out/tables/table3_regressions.rtf", replace         ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label nobaselevels             ///
    indicate("Division FE = *.division")                                    ///
    mtitles("Log income" "Log crop income" "Log income (unweighted)")       ///
    stats(n_hh, labels("Households") fmt(0))                                ///
    title("Table 3. Crop count and household income")                       ///
    note("Models 1-2: survey-weighted, design-based standard errors. "      ///
         "Model 3: unweighted OLS, standard errors clustered by PSU.")

*-- Multicollinearity check (VIF depends only on the regressors) -------------
quietly regress ln_income crop_count `controls' i.division if insample
estat vif
