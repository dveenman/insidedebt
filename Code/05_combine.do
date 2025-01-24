global path "C:\...\...\..."

    use "$path/OutFiles/ccm_annual_clean.dta", clear
    sum fyear, d
    
            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            drop gid
    
    gen lagta=l.at
    gen lnta=ln(at)
    gen mv=prcc_f*csho
    gen btm=ceq/mv
    *He (2015) controls for market-to-book, and we control for book-to-market.
    gen mtb=mv/ceq
    gen lnmv=ln(mv)
    gen debt=(dlc+dltt)/at
    *He (2015) controls for Debt as "The ratio of long-term debt to total assets at the beginning of a fiscal year". We measure it at the end of the fiscal year
    gen lag_debt=l.debt
    gen salesgr=sale/l.sale-1
    *He (2015) calculates ROA as income before extraordinary items (ib) divided by total assets for the fiscal year
    gen roa=ib/at
    gen loss=0
    replace loss=1 if ib<0
    *He (2015) defines loss based on operating income. We use operating income after depreciation (oiadp)
    gen loss_operating=0
    replace loss_operating=1 if oiadp<0
    
    // Cadman and Vincent (2015) additional variables:
    gen fcf=(oancf-capx)/at
    gen rnd=xrd/at
    replace rnd=0 if xrd<0 | xrd==.
    gen lev=(dltt+dlc)/at
    
    // Loss frequency:
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

    drop if sich>5999 & sich<7000    
    
            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            drop gid
    
    joinby gvkey datadate using "$path\OutFiles\comp_pensions.dta", unmatched(master)
    drop _merge
    sum fyear ppsc
    gen bdb=0
    replace bdb=1 if ppsc>0 & ppsc!=.
    tabstat bdb, by(fyear)
    
    joinby gvkey fyear using "$path/OutFiles/ccm_annual_da.dta", unmatched(master)
    drop _merge
    drop if absda==.
    
            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            drop gid

    joinby gvkey fyear using "$path/OutFiles/ccm_annual_dd_sdresidual.dta", unmatched(master)
    drop _merge
    drop countobs

    joinby gvkey fyear using "$path/OutFiles/opvolatility.dta", unmatched(master)
    drop _merge

    gen year=year(datadate)
    gen month=month(datadate)
    
    joinby permno year month using "$path/OutFiles/mse_idioshock.dta", unmatched(master)
    drop _merge
        
    joinby cik fyear using "$path/Outfiles/auditanalytics_restatement2.dta", unmatched(master)
    drop _merge
    replace restatement=0 if restatement==.
    replace restatement_severe=0 if restatement_severe==.

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
    drop if ceo_age==.
    drop if ceo_tenure==.
    gen lnceo_age=ln(ceo_age)
    gen lnceo_ten=ln(ceo_tenure)
    
            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            drop gid
            
    drop if salesgr==.
    drop if roa==.
    drop if btm==.
    drop if debt==.
    drop if idioshock2==.
    drop if sdcfo==.

            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021 & year(datadate)<=2021
            drop gid

            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & sdresidual!=. & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            drop gid

            egen gid=group(gvkey) if fyear>2005 & fyear<=2021 & mjb!=. & disp!=. & year(datadate)<=2021
            sum gid if fyear>2005 & fyear<=2021 & year(datadate)<=2021
            drop gid
            
    gen lndelta=ln(1+deltaceo)
    gen lnvega=ln(1+vegaceo)
    gen lndisp=ln(1+100*disp)
    gen lnnumest=ln(1+numest)

    keep if fyear>2005 & fyear<=2021
    drop if year(datadate)>2021

    sum datadate, f d
    
    *Firm age
    joinby gvkey using "$path\OutFiles\firm_age.dta", unmatched(master)
    drop _merge
    gen firm_age=fyear-fyear_first
    gen lnfirm_age=ln(firm_age)
    
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

    xtile xrelativelev=ceo_relative_leverage if ceo_relative_leverage!=0, nq(10)
    replace xrelativelev=0 if xrelativelev==. & debt!=0
    replace xrelativelev=(xrelativelev)/10    

    xtile xrelativeinc=relative_incentive_ratio if relative_incentive_ratio!=0, nq(10)
    replace xrelativeinc=0 if xrelativeinc==. & debt!=0
    replace xrelativeinc=(xrelativeinc)/10
    
    xtile xrelativelev_pension=ceo_relative_leverage_pension if ceo_relative_leverage_pension!=0, nq(10)
    replace xrelativelev_pension=0 if xrelativelev_pension==. & debt!=0
    replace xrelativelev_pension=(xrelativelev_pension)/10    
    
    sum fyear
    local a=r(min)
    local b=r(max)
    forvalues i=`a'(1)`b'{
        qui gen yeardum_`i'=0
        qui replace yeardum_`i'=1 if fyear==`i'
    }    
    
    replace sic=sich
    tostring sich, replace

    * Fama/French 12 industries:
        gen ff12=.
    * 1 NoDur  Consumer NonDurables : Food, Tobacco, Textiles, Apparel, Leather, Toys
        replace ff12=1 if sic>=100 & sic<=999
        replace ff12=1 if sic>=2000 & sic<=2399
        replace ff12=1 if sic>=2700 & sic<=2749
        replace ff12=1 if sic>=2770 & sic<=2799
        replace ff12=1 if sic>=3100 & sic<=3199
        replace ff12=1 if sic>=3940 & sic<=3989
    * 2 Durbl  Consumer Durables : Cars, TV's, Furniture, Household Appliances
        replace ff12=2 if sic>=2500 & sic<=2519
        replace ff12=2 if sic>=2590 & sic<=2599
        replace ff12=2 if sic>=3630 & sic<=3659
        replace ff12=2 if sic>=3710 & sic<=3711
        replace ff12=2 if sic>=3714 & sic<=3714
        replace ff12=2 if sic>=3716 & sic<=3716
        replace ff12=2 if sic>=3750 & sic<=3751
        replace ff12=2 if sic>=3792 & sic<=3792
        replace ff12=2 if sic>=3900 & sic<=3939
        replace ff12=2 if sic>=3990 & sic<=3999
    * 3 Manuf  Manufacturing : Machinery, Trucks, Planes, Off Furn, Paper, Com Printing
        replace ff12=3 if sic>=2520 & sic<=2589
        replace ff12=3 if sic>=2600 & sic<=2699
        replace ff12=3 if sic>=2750 & sic<=2769
        replace ff12=3 if sic>=3000 & sic<=3099
        replace ff12=3 if sic>=3200 & sic<=3569
        replace ff12=3 if sic>=3580 & sic<=3629
        replace ff12=3 if sic>=3700 & sic<=3709
        replace ff12=3 if sic>=3712 & sic<=3713
        replace ff12=3 if sic>=3715 & sic<=3715
        replace ff12=3 if sic>=3717 & sic<=3749
        replace ff12=3 if sic>=3752 & sic<=3791
        replace ff12=3 if sic>=3793 & sic<=3799
        replace ff12=3 if sic>=3830 & sic<=3839
        replace ff12=3 if sic>=3860 & sic<=3899
    * 4 Enrgy  Oil, Gas, and Coal Extraction and Products
        replace ff12=4 if sic>=1200 & sic<=1399
        replace ff12=4 if sic>=2900 & sic<=2999
    * 5 Chems  Chemicals and Allied Products
        replace ff12=5 if sic>=2800 & sic<=2829
        replace ff12=5 if sic>=2840 & sic<=2899
    * 6 BusEq  Business Equipment : Computers, Software, and Electronic Equipment
        replace ff12=6 if sic>=3570 & sic<=3579
        replace ff12=6 if sic>=3660 & sic<=3692
        replace ff12=6 if sic>=3694 & sic<=3699
        replace ff12=6 if sic>=3810 & sic<=3829
        replace ff12=6 if sic>=7370 & sic<=7379
    * 7 Telcm  Telephone and Television Transmission
        replace ff12=7 if sic>=4800 & sic<=4899
    * 8 Utils  Utilities
        replace ff12=8 if sic>=4900 & sic<=4949
    * 9 Shops  Wholesale, Retail, and Some Services (Laundries, Repair Shops)
        replace ff12=9 if sic>=5000 & sic<=5999
        replace ff12=9 if sic>=7200 & sic<=7299
        replace ff12=9 if sic>=7600 & sic<=7699
    *10 Hlth   Healthcare, Medical Equipment, and Drugs
        replace ff12=10 if sic>=2830 & sic<=2839
        replace ff12=10 if sic>=3693 & sic<=3693
        replace ff12=10 if sic>=3840 & sic<=3859
        replace ff12=10 if sic>=8000 & sic<=8099
    *11 Money  Finance
        replace ff12=11 if sic>=6000 & sic<=6999
    *12 Other  Other : Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment
        replace ff12=12 if ff12==.

    egen sic2id=group(sic2)
    sum sic2id
    local a=r(min)
    local b=r(max)
    forvalues i=`a'(1)`b'{
        qui gen indusdum_`i'=0
        qui replace indusdum_`i'=1 if sic2id==`i'
    }    

    // Winsorize variables:
    winsor2 absda* sdresidual sdcfo sdsal firm_leverage debt at salesgr ceo_ownership deltaceo vegaceo numest disp lnmv lnta lndelta lnvega lnnumest lndisp idioshock2 ceo_relative_leverage btm roa fcf rnd lev lnceo_* firm_age lnfirm_age lncashcomp sdearn cashcomp ceo_age ceo_tenure ceo_idebt pension_value_tot defer_balance_tot ceo_equity, replace cuts(1 99)

    keep gvkey fyear datadate sic2* absda absda_roa absda_cfo absda_basic sdresidual lnta at btm debt lnfirm_age firm_age salesgr inst lnnumest numest big4 bdb lncashcomp cashcomp ceo_ownership lndelta lnvega deltaceo vegaceo lnceo_age ceo_age lnceo_ten ceo_tenure sdcfo sdsal idioshock2 roa lossperc rnd sdearn insidedebt insidedebtratio relativelev xrelativelev pension_value_tot pension_value_tot defer_balance_tot ff12 insidedebt_* ceo_idebt pension_value_tot defer_balance_tot ceo_equity ceo_relative_leverage restatement restatement_severe mjb mbe tacc ppe drev
    
    save "$path/OutFiles/firmyears_compensation2.dta", replace

