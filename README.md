# Does CEO Inside Debt Really Improve Financial Reporting Quality?
 Code repository for reexamination and replications
 *By Stefano Cascino, Mate Szeles, and David Veenman*

 <hr>

This repository contains the Stata code to replicate the results of Cascino, Szeles, and Veenman (2025) "Does CEO Inside Debt Really Improve Financial Reporting Quality?" The main paper presents a *reexamination* of the relation between inside debt and measures of financial reporting quality using research design choices independent from prior research, while the Online Appendix presents *replications* of two prior studies that documented a significant negative association between inside debt variables and inverse measures of financial reporting quality.

The repository contains the following do-files:

- **00_wrds_data.do**: contains the queries we used to obtain data from the WRDS platform. Note that because of continuous updates made to the underlying databases on WRDS, the sample sizes obtained from running the code will unlikely be exactly the same as we present in the paper. 
- **01_ccm.do**: contains (a) a list of external ado Stata programs used (and their versions) and (b) code to create a CRSP/Compustat intersection of firm-year observations.
- **02a_aac_data.do**: contains code used to construct discretionary accrual measures of financial reporting quality.
- **02b_aq_data_opvol.do**: contains code used to construct Dechow-Dichev measure of financial reporting quality and measures of past operating volatility.
- **02c_idiosync.do**: contains code used to construct the Owens et al. (2017) measure of idiosyncratic return volatility.
- **03_compensation_data.do**: contains code used to process and clean compensation data and to construct the inside debt test variables.
- **04_other_variables.do**: contains code used to construct other (control) variables used in the analyses.
- **05_combine.do**: contains code used to merge the previously created datasets into a "final" dataset used in the main analyses of the paper.
- **06a_tests.do**: contains code used for the descriptive statistics and main tests reported in the paper.
- **06b_tests_twostep.do**: contains code used for the two-step regression procedure in Table 6 of the paper. 
- **06c_tests_restatements_mb.do**: contains code used the restatement tests in Table 7 of the paper and the meet/beat tests reported in the Online Appendix.
- **07_tests_quantile.do**: contains code used for the quantile regression tests reported in the Online Appendix.
- **08a_combine_reconcile_He.do**: contains code used to recreate the sample and tests of He (2015, *RAST*) as closely as possible (see Online Appendix for details and results).
- **08b_combine_reconcile_Dhole.do**: contains code used to recreate the sample and tests of Dhole et al. (2016, *JAAF*) as closely as possible (see Online Appendix for details and results).
