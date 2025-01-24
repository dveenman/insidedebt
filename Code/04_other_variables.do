global path "C:\...\...\..."

****************************************************************    
* Historical HQ-states from 8-K filings for IV tests:
****************************************************************    
    // Obtained from https://mingze-gao.com/posts/firm-historical-headquarter-state-from-10k/
    import delimited "$path\InFiles\hist_state_zipcode_from_8k_2004_2022.csv", delimiter(comma) clear 
    keep cik year state
    ren state state_hist
    save "$path\OutFiles\states_hq.dta", replace

****************************************************************    
* State tax variable for IV approach:
****************************************************************    
    // Obtained from https://taxsim.nber.org/state-rates/
    use "$path\InFiles\state_tax_rates.dta", clear 
    ren var1 year
    ren var12 state 
    ren var4 taxrate_wage
    ren var7 taxrate_gain
    ren var10  taxrate_mort
    order state, before(year)
    keep state year taxra*
    drop if state=="federal"
    joinby state using "$path\InFiles\state_abbreviations.dta", unmatched(master)
    drop _merge
    replace state=stateid
    drop stateid
    compress
    save "$path\OutFiles\state_tax_rates.dta", replace

****************************************************************    
* Create linking table for CUSIP-PERMNO link Thomson data (and ISS for He (2015) directors data)
****************************************************************    
    use "$path\InFiles\stocknames.dta", clear
    replace cusip=ncusip if ncusip!="" & ncusip!=cusip
    gen cusip6=substr(cusip, 1, 6)
    ren cusip cusip8
    drop if year(nameenddt)<2003
    keep cusip6 cusip8 permno namedt nameenddt ticker
    sort permno namedt
    save "$path\OutFiles\stocknames_permno_cusip.dta", replace

****************************************************************    
* Institutional investor ownership
****************************************************************    
    use "$path\InFiles\s34.dta", clear
    keep rdate cusip ticker shrout1 shrout2 shares mgrno
    drop if cusip=="" | shares==.
    sort cusip rdate 
    gegen double shares_held=sum(shares), by(cusip rdate)
    gen double total_shares_out=shrout2 if shrout2!=. & shrout2>0
    replace total_shares_out=shrout1*1000 if total_shares_out==. & shrout1!=. & shrout1>0
    drop if total_shares_out==0 | total_shares_out==.
    // Fix issue with some firm-quarters having different outstanding shares listed:
    gegen hulp=median(total_shares_out), by(cusip rdate)
    replace total_shares_out=hulp
    gen double held_pct=shares_held/(total_shares_out*1000)
    drop if held_pct==.
    gduplicates drop cusip rdate, force
    keep cusip rdate shares_held total_shares_out held_pct
    sort cusip rdate
    gen year=year(rdate)
    gen quarter=quarter(rdate)
    drop rdate
    rename cusip cusip8
    save "$path\OutFiles\inst.dta", replace
    
****************************************************************    
* Big 4 dummy
****************************************************************    
    use "$path\InFiles\auditopin.dta", clear
    ren company_fkey cik
    gen big4=0
    replace big4=1 if auditor_fkey>=1 & auditor_fkey<=4
    sum big4
    ren fiscal_year_of_op fyear
    duplicates report cik fyear
    egen max=max(big4), by(cik fyear)
    replace big4=max
    duplicates drop cik fyear, force
    keep cik fyear big4
    save "$path\OutFiles\big4.dta", replace

****************************************************************    
* Broad-based DB plans
****************************************************************    
    use "$path\InFiles\aco_pnfnda.dta", clear
    keep gvkey datadate ppsc
    destring gvkey, replace
    duplicates report gvkey datadate
    save "$path\OutFiles\comp_pensions.dta", replace
        
