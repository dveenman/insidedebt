global path "C:\...\...\..."

    global controls_firm ///
        lnta btm debt lnfirm_age salesgr inst lnnumest big4 bdb 
        
    global controls_ceo ///
        lncashcomp ceo_ownership lndelta lnvega lnceo_age lnceo_ten 

    global controls_opvol ///
        sdcfo sdsal idioshock2 roa lossperc rnd

    global bootstep_options ///
        residual ///
        cluster(gvkey fyear) ///
        nboot(1000) ///
        absorb(sic2id_ccm)
        
    use "$path/OutFiles/firmyears_compensation2.dta", clear
        
    ******************************************************************
    * Results when using fitted values:
    ******************************************************************
    set seed 1234
    ***********************************************************************
    bootstep insidedebt $controls_opvol | ///
        absda $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep insidedebt $controls_opvol | ///
        absda_roa $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep insidedebt $controls_opvol | ///
        absda_cfo $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep insidedebt $controls_opvol | ///
        absda_basic $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep insidedebt $controls_opvol | ///
        sdresidual $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    ***********************************************************************
    bootstep insidedebtratio $controls_opvol | ///
        absda $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep insidedebtratio $controls_opvol | ///
        absda_roa $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep insidedebtratio $controls_opvol | ///
        absda_cfo $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep insidedebtratio $controls_opvol | ///
        absda_basic $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep insidedebtratio $controls_opvol | ///
        sdresidual $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    ***********************************************************************
    bootstep relativelev $controls_opvol | ///
        absda $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep relativelev $controls_opvol | ///
        absda_roa $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep relativelev $controls_opvol | ///
        absda_cfo $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep relativelev $controls_opvol | ///
        absda_basic $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep relativelev $controls_opvol | ///
        sdresidual $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes) 

    ***********************************************************************
    bootstep xrelativelev $controls_opvol | ///
        absda $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep xrelativelev $controls_opvol | ///
        absda_roa $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_roa) nocons adjr2 addtext(Industry-year FE, Yes) 

    bootstep xrelativelev $controls_opvol | ///
        absda_cfo $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_cfo) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep xrelativelev $controls_opvol | ///
        absda_basic $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda_basic) nocons adjr2 addtext(Industry-year FE, Yes) 
        
    bootstep xrelativelev $controls_opvol | ///
        sdresidual $controls_firm $controls_ceo, ///
        $bootstep_options
    outreg2 using "$path/Tables/tables_bootstep.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(sdresidual) nocons adjr2 addtext(Industry-year FE, Yes) 
    
