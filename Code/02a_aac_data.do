global path "C:\...\...\..."

*****************************************************************
* Compute discretionary accruals using CRSP/Compustat merged file
*****************************************************************
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    gen lagta=l.at
    gen tacc=(ibc-oancf)/lagta
    gen drev=(d.sale-d.rect)/lagta
    gen inverse_a=1/lagta
    gen ppe=ppegt/lagta
    gen roa=ibc/lagta
    
    drop cfo
    gen cfo=oancf/lagta    
    
    drop if tacc==.
    drop if drev==.
    drop if ppe==.
    drop if roa==.
    
    keep if fyear>=2003
    
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
    
    gen tacc0=tacc
    winsor2 tacc drev inverse_a ppe roa cfo, cuts(1 99) replace by(fyear)
    
    gen dcfo=0
    replace dcfo=1 if cfo<0
    gen dcfocfo=dcfo*cfo
    
    gen da=.
    gen da_roa=.
    gen da_cfo=.
    gen r2a=.
    gen r2a_roa=.
    gen r2a_cfo=.

    sum sic2id
    local k=r(max)
    forvalues i=1(1)`k'{
        qui reg tacc inverse_a drev ppe if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da=res if sic2id==`i'
        qui drop res
        qui replace r2a=e(r2_a) if sic2id==`i'
        qui reg tacc inverse_a drev ppe roa if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da_roa=res if sic2id==`i'
        qui replace r2a_roa=e(r2_a) if sic2id==`i'
        qui drop res
        qui reg tacc inverse_a drev ppe cfo dcfo dcfocfo if sic2id==`i'
        qui predict res if sic2id==`i', res
        qui replace da_cfo=res if sic2id==`i'
        qui replace r2a_cfo=e(r2_a) if sic2id==`i'
        qui drop res
        di `i' " / " `k'
    }
    egen nobs2=count(sic2id), by(sic2id)
    sort sic2id
    by sic2id: gen n=_n
    replace nobs=. if n>1
    sum da da_roa da_cfo r2*
    pwcorr da da_roa da_cfo
    gen absda=abs(da)
    gen absda_roa=abs(da_roa)
    gen absda_cfo=abs(da_cfo)
    
    * Non-model based DA:
    egen mean=mean(tacc), by(sic2id)
    gen da_basic=tacc-mean
    gen absda_basic=abs(da_basic)
    ren sic2id sic2id_ccm
    
    keep gvkey fyear da da_roa absda* nobs2 r2a* da_basic sic2id_ccm tacc roa da_cfo tacc0 inverse_a drev ppe cfo dcfo*
    ren roa roa_da
    save "$path\OutFiles\ccm_annual_da.dta", replace
    

    