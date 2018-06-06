/****************************************************************************************************/
/*	PROGRAM NAME: ELR_Dropoff_SaTScan_Master_GitHub.sas												*/
/*	CREATED: 2017																					*/
/*	UPDATED: May 24, 2018																			*/
/*	PROGRAMMERS: Eric Peterson																		*/
/*				 Erin Andrews																		*/
/*		 PURPOSE: Call ELR SaTScan analysis and associated macros, generate output, send e-mails	*/
/****************************************************************************************************/
 
/* OPTION BELOW WILL DETECT IF RUNNING IN 9.4 AND CORRECT EXTENDOBSCOUNTER OPTION */
%macro version;
%if &sysver=9.4 %then %do;
      options extendobscounter=no;
%end;
%mend;
%version

/* Set libraries */
libname maven odbc database=MavenBCD_RPT owner=dbo;		/* Maven BI Tables */
libname eclrs odbc database=ECLRS owner=dbo;			/* ECLRS BI tables */																	/* Analyst Tools Folder */
libname support "S:\...\SaTScan\SupportingFiles";		/* Permanent SaTScan Datasets */

/* Set filepaths - SATSCAN location is used when calling batch files and must on local drive to run */
%LET SATSCAN	=C:\SaTScan94;
%LET HOME		=S:\...\SaTScan;
%LET ARCHIVE	=S:\...\SaTScan\Archive;
%LET INPUT		=S:\...\SaTScan\Archive\&today\INPUT;
%LET OUTPUT		=S:\...\SaTScan\Archive\&today\OUTPUT;

/* SAS output window options */
ods noresults; 
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate orientation=landscape;
options symbolgen mlogic mprint noxwait minoperator source source2;
OPTIONS EMAILHOST="xxxxxxxx" EMAILSYS=SMTP EMAILPORT=##;

/*set date macros */
/* TODAY, YESTERDAY, TWO WEEKS AGO (WITH LAG, TODAY-14 DAYS), ONE YEAR AGO */
data _null_;
	call symput('YTDAY',put(today()-1,date9.));
	call symput('TODAY',put(today(),date9.));
	call symput('TODAYNUM',today());
	call symput('LASTYEAR',put(today()-365,date9.));
	call symput('LASTWEEK',put(today()-7,date9.));
run;

%put &YTDAY.;
%put &TODAY.;
%put &TODAYNUM.;
%put &LASTYEAR.;
%put &LASTWEEK.;

/* Select list of hospitals with zipcode outside NYC - these signals will be removed from output */
proc sql;
create table hospital_outNYC as 
select clia
from support.facility_addresses
where zip not in (select zcta5 from support.nyczip2010)and facility_type ="Hospital";
quit;

/* Format facility name and save to match on CLIA as standardized facility name */
data clia_facilityname;
set support.facility_addresses;
	format SendingFacilityNameStd $200.;
	SendingFacilityNameStd=FacilityName;
run;

/*creates archive folder */
options noxwait ;
x "cd &ARCHIVE.";
x "md &today";
x "cd &ARCHIVE.\&today.";
x "md INPUT";
x "md OUTPUT";
x "exit";

proc printto log="&ARCHIVE.\logs\&TODAY..log"; run;

/* Read in analysis parameter Macros */
%include "&HOME.\ELR_Dropoff_SaTScan_Parameters_GitHub.sas"; 
/* Run dropoff code */
%include "&HOME.\ELR_Dropoff_SaTScan_Analysis_GitHub.sas";

/*checking the lab clusterhistory */
data current_dropoffs;
set support.clusterhistory_dropoff_all;
where rundate="&today"d and suppress='N';
	format observed 5.0;
	format expected 5.1;
	format ODE 5.2;
	ODE= (observed/expected);
	if index(type,"Lab")>0 then hierarchy=1;
	if index(type,"Disease")>0 then hierarchy=2;
	if index(type,"Testtype")>0 then hierarchy=3;
	format signal $10.;
	signal=scan(type,1,"-");
	if signal="Testtype" then signal="Test Type";
run;

