
%LET SUPPORT		=...\SaTScan\SupportingFiles\;

libname support "&SUPPORT.";

/* Make changes/additions to excel sheet and run this to update SAS dataset */

PROC IMPORT OUT= support.diseaselist
            DATAFILE= "&SUPPORT.diseaselist.xlsx" 
            DBMS=xlsx REPLACE; 
     GETNAMES=YES;
RUN;

