/********************************************************************************************/
/*	PROGRAM NAME: SaTScan94Master.sas												*/
/*	DATE CREATED: 2015																		*/
/*	LAST UPDATED: 12/4/2018																	*/
/*	PROGRAMMERS: Eric Peterson																*/
/*				 Deb Kapell																	*/
/*		 PURPOSE: Call SaTScan 9.4 analysis and associated macros, send reviewer e-mails	*/
/********************************************************************************************/
/* OPTION BELOW WILL DETECT IF RUNNING IN 9.4 AND CORRECT EXTENDOBSCOUNTER OPTION */
%macro version;
%if &sysver=9.4 %then %do;
      options extendobscounter=no; 
%end; 
%mend; 
%version;

/* Set filepaths for output from batch runs of SaTScan */
	/* SaTScan install folder */
%LET SATSCAN		=...\SaTScan\;
	/* Location of daily archive files and folders */
%LET ARCHIVE		=...\SaTScan\archive\;
	/* Location of today's output */
%LET ARCHIVETODAY	=...\SaTScan\archive\&today\;
	/* SaTScan input/case files will be saved here */
%LET INPUT			=...\SaTScan\archive\&today\casefilesText_94\;
	/* SaTScan output files will be saved here */
%LET OUTPUT			=...\SaTScan\archive\&today\outputText_94\;
	/* Location of supporting files */
%LET SUPPORT		=...\SaTScan\SupportingFiles\;
%LET SUPPORTMAP		=.../SaTScan/SupportingFiles/;

/* Set libraries */
libname maven odbc database=XXXXXXXX owner=dbo;		/* Establish connection to disease surveillance database */
libname support "&SUPPORT.";		/* Permanent SaTScan Datasets, coordinate files, shapefiles, etc. */

/* SAS output window options */
OPTIONS EMAILHOST="XXXXXXX" EMAILSYS=XXXX EMAILPORT=XX;
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate;
options symbolgen mlogic mprint minoperator source source2 orientation=landscape;

data _null_;
call symput ('today',put(today(),date9.));
call symput ('todaynum',today());
run;

/* If running retrospectively replace 'today()' with the run date you want to simulate. Example below: */
/*data _null_;*/
/*call symput ('today',put('20JUL2017'd,date9.));*/
/*call symput ('todaynum','20JUL2017'd);*/
/*run;*/

/* Create a file in the archive to store today's output from analysis */
options noxwait ;
x "cd &ARCHIVE";
x "md &today";
x "cd &ARCHIVETODAY";
x "md outputText_94";
x "md casefilesText_94";
x "exit";

/* if you only want to run for select diseases, limit diseases in the where= of the */
/*	 data step in the "SaTScan94Analysis" code that creates the "events" dataset */
proc printto log="&ARCHIVE.logs\Satscan94_&today..txt"; run;
 
/* backup clusterhistory and satscanlinelist datasets - run as needed */
/*
data support.clusterhistory_94_&today;
set support.clusterhistory_94;
run;

data support.satscanlinelist_94_&today;
set support.satscanlinelist_94;
run;
*/

/* Read in file with macros needed for the analysis */
%include "&SATSCAN.Satscan94Macros_GitHub.sas";

/* Run analysis code */
%include "&SATSCAN.Satscan94Analysis_GitHub.sas";

/*After analyses have run, check for events added to satscan linelist today */
proc sql; create table NewEvent as
select distinct disease_code
	,cluster, MaxTemp, agegroup, rundate,
	count(*) as cases
from support.satscanlinelist_94
where rundate=&todaynum
group by disease_code, maxtemp, agegroup, rundate
order by disease_code, MaxTemp, agegroup, rundate;
quit;

/* and for clusters added to the cluster history file today */
proc sql; create table NewCluster as
select distinct disease_code
	,MaxTemp, agegroup, rundate, NumConfProbSuspPend, RECURR_INT, recurrence
from support.clusterhistory_94
where rundate=&todaynum
order by disease_code, MaxTemp, agegroup, rundate;
quit;

/* merge and keep as relevant cluster if has one or more new events added today and includes 3 or more /*
/*	confirmed/probable/suspect/pending cases */
data NewEventCluster;
	merge NewEvent (in=a) NewCluster;
	by disease_code MaxTemp agegroup;
	if a & (NumConfProbSuspPend > 2);