%LET complete_lab="NONE";
proc sql;
select distinct quote(strip(CLIA))
into :complete_lab separated by ", "
from current_dropoffs
where hierarchy=1 and observed=0;
quit;
%put &complete_lab;

%LET complete_hepb="NONE";
proc sql;
select distinct quote(strip(CLIA))
into :complete_hepb separated by ", "
from current_dropoffs
where hierarchy=2 and detail="HBVC" and observed=0;
quit;
%put &complete_hepb;

%LET complete_hepc="NONE";
proc sql;
select distinct quote(strip(CLIA))
into :complete_hepc separated by ", "
from current_dropoffs
where hierarchy=2 and detail="HCVC" and observed=0;
quit;
%put &complete_hepc;


proc sql;
create table current_dropoffs_severity as
	select a.*, b.disease_category
	from current_dropoffs a left join support.disease_parameters b
	 on a.detail=b.disease_code;
quit;

data current_dropoffs_tosend complete partial;
set current_dropoffs_severity;
/* Suppress disease/testtype complete dropoff signals if there is a lab complete dropoff signal */
if observed=0 and hierarchy in(2,3) and CLIA in(&complete_lab) then delete;
/* Suppress hep testtype complete dropoff signals if there is a complete hep disease level dropoff signal - Added 01MAR2018 */
if observed=0 and hierarchy=3 and index(detail,"HepB")>0 and CLIA in(&complete_hepb) then delete;
if observed=0 and hierarchy=3 and index(detail,"HepC")>0 and CLIA in(&complete_hepc) then delete;
output current_dropoffs_tosend;
if observed=0 then output complete;
if observed^=0 then output partial;
run;

/* # of dropoffs to report */
%let dsid=%sysfunc(open(current_dropoffs_tosend));
%let num_obs=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%put &num_obs;

/* # of complete dropoffs to report */
%let dsid2=%sysfunc(open(complete));
%let num_obs_complete=%sysfunc(attrn(&dsid2,nobs));
%let rc2=%sysfunc(close(&dsid2));
%put &num_obs_complete;

/* # of partial dropoffs to report */
%let dsid3=%sysfunc(open(partial));
%let num_obs_partial=%sysfunc(attrn(&dsid3,nobs));
%let rc3=%sysfunc(close(&dsid3));
%put &num_obs_partial;

/* send email and generate output */
%macro output_report;
%macro dummy;%mend dummy;

/* If no signals to report, send email to analysts who maintain program to confirm it ran */
%if &num_obs = 0 %then %do;

   filename mymail

		email from='analyst1@health.nyc.gov'
			to=('analyst1@health.nyc.gov'
				'analyst2@health.nyc.gov')
		subject="ECLRS: No SaTSCan Drop-offs Detected";
data _null_;

 file mymail;
   put "There were no drop-offs detected by SaTScan this week.";
   put " ";
run;
quit;
%end;

/* If there are signals to report, email team that follows up on reporting dropoffs and generate output */
%if &num_obs >= 1 %then %do;

   filename mymail

		email from="analyst1@health.nyc.gov"
			to=('analyst1@health.nyc.gov'
				'analyst2@health.nyc.gov'
				'analyst3@health.nyc.gov'
				'analyst4@health.nyc.gov'
				'analyst5@health.nyc.gov'
				'analyst6@health.nyc.gov'
				'analyst7@health.nyc.gov')
		subject=" ELR: SaTScan Detected Drop-offs";
data _null_;

 file mymail;
   put "There were drop-offs in ECLRS reporting detected by SaTScan this week."; 
   put " ";
   put "If you are the ECLRS Analyst on rotation, please investigate the linelist and submit tickets where appropriate: &ARCHIVE.\&TODAY.\SaTScan_Output_ELR_Dropoff_Detection_&today..rtf";
   put " ";
   put "If you submit a ticket as a result of this report, please add to appropriate tab on tracker: &HOME.\Reporting Dropoff Detection SaTScan Signals.xlsx";
run;
quit;

/* ODS output of signals identified this week */
ods rtf file = "&ARCHIVE.\&TODAY.\SaTScan_Output_ELR_Dropoff_Detection_&today..rtf";

