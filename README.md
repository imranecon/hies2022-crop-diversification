# Crop diversification and household income in rural Bangladesh

This repository has the Stata code for a cross-sectional analysis of whether rural farming households that grow more kinds of crops earn more. It uses the Household Income and Expenditure Survey (HIES) 2022 from the Bangladesh Bureau of Statistics (BBS).

The results are associations, not causal effects. Households choose how many crops to grow, and that choice is likely tied to land quality, market access and wealth that the controls do not fully capture.

## Question

Is the number of crops a household cultivates associated with higher total household income and higher crop income, once land, household head characteristics, household size, access to financial services and division are controlled for?

## Data

The code uses HIES 2022 household and individual microdata. **The data are not included in this repository.** BBS distributes HIES microdata on request and under its own terms of use, so you need to obtain the files from BBS yourself.

Place the following files in `data/` before running the code:

| File | Content used |
|---|---|
| `HH_SEC_1A.dta` | Household size, rural/urban, division |
| `HH_SEC_1A1.dta` | Member roster: head’s sex, age and member ID |
| `HH_SEC_2A.dta` | Education: head’s education |
| `HH_SEC_4A.dta` | Wage and salary income |
| `HH_SEC_05.dta` | Non-agricultural enterprise income |
| `HH_SEC_7A.dta` | Cultivable land owned |
| `HH_SEC_7B.dta` | Crops cultivated and crop sales |
| `HH_SEC_8B.dta` | Other household income |
| `HH_SEC_8D1.dta` | Bank and microfinance accounts |
| `weight_final_2022.dta` | Household weights and strata |

Households are identified by `PSU` and `HHID`.

## Sample

The analysis sample is rural households that cultivated at least one crop, with non-negative total income and non-missing values on the head’s education, age and sex, household size, land and survey weight. The final sample has [N] households.

All households stay in the analysis file, and the sample is flagged with `insample`. Survey estimates use `svy, subpop(insample)`, which gives correct standard errors for a subpopulation; dropping the other households first would not.

## Variables

The main outcome is log total household income: the sum of wage income, enterprise income, crop sales and other income from Section 8B, top-coded at the survey-weighted 99th percentile within the sample. The second outcome is log crop sales income, top-coded the same way.

The main explanatory variable is the number of crops the household cultivated. The controls are cultivable land owned, the head’s education, age and sex, household size, whether any member has a bank or MFI account, and division fixed effects.

## Methods

The survey design is declared with `svyset PSU [pw=hh_wgt], strata(stratum16)`. The code produces:

- weighted means for all sample households and separately for single-crop and multi-crop households (Table 1)
- weighted differences in log income and log crop income between the two groups, with design-based standard errors (Table 2), plus unweighted Wilcoxon rank-sum tests in the log
- four figures on crop count and income
- regressions of log income and log crop income on crop count, controls and division fixed effects (Table 3). Models 1 and 2 are survey-weighted; Model 3 repeats Model 1 without weights, with standard errors clustered by PSU, as a check
- variance inflation factors for the regressors

## Repository structure

```
.
├── master.do            Sets paths, installs estout, runs all scripts
├── code/
│   ├── 01_build.do      Merges survey sections into one household file
│   ├── 02_clean.do      Builds variables and flags the analysis sample
│   └── 03_analysis.do   Tables, tests, figures and regressions
├── data/                Raw HIES files go here (not tracked)
│   └── derived/         Intermediate files created by the code (not tracked)
└── output/
    ├── tables/
    ├── figures/
    └── logs/            (not tracked)
```

The build script checks that each household-level file has one row per household and reports match rates for every merge. If a file that should be household-level has duplicate rows, the code stops with a message instead of dropping rows.

## How to run

1. Get the HIES 2022 files from BBS and copy them into `data/`.
2. Open `master.do` and set the root path to the folder where you cloned this repository:
   ```stata
   global root "C:/path/to/hies2022-crop-diversification"
   ```
3. Run `master.do`. It installs `estout` from SSC if it is missing, runs the three scripts in order, and writes a log to `output/logs/master.log`.

The code requires Stata 16 or later and was tested in Stata [version].

## Main results

[Add two or three sentences on the crop-count coefficient in Models 1 and 2: its size, its precision, and whether Model 3 changes it.]

![Income by number of crops cultivated](output/figures/fig1_income_by_cropgroup.png)

## Limitations

The data are a single cross-section, so the estimates cannot separate the effect of diversification from the characteristics of households that diversify. Crop income covers sales only and leaves out crops kept for home consumption, which understates farm output for subsistence households. Crop count also treats a small vegetable plot and a main rice crop the same way; a share-based index such as a Herfindahl or Simpson index would capture concentration better.

## Author

Imran Hossain
Research Associate, BRAC Institute of Governance and Development (BIGD), BRAC University
[email or website link]

## License

The code is released under the MIT License. The HIES data belong to BBS and are subject to its terms of use.
