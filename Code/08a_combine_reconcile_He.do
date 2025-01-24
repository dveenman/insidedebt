global path "C:\...\...\..."

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////    
// Construct variables and sample:    
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
    
****************************************************************    
* Independent directors (percentage + ownership)
****************************************************************    
    * The data are split between pre and post 2007 so we need both since our sample starts in 2006
    * Pre-2007 sample:
    use "$path\InFiles\iss_directors.dta", clear
    keep year cusip classification num_of_shares meetingdate
    drop if cusip==""
    keep if year==2006
    sort cusip year
    ren cusip cusip6
    gen independent=0
    replace independent=1 if classification=="I"
    *Indp: The proportion of independent directors on the board of directors as of the end of a fiscal year
    egen indp=mean(independent), by (cusip6 year)
    sum indp, d
    *IndpShare: The sum of all independent directors' equity ownership as a percentage of total shares outstanding as of the end of a fiscal year.
    gen independentshare=0
    replace independentshare=num_of_shares if independent==1
    egen independentshare_sum=sum(independentshare), by (cusip6 year)
    duplicates drop cusip6 year, force
    keep cusip6 year indp independentshare_sum meetingdate
    save "$path\OutFiles\iss_directors_pre2007.dta", replace

    * Post-2007 sample:
    use "$path\InFiles\iss_directors_new.dta", clear
    keep year cusip classification num_of_shares meetingdate
    drop if cusip==""
    drop if year>2021
    sort cusip year
    gen cusip6=substr(cusip, 1, 6)
    gen independent=0
    replace independent=1 if classification=="I" | classification=="I-NED"
    *Indp: The proportion of independent directors on the board of directors as of the end of a fiscal year
    egen indp_new=mean(independent), by (cusip6 year)
    sum indp_new, d
    *IndpShare: The sum of all independent directors' equity ownership as a percentage of total shares outstanding as of the end of a fiscal year.
    gen independentshare=0
    replace independentshare=num_of_shares if independent==1
    egen independentshare_sum_new=sum(independentshare), by (cusip6 year)
    duplicates drop cusip6 year, force
    keep cusip6 year indp_new independentshare_sum_new meetingdate
    ren meetingdate meetingdate_new
    save "$path\OutFiles\iss_directors_post2007.dta", replace

