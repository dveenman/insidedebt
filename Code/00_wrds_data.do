global path "C:\...\...\..."

* This file contains the code to download the input data from WRDS directly through Stata

    **************************************************************************
    * First check how tables are named and located where 
    **************************************************************************
    odbc load, exec("select distinct frname from wrds_lib_internal.friendly_schema_mapping;") dsn("wrds-pgdata-64") clear
    list    
    
    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='crsp' order by table_name;") dsn("wrds-pgdata-64") clear
    list

    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='ibes' order by table_name;") dsn("wrds-pgdata-64") clear
    list
    
    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='audit' order by table_name;") dsn("wrds-pgdata-64") clear
    list

    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='comp' order by table_name;") dsn("wrds-pgdata-64") clear
    list

    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='execcomp' order by table_name;") dsn("wrds-pgdata-64") clear
    list

    odbc load, exec("select distinct table_name from information_schema.columns where table_schema='risk' order by table_name;") dsn("wrds-pgdata-64") clear
    list
    
    **************************************************************************
    * Get CCM linking table
    **************************************************************************
    odbc load, exec("select * from crsp.ccmxpf_lnkhist") noquote dsn("wrds-pgdata-64") clear
    gduplicates report gvkey 
    save "$path\InFiles\ccmxpf_lnkhist.dta"    

    **************************************************************************
    * Get CRSP data
    **************************************************************************
    odbc load, exec("select * from crsp.stocknames") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\stocknames.dta"    

    odbc load, exec("select * from crsp.msf where date>'20000101'") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\crspmonthly.dta"    

    odbc load, exec("select date,vwretd from crsp.msi where date>'20000101'") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\crspmonthly_vwretd.dta"    

    **************************************************************************
    * Get AA data
    **************************************************************************
    odbc load, exec("select * from audit.auditnonreli") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\auditnonreli.dta"    

    odbc load, exec("select company_fkey,auditor_fkey,fiscal_year_of_op from audit.auditopin") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\auditopin.dta"    
    
    **************************************************************************
    * Get Compustat pension data
    **************************************************************************
    odbc load, exec("select * from comp.aco_pnfnda") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\aco_pnfnda.dta"    
    
    **************************************************************************
    * Get Compustat accounting data
    **************************************************************************
    global query ///
        select * ///
        from comp.funda ///
        where datadate>'20000101' ///
        and indfmt='INDL' ///
        and datafmt='STD'

    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear
    sum fyear at
    save "$path\InFiles\funda.dta"    

    odbc load, exec("select * from comp.company") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\company.dta"    
    
    **************************************************************************
    * Get Compustat data for firm age variable
    **************************************************************************
    global query ///
        select gvkey, datadate, fyear, at, revt ///
        from comp.funda ///
        where indfmt='INDL' ///
        and datafmt='STD'

    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear
    sum fyear at
    save "$path\InFiles\funda_1950_2024.dta"    
    
    **************************************************************************
    * Get Execucomp data
    **************************************************************************
    odbc load, exec("select * from execcomp.anncomp where year>='2004'") noquote dsn("wrds-pgdata-64") clear
    save "$path\InFiles\execucomp_anncomp.dta"    

    odbc load, exec("select * from execcomp.outstandingawards where year>='2004'") noquote dsn("wrds-pgdata-64") clear
    drop address city state zip tele sicdesc naicsdesc inddesc
    save "$path\InFiles\execucomp_outstandingawards.dta"    
    
    **************************************************************************
    * Get IBES data
    **************************************************************************
    global query ///
        select * ///
        from ibes.actu_epsus ///
        where anndats>'20040101' ///
        and measure='EPS' ///
        and pdicity='ANN' 
    
    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear 
    save "$path\InFiles\ibes_actuals.dta"    

    global query ///
        select * ///
        from ibes.statsumu_epsus ///
        where statpers>'20040101' ///
        and measure='EPS' ///
        and fpi='1' 
    
    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear 
    save "$path\InFiles\ibes_statsumu.dta"    

    global query ///
        select * ///
        from ibes.statsumu_epsus ///
        where statpers>'20040101' ///
        and measure='EPS' ///
        and fpi='6' 
    
    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear 
    save "$path\InFiles\ibes_statsumu_quarterly.dta"    

    global query ///
        select * ///
        from ibes.actu_epsus ///
        where anndats>'20040101' ///
        and measure='EPS' ///
        and pdicity='QTR' 
    
    odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear 
    save "$path\InFiles\ibes_actuals_quarterly.dta"    
    
    **************************************************************************
    * Get directors data
    **************************************************************************
    odbc load, exec("select * from risk.directors") noquote dsn("wrds-pgdata-64") clear
    compress
    save "$path\InFiles\iss_directors.dta"    
    
    /* SQL/server error message, so downloaded from WRDS website instead:
    odbc load, exec("select * from risk.rmdirectors") noquote dsn("wrds-pgdata-64") clear
    compress
    save "$path\InFiles\iss_directors_new.dta"    */
    
    odbc load, exec("select * from risk.dirnames") noquote dsn("wrds-pgdata-64") clear
    compress
    save "$path\InFiles\iss_dirnames.dta"    
    
    **************************************************************************
    * Get institutional ownership data
    **************************************************************************
    odbc load, exec("select * from tfn.s34 where rdate>'20041231'") noquote dsn("wrds-pgdata-64") clear
    compress
    keep rdate cusip ticker shrout1 shrout2 prc shares mgrno
    save "$path\InFiles\s34.dta"    
    
