global path "C:\...\...\..."

***************************************************
* Identify firms in the Compustat/CRSP merged file
***************************************************
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    keep permno
    gen ccm=1
    duplicates drop permno, force
    save "$path\OutFiles\ccm_firms.dta", replace

***************************************************
* Identify fiscal year end months
***************************************************
    use "$path\OutFiles\ccm_annual_clean.dta", clear
    keep permno datadate
    gen year=year(datadate)
    gen month=month(datadate)
    drop datadate
    gen fyemonth=1
    keep permno year month fyemonth
    save "$path\OutFiles\ccm_firms_fyemonth.dta", replace
    
***************************************************
* Prepare return file for market model estimations
***************************************************
    use "$path\InFiles\crspmonthly.dta", clear
    joinby date using "$path\InFiles\crspmonthly_vwretd.dta", unmatched(master)
    drop _merge
    
    keep permno date hsiccd ret vwretd shrout prc
    ren hsiccd siccd
    gen year=year(date)
    gen month=month(date)
    egen yearmonth=group(year month)
    joinby permno using "$path\OutFiles\ccm_firms.dta", unmatched(master)
    drop _merge
    sum date ccm
    replace ccm=0 if ccm==.
    sum date ccm, f
        
    * Compute monthly industry return
    drop if ret==.
    drop if ret==.b
    drop if ret==.c
    drop if prc==.
    drop if shrout==.

    * Take absolute value of price (CRSP indicates bid-ask mean values as negative)
    replace prc=abs(prc)

    * Create market value to be able to value-weight
    gen mv=shrout*prc
    tsset permno yearmonth
    * Calculate lagged market value so that we determine weight at the beginning of the period (end of previous period) so that there is no mechanical relation between market value and returns from the same period
    gen lagmv=l.mv
    drop if lagmv==.
    rename vwretd vwretd_market

    * Clean up industry variable and create groups based on 2-digit SIC
    drop if siccd==.
    drop if siccd==0
    tostring siccd, format(%04.0f) replace
    gen sic2=substr(siccd,1,2)
    egen sic2id=group(sic2 yearmonth)
    sort sic2id
    egen count=count(sic2id), by(sic2id)
    drop if count<20
    drop count sic2id
    egen sic2id=group(sic2 yearmonth)

    *********************************************
    * Value weighted industry returns
    *********************************************
    * Sum market value per industry to be able to calculate individual weights
    egen summv_ind=sum(lagmv),by(sic2id yearmonth)
    gen weight_ind=lagmv/summv_ind
    sum weight_ind
    * First calculate the value-weighted return including securitity i
    gen wret_ind=weight_ind*ret
    egen vwret0_ind=sum(wret_ind), by(sic2id yearmonth)
    * Now substract the firm from the market value of the industry-year
    gen summv2_ind=summv_ind-mv
    gen vwretd_ind=vwret0_ind-((ret-vwret0_ind)*(lagmv/summv2_ind))
    drop summv2_ind vwret0_ind wret_ind weight_ind summv_ind

    keep if ccm==1
    * Inspect the data:    
    sum ret vwretd_market vwretd_ind 
    sum ret,d
    sum vwretd_ind,d
        
    gen sdres24=.
    gen sdres24_n=.
    gen sdres12=.
    gen sdres12_n=.
    gen mse24=.
    gen mse12=.
    
    * Identify the month if fiscal year end to reduce the number of calculations:
    joinby permno year month using "$path\OutFiles\ccm_firms_fyemonth.dta", unmatched(master)
    drop _merge
    sum ret fyemonth
    
    * This is going to be first dimension for the loop, run from first to the last company
    egen firmid=group(permno)    
    sort firmid yearmonth
    * This is going to be the second dimension of the loop, run from first month of the company until the last month of the company
    by firmid: gen n=_n
    by firmid: gen n0=_n if fyemonth==1
    egen nn=group(firmid n0)
    egen count=count(nn), by(permno)
    sum count
    drop if count==0
    drop count n n0 nn firmid
    egen firmid=group(permno)    
    sort firmid yearmonth
    by firmid: gen n=_n
    by firmid: gen n0=_n if fyemonth==1
    egen nn=group(firmid n0)
    egen count=count(nn), by(permno)
    sum count
    keep permno ret year month vwretd_market vwretd_ind sdres* firmid n nn mse* sic2
    compress
    save "$path\OutFiles\crspmonthly_loopready.dta", replace

