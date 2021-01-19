*************************************************************************************************;
*	PROGRAM NAME: COVID_Analysis  										 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/14/2021																		*;
*	PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		PURPOSE: Runs SaTScan analysis for COVID												*;
*		 		  using poisson-based scan statistics		                 	 				*;
*		PARENT: Called via %include statement in COVID_Master 									*;
*************************************************************************************************;

proc printto log="&ARCHIVE.logs\Satscan_COVID_&today._analysis.txt"; run; 

/* delete today's lines from archived datasets if this is rerun on the same day */
proc sql;
delete * from support.BCD005_satscanlinelist_covid
where rundate=&todaynum;
quit;
proc sql;
delete * from support.BCD005_clusterhistory_covid
where rundate=&todaynum;
quit;

/* Import dataset of 2010 census tracts */
data nyc_censustracts;
set support.BCD005_nyc_censustracts;
run;

/* Import censustract-neighborhoods dataset */
data nocc;
set support.BCD005_nocc;
run;

proc sql;
	create table nocc_alt as
	select a.loc_id,
			input(a.x_coord,best12.0) as x,
			input(a.y_coord,best12.0) as y,
			b.nocc_name
	from nyc_censustracts a left join nocc b
		on a.loc_id=b.USCB_tract_10
	where b.nocc_name ^in("Airport","NA");
quit;

/* backup clusterhistory and satscanlinelist datasets - run as needed */
/*
data support.clusterhistory_covid_&today;
set support.BCD005_clusterhistory_covid;
run;

data support.satscanlinelist_covid_&today;
set support.BCD005_satscanlinelist_covid;
run;
*/



/* Create a dataset of analysis parameters */
/* This will be used to create macro variables for performing seperate SaTScan analyses by unique parameter settings */
PROC IMPORT OUT=diseaselist
            DATAFILE= "&SUPPORT.BCD005_diseaselist_GitHub.xlsx" 
            DBMS=xlsx REPLACE; 
     GETNAMES=YES;
RUN;
proc sql; 
	create table diseaseListCurrent as
	select *
		,strip(tranwrd(put(rr_threshold,best10.),'.','_')) as rr_threshold_print
	from diseaselist 
	order by analysis_print;
quit;

proc printto; run;

/* create macro variables for looping */
data _null_;
	set diseaselistcurrent;
	by analysis_print;
	if first.analysis_print then do;
		i+1;
		call symputx ('disease_code'||left(put(i,4.)),strip(disease_code));
		call symputx ('lagtime'||left(put(i,4.)),lagtime);
		call symputx ('recurrence'||left(put(i,4.)),recurrence);
		call symputx ('endloop' ,left(put(i,4.)));
		call symputx ('minTemp'||left(put(i,4.)),minTemp);
		call symputx ('maxTemp'||left(put(i,4.)),maxTemp);	
		call symputx ('maxGeog'||left(put(i,4.)),maxGeog);
		call symputx ('monteCarlo'||left(put(i,4.)),monteCarlo);
		call symputx ('studyperiod'||left(put(i,4.)),studyperiod);
		call symputx ('agegroup'||left(put(i,4.)),agegroup);
		call symputx ('restrictspatial'||left(put(i,4.)),restrictspatial);
		call symputx ('maxspatial'||left(put(i,4.)),maxspatial);
		call symputx ('timeagg'||left(put(i,4.)),timeagg);
		call symputx ('weeklytrends'||left(put(i,4.)),weeklytrends);
		call symputx ('analysis'||left(put(i,4.)),analysis);
		call symputx ('mincases'||left(put(i,4.)),mincases);
		call symputx ('setrisklimit'||left(put(i,4.)),setrisklimit);
		call symputx ('rr_threshold'||left(put(i,4.)),rr_threshold);
		call symputx ('rr_threshold_print'||left(put(i,4.)),rr_threshold_print);
		call symputx ('timetrendadjustmenttype'||left(put(i,4.)),timetrendadjustmenttype);
		call symputx ('spatialadjustmenttype'||left(put(i,4.)),spatialadjustmenttype);
		call symputx ('analysistype'||left(put(i,4.)),analysistype);
		call symputx ('modeltype'||left(put(i,4.)),modeltype);
		call symputx ('analysis_print'||left(put(i,4.)),analysis_print);
	end;
run;

/* Import COVID data */
%include "&CODE.\BCD005_COVID_ANALYSIS_data_prep.sas";

/* Output percent positivity trend figure */
%include "&CODE.\BCD005_COVID_ANALYSIS_citywide_percent_positivity_graphs.sas";


/* Run SaTScan analyses, looping through unique analysis parameter iterations */
%macro RunProgram;
%macro dummy; %mend dummy;

%do i=1 %to &endloop;

	proc printto log="&ARCHIVE.logs\Satscan_COVID_&today._satscan_loop&i..txt"; run; 

	data _null_;
		* START AND END DATE OF ANALYSIS;
		%global simstart;
		* First date analyzed in simulation ;
		  simstart=&todaynum-(&&studyperiod&i+(&&lagtime&i-1));     
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		  call symputx('SimStartDate',put(simstart,date9.));
		%global simend;
		* Last date analyzed in simulation ;
		  simend  =&todaynum- &&lagtime&i;     				
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
		  call symputx('SimEndDate',put(simend,date9.));
		%global simActive;
		* First date of active window ;
		  simActive = (&todaynum- &&lagtime&i)-(&&maxtemp&i-1);	
		  call symputx('simactive',simactive);
		  call symputx('SimActiveFormat',put(simactive,date7.)); 
	run;

	%include "&CODE.\BCD005_COVID_ANALYSIS_satscan_input_files.sas";

	* define start date and end date for SaTScan parameter file;
	data _null_;
		%global startdate enddate;
		call symput("startdate",put(&simstart.,yymmdds10.));
		call symput("enddate",put(&simend.,yymmdds10.));
	run;
	* output SaTScan parameter file;
	data _null_;
		outfilename="&OUTPUT.COVID_&&analysis_print&i.._&today..txt";
		file "&INPUT.param_COVID_&&analysis_print&i.._&today..txt";
		put %Param;
	run;
	* create bat file to run SaTScan in batch mode;
	data _null_;
		file "&BATCH.\Spatial_ncov.bat";
		string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&INPUT.param_COVID_&&analysis_print&i.._&today..txt"||'"';
		put string;
	run;

	* Run SaTScan batch file;
	x "&BATCH.\Spatial_ncov.bat"; Run; 
	proc printto; run;

	* prepare SaTScan results for RTF output generation;
	%format_output
	%personlinelist_setup
	%CHOROPLETH_setup
	%clustersummary_setup

	* RTF output generation;
	%MakePersonLineList
	%MakeChoropleth
	%MakeClusterSummary
	%MakeTemporalGraphs

%end;

%mend RunProgram;

%RunProgram;
