global path "C:\...\...\..."

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////    
// Construct variables and sample:    
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
    
****************************************************************    
* Quarterly meet/beat variables:    
****************************************************************    
    * Clean actuals QUARTERLY file
    use "$path\InFiles\ibes_actuals_quarterly.dta", clear
    rename *, lower
    drop if value==.
    drop if cusip==""
    drop if anndats==.
    gen delay=anndats-pends
    sum delay,d
    * Drop erroneous or late earnings announcements:
    drop if delay<=0
    drop if delay>180
    egen gr=group(ticker pends)
    egen count=count(gr), by(gr)
    sort count gr
    duplicates drop ticker pends anndats value actdats, force
    * Keep only last observations that was activated in IBES, assuming that one is more correct:
    sort ticker pends anndats actdats
    duplicates drop ticker pends anndats, force
    duplicates drop ticker pends, force
    keep ticker pends anndats value
    ren value actual_quarterly
    save "$path\OutFiles\ibes_actuals_quarterly.dta", replace

    * Clean QUARTERLY forecast file and attach actuals + permno
    use "$path\InFiles\ibes_statsumu_quarterly.dta", clear
    rename *, lower
    drop if cusip==""
    sort cusip
    joinby cusip using "$path\OutFiles\stocknames2.dta", unmatched(master)
    drop _merge
    sum statpers permno
    drop if permno==.
    * Check if link within date range:
    keep if statpers>=mind & statpers<=maxd
    ren fpedats pends
    sort ticker pends
    joinby ticker pends using "$path\OutFiles\ibes_actuals_quarterly.dta", unmatched(master)
    drop _merge
    drop if anndats==.
    * Keep only forecast consensus measured at least 1 day before earnings announcement:
    drop if statpers>=anndats-1
    * Keep only latest consensus before earnings announcement:
    gsort ticker pends -statpers
    duplicates drop ticker pends, force
    duplicates drop permno pends, force
    replace actual=round(100*actual)
    replace medest=round(100*medest)
    gen surprise=actual-medest
    * Check if distribution is asymmetric as is generally found in the literature (more small beats than small misses)
    tabstat surprise if abs(surprise)<=10, by(surprise) stats(N)
    * Generate variables of interest
    gen mbe=0
    replace mbe=1 if surprise>=0
    sum mbe
    keep permno pends mbe 
    ren pends datadate 
    * String of MBE (Habitual beater): The frequency of meeting or beating analysts' earnings forecasts in the past four quarters (ranges from 0 to 4), in alignment with Dhole (2016)
    sort permno datadate
    egen gr=group(permno datadate)
    tsset permno gr
    gen string_mbe=0
    replace string_mbe=l.mbe if l.mbe!=.
    replace string_mbe=string_mbe+l2.mbe if l2.mbe!=.
    replace string_mbe=string_mbe+l3.mbe if l3.mbe!=.
    replace string_mbe=string_mbe+l4.mbe if l4.mbe!=.
    keep permno datadate string_mbe 
    save "$path\OutFiles\ibes_habitual_beater.dta", replace