****************************************************************    
* Discretionary accruals
****************************************************************    
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    gen lagta=l.at
    gen tacc=(ib-oancf)/lagta
    gen drev=(d.sale-d.rect)/lagta
    gen inverse_a=1/lagta
    gen ppe=ppegt/lagta
    gen roa=ib/lagta
    drop cfo
    gen cfo=oancf/lagta
    
    drop if tacc==.
    drop if drev==.
    drop if ppe==.
    
    keep if fyear>=2006 & fyear<=2011
    
    destring sic, replace
    replace sich=sic if sich==.
    drop if sich==.
    tostring sich, format(%04.0f) replace
    
    gen sic2=substr(sich,1,2)
    egen sic2id=group(sic2 fyear)
    sort sic2id
    egen count=count(sic2id), by(sic2id)
    drop if count<20
    drop count sic2id
    egen sic2id=group(sic2 fyear)

    winsor2 tacc inverse_a drev ppe roa cfo, cuts(1 99) replace by(fyear)
    
    gen dcfo=0
    replace dcfo=1 if cfo<0
    gen dcfocfo=dcfo*cfo
    
    gen da_he=.
    gen da_he2=.
    gen da_he3=.

    sum sic2id
    local k=r(max)
    forvalues i=1(1)`k'{
        qui reg tacc inverse_a drev ppe if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da_he=res if sic2id==`i'
        qui drop res
        qui reg tacc inverse_a drev ppe roa if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da_he2=res if sic2id==`i'
        qui drop res
        qui reg tacc inverse_a drev ppe cfo dcfo dcfocfo if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da_he3=res if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }
    gen absda_he=abs(da_he)
    gen absda_he2=abs(da_he2)
    gen absda_he3=abs(da_he3)
    keep gvkey fyear absda_he* da_he* 
    save "$path\OutFiles\ccm_annual_da_he.dta", replace

****************************************************************    
* DD measure
****************************************************************    
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    drop cfo
    gen avta=(l.at+at)/2
    gen cfom1=l.oancf/avta
    gen cfo=oancf/avta
    gen cfop1=f.oancf/avta
    gen wca=(ibc-oancf+dpc)/avta
    gen dsal=(d.sale)/avta
    gen ppeg=ppegt/avta
    drop if wca==.
    drop if cfom1==.
    drop if cfo==.
    drop if cfop1==.
    drop if dsal==.
    drop if ppeg==.

    destring sic, replace
    replace sich=sic if sich==.
    drop if sich==.
    tostring sich, format(%04.0f) replace
    
    drop if fyear>2011
    
    gen sic2=substr(sich,1,2)
    egen sic2id=group(sic2 fyear)
    egen count=count(sic2id),by(sic2id)
    drop if count<20
    drop count
    drop sic2id
    egen sic2id=group(sic2 fyear)
    keep gvkey fyear sic* wca cfom1 cfo cfop1 dsal ppeg 

    winsor2 wca cfom1 cfo cfop1 dsal ppeg, cuts(1 99) replace by(fyear)

    gen residual=.

    sum sic2id
    scalar max2=r(max)
    local k=max2
    set more off
    forvalues i=1(1)`k'{
        qui reg wca cfom1 cfo cfop1 dsal ppeg if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace residual=res if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }

    sort gvkey fyear
    gen n=_n
    gen res_1=residual
    gen res_2=l.residual
    gen res_3=l2.residual
    gen res_4=l3.residual
    gen res_5=l4.residual
    reshape long res_, i(n) j(j)
    egen countobs=count(res_), by(n)
    egen dd_he=sd(res_), by(n)
    replace dd=. if countobs<5
    keep if j==1
    sort gvkey fyear
    keep gvkey fyear dd_he
    drop if dd_he==.
    save "$path\OutFiles\ccm_annual_dd_he.dta", replace

    use "$path/OutFiles/ccm_annual_clean.dta", clear
    sum fyear, d
    
    gen lagta=l.at
    gen mv=prcc_f*csho
    gen mtb=l.mv/l.ceq
    gen size=ln(l.mv)
    gen debt=l.dltt/l.at
    gen salesgr=sale/l.sale-1
    gen roa=ib/at
    gen loss_operating=0 if oiadp!=.
    replace loss_operating=1 if oiadp<0

    gen rnd=xrd/at
    replace rnd=0 if xrd<0 | xrd==.
    
    gen lossperc=0
    gen ltot=0
    replace ltot=ltot+1 if ib<0
    gen lc=0
    replace lc=lc+1 if ib!=.
    replace ltot=ltot+1 if l.ib<0
    replace lc=lc+1 if l.ib!=.
    replace ltot=ltot+1 if l2.ib<0
    replace lc=lc+1 if l2.ib!=.
    replace ltot=ltot+1 if l3.ib<0
    replace lc=lc+1 if l3.ib!=.
    replace ltot=ltot+1 if l4.ib<0
    replace lc=lc+1 if l4.ib!=.
    replace lossperc=ltot/lc
    sum lossperc

    destring sic, replace
    sum fyear sic sich
    replace sich=sic if sich==.

    tostring sich, format(%04.0f) replace
    gen sic2=substr(sich,1,2)
    
    joinby gvkey fyear using "$path/OutFiles/ccm_annual_da_he.dta", unmatched(master)
    drop _merge
    drop if absda_he==.

    joinby gvkey fyear using "$path/OutFiles/ccm_annual_dd_he.dta", unmatched(master)
    drop _merge

    joinby gvkey fyear using "$path/OutFiles/opvolatility.dta", unmatched(master)
    drop _merge

    gen year=year(datadate)
    gen month=month(datadate)
    
    joinby permno year month using "$path/OutFiles/mse_idioshock.dta", unmatched(master)
    drop _merge
        
    joinby permno datadate using "$path/OutFiles/ibes_analyst_variables.dta", unmatched(master)
    drop _merge
    replace numest=0 if numest==.

    joinby cik fyear using "$path\OutFiles\big4.dta", unmatched(master)
    drop _merge
    sum fyear big4
    replace big4=0 if big==.

    sum fyear
    joinby permno using "$path\OutFiles\stocknames_permno_cusip", unmatched(master)
    drop _merge
    sum fyear namedt
    keep if datadate>=namedt & datadate<=nameenddt
    sum fyear
    
    gen quarter=quarter(datadate)
    joinby cusip8 year quarter using "$path\OutFiles\inst.dta", unmatched(master)
    drop _merge
    drop quarter
    replace held_pct=0 if held_pct==.
    sum held_pct, d
    replace held_pct=1 if held_pct>1
    ren held_pct inst
    
    joinby gvkey fyear using "$path/OutFiles/firmyears_compensation.dta", unmatched(master)
    drop _merge
    drop if insidedebt==.
            
    joinby cusip6 year using "$path\OutFiles\iss_directors_pre2007.dta", unmatched(master)
    drop _merge
    sum fyear indp* indep*
    
    joinby cusip6 year using "$path\OutFiles\iss_directors_post2007.dta", unmatched(master)
    drop _merge
    sum fyear indp* indep*

    replace indp=indp_new if indp==.
    replace independentshare_sum=independentshare_sum_new if independentshare_sum==.
    
    * IndpShare: The sum of all independent directors' equity ownership as a percentage of total shares outstanding as of the end of a fiscal year.
    gen indpshare=independentshare_sum/(csho*1000000)
    sum indpshare,d
    replace indpshare=1 if indpshare>1 & indpshare!=.
    drop independentshare_sum
    sum year indp indpshare
    
    joinby cik fyear using "$path/Outfiles/auditanalytics_restatement2.dta", unmatched(master)
    drop _merge
    replace restatement=0 if restatement==.
    replace restatement_severe=0 if restatement_severe==.
    sum restatement*
    
    drop if salesgr==.
    drop if roa==.
    drop if loss_operating==.
    drop if mtb==.
    drop if debt==.
    drop if sdcfo==.
    drop if numest==.
    drop if big4 ==.
    drop if ceo_ownership==.
    drop if vega==.
    drop if sdsal==.
    drop if size==.
    drop if inst==.
    drop if indp==.
    drop if indpshare==.
    drop if relativelev==.
    
    gen lnnumest=ln(1+numest)
    gen lnvega=ln(1+vega)

    keep if fyear>=2006 & fyear<=2011
    sum datadate, f d
    
    * Get state marginal tax rates for IV using historical HQ:
    destring cik, replace
    sum fyear
    joinby cik year using "$path\OutFiles\states_hq.dta", unmatched(master)
    drop _merge
    sum fyear
    sum fyear if state!=""
    sum fyear if state_hist!=""
    
    gen diff=0 if state!="" & state_hist!=""
    replace diff=1 if state!=state_hist & state!="" & state_hist!=""
    tabstat diff, by(fyear)
    
    replace state=state_hist if state_hist!=""
    sum fyear if state!=""
    
    joinby state year using "$path\OutFiles\state_tax_rates.dta", unmatched(master)
    drop _merge
    sum year taxrate_*
    // Mortgage rate is negative and should be reported as subsidy:
    replace taxrate_mort=-taxrate_mort
        
    * CEO ownership specified as percentage:
    replace ceo_ownership=ceo_ownership*100
    
    keep gvkey fyear datadate sic2 absda_he da_he absda_he2 dd_he restatement restatement_severe mjb_perc mjb relativelev inst indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal lossperc idioshock2 rnd taxrate_* 
    
    save "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", replace

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////    
// Descriptives and tests:    
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
    
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear
    tabstat fyear, by(fyear) stats(N)

    // He (2015) has 5596 obs
    egen gid=group(gvkey)
    sum gid
    
    tabstat absda_he da_he absda_he2 dd_he restatement mjb_perc relativelev inst indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal, stats(N mean sd p25 median p75) columns(statistics)
    
    // He (2015) Table 3: 
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear
    reghdfe absda_he relativelev, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_1.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe absda_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe absda_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe absda_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating size mtb lnnumest debt salesgr inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    
    // Signed DA measure:
    reghdfe da_he relativelev, absorb(fyear) cluster(gvkey)
    reghdfe da_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    
    // Table 3 with alternative DA measure controlling for ROA: 
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear    
    reghdfe absda_he2 relativelev, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_2.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe absda_he2 relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  

    winsor2 absda_he* da_he* dd_he ceo_ownership lnvega roa size mtb lnnumest debt salesgr sdcfo sdsal idioshock2 rnd, cuts(1 99) replace
    reghdfe absda_he2 relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe absda_he2 relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(sic2 fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  

    factor sdcfo sdsal lossperc idioshock2 roa rnd, pcf
    predict opvol
    reghdfe absda_he2 relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst opvol, absorb(sic2 fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    
    // He (2015) Table 4: 
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear
    reghdfe dd_he relativelev, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_3.xls", replace stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    reghdfe dd_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_3.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  

    winsor2 absda_he* da_he* dd_he ceo_ownership lnvega roa size mtb lnnumest debt salesgr sdcfo sdsal idioshock2 rnd, cuts(1 99) replace
    reghdfe dd_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_3.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  
    
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear
    reghdfe dd_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, absorb(sic2 fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_3.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  

    factor sdcfo sdsal lossperc idioshock2 roa rnd, pcf
    predict opvol
    reghdfe dd_he relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst opvol, absorb(fyear) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_accruals_3.xls", append stats(coef tstat) tdec(2) bdec(3) par drop(absda) nocons adjr2  

    // He (2015) Tables 5 and 6:     
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear

    probit restatement i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_other.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Pseudo R2, e(r2_p))
    probit mjb_perc i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_other.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Pseudo R2, e(r2_p))
    probit restatement_severe i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_other.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Pseudo R2, e(r2_p))
    probit mjb i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_other.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Pseudo R2, e(r2_p))
    
    winsor2 absda_he* da_he* dd_he ceo_ownership lnvega roa size mtb lnnumest debt salesgr sdcfo sdsal idioshock2 rnd, cuts(1 99) replace
    probit restatement i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    probit mjb_perc i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    probit restatement_severe i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)
    probit mjb i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst, cluster(gvkey)

    factor sdcfo sdsal lossperc idioshock2 roa rnd, pcf
    predict opvol
    probit restatement_severe i.fyear relativelev indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst opvol, cluster(gvkey)
    
    ///////////////////////////////////////////////////
    // Instrumental variables analysis:
    ///////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2_reconcile_He.dta", clear
    drop if taxrate_mort==.
    pwcorr taxrate*

    global controls "indpshare ceo_ownership lnvega big4 indp loss_operating roa size mtb lnnumest debt salesgr sdcfo sdsal inst"
    global instruments "taxrate_wage taxrate_mort"
    
    probit relativelev i.fyear $instruments, cluster(gvkey)
    probit relativelev i.fyear $instruments $controls, cluster(gvkey)
        test taxrate_wage taxrate_mort
        scalar chisq=r(chi2)
        scalar chisqp=r(p)
    outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Pseudo R2, e(r2_p), Chi-sq, chisq, Chi-sq (p), chisqp) drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear) 
    
    reg relativelev i.fyear $instruments $controls, cluster(gvkey)
        test taxrate_wage taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    
    outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp) drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear) adjr2

    reg relativelev i.fyear taxrate_wage $controls, cluster(gvkey)
        test taxrate_wage 
        scalar partialf=r(F)
        scalar partialfp=r(p)
    //outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp) drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear) 
    reg relativelev i.fyear taxrate_mort $controls, cluster(gvkey)
        test taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    //outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp) drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear) 
    
    ivregress 2sls absda_he2 (relativelev = $instruments) i.fyear $controls, cluster(gvkey) first
    bootstep relativelev i.fyear $instruments $controls | absda_he2 i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear absda_he2 dd_he restatement_severe) adjr2
    ivregress 2sls dd_he (relativelev = $instruments) i.fyear $controls, cluster(gvkey) first
    bootstep relativelev i.fyear $instruments $controls | dd_he i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear absda_he2 dd_he restatement_severe) adjr2 
    ivregress 2sls restatement_severe (relativelev = $instruments) i.fyear $controls, cluster(gvkey) first
    bootstep relativelev i.fyear $instruments $controls | restatement_severe i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey)
    outreg2 using "$path/Tables/tables_reconcile_he_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons drop(relativelev 2007.fyear 2008.fyear 2009.fyear 2010.fyear 2011.fyear absda_he2 dd_he restatement_severe) adjr2 

    
    
    
    
    
    
    
    
    
    