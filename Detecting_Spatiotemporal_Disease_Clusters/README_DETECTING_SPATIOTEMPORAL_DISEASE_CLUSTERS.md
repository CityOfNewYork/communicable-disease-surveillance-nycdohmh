# Detecting Spatiotemporal Disease Clusters

## Project File Inventory

### `BCD003_SaTScan94Master.sas` – Assigns folder and library locations, calls `BCD003_SaTScan94Macros.sas` to set parameters and load macros, calls `BCD003_SaTScan94Analysis.sas` to run analyses, generates output, sends e-mails

### `BCD003_SaTScan94Analysis.sas` – Imports and formats data, runs SaTScan analyses, imports results, generates output if cluster reporting criteria are met

### `BCD003_SaTScan94Macros.sas` – loads macros and SaTScan parameters template

### `BCD003_Diseaselist.sas7bdat` – SAS dataset of values in `BCD003_diseaselist.xlsx`

### `BCD003_Reviewers.sas7bdat` – SAS dataset of disease-specific reviewer/investigator email distribution lists

### `BCD003_Clusterhistory_94.sas7bdat` – archive of output from daily runs of SaTScan, stores clusters meeting or exceeding the recurrence interval (RI) threshold, or the most likely cluster if none exceed the RI threshold

### `BCD003_Satscanlinelist_94.sas7bdat` – archive of Confirmed/Probable/Suspected/Pending events identified as part of a cluster exceeding the RI threshold

### `BCD003_Not_merged.sas7bdat` – dataset of events with an invalid census tract, updated with each run for output and manual review and correction in source data

### `BCD003_Previously_geocoded.sas7bdat` – dataset of events with a prior address that geocoded but current primary address does not geocode, updated with each run for output and manual review and correction in source data

### `BCD003_Update_diseaselist_supporting_file.sas` – updates `BCD003_diseaselist.sas7bdat` with values from `BCD003_diseaselist.xlsx`

### `BCD003_Update_reviewers_table.sas` – use to modify disease-specific distribution lists for signals

### `BCD003_Quickly_look_at_todays_output.sas` – Outputs tabular results from today’s analyses and events with addresses needing manual review and correction

### `BCD003_SaTScan SAS Code Structure.pptx` – Workflow file location of SAS code components

### `BCD003_Diseaselist.xlsx` – Easily modified excel table of disease-specific analysis parameters

### `BCD003_TractNYCoord.txt` – sample coordinate file, with census tract ID and X/Y coordinates of NYC census tract centroids

### `BCD003_LatLongCoord.txt` – sample coordinate file, with census tract ID and latitude/longitude coordinates of NYC census tract centroids; SaTScan v9.4 can generate KML and shapefile output only when geographical coordinates are specified using latitudes and longitudes.

### `BCD003_Census_Tract_SF1SF32K_OEM_2010.shp/dbf/prj/sbn/sbx/shx` – NYC census tract-level shapefile (7 files)

### `BCD003_Kml_circle_tessellation.sas7bdat` – scaling factors for adding representation of cluster extent to google earth output

### `BCD003_CaseStatus_legend/CaseandCTStatus_legend.png` – image files for screen overlay of legend onto google earth visualization

### `BCD003_Triangle/square/donut/flag.png` – icons used for points on google earth visualization

## General guidelines for adaptation

### The prospective spatiotemporal disease cluster detection process using SaTScan applied by the Bureau of Communicable Disease at the NYC DOHMH is described in [this article](https://wwwnc.cdc.gov/eid/article/22/10/16-0097_article) published in Emerging Infectious Diseases in 2016. The SAS code posted here updates the annotated SAS code published in the [Technical Appendix](https://wwwnc.cdc.gov/eid/article/22/10/16-0097-techapp1.pdf) of that article with: (1) the addition of event locations to the coordinate file and the use of event ID to link case and coordinate files to consider precise case locations in determining cluster center and extent, (2) the inclusion in rtf output of a cluster history linelist to show trends in signal strength across recent analyses, (3) the integration of Google Earth functionality to produce interactive maps in addition to static rtf output, and (4) the incorporation of additional coding efficiencies.

### This code runs SaTScan in batch mode. [SaTScan](https://www.satscan.org) is free and open-source. Depending on organizational IT security policies, execution of batch files might be restricted to users with administrator permissions or only allowed on specially configured workstations (e.g. via a secure virtual machine or on a workstation without an internet connection).

### This code makes extensive use of macro variables and programming to minimize the number of changes that need to be made when modifying folder locations, analysis parameters, etc. All user-defined macro variables that set folder locations and libnames referenced throughout the code are found in the first 50 lines of `BCD003_SaTScan94Master.sas`.

### As currently configured, the code primarily references two subfolders within a main “SaTScan” folder: a “supportingfiles” subfolder and an “archive” subfolder. The former is referenced as the location of all sample datasets, table shells, and other supporting files. The latter is used to store all input and output files generated by the program.

### Sections of the code use NYC-specific geographic data and surveillance database elements, which we have retained in order to give a comprehensive view of code features. We have flagged sections that might be useful to some jurisdictions but are tangential to the primary purpose of the program. Removing these sections might require some modification to downstream code.

### Recent public releases of SaTScan (starting July 2021) allow for automating multiple analyses and have built in many of the advanced output elements orginally developed using this SAS code, including cluster summary tables, case linelists, and interactive maps. The multiple analyses feature allows for automation of sequential analyses and generates output directly in the SaTScan User Interface without the advanced coding skills required to adapt and maintain much of the code posted here. However, this code may still provide a helpful template to produce required SaTScan input files. To limit the code functionality to inclusion/exclusion criteria and input file generation, comment out lines 611-650 in the "BCD003_SaTScan94Analysis.sas" file.

### For further guidance on designing and finetuning cluster detection analyses using SaTScan, please refer to the [Tutorial for Designing and Fine-Tuning a System to Detect Reportable Communicable Disease Outbreaks]( https://publichealth.jmir.org/2024/1/e50653) published in JMIR Public Health and Surveillance in 2023.