run;

/* Create macro variables for each row of relevant clusters to loop through */
data _null_;
	set NewEventCluster;
	by disease_code MaxTemp agegroup;
	if first.disease_code | first.maxTemp | first.agegroup
		then do;
		i+1;
		call symputx('disease_code'||left(put(i,4.)),disease_code);
		call symputx('maxtemp'||left(put(i,4.)),maxtemp);
		call symputx('agegroup'||left(put(i,4.)),agegroup);
		call symputx('end',left(put(i,4.)));
		end;
run;

/* Count rows in dataset */
%let dsid=%sysfunc(open(NewEventCluster));	/* open out1 */
%let numclusterevent=%sysfunc(attrn(&dsid,nobs));	/* # observations in work.display */
%let rc=%sysfunc(close(&dsid)); 			/* close work.display */

/* Define as new cluster or new event added to ongoing cluster */
%macro ClusterEventDefinition;
%macro dummy;%mend dummy;

/* If no rows in dataset stop processing */
%if &numclusterevent=0 %then %return;

%do i=1 %to &end;

%let open=%sysfunc(open(existing_&&disease_code&i.._&&maxtemp&i.._&&agegroup&i..));
%global num_exist;
%let num_exist=%sysfunc(attrn(&open,nobs));
%let close=%sysfunc(close(&open));

	data NewEventCluster;
	set NewEventCluster;
		format signaltype $10.;
		if disease_code="&&disease_code&i" and maxtemp=&&maxtemp&i and agegroup="&&agegroup&i" then do;
			if &num_exist<=0 then signaltype="Cluster";
			if &num_exist>0 then signaltype="Event";
		end;
	run;

%symdel num_exist;

%end;

%mend ClusterEventDefinition;

%ClusterEventDefinition


	
/* If no new clusters and no new events, e-mail analysts to confirm program ran successfully */
%macro noClusters;
%macro dummy;%mend dummy;

filename mymail
email from="XXXXXXXX@health.nyc.gov"
to 	=("XXXXXXXX@health.nyc.gov")
cc  =("XXXXXXXX@health.nyc.gov")

subject="SaTScan94: No new clusters today"
emailsys=SMTP;
data _null_;
file mymail;
put 'All quiet.'/
	"FYI, the cluster history is here: &SUPPORT."/;
run;
quit;
%mend noClusters;

/* If new clusters or new events, get reviewer info and send e-mails to analysts, reviewers, investigators */
%macro GetReviewers;
%macro dummy;%mend dummy;

/* Merge reviewer e-mails with new event and cluster dataset */
proc sql; create table signals_reviewer as  
select n.disease_code
	,n.agegroup
	,n.maxtemp
	,n.cluster
	,n.signaltype
	,n.cases
	,r.notes as reviewer	
from NewEventCluster as n
	,support.reviewers as r
where n.disease_code=r.code	
order by reviewer;
quit;

proc sort data=signals_reviewer nodupkey;by reviewer maxtemp agegroup disease_code signaltype;run;

/* Split into separate datasets by new clusters and events */
data signals_reviewer_clusters signals_reviewer_events;
set signals_reviewer;
	format agegroupprint $20.;
	if agegroup="AllAges" then agegroupprint="All Ages";
	else if agegroup="Under5" then agegroupprint="Under 5";
	else if agegroup="5to18" then agegroupprint="5 to 18";
	else if agegroup="Under18" then agegroupprint="Under 18";
	if signaltype="Cluster" then output signals_reviewer_clusters;
	if signaltype="Event" then output signals_reviewer_events;
run;



/* Keep one row per unique disease-parameter-reviewer combination from each dataset */
proc sort data=signals_reviewer_clusters nodupkey;by disease_code maxtemp agegroup reviewer;run;
proc sort data=signals_reviewer_events nodupkey;by disease_code maxtemp agegroup reviewer;run;

/* Counts number of rows in new cluster dataset and outputs value to macro variable */
%let dsid2=%sysfunc(open(signals_reviewer_clusters));
%global numnew_unique_clusters;
%let numnew_unique_clusters=%sysfunc(attrn(&dsid2,nobs));
%let rc2=%sysfunc(close(&dsid2));

