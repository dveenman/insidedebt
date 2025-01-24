global path "C:\...\...\..."


////////////////////////////////////////////////////////////////
/* Additional external ado-programs required to run code (versions identified with command "which PROGRAMNAME.ado"):

ssc inst ftools         // Required for reghdfe program (see below)
    *! version 2.49.1 08aug2023
ssc inst reghdfe        // For fixed effects estimation and two-way clustering of standard errors
    *! version 6.12.3 08aug2023
ssc inst winsor2        // Winsorization program
    *! 1.1 2014.12.16
ssc inst outreg2        // To export regression results
    *! outreg2 2.3.2  17aug2014 by roywada@hotmail.com
ssc inst robreg         // For quantile regression (sensitivity test)
    *! version 2.0.8  18sep2021  Ben Jann
ssc inst egenmore       // For by-group calculation of correlation (Dhole et al. smoothing measure)
    See https://ideas.repec.org/c/boc/bocode/s386401.html
ssc inst ranktest       // Required for ivreg2 program (see below)
    *! ranktest 2.0.04  21sept2020
ssc inst ivreg2         // Used to obtain Kleibergen/Paap statistic after 2SLS (Dhole et al. replication)
    *! ivreg2 4.1.12  14aug2024
ssc inst moremata       // Required for bootstep program (see below)
    See https://ideas.repec.org/c/boc/bocode/s455001.html
bootstep                // Available in "ado" subfolder of this repository, for latest version see: https://github.com/dveenman/bootstep
    *! version 1.2.1 20241217 David Veenman
*///////////////////////////////////////////////////////////////


*****************************************************************
* Construct CRSP/Compustat sample of firm-years
*****************************************************************
    use "$path\InFiles\ccmxpf_lnkhist.dta", clear
    drop if lpermno==.
    keep if linktype=="LU" | linktype=="LC"
    keep if linkprim=="P" | linkprim=="C"
    replace linkenddt=24000 if linkenddt==.
    destring gvkey, replace
    sort gvkey linkdt
    keep gvkey lpermno lpermco linkdt linkenddt 
    save "$path\OutFiles\ccmxpf_lnkhist_sorted.dta", replace

    use "$path\InFiles\funda.dta", clear
    keep if indfmt=="INDL" & consol=="C" & popsrc=="D" & datafmt=="STD" & curcd=="USD"
    drop if at==.
    drop if at<=0
    destring gvkey, replace
    egen gr=group(gvkey fyear)
    egen count=count(gr), by(gr) 
    sort count gr
    duplicates drop gvkey fyear, force
    drop count gr
    tabstat fyear, by(fyear) stats(N)
    tsset gvkey fyear
    save "$path\OutFiles\funda_clean.dta", replace

    use "$path\OutFiles\funda_clean.dta", clear
    joinby gvkey using "$path\OutFiles\ccmxpf_lnkhist_sorted.dta", unmatched(master)
    drop _merge
    sum datadate linkdt
    drop if linkdt==. | datadate<linkdt | datadate>linkenddt
    
    duplicates report gvkey fyear 
    duplicates report gvkey datadate
    
    keep gvkey fyear lpermno
    ren lpermno permno
    
    gen ccm=1
    save "$path\OutFiles\ccm_annual.dta", replace

    use "$path\InFiles\funda.dta", clear
    joinby gvkey using "$path\InFiles\company.dta"
    drop if at==.
    drop if at<=0
    destring gvkey, replace
    egen gr=group(gvkey fyear)
    egen count=count(gr), by(gr) 
    sort count gr
    duplicates drop gvkey fyear, force
    drop count gr
    tabstat fyear, by(fyear) stats(N)
    tsset gvkey fyear

    joinby gvkey fyear using "$path\OutFiles\ccm_annual.dta", unmatched(master)
    drop _merge
    keep if ccm==1    
    
    tabstat fyear, by(fyear) stats(N)
    tsset gvkey fyear
    save "$path\OutFiles\ccm_annual_clean.dta", replace
