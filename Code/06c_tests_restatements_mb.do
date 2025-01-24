global path "C:\...\...\..."

    global controls_firm ///
        lnta btm debt lnfirm_age salesgr inst lnnumest big4 bdb 
        
    global controls_ceo ///
        lncashcomp ceo_ownership lndelta lnvega lnceo_age lnceo_ten 

    global controls_opvol ///
        sdcfo sdsal idioshock2 roa lossperc rnd

///////////////////////////////////////
// Restatement tests:
///////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2.dta", clear
    reghdfe restatement insidedebt $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement insidedebtratio $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement relativelev $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement xrelativelev $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin

    reghdfe restatement_severe insidedebt $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement_severe insidedebtratio $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement_severe relativelev $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
    reghdfe restatement_severe xrelativelev $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin

    use "$path/OutFiles/firmyears_compensation2.dta", clear
    
    gen testvar=.
    
    replace testvar=insidedebt
        reghdfe restatement testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe restatement testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe restatement testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe restatement testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 

    replace testvar=insidedebt
        reghdfe restatement testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe restatement testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe restatement testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe restatement testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement) nocons adjr2 addtext(Industry-year FE) 

    use "$path/OutFiles/firmyears_compensation2.dta", clear
    
    gen testvar=.
    
    replace testvar=insidedebt
        reghdfe restatement_severe testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe restatement_severe testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe restatement_severe testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe restatement_severe testvar, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 

    replace testvar=insidedebt
        reghdfe restatement_severe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe restatement_severe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe restatement_severe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe restatement_severe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_restatements_severe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(restatement_severe) nocons adjr2 addtext(Industry-year FE) 

    
///////////////////////////////////////
// Meet/beat tests:
///////////////////////////////////////    
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    gen testvar=.
    
    replace testvar=insidedebt
        reghdfe mjb testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(mjb) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe mjb testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mjb) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe mjb testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mjb) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe mjb testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mjb) nocons adjr2 addtext(Industry-year FE) 

    replace testvar=insidedebt
        reghdfe mbe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mbe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=insidedebtratio
        reghdfe mbe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mbe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=relativelev
        reghdfe mbe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mbe) nocons adjr2 addtext(Industry-year FE) 
    replace testvar=xrelativelev
        reghdfe mbe testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey fyear) absorb(sic2id_ccm) keepsin
        outreg2 using "$path/Tables/tables_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(mbe) nocons adjr2 addtext(Industry-year FE) 
    
