libname support 'S:\BCD\COMDISshared\Analyst_of_the_week\Maven\ECLRS\SaTScan\WIP\Code for GitHub and Technical Appendix\SupportingFiles';


/* Make changes/additions to excel sheet and run this to update SAS dataset */

PROC IMPORT OUT= support.disease_parameters
            DATAFILE= "S:\BCD\COMDISshared\Analyst_of_the_week\Maven\ECLRS\SaTScan\SupportingFiles\disease_parameters.xlsx" 
            DBMS=EXCELCS REPLACE; 
/*     GETNAMES=YES;*/
/*     MIXED=NO;*/
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