****************************************************************    
* REM measures:    
****************************************************************    
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    gen lagta=l.at
    drop cfo
    gen cfo=oancf/lagta    
    gen inverse_a=1/lagta
    gen rev=sale/lagta
    gen revm1=l.sale/lagta
    gen drev=d.sale/lagta
    gen drevm1=(l.sale-l2.sale)/lagta
    gen prod=(cogs+d.invt)/lagta
    replace xad=0 if xad==.
    replace xrd=0 if xrd==.
    replace xsga=0 if xsga==.
    gen disx=(xad+xrd+xsga)/lagta
        
    drop if cfo==.
    drop if rev==.
    drop if drev==.
    drop if drevm1==.
    drop if prod==.
    drop if disx==.
    
    keep if fyear>=2006 & fyear<=2010
    
    destring sic, replace
    replace sich=sic if sich==.
    drop if sich==.
    drop if sich>5999 & sich<7000
    tostring sich, format(%04.0f) replace
    
    gen sic2=substr(sich,1,2)
    egen sic2id=group(sic2 fyear)
    sort sic2id
    egen count=count(sic2id), by(sic2id)
    drop if count<20 
    drop count sic2id
    egen sic2id=group(sic2 fyear)
    
    winsor2 cfo inverse_a rev revm1 drev drevm1 prod disx, cuts(1 99) replace by(fyear)
    
    gen rcfo=.
    gen rprod=.
    gen rdisx=.
    
    sum sic2id
    local k=r(max)
    forvalues i=1(1)`k'{
        qui reg cfo inverse_a rev drev if sic2id==`i', noconstant
        qui predict res if sic2id==`i', res
        qui replace rcfo=res if sic2id==`i'
        qui drop res
        qui reg prod inverse_a rev drev drevm1 if sic2id==`i', noconstant
        qui predict res if sic2id==`i', res
        qui replace rprod=res if sic2id==`i'
        qui drop res
        qui reg disx inverse_a revm1 if sic2id==`i', noconstant
        qui predict res if sic2id==`i', res
        qui replace rdisx=res if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }
    
    sum rcfo rprod rdisx, d
    keep gvkey fyear rcfo rprod rdisx
    
    gen absrcfo=abs(rcfo)
    gen absrprod=abs(rprod)
    gen absrdisx=abs(rdisx)
    save "$path\OutFiles\ccm_annual_rem.dta", replace

****************************************************************    
* Disretionary accruals:    
****************************************************************    
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    gen lagta=l.at
    drop cfo
    gen cfo=oancf/lagta    
    gen tacc=(ib-oancf)/lagta
    gen drev=d.sale/lagta
    gen inverse_a=1/lagta
    gen ppe=ppegt/lagta
    gen roa=ib/lagta
    
    drop if tacc==.
    drop if drev==.
    drop if ppe==.
    drop if roa==.
    
    keep if fyear>=2000 & fyear<=2010
    
    destring sic, replace
    replace sich=sic if sich==.
    drop if sich==.
    drop if sich>5999 & sich<7000
    tostring sich, format(%04.0f) replace
    
    gen sic2=substr(sich,1,2)
    egen sic2id=group(sic2 fyear)
    sort sic2id
    egen count=count(sic2id), by(sic2id)
    drop if count<20 // 
    drop count sic2id
    egen sic2id=group(sic2 fyear)

    gen tacc0=tacc
    winsor2 tacc drev inverse_a ppe roa cfo, cuts(1 99) replace by(fyear)
    
    gen da_dhole=.

    sum sic2id
    local k=r(max)
    forvalues i=1(1)`k'{
        qui reg tacc inverse_a drev ppe roa if sic2id==`i', noconstant
        qui predict res if sic2id==`i', res
        qui replace da_dhole=res if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }
    gen absda_dhole=abs(da_dhole)
    keep gvkey fyear absda_dhole da_dhole roa tacc0
    save "$path\OutFiles\ccm_annual_da_dhole.dta", replace

