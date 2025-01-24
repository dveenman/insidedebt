global path "C:\...\...\..."
    
    global depvars ///
        absda absda_roa absda_cfo absda_basic sdresidual
    
    global controls_firm ///
        lnta btm debt lnfirm_age salesgr inst lnnumest big4 bdb 
        
    global controls_ceo ///
        lncashcomp ceo_ownership lndelta lnvega lnceo_age lnceo_ten 

    global controls_opvol ///
        sdcfo sdsal idioshock2 roa lossperc rnd

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// FIGURE 1
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    factor $controls_opvol, pcf
    predict opvol
    
    //////////////////////////////////////////////////
    // Double check what the procedure does exactly:
    foreach var in $controls_opvol {
        gen `var'_st=`var'
        sum `var'_st
        replace `var'_st=(`var'_st-r(mean))/r(sd)
    }
    
    gen check=0.27027*sdcfo_st+0.15490*sdsal_st+0.27135*idioshock2_st-0.24757*roa_st+0.29688*lossperc_st+0.21710*rnd_st
    sum check opvol
    pwcorr check opvol

    reg opvol $controls_opvol
    pwcorr opvol $controls_opvol    
    pwcorr opvol bdb
    pwcorr opvol sdearn
    //////////////////////////////////////////////////
           
    xtile xopvol=opvol, nq(10)
    tabstat insidedebt insidedebtratio relativelev xrelativelev, by(xopvol)
    
    egen mean1=mean(insidedebt), by(xopvol)
    egen mean2=mean(insidedebtratio), by(xopvol)
    egen mean3=mean(relativelev), by(xopvol)
    egen mean4=mean(xrelativelev), by(xopvol)
    tabstat mean1 mean2 mean3 mean4, by(xopvol)
    sort xopvol
    by xopvol: gen n=_n
    keep if n==1    
    
    gen xopvol1=xopvol-.3
    gen xopvol2=xopvol-.1
    gen xopvol3=xopvol+.1
    gen xopvol4=xopvol+.3
    
    twoway bar mean1 xopvol1, color(%90) lwidth(medthick) ///
        barw(0.2) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean2 xopvol2, color(%70 ) lwidth(medthick) ///
        barw(0.2) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean3 xopvol3, color(%50) lwidth(medthick) ///
        barw(0.2) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean4 xopvol4, color(%30) lwidth(medthick) ///
        barw(0.2) xscale(range(1 10)) xlabel(1(1)10) ///
        yscale(range(0 1)) ///
        ylabel(0(0.2)1, format(%6.1fc)) ///
        ysize(3.5) ///
        legend(on order(1 2 3 4) ///
            label(1 "{it:InsideDebtDum}") ///
            label(2 "{it:InsideDebtRatio}") ///
            label(3 "{it:RelativeLevDum}") ///
            label(4 "{it:RelativeLevDec}") ///
            size(medium) ///
            region(lcolor(white)) ///
            ring(0) ///
            bplacement(north) ///
            cols(4)) ///
        graphregion(color(white) margin(zero)) ///
        bgcolor(white) ///
        xtitle("Decile of operating environment factor", ///
            size(medium) height(5)) ///
        ytitle("Mean of inside debt variable", ///
            size(medium) height(5)) 
    
    graph set window fontface "Times New Roman"
    set printcolor asis
    graph export "$path\Tables\opvol_idebt.png", replace
    graph export "$path\Tables\opvol_idebt.pdf", replace

    
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    factor $controls_opvol, pcf
    predict opvol
    xtile xopvol=opvol, nq(10)

    egen mean1=mean(absda), by(xopvol)
    egen mean2=mean(absda_roa), by(xopvol)
    egen mean3=mean(absda_cfo), by(xopvol)
    egen mean4=mean(absda_basic), by(xopvol)
    egen mean5=mean(sdresidual), by(xopvol)
    tabstat mean1 mean2 mean3 mean4 mean5, by(xopvol)
    sort xopvol
    by xopvol: gen n=_n
    keep if n==1    
    
    gen xopvol1=xopvol-.3
    gen xopvol2=xopvol-.15
    gen xopvol3=xopvol
    gen xopvol4=xopvol+.15
    gen xopvol5=xopvol+.3
    
    twoway bar mean1 xopvol1, color(%90) lwidth(medthick) ///
        barw(0.15) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean2 xopvol2, color(%70 ) lwidth(medthick) ///
        barw(0.15) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean3 xopvol3, color(%50) lwidth(medthick) ///
        barw(0.15) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean4 xopvol4, color(%30) lwidth(medthick) ///
        barw(0.15) xscale(range(1 10)) xlabel(1(1)10) || ///
    bar mean5 xopvol5, color(%20) lwidth(medthick) ///
        barw(0.15) xscale(range(1 10)) xlabel(1(1)10) ///
        yscale(range(0 0.105)) ///
        ylabel(0(0.02)0.10, format(%6.2fc)) ///
        ysize(3.5) ///
        legend(on order(1 2 3 4 5) ///
            label(1 "{it:|DA|}") ///
            label(2 "{it:|DA{superscript:ROA}|}") ///
            label(3 "{it:|DA{superscript:CFO}|}") ///
            label(4 "{it:|DA{superscript:Basic}|}") ///
            label(5 "{it:DD}") ///
            size(medium) ///
            region(lcolor(white)) ///
            ring(0) ///
            bplacement(north) ///
            cols(5)) ///
        graphregion(color(white) margin(zero)) ///
        bgcolor(white) ///
        xtitle("Decile of operating environment factor", ///
            size(medium) height(5)) ///
        ytitle("Mean of accrual-based FRQ variable", ///
            size(medium) height(5)) 
    
    graph set window fontface "Times New Roman"
    set printcolor asis
    graph export "$path\Tables\opvol_accruals.png", replace
    graph export "$path\Tables\opvol_accruals.pdf", replace
    
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// DESCRIPTIVES Tables 1-2
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    // Descriptives for Table 1-B:
    tabstat insidedebt, by(fyear) stats(N mean)
    tabstat insidedebt_*, by(fyear) stats(mean)
    
    gen pensionpct=pension_value_tot/(pension_value_tot+defer_balance_tot)
    tabstat pensionpct, by(fyear) stats(mean)
    
    // Descriptives for Table 1-C:
    tabstat insidedebt, by(ff12) stats(N mean)
    tabstat insidedebt_* pensionpct, by(ff12) stats(mean)

    replace ceo_idebt=ceo_idebt/1000
    replace pension_value_tot=pension_value_tot/1000
    replace defer_balance_tot=defer_balance_tot/1000
    replace ceo_equity=ceo_equity/1000
    
    // Descriptives for Table 2:    
    tabstat ceo_idebt pension_value_tot defer_balance_tot ceo_equity ///
        insidedebt insidedebtratio relativelev ceo_relative_leverage ///
        absda absda_roa absda_cfo absda_basic sdresidual ///
        at btm debt firm_age salesgr inst numest big4 bdb ///
        cashcomp ceo_ownership deltaceo vegaceo ceo_age ceo_tenure ///
        sdcfo sdsal idioshock2 roa lossperc rnd, ///
        columns(statistics) stats(N mean sd p1 p25 p50 p75 p99 skew kurt)

        
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// COMPARISON Table 3
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    tabstat $depvars $controls_firm $controls_ceo $controls_opvol if insidedebt==1, columns(statistics)
    tabstat $depvars $controls_firm $controls_ceo $controls_opvol if insidedebt==0, columns(statistics)
    
    gen t=.
    gen p=.
    
    gen n=_n
    local varlist $depvars $controls_firm $controls_ceo $controls_opvol
    local j=1
    foreach var in `varlist' {
        reghdfe `var' insidedebt, cluster(gvkey fyear) 
        qui local t=_b[insidedebt]/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        qui replace t=`t' if n==`j'
        qui replace p=`p' if n==`j'
        local `j++'
    }
    tabstat t p if t!=., by(n)
    
        
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
// Table 4 determinants of FRQ measures:
/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    reghdfe absda $controls_firm $controls_ceo, cluster(gvkey fyear) absorb(sic2id_ccm) 
    scalar adjr2_1=e(r2_a)
    reghdfe absda_roa $controls_firm $controls_ceo, cluster(gvkey fyear) absorb(sic2id_ccm) 
    scalar adjr2_2=e(r2_a)
    reghdfe absda_cfo $controls_firm $controls_ceo, cluster(gvkey fyear) absorb(sic2id_ccm) 
    scalar adjr2_3=e(r2_a)
    reghdfe absda_basic $controls_firm $controls_ceo, cluster(gvkey fyear) absorb(sic2id_ccm) 
    scalar adjr2_4=e(r2_a)
    reghdfe sdresidual $controls_firm $controls_ceo, cluster(gvkey fyear) absorb(sic2id_ccm) 
    scalar adjr2_5=e(r2_a)
    
    reghdfe absda $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    outreg2 using "$path/Tables/tables_accruals_controls.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addstat(R2 without opvol, adjr2_1)
    reghdfe absda_roa $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin 
    outreg2 using "$path/Tables/tables_accruals_controls.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addstat(R2 without opvol, adjr2_2) 
    reghdfe absda_cfo $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin 
    outreg2 using "$path/Tables/tables_accruals_controls.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addstat(R2 without opvol, adjr2_3) 
    reghdfe absda_basic $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin 
    outreg2 using "$path/Tables/tables_accruals_controls.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addstat(R2 without opvol, adjr2_4) 
    reghdfe sdresidual $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin 
    outreg2 using "$path/Tables/tables_accruals_controls.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addstat(R2 without opvol, adjr2_5) 
        
        
        
****************************************************************
****************************************************************
* Table 5A: With all control variables:
****************************************************************
****************************************************************
    use "$path/OutFiles/firmyears_compensation2.dta", clear
    local p10=0
    local p5=0
    local p1=0
        
    reghdfe absda $controls_firm $controls_ceo $controls_opvol insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo $controls_opvol insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo $controls_opvol insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo $controls_opvol insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo $controls_opvol insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo $controls_opvol insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo $controls_opvol insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo $controls_opvol insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo $controls_opvol insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo $controls_opvol insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo $controls_opvol relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo $controls_opvol relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo $controls_opvol relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo $controls_opvol relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo $controls_opvol relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo $controls_opvol xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo $controls_opvol xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo $controls_opvol xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo $controls_opvol xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo $controls_opvol xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_a.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 



****************************************************************
****************************************************************
* Table 5B: Without operating env. characteristics:
****************************************************************
****************************************************************
    use "$path/OutFiles/firmyears_compensation2.dta", clear
    local p10=0
    local p5=0
    local p1=0
    
    reghdfe absda $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_b.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 



****************************************************************
****************************************************************
* Table 5C: Additionally drop bdb variable:
****************************************************************
****************************************************************
    use "$path/OutFiles/firmyears_compensation2.dta", clear
    local p10=0
    local p5=0
    local p1=0
    
    replace bdb=0 // this will drop the variable from the estimation
    
    reghdfe absda $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo insidedebt, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebt])/_se[insidedebt]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo insidedebtratio, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[insidedebtratio])/_se[insidedebtratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo relativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[relativelev])/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    reghdfe absda $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_roa $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_cfo $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe absda_basic $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 
    reghdfe sdresidual $controls_firm $controls_ceo xrelativelev, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin noconstant
        qui local t=(_b[xrelativelev])/_se[xrelativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
        if `t'<0 & `p'<=0.10{
            local `p10++'
        }
        if `t'<0 & `p'<=0.05{
            local `p5++'
        }
        if `t'<0 & `p'<=0.01{
            local `p1++'
        }
    outreg2 using "$path/Tables/tables_accruals_controls_c.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes, p10, `p10', p5, `p5', p1, `p1') 

    