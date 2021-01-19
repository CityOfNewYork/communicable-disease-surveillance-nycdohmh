*************************************************************************************************;
*	PROGRAM NAME: COVID_Master  										 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/15/2021																		*;
*	 PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		 PURPOSE: Call SaTScan COVID analysis and associated macros, send  e-mails				*;
*************************************************************************************************;

/* Set libraries */
libname support     "\\...\SupportingFiles";	/* Permanent SaTScan Datasets */
libname archive		"\\...\SupportingFiles\archive";
libname datasets 	"\\...\Event data";

%global today todaynum weekday todaywords;
data _null_;
call symput ('today',put(today(),yymmddn8.));
call symput ('todaynum',today());
call symput ('WeekDay',weekday(today()));
call symput ('todaywords',strip(put(today(),worddate.)));
run;

/* If running retrospectively as with sample data, replace today() with the run date you want to simulate. */
/* To run with sample data use 22NOV2020*/
data _null_;
call symput ('today',put('22NOV2020'd,yymmddn8.));
call symput ('todaynum','22NOV2020'd);
call symput ('WeekDay',weekday('22NOV2020'd));
call symput ('todaywords',strip(put('22NOV2020'd,worddate.)));
run;

/* Set filepaths for inputs, code, and outputs from batch runs of SaTScan */
%LET SUPPORT	=\\...\SupportingFiles\;
%LET CODE		=\\...\code\;
%LET ARCHIVE	=\\...\Results\;
%LET INPUT		=\\...\Results\&today\casefilesText_ncov\;
%LET OUTPUT		=\\...\Results\&today\outputText_ncov\;
%LET SATSCAN	=C:\Program Files\SaTScan;
%LET BATCH		=C:\SaTScan;

%let email_dist=('covid_analyst_team@health.nyc.gov');

/* For testing */
libname support		"\\...\WIP\SupportingFiles";
libname archive		"\\...\WIP\SupportingFiles\archive";
libname datasets	"\\...\Event data";
%LET SUPPORT	=\\...\WIP\SupportingFiles\;
%LET CODE		=\\...\WIP\code\;
%LET ARCHIVE	=\\...\WIP\Results\;
%LET INPUT		=\\...\WIP\Results\&today\casefilesText_ncov\;
%LET OUTPUT		=\\...\WIP\Results\&today\outputText_ncov\;
%LET SATSCAN	=C:\Program Files\SaTScan;
%LET BATCH		=C:\SaTScan;

/* SAS output window options */
ods noresults; 
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate;
options symbolgen mlogic mprint minoperator source source2;
options noxwait orientation=landscape validvarname=v7;
ods results off;
/* OPTION BELOW WILL DETECT IF RUNNING IN 9.4 AND CORRECT EXTENDOBSCOUNTER OPTION */
%macro version;
%if &sysver=9.4 %then %do;
      options extendobscounter=no; 
%end; 
%mend; 
%version; 


/* Read in file with most of the macros needed for the analysis */
%include "&CODE.\BCD005_COVID_Macros.sas";

/* Create files to store output from analysis */
options noxwait ;
x "cd &ARCHIVE.";
x "md &today";
x "cd &ARCHIVE.&today";
x "md outputText_ncov";
x "md casefilesText_ncov";
x "exit";

/* Run analysis */
%include "&CODE.\BCD005_COVID_Analysis.sas";

/* Send email with link to results */
OPTIONS EMAILHOST="XXXXXXXX" EMAILSYS=SMTP EMAILPORT=XX;
/* make folder links for email */
data _null_;
call symputx('historylink',cats("<a href='&ARCHIVE.'>&ARCHIVE.</a>"));
call symputx('outputlink',cats("<a href='&ARCHIVE.&today.'>&ARCHIVE.&today.</a>"));

run;
run;

%put &historylink;
%put &outputlink;


filename mymail
email from="analyst1@health.nyc.gov"
to 	= &email_dist. 	
cc  =("covid_satscan_analysts@health.nyc.gov")
subject="SaTScan - COVID-19: Daily run is complete"
type="text/HTML";;
data _null_;
file mymail;
put "<body>";

put "<p>SaTScan output for is available here:";
put "&outputlink";
put "<p> </p>";
put "<p>Archive of historical output is here: </p>";
put "&historylink";
put "</body>";
run;
quit;