/* Counts number of rows in new events dataset and outputs value to macro variable */
%let dsid3=%sysfunc(open(signals_reviewer_events));
%global numnew_unique_events;
%let numnew_unique_events=%sysfunc(attrn(&dsid3,nobs));
%let rc3=%sysfunc(close(&dsid3));

%mend GetReviewers;


	
/* If there are new clusters this macro will generate an e-mail to designated staff */
%macro ClustersExist;
%macro dummy;%mend dummy;

%if &numnew_unique_clusters=0 %then %return;

proc sort data=signals_reviewer_clusters;by disease_code maxtemp agegroup reviewer;run;

data _null_;
	set signals_reviewer_clusters;
	by disease_code maxtemp agegroup reviewer;
	if first.disease_code or first.maxtemp or first.agegroup
		then do;
		i+1;
		call symputx('disease'||left(put(i,4.)),disease_code);
		call symputx('maxtemp'||left(put(i,4.)),maxtemp);
		call symputx('agegroup'||left(put(i,4.)),agegroup);
		call symputx('agegroupprint'||left(put(i,4.)),agegroupprint);
		call symputx('reviewer'||left(put(i,4.)),reviewer);
		call symputx('end',left(put(i,4.)));
		end;
run;

%do i=1 %to &numnew_unique_clusters;

filename mymail
email from="XXXXXXXX@health.nyc.gov"
to 	=(&&reviewer&i) 	
cc  = ("XXXXXXXX@health.nyc.gov"
	  "XXXXXXXX@health.nyc.gov")

subject="SaTScan94: New &&disease&i signal"
emailsys=SMTP;

data _null_;
file mymail;
put "New SaTScan94 signal for &&disease&i (&&agegroupprint&i age group, &&maxtemp&i day maximum temporal window) on &today"//
	"SaTScan cluster information is here:"/
	"&ARCHIVETODAY."//
	"If you have any questions, please ask an analyst."/;
run;
quit;
%end;
%mend ClustersExist;



/* If there are new events this macro will generate an e-mail to designated BCD staff */
%macro EventsExist;
%macro dummy;%mend dummy;

%if &numnew_unique_events=0 %then %return;

proc sort data=signals_reviewer_events;by disease_code maxtemp agegroup reviewer;run;

data _null_;
	set signals_reviewer_events;
	by disease_code maxtemp agegroup reviewer;
	if first.disease_code or first.maxtemp or first.agegroup
		then do;
		i+1;
		call symputx('disease'||left(put(i,4.)),disease_code);
		call symputx('maxtemp'||left(put(i,4.)),maxtemp);
		call symputx('agegroup'||left(put(i,4.)),agegroup);
		call symputx('agegroupprint'||left(put(i,4.)),agegroupprint);
		call symputx('reviewer'||left(put(i,4.)),reviewer);
		call symputx('newcases'||left(put(i,4.)),cases);
		call symputx('end',left(put(i,4.)));
		end;
run;

%do i=1 %to &numnew_unique_events;

filename mymail
email from="XXXXXXXX@health.nyc.gov"
to 	=(&&reviewer&i) 	
cc  = ("XXXXXXXX@health.nyc.gov"
	  "XXXXXXXX@health.nyc.gov")

subject="SaTScan94: Ongoing &&disease&i signal"
emailsys=SMTP;

data _null_;
file mymail;
put "&&newcases&i cases of &&disease&i (&&agegroupprint&i age group, &&maxtemp&i day maximum temporal window) added to ongoing SaTScan94 signal on &today."//
	"SaTScan cluster information is here:"/
	"&ARCHIVETODAY."//
	"If you have any questions, please ask an analyst."/;
run;
quit;
%end;
%mend EventsExist;


/* All e-mail macros run together */
%macro decision;
%if &numclusterevent=0 
	%then %do;
		%noclusters
	%end;
%if &numclusterevent>0 
	%then %do;
		%GetReviewers
		%if &numnew_unique_clusters>0 %then %do;
			%ClustersExist
		%end;
		%if &numnew_unique_events>0 %then %do;
			%EventsExist;
		%end;
	%end;
%mend decision;

%decision

proc printto; run;