****************************************************************    
* Restatements
****************************************************************    
    use "$path\InFiles\auditnonreli.dta", clear
    keep if res_accounting==1
    drop if res_cler_err==1
    keep if res_adverse==1
    
    gen severe=0
    replace severe=1 if res_fraud==1 | res_sec==1
    keep res_begin_date res_end_date company_fkey severe res_notif_key file_date_num
    ren company_fkey cik
    gen year_start=year(res_begin_date)
    gen month_start=month(res_begin_date)
    gen year_end=year(res_end_date)
    gen month_end=month(res_end_date)
    drop if year_start<2000
    gen diff=round((res_end_date-res_begin_date)/30)
    sum diff,d
    replace diff=1 if diff==0
    local k=r(max)
    forvalues i=1(1)`k'{
        gen m_`i'=`i' if diff>=`i'
    }    

    gen id=_n
    reshape long m_, i(id) j(j)
    drop if m_==.
    gen m=m_-1
    gen year=year_start
    gen month=month_start+m
    sort cik year month
    sum month,d
    local k=r(max)
    while `k'>12 { 
        replace year=year+1 if month>12
        replace month=month-12 if month>12
        sum month
        local k=r(max)
    }
    keep cik year month severe file_date_num
    sort cik year month
    duplicates report cik year month, force
    egen max=max(severe), by(cik year month)
    replace severe=max
    drop max
    egen min=max(file_date_num), by(cik year month)
    replace file_date_num=min
    drop min
    duplicates drop cik year month, force
    gen rest=1
    save "$path\Outfiles\auditanalytics_restatement.dta", replace

    use "$path\OutFiles\ccm_annual_clean.dta", clear
    drop if cik==""
    keep cik datadate fyear
    gen year=year(datadate)
    gen month=month(datadate)
    forvalues i=1(1)12{
        gen m_`i'=`i'
    }
    gen id=_n
    reshape long m_, i(id) j(n)
    replace month=month+1-m_
    replace year=year-1 if month<1
    replace month=month+12 if month<1
    drop id n m_
    sort cik year month
    duplicates drop cik year month fyear, force        
    joinby cik year month using "$path\Outfiles\auditanalytics_restatement.dta", unmatched(master)
    drop _merge
    sum fyear rest
    egen restatement=max(rest), by(cik fyear)
    egen restatement_severe=max(severe), by(cik fyear)
    egen res_anndate=min(file_date_num), by(cik fyear)
    format res_anndate %d
    replace restatement=0 if restatement==.
    replace restatement_severe=0 if restatement_severe==.
    keep cik fyear restatement* res_anndate
    duplicates drop cik fyear, force
    sum restatement*
    sort cik fyear
    save "$path\Outfiles\auditanalytics_restatement2.dta", replace

****************************************************************    
* Analyst coverage and meet/beat variables    
****************************************************************
    use "$path\InFiles\stocknames.dta", clear
    replace cusip=ncusip if ncusip!="" & ncusip!=cusip
    egen mind=min(namedt), by(permno cusip)
    egen maxd=max(nameenddt), by(permno cusip)
    format mind maxd %d
    keep cusip permno mind maxd
    duplicates drop cusip permno, force
    duplicates drop cusip, force
    sort cusip
    save "$path\OutFiles\stocknames2.dta", replace

    * Clean actuals file
    use "$path\InFiles\ibes_actuals.dta", clear
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
    sort ticker pends anndats actdats acttims
    duplicates drop ticker pends anndats, force
    duplicates drop ticker pends, force
    keep ticker pends anndats value
    ren value actual
    save "$path\OutFiles\ibes_actuals_clean.dta", replace
    
    * Clean forecast file and attach actuals + permno
    use "$path\InFiles\ibes_statsumu.dta", clear
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
    joinby ticker pends using "$path\OutFiles\ibes_actuals_clean.dta", unmatched(master)
    drop _merge
    drop if anndats==.
    * Keep only forecast consensus measured at least 1 day before earnings announcement:
    drop if statpers>=anndats-1
    * Keep only latest consensus before earnings announcement:
    gsort ticker pends -statpers
    duplicates drop ticker pends, force
    duplicates drop permno pends, force
    gen surprise=actual-medest
    * Generate variables of interest
    gen mjb=0
    replace mjb=1 if surprise>=0 & surprise<=0.01
    gen mbe=0
    replace mbe=1 if surprise>=0
    gen mjb_perc=0
    replace mjb_perc=1 if (surprise/medest)>=0 & (surprise/medest)<=0.01
    gen justmbe=mjb
    gen largembe=0
    replace largembe=1 if surprise>=0.04
    sum mjb mbe largembe mjb_perc
    keep permno pends ticker stdev numest mjb surprise mbe cusip mjb_perc largembe justmbe
    ren cusip cusip_ibes
    ren pends datadate 
    ren ticker ticker_ibes
    ren stdev disp
    save "$path\OutFiles\ibes_analyst_variables.dta", replace
            
****************************************************************    
* Firm age
****************************************************************    
    use "$path\InFiles\funda_1950_2024.dta", clear
    drop if at==. & revt==.
    destring gvkey, replace
    keep gvkey fyear
    sort gvkey fyear
    duplicates drop gvkey, force
    rename fyear fyear_first
    save "$path\OutFiles\firm_age.dta", replace