ods results on;
ods startpage=yes;
ods escapechar='^';

title; footnote;

footnote1 font=Arial color=black h=0.8 "All analyses are performed using Maven data, and exclude all reports from NYS and NYC PHLs, and hospital labs outside NYC. Lab-level analyses exclude reports of MRSA, RSV & FLU";
footnote2 font=Arial color=black h=0.8 "Lab-level analyses use a study period of 365 days with no lag and min and max temporal windows of 3 and 14 days, respectively.";
footnote3 font=Arial color=black h=0.8 "Disease-level analyses use a study period of 365 days with no lag and min/max temporal windows of 7/28 and 28/56 days for major and minor diseases, respectively.";
footnote4 font=Arial color=black h=0.8 "Hepatitis and test type-level analyses use a study period of 365 days with a 30 day lag and min and max temporal windows of 7 and 28 days.";
footnote5 font=Arial color=black h=0.8 "All signals included in output meet or exceed recurrence interval threshold of 100 and have >=5 reports for concurrent period in previous year. Inclusion criteria specific to signal type are as follows:";
footnote6 font=Arial color=black h=0.8 "Lab: >=1 expected report per day, no indication of batch reporting, >=13 reports in previous year*, no reports of MRSA, FLU, or RSV in dropoff period*, no reports on day of analysis*, observed/expected<=0.1**, expected>=50**";
footnote7 font=Arial color=black h=0.8 "Disease: signal disease is in-season, >=13 reports in previous year*, no complete lab dropoff in same lab*, no indication of batch reporting*, no reports of signal disease on day of analysis*, observed/expected<=0.1*";
footnote8 font=Arial color=black h=0.8 "Hepatitis/test type: >=13 reports in previous year*, no complete hepatitis B/C dropoff in same lab*, no indication of batch reporting*, no reports of signal test types on day of analysis*, observed/expected<=0.1**";
footnote9 font=Arial color=black h=0.8 "*Complete drop-offs only       **Partial drop-offs only";

%if &num_obs_complete>0 %then %do;
proc sort data=complete;
	by hierarchy last_report;
run;

ods rtf text = "^S={font_face='Arial' font_weight=bold } ^{style [textdecoration=underline fontsize=12pt just=l]Complete drop-offs in reporting}";
proc report data=complete nowd;
	column signal detail CLIA sendingfacilitynamestd  new_dropoff last_report days_since_report lastyear_reports
		report_disease recurr_int expected;
	define signal / 'Signal type';
	define detail / 'Detail';
	define CLIA / 'CLIA';
	define sendingfacilitynamestd / 'Lab name';
	define new_dropoff / 'New';
	define last_report /'Date of last report';
	define days_since_report / '# of days since last report';
	define lastyear_reports /'# of reports over same interval last year';
	define recurr_int / 'Recurrence interval (weeks)';
	define report_disease/'Diseases reported 2 weeks prior to last report (lab only)';
	define expected/'Expected';
run;

%end;

%if &num_obs_partial>0 %then %do;
proc sort data=partial;
	by hierarchy Clusterstartdate;
run;
ods rtf text = "^S={font_face='Arial' font_weight=bold } ^{style [textdecoration=underline fontsize=12pt just=l]Partial drop-offs in reporting}" startpage=now;
proc report data=partial nowd;
	column signal detail CLIA sendingfacilitynamestd  new_dropoff Clusterstartdate lastyear_reports
		report_disease recurr_int observed expected ode;
	define signal / 'Signal type';
	define detail / 'Detail';
	define CLIA / 'CLIA';
	define sendingfacilitynamestd / 'Lab name';
	define new_dropoff / 'New';
	define Clusterstartdate / 'Cluster start date';
	define lastyear_reports /'# of reports over same interval last year';
	define recurr_int / 'Recurrence interval (weeks)';
	define report_disease/'Diseases reported 2 weeks prior to start of cluster (lab only)';
	define observed/'Received';
	define expected/'Expected';
run;

	%end;

ods rtf close;
%end;

%mend output_report;
%output_report

proc printto;

	
