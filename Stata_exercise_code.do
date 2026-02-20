/* define the folder path and import data */
clear all
global file_path "/Users/fengcheng/Downloads/consumption.txt"
global result_path "/Users/fengcheng/Downloads"

import delimited "$file_path",  delimiter(space, collapse) varnames(1) 

	
/* prepare variables */
egen t = group(year qtr)
tsset t
gen lnrealco=log(realcons)
gen lnrealdpi=log(realdpi)
gen lnrealdpi_lag  = L.lnrealdpi
gen lnrealco_lag = L.lnrealco

/* ── (1) OLS with robust SE ── */
reg lnrealco lnrealdpi tbilrate lnrealco_lag , vce(r)
est store ols
estadd local  robust_se "Yes"
estadd scalar endo_p = .

/* ── (2) IV with robust SE ── */
ivregress 2sls lnrealco (lnrealdpi = lnrealdpi_lag) tbilrate lnrealco_lag, vce(r)
est store iv
estat endogenous
estadd scalar endo_p = r(p)
estadd local  robust_se "Yes"


/* ── (3) OLS without robust SE ── */
reg lnrealco lnrealdpi tbilrate lnrealco_lag
est store betasOLS
estadd local  robust_se "No"
estadd scalar endo_p =.

/* ── (4) IV without robust SE ── */
ivregress 2sls lnrealco (lnrealdpi = lnrealdpi_lag) tbilrate lnrealco_lag
est store betasIV
hausman betasIV betasOLS
estadd scalar endo_p = r(p)
estadd local  robust_se "No"

/* ── Export table ── */
esttab ols iv betasOLS betasIV using "$result_path/results_compare.tex", replace          ///
    style(tex) booktabs                                                       ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)                                ///
    numbers                                                                   ///
    mtitle("OLS" "IV (2SLS)" "OLS" "IV (2SLS)")                             ///
    mgroups("Robust SE" "Standard SE",                                       ///
            pattern(1 0 1 0)                                                 ///
            prefix(\multicolumn{@span}{c}{) suffix(})                        ///
            span erepeat(\cmidrule(lr){@span}))                              ///
    coeflabels(lnrealdpi      "\$logged\$ Real Disposable Income"                                       ///
               tbilrate      "90-day T bill rate"                             ///
               lnrealco_lag "\$logged\$ Lagged Real Consumption"                        ///
               _cons        "Constant")                                      ///
    scalars("robust_se Robust SE"                                            ///
            "r2 \$R^{2}\$"                                                   ///
            "endo_p Endogeneity \$p\$-value")                                ///
    sfmt(%9s %9.3f %9.3f)                                                    ///
    title("Regression Results of Real Consumption: Standard vs. Robust Standard Errors"        ///
          "\label{tab:results_compare}")                                      ///
    nonote compress nogap
 
