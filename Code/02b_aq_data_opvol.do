global path "C:\...\...\..."

*****************************************************************
* DD model estimation
*****************************************************************
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    drop cfo
    gen avta=(l.at+at)/2
    gen cfom1=l.oancf/avta
    gen cfo=oancf/avta
    gen cfop1=f.oancf/avta
    gen wca=(ibc-oancf+dpc)/avta
    gen dsal=(d.sale)/avta
    gen ppeg=ppegt/avta
    gen sales=sale/avta
    drop if wca==.
    drop if cfom1==.
    drop if cfo==.
    drop if cfop1==.
    drop if dsal==.
    drop if ppeg==.
    drop if sales==.

    destring sic, replace
    replace sich=sic if sich==.
    drop if sich==.
    drop if sich>5999 & sich<7000
    tostring sich, format(%04.0f) replace
    
    gen sic2=substr(sich,1,2)
    egen sic2id=group(sic2 fyear)
    egen count=count(sic2id),by(sic2id)
    drop if count<20
    drop count
    drop sic2id
    egen sic2id=group(sic2 fyear)
    keep gvkey fyear sic* wca cfom1 cfo cfop1 dsal ppeg sales permno

    winsor2 wca cfom1 cfo cfop1 dsal ppeg sales, cuts(1 99) replace by(fyear)

    gen residual=.
    gen adjr2=.
    gen b0=.
    gen b1=.
    gen b2=.
    gen b3=.
    gen b4=.
    gen b5=.

    sum sic2id
    scalar max2=r(max)
    local k=max2
    set more off
    forvalues i=1(1)`k'{
        qui reg wca cfom1 cfo cfop1 dsal ppeg if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace residual=res if sic2id==`i'
        qui replace adjr2=e(r2_a) if sic2id==`i'
        qui replace b0=_b[_cons] if sic2id==`i'
        qui replace b1=_b[cfom1] if sic2id==`i'
        qui replace b2=_b[cfo] if sic2id==`i'
        qui replace b3=_b[cfop1] if sic2id==`i'
        qui replace b4=_b[dsal] if sic2id==`i'
        qui replace b5=_b[ppeg] if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }
    sort gvkey fyear
    tabstat adjr2 residual b0 b1 b2 b3 b4 b5, stats(N mean p25 median p75) columns(statistics)
    save "$path\OutFiles\ccm_annual_dd.dta", replace
    
    use "$path\OutFiles\ccm_annual_dd.dta", clear
    sort gvkey fyear
    gen n=_n
    gen res_1=residual
    gen res_2=l.residual
    gen res_3=l2.residual
    gen res_4=l3.residual
    gen res_5=l4.residual
    reshape long res_, i(n) j(j)
    egen countobs=count(res_), by(n)
    egen sdresidual=sd(res_), by(n)
    replace sdresidual=. if countobs<3
    keep if j==1
    sort gvkey fyear
    sum sdresidual countobs
    keep gvkey fyear sdresidual countobs permno
    save "$path\OutFiles\ccm_annual_dd_sdresidual.dta", replace
    
*****************************************************************
* CFO/Sales volatility
*****************************************************************
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    drop cfo
    gen cfo=oancf/at
    replace sale=. if sale<=0
    gen sales=sale/at
    drop if cfo==.
    drop if sales==.

    gen earn=ib/at

    sort gvkey fyear
    gen n=_n
    gen cfo_1=cfo
    gen cfo_2=l.cfo
    gen cfo_3=l2.cfo
    gen cfo_4=l3.cfo
    gen cfo_5=l4.cfo
    gen sal_1=sales
    gen sal_2=l.sales
    gen sal_3=l2.sales
    gen sal_4=l3.sales
    gen sal_5=l4.sales
    gen earn_1=earn
    gen earn_2=l.earn
    gen earn_3=l2.earn
    gen earn_4=l3.earn
    gen earn_5=l4.earn
    reshape long cfo_ sal_ earn_, i(n) j(j)
    egen countobs=count(cfo_), by(n)
    egen sdcfo=sd(cfo_), by(n)
    egen sdsal=sd(sal_), by(n)
    egen sdearn=sd(earn_), by(n)
    replace sdcfo=. if countobs<3
    replace sdsal=. if countobs<3
    replace sdearn=. if countobs<4 //sdearn requires minimum 4 years, following Dhole et al. (2016)
    keep if j==1
    sort gvkey fyear
    
    sum sdcfo sdsal sdearn countobs
    keep gvkey fyear sdcfo sdsal sdearn countobs
    duplicates drop gvkey fyear, force
    save "$path\OutFiles\opvolatility.dta", replace
    
