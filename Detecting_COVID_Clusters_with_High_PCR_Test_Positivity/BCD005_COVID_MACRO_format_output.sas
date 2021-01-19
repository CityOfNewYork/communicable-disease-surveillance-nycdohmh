/* This macro formats SaTScan output, appends all cluster info to archive, */
/*  and determines if there are any new clusters or events */

%macro format_output;
%macro dummy; %mend dummy;

proc printto log="&ARCHIVE.logs\Satscan_COVID_&today._output_setup_loop&i..txt"; run; 

/* read in the SaTScan output */

/* Col file: One row per identified cluster with following fields (some fields are specific to analysis/model type): */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio, relative risk */
PROC IMPORT OUT= WORK.OutCol_&&analysis_print&i.. 
            DATAFILE= "&OUTPUT.COVID_&&analysis_print&i.._&today..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

/* GIS file: One row per census tract with following fields (some fields are specific to analysis/model type) */
/*	Census tract, cluster number, p-value, recurrence interval, observed cases */
/* 	in cluster, expected cases in cluster, observed/expected ratio in cluster, */
/*	observed cases in census tract, expected cases in census tract, relative risk, */
/*	observed/expected ratio in census tract */ 
PROC IMPORT OUT= WORK.OUTGIS_&&analysis_print&i.. 
            DATAFILE= "&OUTPUT.COVID_&&analysis_print&i.._&today..gis.dbf" 
            DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;


data outcol;
	set outcol_&&analysis_print&i..;
run;

data outgis;
	set outgis_&&analysis_print&i..;
run;

/* Count total cases in analysis to identify unexpected changes */
proc sql;
	select sum(cases) into :total_cases_analysis
	from &&analysis_print&i.._cases_agg;
quit;

/* Populate alternate censustract values for neighborhood */
proc sql;
	create table outcol_alt as
	select a.*,
			b.loc_id as loc_id_nocc,
			b.nocc_name as centroidnocc_name,
			sqrt((abs(a.x-b.x)**2)+(abs(a.y-b.y)**2)) as dist_from_center,
			min(calculated dist_from_center) as min_dist_from_center
	from outcol a, nocc_alt b
	group by a.cluster
		having calculated dist_from_center=calculated min_dist_from_center;
quit;

data clusterinfo; 
	set outcol_alt;
	length disease_code $45 agegroup $15;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
	radiusMile = radius/5280; format radiusMile 6.2;
	radiusKm = radius/3280.84; format radiusKM 6.2; 
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD, which SAS cannot read. */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate=&todaynum; format rundate mmddyy10.;
	disease_code ="&&disease_code&i";
	agegroup ="&&agegroup&i";
	format analysis $15.;
	analysis="&&analysis&i";
	format total_cases_analysis 8.;
	total_cases_analysis=&total_cases_analysis.;
	format recurr_int best12.0;
	if recurr_int=. then recurr_int=ceil(1/p_value);
	drop start_date end_date;
run;

/* Keep only clusters over predetermined recurrence interval threshold. If all id'd clusters are below this */
/* threshold then keep least likely cluster */
proc sort data=clusterinfo; by cluster p_value; run;
data clusterinfo; 
	set clusterinfo;
	if _n_=1 or recurr_int>=&&recurrence&i;
run;

/* Keep fields to append to clusterhistory and satscanlinelist datasets, and for use in output if needed */
proc sql; 
	create table ClusterHistory as
	select disease_code
		,analysis
		,total_cases_analysis
		,agegroup
		,centroidnocc_name
		,cluster
		,x
		,y
		,radiusMile format=6.2
		,radiusKm format= 6.2
		,ode format=4.2
		,clusterstartdate
		,clusterEndDate
		,numClusterdays
		,runDate
		,recurr_int
		,p_value format 6.2
	/* populate analysis parameter fields */
		,strip("&&analysis_print&i") as analysis_print
		,&&recurrence&i as Recurrence
		,&&maxGeog&i as MaxGeog
		,&&mintemp&i as MinTemp
		,&&maxTemp&i as MaxTemp
		,&&monteCarlo&i as MonteCarlo
		,&&studyperiod&i as Studyperiod
		,"&&restrictspatial&i" as restrictspatial
		,&&maxspatial&i as maxspatial
		,0 as NumCases
		,&&rr_threshold&i as RR_threshold
	from clusterInfo;
quit;

/* Append saved cluster details to clusterhistory file - ignore warnings of missing columns in 'data' table */
proc append base=support.BCD005_Clusterhistory_covid data=ClusterHistory;run;
proc sort data=support.BCD005_Clusterhistory_covid out=support.BCD005_Clusterhistory_covid ; by disease_code analysis_print;run;

/* join all unique tract info on event id */
proc sql;
create table outgis2 as
	select distinct a.*,
			b.censustract as tract
	from outgis a left join studyperiod_tests b
		on a.loc_id=b.censustract
	where b.censustract is not null;
quit;

/* Keep one row per census tract, prioritizing least likely by chance cluster association */
	/* Least likely by chance = highest RI value, if a census tract is in overlapping clusters it
		should be mapped as part of the least likely cluster by chance */
/* For analyses that do not output recurrence intervals, calculate by taking 1/p-value */
proc sort data=outgis2; by loc_id cluster; run;
data outgis3; 
	set outgis2;
	by loc_id;
	if first.loc_id=1;
	format recurr_int best12.0;
	if recurr_int=. then recurr_int=ceil(1/p_value);
run;

%mend format_output;
