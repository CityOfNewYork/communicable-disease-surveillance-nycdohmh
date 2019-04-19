/*******************************************************************************************
	PROGRAM NAME: BCD001_ELR_Dropoff_SaTScan_Master.sas										
	CREATED: 2017																			
	UPDATED: April 12, 2019																	
	PROGRAMMERS: Eric Peterson																
				 Erin Andrews																
********************************************************************************************/
 
/* OPTION BELOW WILL DETECT IF RUNNING IN 9.4 AND CORRECT EXTENDOBSCOUNTER OPTION */
%macro version;
%if &sysver=9.4 %then %do;
      options extendobscounter=no; 
%end; 
%mend; 
%version;

/* Set libraries */
libname maven odbc database=MavenBCD_RPT owner=dbo;		/* Maven BI Tables */
libname eclrs odbc database=ECLRS owner=dbo;			/* Eclrs tables */
libname support 'S:\...\SaTScan\SupportingFiles';		/* Permanent SAS Datasets */

/* Set filepaths for output */
/* Location of SAS Code */
%LET HOME		=S:\...\SaTScan;

/* Archive of reports and input/output files (FYI - does not need to be a subfolder of HOME) */
%LET ARCHIVE	=S:\...\SaTScan\Archive;

/* Location of SaTScan install */
%LET SATSCAN	=C:\SaTScan94;


/* SAS output window options */
ods noresults; ods graphics / imagefmt=png;
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate;
options symbolgen mlogic mprint noxwait;
options minoperator source source2 orientation=landscape;
OPTIONS EMAILHOST="XXXXXXXX" EMAILSYS=SMTP EMAILPORT=XX;

/* macro to pull folder names (previous run dates) from archive folder */
%macro get_filenames(location);
    filename _dir_ "%bquote(&location.)";
    data filenames(keep=fname);
      handle=dopen( '_dir_' );
      if handle > 0 then do;
        count=dnum(handle);
        do i=1 to count;
          fname=subpad(dread(handle,i),1,50);/* extract first fifty letters */
          output filenames;
        end;
      end;
      rc=dclose(handle);
    run;
    filename _dir_ clear;
    %mend;

%get_filenames("&ARCHIVE.");

/* select max (most recent) run date value in date9 format */
proc sql;
create table filenames_dates as
select *,
	input(fname,date9.) as rundate format date9.
from filenames
where prxmatch("m/\d\d\D\D\D\d\d\d\d/io",fname)=1;
select max(rundate) into :lastrun from filenames_dates
where rundate^=.;
quit;

%put &lastrun;

/*set date macros */
/* TODAY, YESTERDAY, ONE YEAR AGO, LAST RUN DATE */
data _null_;
	call symput('YTDAY',put(today()-1,date9.));
	call symput('TODAY',put(today(),date9.));
	call symput('TODAYNUM',today());
	call symput('LASTYEAR',put(today()-365,date9.));
	call symput('LASTWEEK',put(&lastrun,date9.));
run;

%put &YTDAY.;
%put &TODAY.;
%put &TODAYNUM.;
%put &LASTYEAR.;
%put &LASTWEEK.;

/* Format facility name and save to match on CLIA as standardized facility name */
data clia_facilityname;
set support.BCD001_facility_addresses;
	format SendingFacilityNameStd $200.;
	SendingFacilityNameStd=FacilityName;
run;

/*create folders for input and output files */
options noxwait ;
x "cd &ARCHIVE.";
x "md &today";
x "cd &ARCHIVE.\&today.";
x "md INPUT";
x "md OUTPUT";
x "exit";

proc printto log="&ARCHIVE.\logs\&TODAY..log"; run;

/* Define analysis parameters */
%include "&HOME.\BCD001_ELR_Dropoff_SaTScan_Parameters.sas";

/* Run dropoff code */
%include "&HOME.\BCD001_ELR_Dropoff_SaTScan_Analysis.sas";

/* pull signals identified today from clusterhistory */
data current_dropoffs;
set support.BCD001_dropoff_history;
where rundate=&TODAYNUM and suppress='N';
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