************************************************************    
* Market model regressions
************************************************************    
    use "$path\OutFiles\crspmonthly_loopready.dta", clear
    local m=10
    sum firmid
    local q=ceil(r(max)/`m')
    di `q'
    forvalues j=1(1)`q'{
        use "$path\OutFiles\crspmonthly_loopready.dta" if firmid>(`j'-1)*`m' & firmid<=`j'*`m', clear
        qui sum nn
        if r(N)>0{
            local a=r(min)
            local b=r(max)
            forvalues i=`a'(1)`b'{
                qui sum firmid if nn==`i'
                local f=r(max)
                qui sum n if nn==`i'
                local y=r(max)
                qui sum ret if n>=(`y'-23) & n<=(`y') & firmid==`f'
                if r(N)>=12{
                    qui reg ret vwretd_market vwretd_ind if n>=(`y'-23) & n<=(`y') & firmid==`f'
                    qui predict res if n>=(`y'-23) & n<=(`y') & firmid==`f', res
                    qui sum res
                    qui replace sdres24=r(sd) if nn==`i' & firmid==`f'
                    qui replace sdres24_n=r(N) if nn==`i' & firmid==`f'
                    qui gen res2=res*res if n>=(`y'-23) & n<=(`y') & firmid==`f'
                    qui sum res2 if n>=(`y'-23) & n<=(`y') & firmid==`f'
                    qui replace mse24=r(mean) if nn==`i' & firmid==`f'
                    qui drop res res2
                }
                qui sum ret if n>=(`y'-11) & n<=(`y') & firmid==`f'
                if r(N)>=12{
                    qui reg ret vwretd_market vwretd_ind if n>=(`y'-11) & n<=(`y') & firmid==`f'
                    qui predict res if n>=(`y'-11) & n<=(`y') & firmid==`f', res
                    qui sum res
                    qui replace sdres12=r(sd) if nn==`i' & firmid==`f'
                    qui replace sdres12_n=r(N) if nn==`i' & firmid==`f'
                    qui gen res2=res*res if n>=(`y'-11) & n<=(`y') & firmid==`f'
                    qui sum res2 if n>=(`y'-11) & n<=(`y') & firmid==`f'
                    qui replace mse12=r(mean) if nn==`i' & firmid==`f'
                    qui drop res res2
                }
                di `j' " / " `q' " --- " `i' " / " `b'
            }
            qui drop if nn==.
            qui keep permno year month mse* sdres*
            qui save "$path\OutFiles\Temp\mse_idioshock_`j'.dta", replace
        }
    }

**************************************************
* Append sub-files and create final file
**************************************************
    use "$path\OutFiles\crspmonthly_loopready.dta", clear
    keep permno year month sic2
    save "$path\OutFiles\crspmonthly_loopready_sic2.dta", replace
    
    use "$path\OutFiles\crspmonthly_loopready.dta", clear
    local m=10
    sum firmid
    local q=ceil(r(max)/`m')
    use "$path\OutFiles\Temp\mse_idioshock_1.dta", clear
    forvalues j=2(1)`q'{
        qui append using "$path\OutFiles\Temp\mse_idioshock_`j'.dta"
        di `j'
    }
    
    sum sdres24_n,d
    sum sdres12_n,d
    
    rename sdres24 idioshock2
    rename sdres12 idioshock1
    drop if idioshock2==.
    
    joinby permno year month using "$path\OutFiles\crspmonthly_loopready_sic2.dta", unmatched(master)    
    drop _merge
    gen fyear=year
    replace fyear=fyear-1 if month<6
    
    egen sic2id=group(sic2 fyear)
    egen count=count(sic2id), by(sic2id)
    sum count, d
    egen sum_idioshock2=sum(idioshock2) if count>1, by(sic2id)
    gen peeridioshock2=(sum_idioshock2-idioshock2)/(count-1)
    drop sic2id sum_idioshock2 count    
    save "$path\OutFiles\mse_idioshock.dta", replace

    use "$path\OutFiles\mse_idioshock.dta", clear
    sum idioshock2
    
