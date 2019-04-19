libname support 'S:\...\SaTScan\SupportingFiles';


/* Make changes/additions to excel sheet and run this to update SAS dataset */

PROC IMPORT OUT= support.BCD001_disease_parameters
            DATAFILE= "S:\...\SaTScan\SupportingFiles\BCD001_disease_parameters.xlsx" 
            DBMS=EXCELCS REPLACE; 
     		SCANTEXT=YES;
     		USEDATE=YES;
     		SCANTIME=YES;
RUN;

