# Detecting Dropoffs in Electronic Laboratory Reporting
## Project File Inventory
### `ELR_Dropoff_SaTScan_Master.sas` - Sets folder and library locations, calls ELR Dropoff SaTScan analysis and associated macros, generates output, sends e-mails
### `ELR_Dropoff_SaTScan_Analysis.sas` - Imports and formats data, runs SaTScan analyses, imports results, applies suppression rules to identified dropoff signals
### `ELR_Dropoff_SaTScan_Parameters.sas` - Sets SaTScan parameter settings for lab- disease- and test type-level analyses
### `disease_parameters.xlsx` - Catalog of disease-specific parameter settings easily modified by user
### `disease_parameters.sas7bdat` - Catalog of disease-specific parameter settings referenced in analysis code
### `Update disease_parameters supporting file.sas` - Code to update disease-specific parameter settings dataset with changes from excel file
### `disease_names.sas7bdat` - reference table to add disease severity and disease type
### `facility_addresses.sas7bdat` - example of reporting facility reference table
### `clusterhistory_dropoff_all` - empty formatted dataset to store signal history
### `nyczip2010` - zip codes within boundaries of New York City

## General guidelines for adaptation
### This code makes extensive use of macro variables and programming to minimize the number of changes that need to be made when modifying folder locations, analysis parameters, etc. All macros defined in the code that require user modification are found in the first 50 lines of `ELR_Dropoff_SaTScan_Master.sas`. The code in this file also sets all SaTScan analysis parameters and runs all analyses by reading in `ELR_Dropoff_SaTScan_Parameters.sas` and `ELR_Dropoff_SaTScan_Analysis.sas`, respectively, then evaluates the identified signals to send emails and generate output, when appropriate.
### `ELR_Dropoff_SaTScan_Parameters.sas` should require no modification unless a user wishes to adjust SaTScan parameters that remain constant in the analysis as currently defined.
### The `ELR_Dropoff_SaTScan_Analysis.sas` will likely require the most modification to adapt to other surveillance databases or data streams, espeically the sections that import and modify data. Rather than try and cover all the possible modifications that might be required for other jurisdictions, we will highlight illustrative features and caveats of the code as adapted for the NYC disease surveillance system which may or may not be applicable for other jurisdictions. These include:
### - The NYC DOHMH uses separate databases for disease surveillance (Maven) and electronic lab reporting (ECLRS). Our analyses primarily use Maven data, which is imported from ECLRS after going through automated QA and standardization processes, to identify potential dropoffs in reporting and to assess past reporting patterns. ECLRS is used as a secondary data source in applying signal suppression rules.
### - "CLIA" is a unique lab identifier, assigned by the Centers for Medicare and Medicaid Services, and is a required field for reporting labs in New York State. A unique lab identifier for each facility included in the analysis that is consistent throughout the study period is essential to obtaining accurate results.
### - When labs merge, send out tests, or change unique identifiers, the analysis may produce signals indicating dropoffs that are not actionable. The affected lab reports may need to be assigned to another CLIA in the code to preserve comparability of baseline and current counts of reporting. Examples of CLIA reassignment for all results and specific diseases/tests can be found at lines 36-47 in `ELR_Dropoff_SaTScan_Analysis.sas`.
### - Dropoffs identified in hospital labs that are outside NYC are not actionable are are removed from output by using `nyczip2010.sas7bdat` a reference table of zip codes within the city limits.