/* Identify CLIAs with complete lab dropoffs to suppress from report */
/*	disease- and test type-level dropoffs in the same CLIA */
%LET complete_lab="NONE";
proc sql;
select distinct quote(strip(CLIA))
into :complete_lab separated by ", "
from current_dropoffs
where hierarchy=1 and observed=0;
quit;
%put &complete_lab;

/* Identify CLIAs with complete Hep B/C dropoffs to suppress from report */
/*	test type-level dropoffs in the same CLIA for those respective diseases */
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
	select distinct a.*, b.disease_category
	from current_dropoffs a left join support.BCD001_disease_parameters b
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

/* Are there any dropoffs to report today? */
%let dsid=%sysfunc(open(current_dropoffs_tosend));
%let num_obs=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));

/* Any complete dropoffs? */
%let dsid2=%sysfunc(open(complete));
%let num_obs_complete=%sysfunc(attrn(&dsid2,nobs));
%let rc2=%sysfunc(close(&dsid2));

/* Any partial dropoffs? */
%let dsid3=%sysfunc(open(partial));
%let num_obs_partial=%sysfunc(attrn(&dsid3,nobs));
%let rc3=%sysfunc(close(&dsid3));

/* Any FLU dropoffs? */
%let dsid4=%sysfunc(open(all_flu2));
%let num_obs_flu=%sysfunc(attrn(&dsid4,nobs));
%let rc4=%sysfunc(close(&dsid4));

%macro dropoffs_report;
%macro dummy; %mend dummy;

%if &num_obs >= 1 %then %do;

ods rtf file = "&ARCHIVE.\&today.\SaTScan Drop-off Output_&today..rtf";

ods results on;
ods startpage=yes;
ods escapechar='^';

title; footnote;

footnote1 font=Arial color=black h=0.8 "All analyses are performed using Maven data, and exclude all reports from PHL. Lab-level analyses exclude reports of MRSA, RSV & FLU.";
footnote2 font=Arial color=black h=0.8 "Lab-level analyses use a study period of 365 days with no lag, min temporal window of 3 and max temporal windows of 14 and 126 days.";
footnote3 font=Arial color=black h=0.8 "Disease-level analyses use a study period of 365 days with no lag and min/max temporal windows of 7/28 and 28/56 days for major and minor diseases. An additional analysis uses a max temp window of 126 days for all diseases.";
footnote4 font=Arial color=black h=0.8 "Hepatitis and test type-level analyses (except Hepatitis B core IgM) use a study period of 365 days with a 30 day lag and min and max temporal windows of 28 and 56 days. These HCVC analyses exclude dialysis centers (CLIAs 05D0592241, 10D0645475, and 31D0961672). Additional HCVC analyses including dialysis centers are run using min/max temp windows of 180/270 and a study period of 730.";
footnote5 font=Arial color=black h=0.8 "Hepatitis B core IgM analyses use a study period of 365 days with no lag and min and max temporal windows of 7 and 28 days.";
footnote6 font=Arial color=black h=0.8 "All signals included in output meet or exceed recurrence interval threshold of 100 and have >=5 reports for concurrent period in previous year. Inclusion criteria specific to signal type for complete(*) and partial(**) dropoffs are as follows:";
footnote7 font=Arial color=black h=0.8 "Lab: >=1 expected report per day, >=13 reports in previous year*, no reports of MRSA, FLU, or RSV in dropoff period*, no reports on day of analysis*, observed/expected<=0.1-0.4 depending on signal strength**, expected>=50**";
footnote8 font=Arial color=black h=0.8 "Disease: signal disease is in-season, >=13 reports in previous year*, no complete lab dropoff in same lab*, no reports of signal disease on day of analysis*, observed/expected<=0.1–0.4 as a function of increasing signal strength*";
footnote9 font=Arial color=black h=0.8 "Hepatitis/test type: >=13 reports in previous year*, no complete hepatitis B/C dropoff in same lab*, no reports of signal test types on day of analysis*, observed/expected<=0.1-0.4 as a function of increasing signal strength**";
footnote10 font=Arial color=black h=0.8 "For partial dropoffs in FLU reporting, please use the accompanying graphs of FLU reporting for each CLIA by test type as a reference.";

