# Generating Interactive Maps of Communicable Disease Reports

## Project File Inventory

### `BCD004_GoogleEarth_Demo.sas` – assigns folder and library locations, imports and formats data, transforms data into KML elements, outputs KML file readable in Google Earth Pro

### `BCD004_leg_cases_demo.sas7bdat` – “case” data for demo

### `BCD004_coolingtowers_demo.sas7bdat` – “cooling tower” data for demo

### `BCD004_LEGStatus_legend.png` – image file for screen overlay of case status legend onto google earth visualization

### `BCD004_CTStatus_legend.png` – image file for screen overlay of cooling tower inspection status legend onto google earth visualization

### `BCD004_triangle/square/donut/flag.png` – icons used for points on google earth visualization

## Summary

### Dynamic interactive maps are helpful tools for disease surveillance that can be generated automatically, customized to meet the needs of public health investigators, and made accessible to relevant staff while maintaining confidentiality for patient data when the file is stored and opened from a local or secure network drive ([Google Earth terms of service; Item 4](https://www.google.com/help/terms_maps/)). The SAS code and supporting files provided here offer an example of how to use KML script to produce a document displaying communicable disease data that can be viewed securely using Google Earth Pro (available for free download [here](https://www.google.com/earth/versions/#earth-pro)).

### This use case demonstrates how to automate daily output to visually examine the home, work, and other coordinates of recently reported cases of Legionnaires’ disease, by disease case status and whether the case was reported in the past day, in relation to registered cooling towers, according to their inspection status. Helpful features to note are customizable pop-up windows to display key characteristics of cases or features of interest, a time slider tool to display cases on the map over time, and a ruler tool to measure distances between cases or points of interest. Other use cases to support public health surveillance include mapping cases during their infectious period and visualizing geographic shifts in outbreaks over time.

### Demo data are not from real cases or cooling towers, and all locations used are derived from publically available datasets that are neither residential nor commercial addresses. For more information, please view [this recorded presentation](https://cste.confex.com/cste/2018/meetingapp.cgi/Paper/9512) from the 2018 annual meeting of the Council of State and Territorial Epidemiologists.
