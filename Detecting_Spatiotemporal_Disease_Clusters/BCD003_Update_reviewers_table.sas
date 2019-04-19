%LET SUPPORT		=...\SaTScan\SupportingFiles\;

libname support "&SUPPORT.";

/* Make backup just in case */
data support.BCD003_reviewersbackup;
set support.BCD003_reviewers;
run;

/* Make temporary dataset of reviewer data  */
data reviewers;
set support.BCD003_reviewers;
run;


/* Make change to work dataset for review */
data reviewers_check;
set reviewers;

/* Define distribution list for specific disease */ 
/*if code="GAS" then notes="'reviewer@health.nyc.gov' 'investigator@health.nyc.gov'";*/

/* replace one reviewer with another for all rows */
/*notes=tranwrd(notes,"reviewer1","reviewer2");*/

run;

/* Review change */
proc print data=reviewers_check;
	var code notes;
run;

/* Overwrite permanent dataset */
data support.BCD003_reviewers;
set reviewers_check;
run;

