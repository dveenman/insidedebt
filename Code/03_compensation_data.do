global path "C:\...\...\..."

*****************************************************************
* Execucomp data
* Step 1: Prepare inputs such as dividend yield and return volatility
* Step 2: Clean the detailed equity grant data and compute equity/option values 
* Step 3: Clean annual compensation file and attach equity/option value data to calculate inside debt measures
*****************************************************************

*****************************************************************
*****************************************************************
* STEP 1
*****************************************************************
*****************************************************************
    use "$path/InFiles/execucomp_anncomp.dta", clear
    keep if ceoann=="CEO"
    ren year fyear
    
    * Identify duplicates:
    duplicates report gvkey fyear
    duplicates tag gvkey fyear, gen(dupid)
    sort dupid gvkey fyear
    drop if dupid>0 & becameceo==.
    drop dupid
    duplicates report gvkey fyear
    duplicates tag gvkey fyear, gen(dupid)
    sort dupid gvkey fyear
    
    * Drop remaining ambiguous duplicates:
    drop if dupid>0
    duplicates report gvkey fyear
    drop dupid
    destring gvkey, replace
    tsset gvkey fyear

    gen shrown=shrown_excl_opts // Following Naveen code: https://sites.temple.edu/lnaveen/data/
    ren age ceo_age
    gen ceo_tenure=fyear+1-year(becameceo) // capture "nth" year as CEO
    sum ceo_tenure, d
    replace ceo_tenure=1 if ceo_tenure<1
    save "$path/OutFiles/execucomp_anncomp_clean.dta", replace

    * Transform from daily treasury rates to monthly to merge on fiscal year end month: https://home.treasury.gov/interest-rates-data-csv-archive ("Daily Treasury Par Yield Curve Rates")
    import delimited "$path/InFiles\yield-curve-rates-1990-2021.csv", clear 
    gen date2=daily(date, "MDY", 2050)
    format date2 %td
    gen day=day(date2)
    gen month=month(date2)
    gen year=year(date2)
    keep year month day v10
    ren v10 rate7yr
    gsort year month -day
    duplicates drop year month, force
    drop day 
    replace rate7yr=rate7yr*0.01
    save "$path/OutFiles/rf.dta", replace

    * Prepare data from Compustat for BSM inputs
    use "$path/OutFiles/ccm_annual_clean.dta", clear
    drop if fyear<2004

    keep gvkey fyear dvpsx_f datadate permno prcc_f 
    drop if prcc_f==.
    destring gvkey, replace
    replace dvpsx_f=0 if dvpsx_f==.
    gen divyield=dvpsx_f/prcc_f

    gen divyield_av=.
    gen nobs=.
    
    gen sum=.
    gen count=.
    replace sum=divyield
    replace count=1 if divyield!=.
    replace sum=sum+l.divyield if l.divyield!=.
    replace count=count+1 if l.divyield!=.
    replace sum=sum+l2.divyield if l2.divyield!=.
    replace count=count+1 if l2.divyield!=.
    replace divyield_av=sum/count
    
    keep gvkey fyear divyield_av datadate permno 
    gen year=year(datadate)
    gen month=month(datadate)    
    joinby year month using "$path/OutFiles/rf.dta", unmatched(master)
    drop _merge
    sum year rate7yr    
    save "$path/OutFiles/ccm_annual_4comp.dta", replace

    use "$path/OutFiles/ccm_annual_4comp.dta", clear
    keep gvkey fyear permno
    duplicates report gvkey fyear permno
    duplicates report gvkey fyear
    save "$path/OutFiles/gvkey_permno_fyear.dta", replace

    use "$path/OutFiles/execucomp_anncomp_clean.dta", clear
    joinby gvkey fyear using "$path/OutFiles/gvkey_permno_fyear.dta", unmatched(master)
    drop _merge
    sum fyear gvkey permno
    drop if permno==.
    sum fyear gvkey permno
    duplicates drop permno, force
    keep permno
    gen execucomp=1
    sort permno
    save "$path/OutFiles/permno.dta", replace

    use "$path/OutFiles/ccm_annual_4comp.dta", clear
    keep permno year month
    duplicates drop permno year month, force
    gen fyemonth=1
    save "$path/OutFiles/ccm_annual_4comp_fye.dta", replace

    * Compute return volatility from CRSP monthly file
    use "$path/InFiles/crspmonthly.dta", clear
    rename *, lower
    keep permno date ret
    gen year=year(date)
    gen month=month(date) 
    egen yearmonth=group(year month)
    joinby permno using "$path/OutFiles/permno.dta", unmatched(master)
    drop _merge
    sum year execucomp
    keep if execucomp==1
    
    egen firmid=group(permno)
    sum firmid 
    duplicates drop firmid yearmonth, force
    tsset firmid yearmonth

    sum year
    joinby permno year month using "$path/OutFiles/ccm_annual_4comp_fye.dta", unmatched(master)
    drop _merge
    sum year
    
    sort permno year month
    gen n=_n
    gen id=_n if fyemonth==1
    egen id2=group(id)

    gen sdret=.
    gen nobs=.
    save "$path/OutFiles/crspmonthly_4sdret.dta", replace
    
    use "$path/OutFiles/crspmonthly_4sdret.dta", clear
    sum firmid
    return list
    local m=300
    local q=ceil(r(max)/`m')
    forvalues j=1(1)`q'{
        use "$path/OutFiles/crspmonthly_4sdret.dta" if firmid>(`j'-1)*`m' & firmid<=`j'*`m', clear
        sum id2
        local g=r(min)
        local k=r(max)
        forvalues i=`g'(1)`k'{
            qui sum firmid if id2==`i'
            qui local f=r(max)
            qui sum n if id2==`i'    
            qui sum ret if n<=r(max) & n>r(max)-60 & firmid==`f'
            qui replace sdret=r(sd) if id2==`i'
            qui replace nobs=r(N) if id2==`i'
            di `j' ": " `i' " //// " `k' " <---- " `q'
        }
        save "$path/OutFiles/Temp/sdret_`j'.dta", replace
    }

    use "$path/OutFiles/crspmonthly_4sdret.dta", clear
    sum firmid
    local m=300
    local q=ceil(r(max)/`m')
    use "$path/OutFiles/Temp/sdret_1.dta", clear
    forvalues j=2(1)`q'{
        qui append using "$path/OutFiles/Temp/sdret_`j'.dta"
        di `i'
    }
    save "$path/OutFiles/sdret.dta", replace

    use "$path/OutFiles/sdret.dta", clear    
    sum nobs
    sum sdret,d
    replace sdret=. if nobs<12    
    drop if sdret==.
    gen fyear=year
    replace fyear=fyear-1 if month<6
    keep permno fyear sdret
    duplicates report permno fyear
    save "$path/OutFiles/sdret_cleaned.dta", replace
    
*****************************************************************
*****************************************************************
* STEP 2
*****************************************************************
*****************************************************************
    * Identify CEOs
    use "$path/OutFiles/execucomp_anncomp_clean.dta", clear
    keep gvkey fyear co_per_rol 
    destring gvkey, replace
    gen ceoindicator=1
    sort gvkey fyear co_per_rol
    duplicates drop gvkey fyear co_per_rol, force
    save "$path/OutFiles/execucomp_anncomp_clean_ceo_indicator.dta", replace

    use "$path/InFiles/execucomp_outstandingawards.dta", clear
    keep co_per_rol outawdnum opts_unex_exer opts_unex_unexer opts_unex_unearn expric prccf year exdate pceo gvkey execid 
    rename opts_unex_exer opt_vested
    rename opts_unex_unexer opt_unvested
    sum opt_* opts_unex_unearn
    drop opts_unex_unearn
    ren year fyear
    destring gvkey, replace
    joinby gvkey fyear co_per_rol using "$path/OutFiles/execucomp_anncomp_clean_ceo_indicator.dta", unmatched(master)
    drop _merge
    keep if ceoindicator==1
    sum fyear 
    joinby gvkey fyear using "$path/OutFiles/ccm_annual_4comp.dta", unmatched(master)
    drop _merge
    sum fyear year
    drop if datadate==.
    joinby permno fyear using "$path/OutFiles/sdret_cleaned.dta", unmatched(master)
    drop _merge
    sum fyear year sdret
    
    replace opt_vested=0 if opt_vested==.
    replace opt_unvested=0 if opt_unvested==.
    sum opt_vested expric exdate
    
    * Drop missing/incorrect input values (for some reason, Execucomp sometimes misses exercise price or expiration dates even if reported in proxy statement):
    drop if exdate==. | exdate<=datadate
    drop if expric==. | expric==0
    drop if sdret==.
    drop if rate7yr==.
    drop if divyield_av==.
    
    * Calculate time-to-maturity
    gen T=(exdate-datadate)/365
    replace T=0.7*T
    
    * Calculate option value
    rename expric X
    rename prccf S
    gen sigma=sdret*sqrt(12)
    gen d=divyield_av 
    gen r=rate7yr 
    
    replace d=ln(1+d)
    replace r=ln(1+r)

    * Winsorize d and sigma at 5th and 95th percentiles following Naveen code: https://sites.temple.edu/lnaveen/data/
    winsor2 d sigma, cuts(5 95) replace
    
    * Calculate option value        
    gen d1=(ln(S/X)+T*(r-d+sigma^2/2))/(sigma*sqrt(T))
    gen d2=d1-(sigma*sqrt(T))
    gen bsmc=(S*exp((-d)*T)*normal(d1)-X*exp((-r)*T)*normal(d2))

    gen options=opt_vested+opt_unvested
    gen optionvalue=bsmc*options
    
    * Sensitivity measures
    gen delta=exp(-d*T)*normal(d1)
    gen vega=exp(-d*T)*normalden(d1)*S*sqrt(T)
    
    gen sensitivity0=delta*options
    gen sensitivity1=delta*0.01*S*options
    gen sensitivity2=vega*0.01*options
    
    egen deltaclean=sum(sensitivity0), by(gvkey fyear)
    egen deltaceo=sum(sensitivity1), by(gvkey fyear)
    egen vegaceo=sum(sensitivity2), by(gvkey fyear)

    egen totaloptionvalueceo=sum(optionvalue), by(gvkey fyear)
    egen totaloptions=sum(options), by(gvkey fyear)
        
    duplicates drop gvkey fyear, force
    keep gvkey fyear deltaclean deltaceo vegaceo totaloptionvalue totaloptions r d sigma
    save "$path/OutFiles/optionvalues.dta", replace
    
    use "$path/OutFiles/execucomp_anncomp_clean.dta", clear
    * Drop observations for missing values of measures that should be reported:
    drop if shrown==. | shrown<0
    drop if pension_value_tot==.
    drop if defer_balance_tot==.
    gen ceo_idebt=pension_value_tot+defer_balance_tot    
    keep gvkey fyear ceo_age ceo_tenure shrown pension_value_tot defer_balance_tot ceo_idebt shrown_tot_pct execid salary bonus tdc1 co_per_rol opt_unex*
    replace ceo_idebt=0 if ceo_idebt<0
    duplicates drop gvkey fyear, force
    save "$path/OutFiles/execucomp_anncomp_compdata.dta", replace

*****************************************************************
*****************************************************************
* STEP 3
*****************************************************************
*****************************************************************
    use "$path/OutFiles/ccm_annual_clean.dta", clear
    joinby gvkey fyear using "$path/OutFiles/optionvalues.dta", unmatched(master)
    drop _merge
    sum fyear totaloptions*
    tabstat fyear totaloptions*, by(fyear) stats(N)
    
    sum fyear
    joinby gvkey fyear using "$path/OutFiles/execucomp_anncomp_compdata.dta", unmatched(master)
    drop _merge
    sum fyear totaloptions* deltaceo vegaceo ceo_idebt 
    
    replace totaloptionvalue=0 if totaloptionvalue==.
    replace totaloptions=0 if totaloptions==.
    replace deltaclean=0 if deltaclean==.
    replace deltaceo=0 if deltaceo==.
    replace vegaceo=0 if vegaceo==.

    gen shares=shrown
    gen sharesvalue=shares*prcc_f
    gen ceo_equity=totaloptionvalue+sharesvalue
    drop if ceo_equity==.
    drop if ceo_equity==0
    sum ceo_equity
    
    * Add shares to calculation of delta:
    replace deltaclean=deltaclean+shares*1
    replace deltaceo=deltaceo+shares*1*0.01*prcc_f
    
    * Inside debt dummy variable #1:
    gen insidedebt=0
    replace insidedebt=1 if ceo_idebt>0 & ceo_idebt!=.
    sum insidedebt
    gen insidedebt_pensions=0
    replace insidedebt_pensions=1 if pension_value_tot>0 & pension_value_tot!=.
    gen insidedebt_dc=0
    replace insidedebt_dc=1 if defer_balance_tot>0 & defer_balance_tot!=.
    sum insidedebt if insidedebt==1
    sum insidedebt if insidedebt_pensions==1 | insidedebt_dc==1
    
    * Inside debt variable #2:
    gen insidedebtratio=ceo_idebt/(ceo_idebt+ceo_equity)
    sum insidedebtratio
    gen insidedebtratio_pension=pension_value_tot/(pension_value_tot+ceo_equity)
    sum insidedebtratio_pension
    
    * Inside debt dummy variable #3:
    gen ceo_personal_leverage=ceo_idebt/ceo_equity
    sum ceo_personal_leverage,d
    gen mv=prcc_f*csho
    gen firm_leverage=(dltt+dlc)/mv
    sum firm_leverage,d
    gen ceo_relative_leverage=ceo_personal_leverage/firm_leverage
    sum ceo_relative_leverage,d
    gen relativelev=0 if ceo_relative_leverage!=.
    replace relativelev=1 if ceo_relative_leverage>1 & ceo_relative_leverage!=.
    sum relativelev

    gen ceo_personal_leverage_pension=pension_value_tot/ceo_equity
    sum ceo_personal_leverage_pension,d
    gen ceo_relative_leverage_pension=ceo_personal_leverage_pension/firm_leverage
    sum ceo_relative_leverage_pension,d
    gen relativelev_pension=0 if ceo_relative_leverage_pension!=.
    replace relativelev_pension=1 if ceo_relative_leverage_pension>1 & ceo_relative_leverage_pension!=.
    sum relativelev_pension
    
    sum insidedebt insidedebtratio relativelev

    * Relative incentive ratio:
    gen S=prcc_f
    gen X=optprcby
    gen T=4
    gen d1=(ln(S/X)+T*(r-d+sigma^2/2))/(sigma*sqrt(T))
    replace optosey=0 if optosey==.
    gen delta_fe=csho*1000*1  // csho is in millions instead of thousands
    replace delta_fe=delta_fe+exp(-d*T)*normal(d1)*optosey*1000 if optosey>0 & d1!=. // optosey is in millions instead of thousands

    gen relative_incentive_ratio=(ceo_idebt/(1000*(dlc+dltt)))/(deltaclean/delta_fe) // ceo_idebt is in thousands and dlc/dltt in millions
    sum relative_incentive_ratio, d
    gen relativeinc=0
    replace relativeinc=1 if relative_incentive_ratio>1 & relative_incentive_ratio!=.
    sum relativeinc
    
    rename shrown_tot_pct ceo_ownership
    replace ceo_ownership=ceo_ownership/100
    replace ceo_ownership=0 if ceo_ownership==.
    
    *Cash pay (Dhole, 2016, control variable)
    gen cashcomp=salary+bonus
    gen lncashcomp=ln(1+cashcomp)
    
    keep gvkey permno datadate fyear deltaceo vegaceo totaloptionvalueceo totaloptions ceo_ownership shrown pension_value_tot defer_balance_tot ceo_idebt shares sharesvalue ceo_equity insidedebt* ceo_personal_leverage* firm_leverage ceo_relative_leverage* relativelev* execid cashcomp lncashcomp relative_incentive_ratio relativeinc tdc1 co_per_rol deltaclean delta_fe ceo_age ceo_tenure
    ren tdc1 totalcomp
    
    sum datadate, f d
    drop if year(datadate)==2006 & month(datadate)<12    
    save "$path/OutFiles/firmyears_compensation.dta", replace

    /////////////////////////////////////////////////////////////////////////////////////
    // CHECK VALIDITY OF CALCULATIONS FOR EQUITY BASED ON NAVEEN CODE/DATA (https://sites.temple.edu/lnaveen/data/):
    import excel "$path/InFiles/deltavega2023_for_posting.xlsx", sheet("deltavega2023_for_posting") firstrow clear
    rename *, lower
    destring gvkey, replace
    ren year fyear
    ren delta delta_naveen
    ren vega vega_naveen
    ren coperol co_per_rol
    save "$path/OutFiles/deltavega_naveen.dta", replace
    
    use "$path/OutFiles/firmyears_compensation.dta", clear
    joinby gvkey fyear co_per_rol using "$path/OutFiles/deltavega_naveen.dta", unmatched(master)
    drop _merge
    drop if firm_related_wealth==.
    
    sum delta* vega*, d
    spearman delta*
    spearman vega*
    
    sum ceo_equity firm_related_wealth if firm_related_wealth!=., d
    spearman ceo_equity firm_related_wealth
    gen difference=abs(ceo_equity-firm_related_wealth)/firm_related_wealth
    sum difference, d    
    /////////////////////////////////////////////////////////////////////////////////////
    