****************************************************************    
* Smoothing measure:    
****************************************************************    
    use "$path\OutFiles\ccm_annual_da_dhole.dta", clear
    gen corr=.
    gen corrn=.
    gen pdi=roa-da_dhole
    tsset
    gen dda=d.da_dhole
    gen dpdi=d.pdi
    drop if dda==.
    drop if dpdi==.
    sort gvkey fyear
    forvalues i=2006(1)2010{
        qui gen v1=dda if fyear<=`i' & fyear>`i'-5
        qui gen v2=dpdi if fyear<=`i' & fyear>`i'-5
        qui egen rho=corr(v1 v2), by(gvkey)
        qui egen count=count(v1), by(gvkey)
        qui replace corr=rho if fyear==`i'
        qui replace corrn=count if fyear==`i'
        qui drop v1 v2 rho count
        di `i'
    }
    drop if fyear<2006
    sum corr corrn
    xtile corrk=-corr, nq(100) // Tucker and Zarowin do this by industry-year
    replace corrk=corrk/100
    keep gvkey fyear corr corrk dda
    drop if corrk==.
    save "$path\OutFiles\ccm_annual_corrk_dhole.dta", replace

****************************************************************    
* Combine files and clean up:    
****************************************************************    
    use "$path/OutFiles/ccm_annual_clean.dta", clear
    gen lnta=ln(at)
    gen mv=prcc_f*csho
    gen mtb=mv/ceq
    gen leverage=(dlc+dltt)/mv
    gen rnd=xrd/at
    replace rnd=0 if xrd<0 | xrd==.
    gen noa=(l.ceq-l.che+l.dlc+l.dltt)/l.at
    gen implicit_claims=1-(ppegt/at)
    destring sic, replace
    sum fyear sic sich
    replace sich=sic if sich==.
    gen litigation=0
    replace litigation=1 if sich>=2833 & sich<=2836    
    replace litigation=1 if sich>=8731 & sich<=8734    
    replace litigation=1 if sich>=3570 & sich<=3577    
    replace litigation=1 if sich>=7370 & sich<=7374    
    replace litigation=1 if sich>=3600 & sich<=3674    
    replace litigation=1 if sich>=5200 & sich<=5961    
    gen lnshares_outst=ln(csho)
    gen csho_growth=csho/l.csho
    gen issue=0
    replace issue=1 if csho_growth>1.1 & csho_growth!=.
    drop csho_growth
    
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

    * Drop financial firms:
    drop if sich>5999 & sich<7000    
    
    * Dhole et al. (2016) Table 1 suggests they also exclude utilities:
    replace sich=sic if sich==.
    drop if sich==.
    drop if sich>4899 & sich<4950
    tostring sich, format(%04.0f) replace
    gen sic2=substr(sich,1,2)
    
    joinby gvkey fyear using "$path/OutFiles/ccm_annual_da_dhole.dta", unmatched(master)
    drop _merge
    drop if absda_dhole==.
    
    joinby gvkey fyear using "$path/OutFiles/ccm_annual_corrk_dhole.dta", unmatched(master)
    drop _merge
    drop if corrk==.

    joinby gvkey fyear using "$path/OutFiles/ccm_annual_rem.dta", unmatched(master)
    drop _merge
    drop if rcfo==.

    joinby gvkey fyear using "$path/OutFiles/opvolatility.dta", unmatched(master)
    drop _merge

    gen year=year(datadate)
    gen month=month(datadate)
    
    joinby permno year month using "$path/OutFiles/mse_idioshock.dta", unmatched(master)
    drop _merge

    joinby permno datadate using "$path/OutFiles/ibes_analyst_variables.dta", unmatched(master)
    drop _merge
    replace numest=0 if numest==.
    sum numest justmbe mbe largembe
    
    local varlist "ticker_ibes cusip_ibes numest disp surprise mjb mbe mjb_perc justmbe largembe"
    foreach var in `varlist' {
        ren `var' `var'_0
    }

    gen datadate0=datadate
    replace datadate=mdy(month(datadate), day(datadate), year(datadate)+1)
    joinby permno datadate using "$path/OutFiles/ibes_analyst_variables.dta", unmatched(master)
    drop _merge
    drop datadate
    ren datadate0 datadate

    drop ticker_ibes cusip_ibes numest disp surprise mjb mbe mjb_perc largembe
    ren justmbe justmbe_p1
    replace justmbe_p1=0 if justmbe_p1==.
    local varlist "ticker_ibes cusip_ibes numest disp surprise mjb mbe mjb_perc justmbe largembe"
    foreach var in `varlist' {
        ren `var'_0 `var'
    }
    
    joinby permno datadate using "$path\OutFiles\ibes_habitual_beater.dta", unmatched(master)
    drop _merge
    
    joinby cik fyear using "$path\OutFiles\big4.dta", unmatched(master)
    drop _merge
    sum fyear big4
    replace big4=0 if big==.
    
    * Firm age
    joinby gvkey using "$path\OutFiles\firm_age.dta", unmatched(master)
    drop _merge
    gen firm_age=fyear-fyear_first
    gen lnfirm_age=ln(firm_age)
    
    joinby gvkey fyear using "$path/OutFiles/firmyears_compensation.dta", unmatched(master)
    drop _merge
    drop if insidedebt==.
            
    drop if cashcomp==.
    drop if sdearn==.
    drop if mtb==.
    drop if noa==.
    drop if deltaceo==.
    drop if vegaceo==.
    drop if lnta==.
    drop if leverage==.
    drop if implicit_claims==.
    drop if litigation==.
    drop if lnshares_outst==.
    drop if big4==.
    drop if issue==.
    drop if string_mbe==.
    drop if numest==.
    drop if lnfirm_age==.
    drop if justmbe==.
                
    gen lndelta=ln(1+deltaceo)
    gen lnvega=ln(1+vegaceo)
    gen lnnumest=ln(1+numest)
    
    keep if fyear>=2006 & fyear<=2010
    sum datadate, f d
    
    egen count=count(fyear), by(sic2)
    tabstat count if count>100, by(sic2) 

    drop if ceo_relative_leverage==.
    drop if relative_incentive_ratio==.

    sum rcfo
    replace rcfo=(rcfo-r(mean))/r(sd)
    sum rprod
    replace rprod=(rprod-r(mean))/r(sd)
    sum rdisx
    replace rdisx=(rdisx-r(mean))/r(sd)    
    sum rcfo rprod rdisx
    replace rprod=-rprod // Cohen, Dey & Lys 2008: "firms that manage earnings upward are likely to have one or all of these: unusually low cash flow from operations, and/or unusually low discretionary expenses, and/or unusually high production costs"
    gen rmproxy=rcfo+rprod+rdisx
    sum rmproxy, d
    gen absrmproxy=abs(rmproxy)
    
    replace ceo_idebt=ceo_idebt/1000
    replace defer_balance_tot=defer_balance_tot/1000
    replace pension_value_tot=pension_value_tot/1000
    replace totalcomp=totalcomp/1000
    replace cashcomp=cashcomp/1000
    replace ceo_equity=ceo_equity/1000
    replace deltaceo=deltaceo/1000
    replace vegaceo=vegaceo/1000
    replace at=at/1000
    
    gen negcorr=-corr

    * Get state marginal tax rates for IV using historical HQ:
    destring cik, replace
    sum fyear
    joinby cik year using "$path\OutFiles\states_hq.dta", unmatched(master)
    drop _merge
    sum fyear
    sum fyear if state!=""
    sum fyear if state_hist!=""
    
    replace state=state_hist if state_hist!=""
    sum fyear if state!=""
    
    joinby state year using "$path\OutFiles\state_tax_rates.dta", unmatched(master)
    drop _merge
    sum year taxrate_*
    // Mortgage rate is negative and should be reported as subsidy:
    replace taxrate_mort=-taxrate_mort

    // Double check relative leverage calculation with Naveen data as input:
    joinby gvkey fyear co_per_rol using "$path/OutFiles/deltavega_naveen.dta", unmatched(master)
    drop _merge
    replace firm_related_wealth=firm_related_wealth/1000
    replace delta_naveen=delta_naveen/1000
    spearman ceo_equity firm_related_wealth
    sum ceo_equity firm_related_wealth, d
    gen diff=abs((ceo_equity/firm_related_wealth)-1)
    sum diff, d
    gen ceo_personal_leverage2=ceo_idebt/(firm_related_wealth)
    gen ceo_relative_leverage2=ceo_personal_leverage2/firm_leverage

    sum deltaceo delta_naveen, d
    spearman deltaceo delta_naveen
    gen deltaclean2=delta_naveen/(0.01*prcc_f)
    gen relative_incentive_ratio2=(ceo_idebt/(1000*(dlc+dltt)))/(deltaclean2/delta_fe) // ceo_idebt is in thousands and dlc/dltt in millions
    
    // Winsorization consistent with original paper:
    winsor2 abs* rmproxy sdcfo sdsal firm_leverage* leverage at ceo_ownership totalcomp deltaceo vegaceo numest lnta lndelta lnvega lnnumest idioshock2 ceo_relative_leverage* sdearn cashcomp lncashcomp lnfirm_age firm_age lnshares lnshares_outst at mtb noa implicit_claims ceo_idebt pension_value_tot defer_balance_tot ceo_equity relative_incentive_ratio* roa rnd, replace cuts(1 99)

    sum ceo_relative_leverage ceo_relative_leverage2 if ceo_relative_leverage2!=., d
    sum relative_incentive_ratio relative_incentive_ratio2 if relative_incentive_ratio2!=., d

    // Dhole et al. (2016) Footnote 11: 39% of obs have zero inside debt:
    sum fyear if ceo_idebt==0
    scalar zero=r(N)
    sum fyear
    scalar perc=zero/r(N)
    di perc
    
    sum tacc0, d
    gen abstacc0=abs(tacc0)
    winsor2 tacc0, cuts(1 99) replace
    egen mean=mean(tacc0), by(fyear)
    gen abstaccadj=abs(tacc0-mean)
    
    winsor2 abstacc0 abstaccadj, cuts(1 99) replace
    sum abstacc0 abstaccadj, d
    
    tabstat fyear, by(fyear) stats(N)
    
    gen sic2new=sic2 if sic2=="13"
    replace sic2new=sic2 if sic2=="20"
    replace sic2new=sic2 if sic2=="28"
    replace sic2new=sic2 if sic2=="35"
    replace sic2new=sic2 if sic2=="36"
    replace sic2new=sic2 if sic2=="37"
    replace sic2new=sic2 if sic2=="38"
    replace sic2new=sic2 if sic2=="48"
    replace sic2new=sic2 if sic2=="50"
    replace sic2new=sic2 if sic2=="56"
    replace sic2new=sic2 if sic2=="58"
    replace sic2new=sic2 if sic2=="73"
    replace sic2new=sic2 if sic2=="80"
    replace sic2new="99" if sic2new==""
    tabstat fyear, by(sic2new) stats(N)
    
    keep gvkey fyear datadate sic2 ceo_idebt defer_balance_tot pension_value_tot ceo_relative_leverage relative_incentive_ratio totalcomp cashcomp ceo_equity deltaceo vegaceo lncashcomp lndelta lnvega corrk negcorr absda_dhole absrcfo absrprod absrdisx rmproxy absrmproxy justmbe largembe justmbe_p1 at lnta sdearn firm_age lnfirm_age mtb leverage noa implicit litig lnsha big4 issue string_mbe numest lnnumest sdcfo sdsal lossperc idioshock2 roa rnd taxrate_* relativelev relativeinc
    
    save "$path/OutFiles/firmyears_compensation2_reconcile_Dhole.dta", replace

    
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////    
// Descriptives and tests:    
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

    use "$path/OutFiles/firmyears_compensation2_reconcile_Dhole.dta", clear
    tabstat ceo_idebt defer_balance_tot pension_value_tot ceo_relative_leverage relative_incentive_ratio totalcomp cashcomp ceo_equity deltaceo vegaceo corrk negcorr absda_dhole absrcfo absrprod absrdisx rmproxy absrmproxy justmbe largembe justmbe_p1 at sdearn firm_age mtb leverage noa implicit litig lnsha big4 issue string_mbe numest, stats(N mean sd p25 median p75) columns(statistics)

    // Check distributions after winsorizing at 95th percentile:
    winsor2 ceo_relative_leverage relative_incentive_ratio, cuts(1 95) 
    tabstat ceo_relative_leverage_w relative_incentive_ratio_w, stats(N mean sd p25 median p75) columns(statistics)

    hist ceo_relative_leverage, ///
        ylabel(, labsize(medium) format(%6.2fc)) ///
        xtitle("{it: CEO relative leverage ratio}", size(medium)) ///
        legend(off) ///
        saving(one, replace)
    
    hist relative_incentive_ratio, ///
        ytitle("") ///
        ylabel(, labsize(medium) format(%6.2fc)) ///
        xtitle("{it: CEO relative incentive ratio}", size(medium)) ///
        legend(off) ///
        saving(two, replace)
    
    graph combine one.gph two.gph, graphregion(color(white) margin(zero) lpattern(none)) ysize(4)
    set printcolor asis
    graph export "$path\Tables\dhole_hist.pdf", replace
    
    // Dhole et al. (2016) Table 4: 
    // Results with continuous variable:
    reghdfe corrk ceo_relative_leverage lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[ceo_relative_leverage]/_se[ceo_relative_leverage]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_1.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe corrk relative_incentive_ratio lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relative_incentive_ratio]/_se[relative_incentive_ratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absda_dhole ceo_relative_leverage lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[ceo_relative_leverage]/_se[ceo_relative_leverage]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absda_dhole relative_incentive_ratio lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relative_incentive_ratio]/_se[relative_incentive_ratio]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_1.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')

    reghdfe corrk ceo_relative_leverage, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe corrk relative_incentive_ratio, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absda_dhole ceo_relative_leverage, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absda_dhole relative_incentive_ratio, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    
    // Results with indicator variable instead:
    reghdfe corrk relativelev lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe corrk relativeinc lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p') 
    reghdfe absda_dhole relativelev lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p') 
    reghdfe absda_dhole relativeinc lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p') 

    // Use correlation instead of rank of negative correlation as dependent:
    reghdfe corr relativelev lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
    reghdfe corr relativeinc lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    

    // Controlling for additional operating environment characteristics:
    factor sdcfo sdsal lossperc idioshock2 roa rnd, pcf
    predict opvol
    
    reghdfe absda_dhole relativelev lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest opvol, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p') 
    reghdfe absda_dhole relativeinc lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest opvol, cluster(gvkey fyear) absorb(sic2 fyear) keepsin noconst    
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_accruals_2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p') 

    // Dhole et al. (2016) Table 5: 
    reghdfe absrcfo relativelev lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrcfo relativeinc lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrprod relativelev lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrprod relativeinc lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrdisx relativelev lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrdisx relativeinc lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrmproxy relativelev lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe absrmproxy relativeinc lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_rem.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  

    reghdfe absrcfo relativelev, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrcfo relativeinc, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrprod relativelev, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrprod relativeinc, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrdisx relativelev, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrdisx relativeinc, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrmproxy relativelev, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrmproxy relativeinc, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    
    // Check with continuous variables:
    reghdfe absrcfo ceo_relative_leverage lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrcfo relative_incentive_ratio lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrprod ceo_relative_leverage lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrprod relative_incentive_ratio lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrdisx ceo_relative_leverage lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrdisx relative_incentive_ratio lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrmproxy ceo_relative_leverage lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe absrmproxy relative_incentive_ratio lncashcomp lndelta lnvega absda_dhole sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    
    // Dhole et al. (2016) Table 7:
    reghdfe justmbe relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe justmbe relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe largembe relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe largembe relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe justmbe_p1 relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativelev]/_se[relativelev]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    reghdfe justmbe_p1 relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
        qui local t=_b[relativeinc]/_se[relativeinc]
        qui local p=2*ttail(e(df_r), abs(`t'))
    outreg2 using "$path/Tables/tables_reconcile_dhole_mbe.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 addtext(p-value, `p')  
    
    // Check with continuous variables:    
    reghdfe justmbe ceo_relative_leverage lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe justmbe relative_incentive_ratio lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe largembe ceo_relative_leverage lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe largembe relative_incentive_ratio lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe justmbe_p1 ceo_relative_leverage lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    reghdfe justmbe_p1 relative_incentive_ratio lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey fyear) absorb(sic2 fyear) keepsin
    
    // logit with one-way clustered SEs:    
    egen sic2id=group(sic2)
    logit justmbe i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    logit justmbe i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    logit largembe i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    logit largembe i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    logit justmbe_p1 i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    logit justmbe_p1 i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(gvkey) 
    
    logit justmbe i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    logit justmbe i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    logit largembe i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    logit largembe i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    logit justmbe_p1 i.fyear i.sic2id relativelev lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    logit justmbe_p1 i.fyear i.sic2id relativeinc lncashcomp lndelta lnvega sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest, cluster(fyear) 
    
    ////////////////////////////////////////////////////
    // Instrumental variables:    
    ////////////////////////////////////////////////////
    use "$path/OutFiles/firmyears_compensation2_reconcile_Dhole.dta", clear
    egen sic2id=group(sic2)
    drop if taxrate_wage==.
    pwcorr taxrate_*

    global controls "lncashcomp lndelta lnvega absrmproxy sdearn lnta lnfirm_age mtb leverage noa implicit_claims litigation lnsha big4 issue string_mbe lnnumest"
    global instruments "taxrate_wage taxrate_mort"

    // Log transformation following Campbell/Galpin/Johnson JFE2016 (p342) to make distributions more symmetric:
    sum ceo_relative_leverage if ceo_relative_leverage>0
    replace ceo_relative_leverage=r(min) if ceo_relative_leverage==0
    gen lnlev=ln(ceo_relative_leverage)
    sum relative_incentive_ratio if relative_incentive_ratio>0
    replace relative_incentive_ratio=r(min) if relative_incentive_ratio==0
    gen lninc=ln(relative_incentive_ratio)

    reg lnlev taxrate_wage taxrate_gain taxrate_mort
    vif
    
    ivreg2 corrk i.fyear i.sic2id $controls (lnlev = $instruments), cluster(gvkey fyear)
        scalar kpuid=e(idstat)
        scalar kpuidp=e(idp)
    reghdfe lnlev $instruments $controls, absorb(sic2 fyear) cluster(gvkey fyear)
        qui local t=_b[taxrate_wage]/_se[taxrate_wage]
        qui local p1=2*ttail(e(df_r), abs(`t'))
        qui local t=_b[taxrate_mort]/_se[taxrate_mort]
        qui local p2=2*ttail(e(df_r), abs(`t'))
    test taxrate_wage taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp, KP stat, kpuid, KP stat (p), kpuidp, p-val 1, `p1', p-val 2, `p2') adjr2 
    bootstep lnlev i.sic2id i.fyear $instruments $controls | corrk i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey fyear)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 
    bootstep lnlev i.sic2id i.fyear $instruments $controls | absda_dhole i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey fyear)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 

    ivreg2 corrk i.fyear i.sic2id $controls (lninc = $instruments), cluster(gvkey fyear)
        scalar kpuid=e(idstat)
        scalar kpuidp=e(idp)
    reghdfe lninc $instruments $controls, absorb(sic2 fyear) cluster(gvkey fyear)
        qui local t=_b[taxrate_wage]/_se[taxrate_wage]
        qui local p1=2*ttail(e(df_r), abs(`t'))
        qui local t=_b[taxrate_mort]/_se[taxrate_mort]
        qui local p2=2*ttail(e(df_r), abs(`t'))
    test taxrate_wage taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp, KP stat, kpuid, KP stat (p), kpuidp, p-val 1, `p1', p-val 2, `p2') adjr2 
    bootstep lninc i.sic2id i.fyear $instruments $controls | corrk i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey fyear)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 
    bootstep lninc i.sic2id i.fyear $instruments $controls | absda_dhole i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(gvkey fyear)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2

    // Significance of IVs when excluding industry FEs and/or clustering only by firm (as in He 2015)
    reghdfe lnlev $instruments $controls, absorb(sic2 fyear) cluster(gvkey fyear)
    reghdfe lninc $instruments $controls, absorb(sic2 fyear) cluster(gvkey fyear)
    reghdfe lnlev $instruments $controls, absorb(sic2 fyear) cluster(gvkey)
    reghdfe lninc $instruments $controls, absorb(sic2 fyear) cluster(gvkey)
    reghdfe lnlev $instruments $controls, absorb(fyear) cluster(gvkey fyear)
    reghdfe lninc $instruments $controls, absorb(fyear) cluster(gvkey fyear)
    reghdfe lnlev $instruments $controls, absorb(fyear) cluster(gvkey)
    reghdfe lninc $instruments $controls, absorb(fyear) cluster(gvkey)
    
    // Test with clustering by firm-year (is equal to regular robust SEs)
    egen fy=group(gvkey fyear)
    ivreg2 corrk i.fyear i.sic2id $controls (lnlev = $instruments), cluster(fy)
        scalar kpuid=e(idstat)
        scalar kpuidp=e(idp)
    reghdfe lnlev $instruments $controls, absorb(sic2 fyear) cluster(fy)
        qui local t=_b[taxrate_wage]/_se[taxrate_wage]
        qui local p1=2*ttail(e(df_r), abs(`t'))
        qui local t=_b[taxrate_mort]/_se[taxrate_mort]
        qui local p2=2*ttail(e(df_r), abs(`t'))
    test taxrate_wage taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", replace stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp, KP stat, kpuid, KP stat (p), kpuidp, p-val 1, `p1', p-val 2, `p2') adjr2 
    bootstep lnlev i.sic2id i.fyear $instruments $controls | corrk i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(fy)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 
    bootstep lnlev i.sic2id i.fyear $instruments $controls | absda_dhole i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(fy)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 

    ivreg2 corrk i.fyear i.sic2id $controls (lninc = $instruments), cluster(fy)
        scalar kpuid=e(idstat)
        scalar kpuidp=e(idp)
    reghdfe lninc $instruments $controls, absorb(sic2 fyear) cluster(fy)
        qui local t=_b[taxrate_wage]/_se[taxrate_wage]
        qui local p1=2*ttail(e(df_r), abs(`t'))
        qui local t=_b[taxrate_mort]/_se[taxrate_mort]
        qui local p2=2*ttail(e(df_r), abs(`t'))
    test taxrate_wage taxrate_mort
        scalar partialf=r(F)
        scalar partialfp=r(p)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons addstat(Partial F, partialf, Partial F (p), partialfp, KP stat, kpuid, KP stat (p), kpuidp, p-val 1, `p1', p-val 2, `p2') adjr2 
    bootstep lninc i.sic2id i.fyear $instruments $controls | corrk i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(fy)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 
    bootstep lninc i.sic2id i.fyear $instruments $controls | absda_dhole i.sic2id i.fyear $controls, nboot(1000) seed(1234) cluster(fy)
    outreg2 using "$path/Tables/tables_reconcile_dhole_iv2.xls", append stats(coef tstat) tdec(2) bdec(3) par nocons adjr2 

    