%if &num_obs_complete>0 %then %do;
proc sort data=complete;
	by hierarchy last_report;
run;

ods rtf text = "^S={font_face='Arial' font_weight=bold } ^{style [textdecoration=underline fontsize=12pt just=l]Complete drop-offs in reporting}";
proc report data=complete nowd;
	column signal detail CLIA sendingfacilityname2  new_dropoff last_report days_since_report max_reporting_gap
		 max_reporting_gap_dates lastyear_reports report_disease recurr_int expected;
	define signal / 'Signal type' width=4;
	define detail / 'Detail' width=5;
	define CLIA / 'CLIA' width=4;
	define sendingfacilityname2 / 'Lab name' width=8;
	define new_dropoff / 'New' width=2;
	define last_report /'Date of last report' width=3;
	define days_since_report / '# of days since last report' width=3;
	define max_reporting_gap / 'longest reporting gap in study period (days)' width=3;
	define max_reporting_gap_dates / 'dates of longest reporting gap in study period' width=6;
	define lastyear_reports /'# of reports over same interval last year' width=3;
	define recurr_int / 'Recurrence interval (weeks)' width=6;
	define report_disease/'Diseases reported 2 weeks prior to last report (lab only)' width=6;
	define expected/'Expected' width=3;
run;

%end;

%if &num_obs_partial>0 %then %do;
proc sort data=partial;
	by hierarchy Clusterstartdate;
run;
ods rtf text = "^S={font_face='Arial' font_weight=bold } ^{style [textdecoration=underline fontsize=12pt just=l]Partial drop-offs in reporting}" startpage=now;
proc report data=partial nowd;
	column signal detail CLIA sendingfacilityname2  new_dropoff Clusterstartdate lastyear_reports
		report_disease recurr_int observed expected ode;
	define signal / 'Signal type' width=4;
	define detail / 'Detail' width=5;
	define CLIA / 'CLIA' width=4;
	define sendingfacilityname2 / 'Lab name' width=8;
	define new_dropoff / 'New' width=2;
	define Clusterstartdate / 'Cluster start date' width=3;
	define lastyear_reports /'# of reports over same interval last year' width=3;
	define recurr_int / 'Recurrence interval (weeks)' width=6;
	define report_disease/'Diseases reported 2 weeks prior to start of cluster (lab only)' width=6;
	define observed/'Received' width=3;
	define expected/'Expected' width=3;
run;

%end;


%if &num_obs_flu>0 %then %do;
footnote;
title height=12pt 'Flu reports by Test Type';
proc sgplot data=all_flu2;
by lab_clia;
xaxis label="Week Ending" fitpolicy=rotatethin type=linear;
yaxis label="# of reports";
vbar labweek / group=test_name;
run;
%end;

ods rtf close;

%end;

%mend dropoffs_report;

%dropoffs_report

/*emails */
%macro send_email;
%macro dummy;%mend dummy;

/* If no signals send a notification to analysts that the program ran */
%if &num_obs = 0 %then %do;

   filename mymail
		email from='analyst1@health.gov'
			to=('analyst1@health.gov'
				'analyst2@health.gov')
		subject="ELR: No SaTScan Drop-offs Detected";
data _null_;

 file mymail;
   put "There were no drop-offs detected by SaTScan this week.";
   put " ";
run;
quit;
%end;

/* If any signals send a notification to wider distribution list */
%if &num_obs >= 1 %then %do;

   filename mymail
		email from='analyst1@health.gov'
			to=('analyst1@health.gov'
				'analyst2@health.gov'
				'analyst3@health.gov'
				'analyst4@health.gov'
				'analyst5@health.gov'
				'analyst6@health.gov')
		subject="ELR: SaTScan Detected Drop-offs";
data _null_;

 file mymail;
   put "There were drop-offs in electronic lab reporting detected by SaTScan this week."; 
   put " ";
   put "If you are the ECLRS Analyst on rotation, please investigate the report and submit tickets where appropriate: &ARCHIVE.\&today.\SaTScan Drop-off Output_&today..rtf";
run;
quit;

%end;

%mend send_email;
%send_email

proc printto;

	
