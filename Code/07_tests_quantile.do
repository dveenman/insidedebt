global path "C:\...\...\..."

    global controls_firm ///
        lnta btm debt lnfirm_age salesgr inst lnnumest big4 bdb 
        
    global controls_ceo ///
        lncashcomp ceo_ownership lndelta lnvega lnceo_age lnceo_ten 

    global controls_opvol ///
        sdcfo sdsal idioshock2 roa lossperc rnd
    
    use "$path/OutFiles/firmyears_compensation2.dta", clear

    winsor2 tacc ppe drev, replace cuts(1 99)
    
    gen testvar=relativelev // relativelev insidedebt insidedebtratio xrelativelev
    
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(10)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(20)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(30)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(40)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(50)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(60)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(70)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(80)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    robreg q tacc fyear##(c.ppe c.drev) testvar $controls_firm $controls_ceo $controls_opvol, cluster(gvkey) q(90)
    outreg2 using "$path/Tables/tables_accruals_quantile.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons keep(testvar $controls_firm $controls_ceo $controls_opvol ) addstat(Pseudo R2, e(r2_p))
    
