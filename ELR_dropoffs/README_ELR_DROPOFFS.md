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

##
