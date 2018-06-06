# Detecting Dropoffs in Electronic Laboratory Reporting
## Project File Inventory
### "ELR_Dropoff_SaTScan_Master.sas" - Sets folder and library locations, calls ELR Dropoff SaTScan analysis and associated macros, generates output, sends e-mails
### "ELR_Dropoff_SaTScan_Analysis.sas" - Imports and formats data, runs SaTScan analyses, imports results, applies suppression rules to identified dropoff signals
### "ELR_Dropoff_SaTScan_Parameters.sas" - Sets SaTScan parameter settings for lab- disease- and test type-level analyses
### "disease_parameters.xlsx" - Catalog of disease-specific parameter settings easily modified by user
### "disease_parameters.sas7bdat" - Catalog of disease-specific parameter settings referenced in analysis code
### "Update disease_parameters supporting file.sas" - Code to update disease-specific parameter settings dataset with changes from excel file
### "disease_names.sas7bdat" - reference table to add disease severity and disease type
### "facility_addresses.sas7bdat" - example of reporting facility reference table
### "clusterhistory_dropoff_all" - empty formatted dataset to store signal history
### "nyczip2010" - zip codes within boundaries of New York City

## General guidelines for adaptation
### This code makes extensive use of macro variables and programming to minimize the number of changes that need to be made when making modifications to folder locations, analysis parameters, etc. All macros defined in the code that may require user modification are found in the first 50 lines of the ELR_Dropoff_SaTScan_Master.sas file. The code in this file also sets all SaTScan analysis parameters and runs all analyses by reading in the ELR_Dropoff_SaTScan_Parameters.sas and ELR_Dropoff_SaTScan_Analysis.sas files, respectively, then evaluates the identified signals to send emails and generate out, when appropriate.
### The ELR_Dropoff_SaTScan_Parameters.sas file should require no modification unless a user wishes to adjust SaTScan parameters that remain constant in the analysis as currently defined.
### The ELR_Dropoff_SaTScan_Analysis.sas file will likely require the most modification to adapt to other surveillance databases or data streams, espeically the sections that import and modify data. Rather than try and cover all the possible modifications that might be required for other jurisdictions, we will highlight the features and caveats of the code as adapted for the NYC disease surveillance system.
