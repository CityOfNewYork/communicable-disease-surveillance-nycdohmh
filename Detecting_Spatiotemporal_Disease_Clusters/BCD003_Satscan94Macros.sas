/** Macro with all parameters for SaTScan;  */
/*	Parameter settings modified via macro variables in the TractParam macro are: */
/*		&&recurrence&i			Recurrence interval */
/*		&&maxGeog&i				Maximum spatial cluster size, and XX% of population at risk */
/*		&&minTemp&i				Minimum temporal cluster size in days */
/*		&&maxTemp&i				Maximum temporal cluster size in days */		
/*		&&monteCarlo&i			Maximum number of montecarlo replications */
/*		&&baseline&i			Length of study period in days */
/*		&&restrictspatial&i		Option to restrict clusters to a maximum size Y/N */
/*		&&maxspatial&i			If restrict spatial=Y, restrict clusters to maximum radius of XXXX in feet */
/*		&&timeagg&i				Sets time aggregation length in days */
/*		&&weeklytrends&i		Adjust for day of week trends Y/N */


%Macro TractParam;
"[Input]"
/";												case data filename"
/"CaseFile=&&INPUT.casefile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt"
/";												control data filename"
/"ControlFile="
/";												time precision (0=None, 1=Year, 2=Month, 3=Day, 4=Generic)"
/"PrecisionCaseTimes=3"
/";												study period start date (YYYY/MM/DD)"
/"StartDate="startdt
/";												study period end date (YYYY/MM/DD)"
/"EndDate="EndDt
/";												population data filename"
/"PopulationFile="
/";												coordinate data filename"
/"CoordinatesFile=&INPUT.coordfile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt"
/";												use grid file? (y/n)"
/"UseGridFile=n"
/";												grid data filename"
/"GridFile="
/";												coordinate type (0=Cartesian, 1=latitude/longitude)"
/"CoordinatesType=0"

//"[Analysis]"
/";												analysis type ( 1=Purely Spatial, 2=Purely Temporal,"
/";																3=Retrospective Space-Time, 4=Prospective Space-Time,"
/";																5=Spatial Variation in Temporal Trends, 6=Prospective Purely Temporal)"
/"AnalysisType=4"
/";												model type (0=Discrete Poisson, 1=Bernoulli, 2=Space-Time Permutation,"
/";															3=Ordinal, 4=Exponential, 5=Normal, 6=Continuous Poisson, 7=Multinomial)"
/"ModelType=2"
/";												scan areas (1=High Rates(Poison,Bernoulli,STP); High Values(Ordinal,Normal);"
/";															Short Survival(Exponential), 2=Low Rates(Poison,Bernoulli,STP);"
/";															Low Values(Ordinal,Normal); Long Survival(Exponential), 3=Both Areas)"
/"ScanAreas=1"
/";												time aggregation units (0=None, 1=Year, 2=Month, 3=Day, 4=Generic)"
/"TimeAggregationUnits=3"
/";												time aggregation length (Positive Integer)"
/"TimeAggregationLength=&&TIMEAGG&i"

//"[Output]"
/";analysis main results output filename"
/"ResultsFile=" OUTFILENAME
/";												output Google Earth KML file (y/n)"
/"OutputGoogleEarthKML=y"
/";												output shapefiles (y/n)"
/"OutputShapefiles=n"
/";												output cluster information in ASCII format? (y/n)"
/"MostLikelyClusterEachCentroidASCII=y"
/";												output cluster information in dBase format? (y/n)"
/"MostLikelyClusterEachCentroidDBase=y"
/";												output location information in ASCII format? (y/n)"
/"CensusAreasReportedClustersASCII=y"
/";												output location information in dBase format? (y/n)"
/"CensusAreasReportedClustersDBase=y"
/";												output risk estimates in ASCII format? (y/n)"
/"IncludeRelativeRisksCensusAreasASCII=y"
/";												output risk estimates in dBase format? (y/n)"
/"IncludeRelativeRisksCensusAreasDBase=y"
/";												output simulated log likelihoods ratios in ASCII format? (y/n)"
/"SaveSimLLRsASCII=n"
/";												output simulated log likelihoods ratios in dBase format? (y/n)"
/"SaveSimLLRsDBase=n"

//"[Multiple Data Sets]"
/"; 											multiple data sets purpose type (0=Multivariate, 1=Adjustment)"
/"MultipleDataSetsPurposeType=0"

//"[Data Checking]"
/";												study period data check (0=Strict Bounds, 1=Relaxed Bounds)"
/"StudyPeriodCheckType=0"
/";												geographical coordinates data check (0=Strict Coordinates, 1=Relaxed Coordinates)"
/"GeographicalCoordinatesCheckType=0"

//"[Spatial Neighbors]"
/";												use neighbors file (y/n)"
/"UseNeighborsFile=n"
/";												neighbors file"
/"NeighborsFilename="
/";												use meta locations file (y/n)"
/"UseMetaLocationsFile=n"
/";												meta locations file"
/"MetaLocationsFilename="
/";												multiple coordinates type (0=OnePerLocation, 1=AtLeastOneLocation, 2=AllLocations)"
/"MultipleCoordinatesType=0"

//"[Spatial Window]"
/";												maximum spatial size in population at risk (<=50%)"
/"MaxSpatialSizeInPopulationAtRisk=&&MAXGEOG&i"
/";												restrict maximum spatial size - max circle file? (y/n)"
/"UseMaxCirclePopulationFileOption=n"
/";												maximum spatial size in max circle population file (<=50%)"
/"MaxSpatialSizeInMaxCirclePopulationFile=&&MAXGEOG&i"
/";												maximum circle size filename"
/"MaxCirclePopulationFile="
/";												restrict maximum spatial size - distance? (y/n)"
/"UseDistanceFromCenterOption=&&RESTRICTSPATIAL&i"
/";												maximum spatial size in distance from center (positive integer)"
/"MaxSpatialSizeInDistanceFromCenter=&&MAXSPATIAL&i"
/";												include purely temporal clusters? (y/n)"
/"IncludePurelyTemporal=n"
/";												window shape (0=Circular, 1=Elliptic)"
/"SpatialWindowShapeType=0"
/";												elliptic non-compactness penalty (0=NoPenalty, 1=MediumPenalty, 2=StrongPenalty)"
/"NonCompactnessPenalty=1"
/";												isotonic scan (0=Standard, 1=Monotone)"
/"IsotonicScan=0"

//"[Temporal Window]"
/";												minimum temporal cluster size (in time aggregation units)"
/"MinimumTemporalClusterSize=&&MINTEMP&i"
/";												how max temporal size should be interpretted (0=Percentage, 1=Time)"
/"MaxTemporalSizeInterpretation=1"
/";												maximum temporal cluster size (<=90%)"
/"MaxTemporalSize=&&MAXTEMP&i"
/";												include purely spatial clusters? (y/n)"
/"IncludePurelySpatial=n"
/";												temporal clusters evaluated (0=All, 1=Alive, 2=Flexible Window)"
/"IncludeClusters=1"
/";												flexible temporal window start range (YYYY/MM/DD,YYYY/MM/DD)"
/"IntervalStartRange=2000/1/1,2000/12/31"
/";												flexible temporal window end range (YYYY/MM/DD,YYYY/MM/DD)"
/"IntervalEndRange=2000/1/1,2000/12/31"

//"[Space and Time Adjustments]"
/";												time trend adjustment type (0=None, 1=Nonparametric, 2=LogLinearPercentage,"
/";																			3=CalculatedLogLinearPercentage, 4=TimeStratifiedRandomization,"
/";																			5=CalculatedQuadraticPercentage)"
/"TimeTrendAdjustmentType=0"
/";												time trend adjustment percentage (>-100)"
/"TimeTrendPercentage=0"
/";												time trend type - SVTT only (Linear=0, Quadratic=1)"
/"TimeTrendType=0"
/";												adjust for weekly trends, nonparametric"
/"AdjustForWeeklyTrends=&&WEEKLYTRENDS&i"
/";												spatial adjustments type (0=No Spatial Adjustment, 1=Spatially Stratified Randomization)"
/"SpatialAdjustmentType=0"
/";												use adjustments by known relative risks file? (y/n)"
/"UseAdjustmentsByRRFile=n"
/";												adjustments by known relative risks file name (with HA Randomization=1)"
/"AdjustmentsByKnownRelativeRisksFilename="

//"[Inference]"
/";												p-value reporting type (Default p-value=0, Standard Monte Carlo=1, Early Termination=2,"
/";																		Gumbel p-value=3)"
/"PValueReportType=0"
/";												early termination threshold"
/"EarlyTerminationThreshold=50"
/";												report Gumbel p-values (y/n)"
/"ReportGumbel=n"
/";												Monte Carlo replications (0, 9, 999, n999)"
/"MonteCarloReps=&&montecarlo&i"
/";												adjust for earlier analyses(prospective analyses only)? (y/n)"
/"AdjustForEarlierAnalyses=n"
/";												prospective surveillance start date (YYYY/MM/DD)"
/"ProspectiveStartDate=1900/1/1"
/";												perform iterative scans? (y/n)"
/"IterativeScan=n"
/";												maximum iterations for iterative scan (0-32000)"
/"IterativeScanMaxIterations=0"
/";												max p-value for iterative scan before cutoff (0.000-1.000)"
/"IterativeScanMaxPValue=0.00"

//"[Border Analysis]"
/";												calculate Oliveira's F"
/"CalculateOliveira=n"
/";												number of bootstrap replications for Oliveira calculation (minimum=100, multiple of 100)"
/"NumBootstrapReplications=1000"
/";												p-value cutoff for cluster's in Oliveira calculation (0.000-1.000)"
/"OliveiraPvalueCutoff=0.05"

//"[Power Evaluation]"
/";												perform power evaluation - Poisson only (y/n)"
/"PerformPowerEvaluation=n"
/";												power evaluation method (0=Analysis And Power Evaluation Together,"
/";																		 1=Only Power Evaluation With Case File,"
/";																		 2=Only Power Evaluation With Defined Total Cases)"
/"PowerEvaluationsMethod=0"
/";												total cases in power evaluation"
/"PowerEvaluationTotalCases=600"
/";												critical value type (0=Monte Carlo, 1=Gumbel, 2=User Specified Values)"
/"CriticalValueType=0"
/";												power evaluation critical value .05 (> 0)"
/"CriticalValue05=0"
/";												power evaluation critical value .001 (> 0)"
/"CriticalValue01=0"
/";												power evaluation critical value .001 (> 0)"
/"CriticalValue001=0"
/";												power estimation type (0=Monte Carlo, 1=Gumbel)"
/"PowerEstimationType=0"
/";												number of replications in power step"
/"NumberPowerReplications=1000"
/";												power evaluation alternative hypothesis filename"
/"AlternativeHypothesisFilename="
/";												power evaluation simulation method for power step (	0=Null Randomization, 1=N/A,"
/";																									2=File Import)"
/"PowerEvaluationsSimulationMethod=0"
/";												power evaluation simulation data source filename"
/"PowerEvaluationsSimulationSourceFilename="
/";												report power evaluation randomization data from power step (y/n)"
/"ReportPowerEvaluationSimulationData=n"
/";												power evaluation simulation data output filename"
/"PowerEvaluationsSimulationOutputFilename="

//"[Spatial Output]"
/";												automatically launch Google Earth - gui only (y/n)"
/"LaunchKMLViewer=y"
/";												create compressed KMZ file instead of KML file (y/n)"
/"CompressKMLtoKMZ=n"
/";												whether to include cluster locations kml output (y/n)"
/"IncludeClusterLocationsKML=y"
/";												threshold for generating separate kml files for cluster locations (positive integer)"
/"ThresholdLocationsSeparateKML=1000"
/";												report hierarchical clusters (y/n)"
/"ReportHierarchicalClusters=y"
/";												criteria for reporting secondary clusters(0=NoGeoOverlap, 1=NoCentersInOther,"
/";														2=NoCentersInMostLikely,  3=NoCentersInLessLikely, 4=NoPairsCentersEachOther,"
/";														5=NoRestrictions)"
/"CriteriaForReportingSecondaryClusters=1"
/";												report gini clusters (y/n)"
/"ReportGiniClusters=n"
/";												gini index cluster reporting type (0=optimal index only, 1=all values)"
/"GiniIndexClusterReportingType=0"
/";												spatial window maxima stops (comma separated decimal values[<=50%] )"
/"SpatialMaxima=1,2,3,4,5,6,8,10,12,15,20,25,30,40,50"
/";												max p-value for clusters used in calculation of index based coefficients (0.000-1.000)"
/"GiniIndexClustersPValueCutOff=0.05"
/";												report gini index coefficents to results file (y/n)"
/"ReportGiniIndexCoefficents=n"
/";												restrict reported clusters to maximum geographical cluster size? (y/n)"
/"UseReportOnlySmallerClusters=n"
/";												maximum reported spatial size in population at risk (<=50%)"
/"MaxSpatialSizeInPopulationAtRisk_Reported=50"
/";												restrict maximum reported spatial size - max circle file? (y/n)"
/"UseMaxCirclePopulationFileOption_Reported=n"
/";												maximum reported spatial size in max circle population file (<=50%)"
/"MaxSizeInMaxCirclePopulationFile_Reported=50"
/";												restrict maximum reported spatial size - distance? (y/n)"
/"UseDistanceFromCenterOption_Reported=n"
/";												maximum reported spatial size in distance from center (positive integer)"
/"MaxSpatialSizeInDistanceFromCenter_Reported=1"

//"[Temporal Output]"
/";												output temporal graph HTML file (y/n)"
/"OutputTemporalGraphHTML=y"
/";												temporal graph cluster reporting type (0=Only most likely cluster,"
/";																					   1=X most likely clusters, 2=Only significant clusters)"
/"TemporalGraphReportType=2"
/";												number of most likely clusters to report in temporal graph (positive integer)"
/"TemporalGraphMostMLC=1"
/";												significant clusters p-value cutoff to report in temporal graph (0.000-1.000)"
/"TemporalGraphSignificanceCutoff=0.01"

//"[Other Output]"
/";												report critical values for .01 and .05? (y/n)"
/"CriticalValue=n"
/";												report cluster rank (y/n)"
/"ReportClusterRank=n"
/";												print ascii headers in output files (y/n)"
/"PrintAsciiColumnHeaders=n"
/";												user-defined title for results file"
/"ResultsTitle="

//"[Elliptic Scan]"
/";												elliptic shapes - one value for each ellipse (comma separated decimal values)"
/"EllipseShapes="
/";												elliptic angles - one value for each ellipse (comma separated integer values)"
/"EllipseAngles="

//"[Power Simulations]"
/";												simulation methods (0=Null Randomization, 1=N/A, 2=File Import)"
/"SimulatedDataMethodType=0"
/";												simulation data input file name (with File Import=2)"
/"SimulatedDataInputFilename="
/";												print simulation data to file? (y/n)"
/"PrintSimulatedDataToFile=n"
/";												simulation data output filename"
/"SimulatedDataOutputFilename="

//"[Run Options]"
/";												number of parallel processes to execute (0=All Processors, x=At Most X Processors)"
/"NumberParallelProcesses=0"
/";												suppressing warnings? (y/n)"
/"SuppressWarnings=n"
/";												log analysis run to history file? (y/n)"
/"LogRunToHistoryFile=y"
/";												analysis execution method  (0=Automatic, 1=Successively, 2=Centrically)"
/"ExecutionType=0"
%Mend TractParam;

/* Use location of installed SaTScan program files to point to "SaTScanBatch.exe" */
%macro callSatscan;
%macro dummy; %mend dummy;
/* Run SaTScan batch file */
x "&SATSCAN.Spatial.bat"; Run; 

/* read in the SaTScan output */

/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OutCol 
            DATAFILE= "&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

/* GIS file: One row per census tract with following fields */
/*	Census tract, cluster number, p-value, recurrence interval, observed cases */
/* 	in cluster, expected cases in cluster, observed/expected ratio in cluster, */
/*	observed cases in census tract, expected cases in census tract, */
/*	observed/expected ratio in census tract */ 
PROC IMPORT OUT= WORK.OUTGIS 
            DATAFILE= "&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today..gis.dbf" 
            DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;
%mend callSatscan;


/* This macro formats SaTScan output, appends all cluster info to archive, */
/*  and determines if there are any new clusters or events */
%macro switch;
%macro dummy; %mend dummy;

/* If cluster is centered on event, will need to bring in boro from event data */
proc sql;
create table outcol1 as
	select distinct a.*,
			b.boro
	from outcol a left join maven_events b
		on a.loc_id=b.event_id and
			a.z1=input(b.x_coord,best12.) and
			a.z2=input(b.y_coord,best12.);
quit;

data clusterinfo; 
	set outcol1;
	length disease_code $45 agegroup $15;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);
/* Cluster radius is output in ft, convert to other units */ 
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
/* If cluster is centered on CT centroid boro can be determined from 11 digit census tract ID */
	format centroidboro $13.;
	centroidboro=boro;
	if prxmatch("m/\d\d\d\d\d\d\d\d\d\d\d/o",loc_id)>0 then do;
		fipsCount=substr(loc_id,3,3);
		if fipsCount='085' then Centroidboro='STATEN ISLAND';
		if fipsCount='005' then Centroidboro='BRONX';
		if fipsCount='081' then Centroidboro='QUEENS';
		if fipsCount='047' then Centroidboro='BROOKLYN';
		if fipsCount='061' then Centroidboro='MANHATTAN';
	end;
	drop start_date end_date fipscount;
run;

/* Keep only clusters over predetermined recurrence interval threshold. If all id'd clusters are below this */
/* threshold then keep the cluster with the lowest p-value */
proc sort data=clusterinfo; by cluster p_value; run;
data clusterinfo2; 
	set clusterinfo;
	if _n_=1 or recurr_int>=&&recurrence&i;
run;

/* Keep fields to append to clusterhistory and satscanlinelist datasets, and for use in output if needed */
proc sql; 
	create table ClusterHistory as
	select disease_code
		,agegroup
		,centroidBoro
		,cluster
		,z1 as x
		,z2 as y
		,radiusMile format=6.2
		,clusterstartdate
		,clusterEndDate
		,numClusterdays
		,runDate
		,recurr_int
		,p_value format 6.2
	/* populate analysis parameter fields */
		,&&recurrence&i as Recurrence
		,&&maxGeog&i as MaxGeog
		,&&minTemp&i as MinTemp
		,&&maxTemp&i as MaxTemp	
		,&&monteCarlo&i as MonteCarlo
		,&&baseline&i as Baseline
		,"&&restrictspatial&i" as restrictspatial
		,&&maxspatial&i as maxspatial
		,0 as NumConfProbSuspPend
	from clusterInfo2;
quit;

/* Append saved cluster details to clusterhistory file */
proc append base=support.BCD003_Clusterhistory_94 data=ClusterHistory;run;
proc sort data=support.BCD003_Clusterhistory_94 out=support.BCD003_Clusterhistory_94 nodupkey ; by disease_code agegroup maxtemp rundate;run;

/* join all unique x, y, and tract info on event id */
proc sql;
create table outgis2 as
	select a.*,
			b.censustract as tract,
			b.x_coord,
			b.y_coord
	from outgis a left join satscan1 b
		on a.loc_id=b.event_id;
quit;

/* If a censustract (not event ID) populate tract with loc_id */
data outgis3; 
	set outgis2;
	if prxmatch("m/\d\d\d\d\d\d\d\d\d\d\d/o",loc_id)>0 and prxmatch("m/^99/o",loc_id)=0 then do;
	tract=loc_id;
	end;
	if tract=" " then delete;
run;

/* Select unique census tracts above the recurrence interval threshold or part of most likely cluster */
proc sort data=outgis3; by tract x_coord y_coord recurr_int; run;
data map_case; 
	set outgis3;
	if recurr_int>=&&recurrence&i or cluster=1;
	tract_lag=lag(tract);
	if tract_lag=tract then delete;
	keep loc_id tract p_value recurr_int cluster;
run;

/* Count # of census tracts above the recurrence interval threshold or in most likely cluster - this helps determines whether any clusters were identified */
%global switch;
%let switch=0;
proc sql noprint;
	select count(*)
	into :Switch
	from map_case
	where recurr_int>=&&recurrence&i or cluster=1;
quit;
%if &switch = 0 %then %return;

/* Count # of census tracts above the recurrence interval threshold - this helps determines whether output should be produced */
%global switch_RI;
%let switch_RI=0;
proc sql noprint;
	select count(*)
	into :switch_RI
	from map_case
	where recurr_int>=&&recurrence&i;
quit;

/* If a census tract or event_id is in more than one cluster, retain affiliation with associated cluster most likely to be true */
proc sort data=outgis3; by loc_id x_coord y_coord cluster; run;
data outgis4; 
	set outgis3;
	by loc_id x_coord y_coord;
	if first.x_coord=1 and first.y_coord=1;
run;

/* Separate event IDs from census tracts */
data cluster_events;
set outgis4;
	if prxmatch("m/\d\d\d\d\d\d\d\d\d\d\d/o",loc_id)=0 and (recurr_int>=&&recurrence&i or cluster=1) then output cluster_events;
run;

%mend switch;

/* Set up the data for the map with this macro */
%macro CHOROPLETH_setup;
%macro dummy; %mend dummy;
/* read in NYC census tracts from shapefile */
proc mapImport DATAFILE="&SUPPORT.BCD003_Detecting_Spatiotemporal_Disease_Clusters\BCD003_census_tract_SF1SF32K_OEM_2010.shp"  
	out=CityCensusTracts;
run;
data map_tract; set CityCensusTracts (keep=x y segment acres borocode nhoodcode puma shape_area shape_len sq_miles tract); run;
proc sort data=map_tract;by tract;run;
proc sort data=map_case; by tract;run;

proc sql;
create table cluster_tracts as
	select *
	from outgis4
	where (prxmatch("m/\d\d\d\d\d\d\d\d\d\d\d/o",loc_id)>0 and prxmatch("m/^99/o",loc_id)=0)
		and recurr_int>=&&recurrence&i;
quit; 

/* Merge all NYC census tracts with associated cluster and recurrence interval */
proc sort data=citycensustracts; by tract segment; run;
proc sort data=cluster_tracts out=outgis5 nodupkey; by tract; run;
proc sql; 
	create table RemoveRecurrence1 as 
	select ct.*
		,og.cluster
		,og.recurr_int
	from citycensustracts as ct
	left join outgis5 as og
	on ct.tract = og.tract;
quit;
/* If census tract is not part of a cluster label as cluster 99 for mapping purposes */  
data RemoveRecurrence2; 
	set RemoveRecurrence1;
	if recurr_int<&&recurrence&i then cluster=99;
	if x ^=.;
run;

/* "proc gremove" eliminates borders between census tracts that share cluster affiliation */
proc sort data=RemoveRecurrence2 out=RemoveRecurrence3; by cluster tract; run;
proc gremove data=RemoveRecurrence3 out=RemoveRecurrence4;
	by cluster;
	id tract;
run;
data RemoveRecurrence5; 
	set RemoveRecurrence4;
	ClusterMap=0;
	if cluster ^= 99 then Clustermap=cluster;
run;

/* Macro variables for assigning fill colors and patterns for mapping */
%global realClusterNum;
%global clusternum;
proc sql noprint;
	select (max(clustermap)), (max(clustermap))+1
	into: RealClusterNum, :clusternum
	from RemoveRecurrence5;
quit;
%mend choropleth_setup;


/* If there is a cluster in the output, set up the data for the cluster summary page with this macro */
%macro linelist_setup;
%macro dummy; %mend dummy;
/* select individuals in a significant census tract, merge cluster info by event ID, cluster, and x/y */
proc sql; 
	create table Satscan3 as 
	select distinct s.*,
					ce.cluster,
					ce.tract,
					ci.z1 as cluster_x,
					ci.z2 as cluster_y,
					ci.radius as cluster_radius,
					ci.Clusterstartdate,
					ci.clusterenddate
	from satscan1 as s
		,cluster_events as ce
		,clusterinfo2 as ci 
	where ce.loc_id = s.event_id and (ce.recurr_int>=&&recurrence&i or ce.cluster=1)
		and ce.cluster=ci.cluster and s.x_coord=ce.x_coord and s.y_coord=ce.y_coord;
quit;

/* Remove event addresses that fall outside cluster using address x/y, cluster center x/y, and radius  */
data SaTScan4;
set SaTScan3;
	dist_from_center=sqrt((abs(x-cluster_x)**2)+(abs(y-cluster_y)**2));
	if dist_from_center>cluster_radius then delete;
run;

proc sort data=satscan4 out=ClusterToCensus;
	by event_id x y cluster;
run;

/* If address in more than one cluster, retain affiliation with associated cluster most likely to be true */
data linelist1; 
	set clustertocensus;
	by event_id x y;
	if first.x=1 and first.y=1;
run;

proc sql;
create table additional_events_samexy as
	select a.*,
			ll.cluster,
			ci.Clusterstartdate,
			ci.clusterenddate		
	from satscan1 a, linelist1 ll, clusterinfo2 ci 
	where a.event_id ^in(select event_id from linelist1) and
		a.x_coord=ll.x_coord and
		a.y_coord=ll.y_coord and
		ll.cluster=ci.cluster and
		a.event_date<=ci.clusterenddate and
		a.event_date>=ci.clusterstartdate;
quit;

/* Exclude events with "Not A Case" disease status or event date outside the cluster window */
data linelist2; 
	set linelist1 additional_events_samexy;
	if disease_status_final not in ('NOT_A_CASE');
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	if event_date >= ClusterStartDate;
	if event_date <= ClusterEndDate;
	attrib InvestStat length=$20.;
	InvestStat=investigation_status;
	runDate=&todaynum; format rundate mmddyy10.;
	MaxTemp=&&maxtemp&i;
	agegroup ="&&agegroup&i";
run;

/* Count number of events in linelist 2 (cluster events excluding "not a case") */
%let cluster_cases=%sysfunc(open(linelist2));
%let num_cluster_cases=%sysfunc(attrn(&cluster_cases,nobs));
%let end=%sysfunc(close(&cluster_cases));

%if &num_cluster_cases >0 %then %do;

proc sort data=linelist2;
	by cluster disease_code agegroup maxtemp rundate;
run;

/* Select all event IDs in cluster */
proc transpose data=linelist2 out=linelist2_wide (drop=_name_ _label_);
by cluster disease_code agegroup maxtemp rundate;
	var event_id;
run;

/* Concatenate event IDs into one field */
data linelist2_catx;
set linelist2_wide;
	format eventIDs $1000.;
	eventIDs=catx("|",of col:);
	drop col:;
run;

proc sort data=support.BCD003_clusterhistory_94;
	by disease_code agegroup maxtemp rundate cluster;
run;

proc sort data=linelist2_catx;
	by disease_code agegroup maxtemp rundate cluster;
run;

/* Add list of event IDs to clusterhistory file */
data support.BCD003_clusterhistory_94;
merge support.BCD003_clusterhistory_94 linelist2_catx;
	by disease_code agegroup maxtemp rundate cluster;
run;

%end;

/* If there is a cluster that meets of exceeds the recurrence interval threshold continue processing */
%if &switch_ri>0 %then %do; 

/* Make a new dataset to retain the current cluster affiliation */
proc sql;
create table current_cluster as
select distinct event_id,
				cluster,
				event_date
	from linelist2
	order by event_id;
quit; 

/* Merge to compare current events with events already in historical satscan linelist */
/* Linelist2: Cluster events that are new or already exist in historical satscan linelist */
/*		Used to print case linelist in output */
/* existing_&&disease_code&i.._&&maxtemp&i.._&&agegroup&i..: Cluster events already in historical satscan linelist */
/*		Used to define a signal as new or ongoing */
proc sort data=linelist2;by event_id disease_code maxtemp agegroup;run;
proc sort data=support.BCD003_satscanlinelist_94;by event_id disease_code maxtemp agegroup;run;
data linelist2 existing_&&disease_code&i.._&&maxtemp&i.._&&agegroup&i..;
	merge linelist2 (in=a) support.BCD003_satscanlinelist_94 (in=b);
	by event_id;
	if a;
	if a & ~b then New = "*";
	if a then output linelist2;
	if a & b then output existing_&&disease_code&i.._&&maxtemp&i.._&&agegroup&i..;
run;

%global cluster_evts;
%let cluster_evts = "NONE";
	proc sql;
		select distinct quote(strip(event_id))
		into :cluster_evts separated by ", "
		from linelist2;
	quit;

%if &cluster_evts="NONE" %then %return;

%global minclusterstartdate maxclusterenddate;
	proc sql;
		select min(clusterstartdate), max(clusterenddate)
		into :minclusterstartdate, :maxclusterenddate
		from linelist2;
	quit;

/* this is where we look for events with secondary addresses in the geographic area of the cluster who are not in the cluster */
/* Pull all addresses in secondary address history table within temporal parameters of at least one cluster */
data check;
	set all_Secondary_addresses;
	where datepart(start_date) >= &minClusterStartDate & datepart(start_date) <= &maxClusterEndDate;
	if type_disp in ("Home (Secondary)","Work (Secondary)") then type_disp = substr(type_disp,1,4);
	x=input(CUSTOM_FIELD1,8.);
	y=input(CUSTOM_FIELD2,8.);
	x_coord=CUSTOM_FIELD1;
	y_coord=CUSTOM_FIELD2;
	format address_enddate mmddyy10.;
	address_enddate=datepart(end_date);
	format address_startdate mmddyy10.;
	address_startdate=datepart(start_date);
	if address_enddate='01JAN2030'd then address_enddate=&todaynum;
run;
/* only keep active addresses or addresses other than Home */
data check2;
	set check (where=(~(datepart(start_date)='01jan1900'd & datepart(end_date)='01jan2030'd) | type_disp~="Home"));
run;
proc sort data = check2 (keep=party_id start_date street1 x y x_coord y_coord custom_field4 custom_field7 type_disp tract county
							address_enddate address_startdate);
	by party_id start_date custom_field4;
run;
/* pull in event mapping to people with disease and within temporal parameters of at least one cluster, but not in a cluster */
data address_events (keep=party_id event_id disease_status_final disease_code event_date uhf boro gender investigation_status zip age);
set events;
	where disease_code="&&disease_code&i" and
			event_date >= &minClusterStartDate and event_date <= &maxClusterEndDate;
run;

%let notcluster_evts = "NONE";
	proc sql;
		select distinct quote(event_id)
		into :notcluster_evts separated by ", "
		from address_events;
	quit;
/* And reports of qualifying events after Maven go-live */
data address_reports (keep=event_id daterecdbybcd reporting_date);
set maven.dd_aow_reports;
	where event_id in(&notcluster_evts) and datepart(daterecdbybcd)>'14jul2012'd;
run;

/* merge event and report data */
proc sort data = address_events; by event_id; run;
proc sort data = address_reports; by event_id; run;
data address_events_reports;
	merge address_events address_reports (in=b);
	by event_id;
	if b;
run;
/* Keep first report date per party */
proc sort data = address_events_reports; by party_id daterecdbybcd; run;
data address_first_report;
	set address_events_reports;
	by party_id daterecdbybcd;
	if first.party_id then output;
run;
/* Merge candidate addresses with candidate events and format census tract */
data maven_addresshistory;
	merge check2 (in=a) address_first_report (in=b);
	by party_id;
	if a & b;
	if datepart(start_date)='01jan1900'd then start_date=daterecdbybcd;
	if year(datepart(start_date))>year(date()) then delete;
	format reportdate mmddyy10.;
	reportdate = datepart(start_date);
	if type_disp = "Home" then address_type = "Other home";
	else if type_disp = "Work" then address_type = "Work";
	else if type_disp not in ("Home","Work") then address_type = "Other";
	/* format census tract */
	StateNum=strip('36');
	/* Marble Hill */
	if index(tract,'309')~=0 and county='Bronx County (Bronx)' then county='New York County (Manhattan)';
	/* Rikers Island men's jails */
	if tract in ('   1','000100') and zip='11370' then county='Bronx County (Bronx)';
	if county = 'Bronx County (Bronx)' then BoroCode=strip('005');
	if county = 'Queens County (Queens)' then BoroCode=strip('081');
	if county = 'Kings County (Brooklyn)' then BoroCode=strip('047');
	if county = 'New York County (Manhattan)' then boroCode=strip('061');
	if county = 'Richmond County (Staten Island)' then borocode=strip('085');
	CensusTract = substr(compress(stateNum||BoroCode||tract),1,11);
/* Keep only confirmed, probable, suspect, pending of disease being evaluated */
	if disease_code = "&&disease_code&i";
	if disease_status_final in ("CONFIRMED","PROBABLE","SUSPECT","PENDING");
	keep party_id event_id disease_status_final disease_code event_date uhf boro gender investigation_status zip age
		reportdate street1 x y x_coord y_coord custom_field4 custom_field7 address_type type_disp censustract;
run;

proc sort data=maven_addresshistory nodupkey;
by event_id x y;
run;

/* Add cluster info */
proc sql; 
	create table addresses_clusterinfo as 
	select distinct s.*,
					ce.cluster,
					ci.z1 as cluster_x,
					ci.z2 as cluster_y,
					ci.radius as cluster_radius,
					ci.Clusterstartdate,
					ci.clusterenddate
	from maven_addresshistory as s
		,cluster_events as ce
		,clusterinfo2 as ci 
	where (ce.recurr_int>=&&recurrence&i or ce.cluster=1) and ce.cluster=ci.cluster;
quit;

data all_secondary_addrs_in_cluster;
set addresses_clusterinfo;
	if event_date >= ClusterStartDate & reportdate >= ClusterStartDate &
		event_date <= ClusterEndDate & reportdate <= ClusterEndDate;
	dist_from_center=sqrt((abs(x-cluster_x)**2)+(abs(y-cluster_y)**2));
	if dist_from_center>cluster_radius then delete;
run;

proc sql;
create table secondary_addrs_new_events as
	select *
	from all_secondary_addrs_in_cluster
	where event_id ^in(select distinct event_id from linelist2)
	order by event_id, cluster;
create table new_secondary_addrs as
	select *
	from all_secondary_addrs_in_cluster
	where event_id in(select distinct event_id from linelist2);
create table new_secondary_addrs2 as
	select a.*
	from new_secondary_addrs a, linelist2 b 
	where a.event_id=b.event_id and (a.x_coord^=b.x_coord or a.y_coord^=b.y_coord)
	order by event_id, x, y, cluster;
quit;


/* Keep one row per disease event meeting spatio-temporal cluster definition */
data linelist6; 
	set secondary_addrs_new_events;
	by event_id cluster;
	if first.event_id=1;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	if event_date >= ClusterStartDate & reportdate >= ClusterStartDate & event_date <= ClusterEndDate & reportdate <= ClusterEndDate;
	attrib InvestStat length=$20.;
	InvestStat=investigation_status;
	runDate=date(); format rundate mmddyy10.;
run;

data new_unique_secondary_addrs;
set new_secondary_addrs2;
	by event_id x y cluster;
	if first.event_id=1 and first.x=1 and first.y=1;
run;

%end;

%mend linelist_setup;



/* Macro to determine if new events 	*/
/*	1. In a new cluster					*/
/*	2. Were added to an ongoing cluster		*/
%macro NewIndividuals;
%macro dummy; %mend dummy;

proc sql; 
	create table LineListIndividuals as
	select distinct event_id
		,disease_code
		,agegroup
		,event_date
		,cluster
		,rundate
		,maxtemp
	from linelist2
	order by event_id, rundate;
quit;
/* Count number of confirmed, probable, and suspect cases */
%global count;
proc sql;
	select count(*) as count
	into :count
	from linelist2
	where disease_status_final in ("CONFIRMED","PROBABLE","SUSPECT","PENDING") and
			cluster=1;
quit;
%put &count;

/* Add confirmed, probable, and suspect count to cluster history */
data clusterhistory;
	set clusterhistory;
	NumConfProbSuspPend = &count.;
run;

/* Add confirmed, probable, and suspect count to archived cluster history dataset */
proc sort data = clusterhistory; by disease_code agegroup maxtemp rundate cluster; run;
proc sort data = support.BCD003_clusterhistory_94; by disease_code agegroup maxtemp rundate cluster; run;
data support.BCD003_clusterhistory_94;
	merge support.BCD003_clusterhistory_94 (in=a) clusterhistory (in=b);
	by disease_code agegroup maxtemp rundate cluster;
	if a;
run;

/* Set up data for cluster history linelist output */
%global current_evts;
proc sql;
select distinct strip(event_id)
	into :current_evts separated by "|"
	from linelist2
	where cluster=1;
quit;

/* Select rows from clusterhistory file from past 7 days with events in common with today's most likely cluster */
data clusterhistory_linelist;
set support.BCD003_clusterhistory_94;
	where disease_code = "&&disease_code&i" and
		agegroup="&&agegroup&i" and
		maxtemp=&&maxtemp&i and
		rundate>=&todaynum-7
		and prxmatch("m/(&current_evts.)/i",eventIDs)>0;
	format x 8.;
	format y 8.;
	format radiuskm 6.2;
	radiuskm=radiusMile*1.60934;
	if RECURR_INT<&&recurrence&i then NumConfProbSuspPend=.;
run;

data clusterhistory_linelist;
set clusterhistory_linelist;
	where eventIDs is not missing;
run;

proc sort data=clusterhistory_linelist;
	by descending rundate;
run;

/* Count number of rows in cluster history linelist dataset */
%global ch_ll_num;
%let ch_ll=%sysfunc(open(clusterhistory_linelist));
%let ch_ll_num=%sysfunc(attrn(&ch_ll,nobs));
%let end=%sysfunc(close(&ch_ll));

/* If only row is today's cluster info do not continue processing */
%if &ch_ll_num >1 %then %do;

/* calculate days between rows */
data clusterhistory_linelist2;
set clusterhistory_linelist;
	row=_n_;
	laggeddate=lag(rundate);
	difference=laggeddate-rundate;
	if rundate=&todaynum then difference=0;
	do i=1 to &ch_ll_num;
		if difference gt 1 then stop=row;
	end;
run;

%global stop;
proc sql;
select min(stop), max(difference)
	into :stop, :max_diff
	from clusterhistory_linelist2;
quit;

/* If any gaps remove so only consecutive rows going back from today are displayed */
%macro cluster_history_rows;
%macro dummy; %mend dummy;
data clusterhistory_linelist3;
set clusterhistory_linelist2;
	%if &max_diff>1 %then %do;
	where row<&stop;
	%end;
	if cluster^=1 and rundate=&todaynum then delete;
run;
%mend cluster_history_rows;
%cluster_history_rows;

%end;


/* Keep events new to SaTScan linelist by disease and analysis parameters */
proc sql; 
	create table NewIndividuals as
	select lli.*
	from linelistIndividuals as lli
	left join support.BCD003_satscanlinelist_94 as s
	on lli.event_id=s.event_id and lli.disease_code=s.disease_code
		and lli.agegroup=s.agegroup and lli.maxtemp=s.maxtemp
	having s.event_id ='';
quit;

/* Count number of rows in dataset of new individuals - determines whether macros to produce output will be run */
%let dsid=%sysfunc(open(NewIndividuals)); *open out1;
%global numnew;
%let numnew=%sysfunc(attrn(&dsid,nobs)); * # observations in work.display;
%let rc=%sysfunc(close(&dsid)); *close work.display;   
%if &NumNew=0 %then %return;
%mend NewIndividuals;

/* Append new individuals to historic SaTScan Linelist */
%macro AddToList;
%macro dummy; %mend dummy;
proc sort data=NewIndividuals; by event_id disease_code agegroup maxtemp ;run;
proc append base=support.BCD003_SatScanLineList_94 data=NewIndividuals;run;
proc sort data=support.BCD003_SatScanLineList_94 out=support.BCD003_SatScanLineList_94 nodupkey; by event_id disease_code agegroup maxtemp;run;
%mend AddtoList;

/* Macro to generate chloropleth map of significant clusters over NYC outline base map */
%macro MakeChoropleth;
%macro dummy; %mend dummy;
data annotate; 
	set LineList2 ;
	length style $6 color $ 6 text $ 20;
	retain xsys ysys '2' hsys '3' when 'a';
	/*Add points for each address in cluster */
	function='symbol'; style='marker'; size=.5; text='C'; color = "CYAN";
run;
/* Open word file for output */
ods listing close;
ods rtf body = "&ARCHIVETODAY.satscan94_&&Disease_Code&i.._&&agegroup&i.._&&maxTemp&i.._&today..rtf";
ods rtf file = "&ARCHIVETODAY.satscan94_&&Disease_Code&i.._&&agegroup&i.._&&maxTemp&i.._&today..rtf";
ods rtf style=Meadow;

/* Set options and title statements */
goptions reset=goptions device=png300 target=png300 ftext='Calibri' ftitle='Calibri/bold' htitle=2 xmax=9 in ymax=7 in;	
title1 height=1.5 "&&disease_code&i clusters with event dates through &Simendformat";
title2 height=1.3 "Confirmed, probable, suspected and pending cases";

/* Set gradient of 10 possible cluster color patterns, 							*/
/* plus one light grey fill pattern for census tracts not affiliated with a cluster 	*/
pattern1 value=msolid color=CXfc8d59; /* cluster with highest recurrence interval */
pattern2 value=msolid color=CXd6ad4b;
pattern3 value=msolid color=CXfee08b;
pattern4 value=msolid color=CXfdfd65;
pattern5 value=msolid color=CXffffbf;
pattern6 value=msolid color=CXe6f598;
pattern7 value=msolid color=CXb7f291;
pattern8 value=msolid color=CX99d594;
pattern9 value=msolid color=CX51d06d;
pattern10 value=msolid color=CX4b9cd8; /* cluster with lowest recurrence interval */
pattern11 value=msolid color=CXECEDEC; /* not part of a cluster */

/* Set cluster color pattern based on number of clusters represented on map */
data _null_;
%if &CLusterNum=2 
	%then %do;
	pattern2 value=msolid color=CXECEDEC;	
	%end;	
%if &CLusterNum=3
	%then %do;
	pattern3 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=4 
	%then %do;
	pattern4 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=5 
	%then %do;
	pattern5 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=6 
	%then %do;
	pattern6 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=7 
	%then %do;
	pattern7 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=8 
	%then %do;
	pattern8 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=9 
	%then %do;
	pattern9 value=msolid color=CXECEDEC;
	%end;
%if &CLusterNum=10 
	%then %do;
	pattern10 value=msolid color=CXECEDEC;
	%end;
run;

/* Set footnotes */
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate;
footnote1 font='Arial' justify=left height=1 "Statistic: Prospective space-time permutation scan statistic";
footnote2 font='Arial' justify=left height=1 "Spatial resolution: census 2000 tracts";
footnote3 font='Arial' justify=left height=1 "Baseline period: &&baseline&i days";
footnote4 font='Arial' justify=left height=1 "Minimum temporal cluster size (days): &&mintemp&i   Maximum temporal cluster size (days): &&maxtemp&i";
%if &&restrictspatial&i=n %then %do;
footnote5 font='Arial' justify=left height=1 "Maximum spatial cluster size (% of cases): &&maxgeog&i";
%end;
%if &&restrictspatial&i=y %then %do;
footnote5 font='Arial' justify=left height=1 "Maximum spatial cluster size (% of cases): &&maxgeog&i    Maximum spatial cluster size as distance from cluster center: &&maxspatial&i";
%end;
footnote6 font='Arial' justify=left height=1 "Number of Monte Carlo simulations: &&montecarlo&i";
footnote7 font='Arial' justify=left height=1 "Criteria for reporting secondary clusters: no cluster center in other clusters";
footnote8 font='Arial' justify=left height=1 "Only recurrence interval >= &&recurrence&i days are shown";
footnote9 font='Arial' justify=left height=1 "Time aggregation (days)= &&timeagg&i    Adjusted for space by day-of-week interaction= &&weeklytrends&i.";

/* Generate map in output */
proc gmap map=RemoveRecurrence5 data=RemoveRecurrence5 anno=annotate; 
	id cluster;
	choro cluster/ levels=&clusternum
	coutline=gray
		CDEFAULT = white	
		cempty=blue
		cempty=black
		legend=legend1;
run; 
quit;
%mend MakeChoropleth;


%macro MakeClusterLineList;
%macro dummy; %mend dummy;
/* Set options and title statements */
title1  "Cluster information";
title2 height=1.5 "Cluster #1 is the most likely cluster, i.e. the cluster least likely to be due to chance";
footnote1 font='Arial' height=2 '*Recurrence interval represents the expected length of follow-up required to see one cluster at least as unusual as the observed cluster by chance.';

/* Modify titles and footnotes if outputting cluster history linelist */
%if &ch_ll_num>1 %then %do;
title2 height=1.5 "First table: Today's clusters. Cluster #1 is the most likely cluster, i.e. the cluster least likely to be due to chance";
title3 height=1.5 "Second table: Linelist of clusters in the past few days with one or more event IDs in common with today's most likely cluster";
footnote2 font='Arial' height=2 '**Missing if recurrence interval below the signaling threshold.';
%end;

/* Format select variables for output */
proc sql; 
	create table clusterinfoGraph as
	select distinct cluster
		,clusterstartdate
		,clusterenddate
		,numclusterdays
		,radiusMile format = 5.2
		,radiusKm format= 6.2
		,ode format=4.2
		,recurr_int
	from clusterinfo
	where recurr_int >= &&recurrence&i;
quit;

/* Output linelist of cluster information to word document - row color corresponds to color of cluster on map */
proc report data=clusterinfoGraph nowd;
	column cluster clusterstartdate clusterenddate numclusterdays radiusMile radiusKm ode recurr_int;
	define cluster / order 'Cluster' width=1;
	define clusterstartdate /'Start date' width = 18;
	define clusterenddate/ 'End date' width=18;
	define NumClusterDays/'# days in cluster' width=5;
	define radiusMile/'Radius (miles)' width=5 ;
	define radiuskm/'Radius (km)' width=5 ;
	define ode / "Observed over Expected" width=4;
	define recurr_int / 'Recurrence interval (days)*' width=5;
	compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
	ENDCOMP;
run;

/* Only output cluster history linelist if more than one row */
%if &ch_ll_num>1 %then %do;
ods startpage=no;

ods rtf text = ' ';
ods rtf text = ' ';

proc report data=clusterhistory_linelist3 nowd;
	column cluster centroidboro X Y radiusmile radiuskm clusterstartdate numclusterdays NumConfProbSuspPend rundate recurr_int;
	define cluster / "Cluster";
	define centroidboro /"Boro of Cluster Center";
	define X /"X Coordinate of Cluster Center";
	define Y /"Y Coordinate of Cluster Center";
	define radiusmile /"Radius (miles)";
	define radiuskm /"Radius (km)";
	define clusterstartdate /"Start Date";
	define numclusterdays /"# Days in Cluster";
	define NumConfProbSuspPend /"# of Confirmed, Probable, Suspect, and Pending cases**";
	define rundate / order "Run Date" order=internal;
	define recurr_int /"Recurrence interval (days)";
compute rundate; 
	if rundate="&today"d 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
endcomp;
run;
ods startpage=yes;
%end;

title;
footnote;

%Mend MakeClusterlinelist;


%macro PersonLineList;
%macro dummy; %mend dummy;
/* Overwrite first cluster affiliation with current cluster affiliation - moved upstream 03JAN2017 */
proc sort data=linelist2; by event_id; run;
proc sort data=current_cluster; by event_id; run;
data linelist3;
	merge linelist2 (in=a) current_cluster (in=b);
	by event_id;
	if a;
run;

/* Format for output */
data linelist4; 
	set linelist3;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib DiseaseStat length=$20.;
	diseaseStat=disease_status_final;
	drop disease_status_final;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

%global outbreak_code_num;
%let outbreak_code_num=0;

%if &disease_code="LEG" %then %do;

proc sql;
create table outbreakcode as
select a.target_case_id as event_id,
		a.source_case_id as outbreak_id,
		b.case_name as outbreak
from maven.dd_aow_case_link a, maven.dd_outbreak b
where target_case_id in(select eventid from linelist4)
	and a.source_case_id=b.case_id;
quit;

%let outbreak_code=%sysfunc(open(outbreakcode));
%let outbreak_code_num=%sysfunc(attrn(&outbreak_code,nobs));
%let end=%sysfunc(close(&outbreak_code));

	%if &outbreak_code_num>0 %then %do;
	proc sql;
	create table linelist4 as
	select a.*,
			b.outbreak_id
	from linelist4 a left join outbreakcode b
		on a.eventid=b.event_id;
	quit;
	%end;
%end;

proc sort data=linelist4; by cluster event_date;run;

/* Set title and footnote statements */
title1 'Cluster information';
title2 'Individuals included in the cluster';
footnote1 '* Event ID did not appear on any previous report';
footnote2 ;
/* Output person linelist to word document */
proc report  data=linelist4 nowd ;
column cluster new eventid  diseasestat investStat event_date age 
	gender type street_1 boroshort zip censustract
	%if &outbreak_code_num>0 %then %do;
		outbreak_id
	%end;
	;
define cluster / order 'Cluster' width=1;
define New / 'New event*' width=1;
define diseasestat /'Disease status' width=5;
define investStat / 'Investigation status' width=4;
define eventid /'Event ID' width=8;
define event_date / 'Event date' format=mmddyy10. width=10;
define age / 'Age' width=3;
define gender / 'Sex' width=2;
define type / 'Address type' width=8;
define street_1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
	%if &outbreak_code_num>0 %then %do;
		define outbreak_id / 'Outbreak ID' width=8;
	%end;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;


/* For certain diseases, pull reporter and reporting facility information for individuals in cluster */
%if &disease_code in("GAS","PNE") %then %do;

/* Pull all disease reports for events in cluster */ 
proc sql;
create table linelist4_reports as
select a.event_id,
		a.cluster,
		b.hcf_name,
		b.hcf_addressline1,
		b.hcf_addressline2,
		b.hcf_city,
		b.hcf_state,
		b.hcf_zip,
		b.hcf_phone,
		b.reporter_facility_name
from linelist4 a left join maven.dd_aow_reports b on event_id;
quit;


/* Keep one report per unique Health Care Facility name value per event */
proc sort data=linelist4_reports nodupkey;by cluster hcf_name event_id;run;

/* Set title and footnote statements */
title1 'Cluster information';
title2 'Reporting information for individuals included in the cluster';
footnote;
/* Output reporting information to word document */
proc report  data=linelist4_reports nowd ;
column cluster event_id hcf_name hcf_phone hcf_addressline1 hcf_addressline2 hcf_city hcf_state hcf_zip reporter_facility_name;
define cluster /order 'Cluster' width=1;
define event_id /'Event ID' width=8;
define hcf_name /'Health Care Facility' width=12;
define hcf_phone /'HCF Contact' width=8;
define hcf_addressline1 /'HCF Address 1' width=13;
define hcf_addressline2 /'HCF Address 2' width=7;
define hcf_city /'HCF City' width=6;
define hcf_state /'HCF State' width=1;
define hcf_zip /'HCF Zip'  width=5;
define reporter_facility_name /'Reporter Facility' width=12;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;
%end;

/* Count number of new events with cluster addresses to print in output */
%let new_cluster_add=%sysfunc(open(linelist6));
%let num_new_cluster_add=%sysfunc(attrn(&new_cluster_add,nobs));
%let end=%sysfunc(close(&new_cluster_add));

/* If any addresses to be output then run */
%if &num_new_cluster_add>0 %then %do;

/* Format for output */
data linelist7; 
	set linelist6;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib DiseaseStat length=$20.;
	diseaseStat=disease_status_final;
	drop disease_status_final;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

%global outbreak_code2_num;
%let outbreak_code2_num=0;

%if &disease_code="LEG" %then %do;

proc sql;
create table outbreakcode2 as
select a.target_case_id as event_id,
		a.source_case_id as outbreak_id,
		b.case_name as outbreak
from maven.dd_aow_case_link a, maven.dd_outbreak b
where target_case_id in(select eventid from linelist8)
	and a.source_case_id=b.case_id;
quit;

%let outbreak_code2=%sysfunc(open(outbreakcode2));
%let outbreak_code2_num=%sysfunc(attrn(&outbreak_code2,nobs));
%let end=%sysfunc(close(&outbreak_code2));

	%if &outbreak_code2_num>0 %then %do;
	proc sql;
	create table linelist7 as
	select a.*,
			b.outbreak_id
	from linelist7 a left join outbreakcode2 b
		on a.eventid=b.event_id;
	quit;
	%end;
%end;

proc sort data=linelist7; by cluster zip;run;

/* Set title and footnote statements */
title1 'Individuals not included in cluster by residential address at time of report who have another home or work address in the cluster';
title2;
footnote1 ;
footnote2 ;
/* Output list of new addresses to word document */
proc report  data=linelist7 nowd ;
column cluster eventid  diseasestat investStat event_date age 
	gender street1 boroshort zip censustract
	%if &outbreak_code2_num>0 %then %do;
		outbreak_id
	%end;
;
define cluster / order 'Cluster' width=1;
define diseasestat /'Disease status' width=5;
define investStat / 'Investigation status' width=4;
define eventid /'Event ID' width=8;
define event_date / 'Event date' format=mmddyy10. width=10;
define age / 'Age' width=3;
define gender / 'Sex' width=2;
define street1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
	%if &outbreak_code2_num>0 %then %do;
		define outbreak_id / 'Outbreak ID' width=8;
	%end;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;
%end;


/* This is where we list additional relevant addresses for events in the cluster */
/* Count number of new cluster addresses to print in output */
%let rev_cluster_add=%sysfunc(open(new_unique_secondary_addrs));
%let num_rev_cluster_add=%sysfunc(attrn(&rev_cluster_add,nobs));
%let end=%sysfunc(close(&rev_cluster_add));

/* If any additional relevant addresses to be output then run */
%if &num_rev_cluster_add>0 %then %do;

/* Format for output */
proc sort data= new_unique_secondary_addrs; by event_id cluster; run;
data new_unique_secondary_addrs2; 
	set new_unique_secondary_addrs;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib Type length=$20.;
	Type=type_disp;
	drop type_disp;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

/* Set title and footnote statements */
title1 'Individuals included in cluster by residential address at time of report who also have another home or work address in the cluster area';
title2;
footnote1 ;
footnote2 ;
/* Output list of additional relevant addresses to word document */
proc report  data=new_unique_secondary_addrs2 nowd ;
column cluster eventid type street_1 boroshort zip censustract;
define cluster / order 'Cluster' width=1;
define eventid /'Event ID' width=8;
define type / 'Address type' width=8;
define street_1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;
%end;

/* Close word document */
ods rtf close;
ods listing;
%mend PersonLineList;


%macro PersonLineList_mPCR;
%macro dummy; %mend dummy;

/* Pull all reports for events in the linelist */
		data cluster_hcfs (keep=event_id hcf_name);
		set maven.dd_aow_reports;
			where event_id in(&cluster_evts);
			provider_name=catx(" ",provider_first_name, provider_middle_name, provider_last_name);
			if hcf_name=" " then hcf_name=provider_name;
			hcf_name=upcase(strip(hcf_name));
		run;

	/* sort and dedupe by hcf name to save only unique facilities */
		proc sort data=cluster_hcfs nodupkey;by event_id hcf_name;run;

	/* transpose to wide format */
		proc transpose data=cluster_hcfs out=cluster_hcfs_wide;
			by event_id;
			var hcf_name;
		run;

	/* Concatenate unique tests */
		data unique_cluster_hcfs (keep = event_id unique_hcfs);
		set cluster_hcfs_wide;
		unique_hcfs = catx('; ',of col:);
		run;

/* Pull all positive labs for events in the linelist */
		data cluster_labs (keep=event_id test_name);
		set maven.dd_aow_labs;
			where event_id in(&cluster_evts);
			if index(upcase(RESULT_NAME),"NEGATIVE")>0 then delete;
			test_name=upcase(strip(test_name));
			test_name=tranwrd(test_name,"BIOFIRE FILMARRAY GASTROINTESTINAL PANEL","BIOFIRE");
		run;

	/* sort and dedupe by test name to save only unique tests */
		proc sort data=cluster_labs nodupkey;by event_id test_name;run;

	/* transpose to wide format */
		proc transpose data=cluster_labs out=cluster_labs_wide;
			by event_id;
			var test_name;
		run;

	/* Concatenate unique tests */
		data unique_cluster_labs (keep = event_id unique_tests);
		set cluster_labs_wide;
			unique_tests = catx('; ',of col:);
		run;
	
	/* Sort and merge by event ID to add hcf and test data to signals dataset */
		proc sort data=linelist2;
			by event_id;
		run;
		proc sort data=unique_cluster_hcfs;
			by event_id;
		run;	
		proc sort data=unique_cluster_labs;
			by event_id;
		run;

		data linelist2;
		merge linelist2 unique_cluster_hcfs unique_cluster_labs;
			by event_id;
		run;

/* Overwrite first cluster affiliation with current cluster affiliation */
data linelist3;
	merge linelist2 (in=a) current_cluster (in=b);
	by event_id;
	if a;
run;
/* Format for output */
data linelist4; 
	set linelist3;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib DiseaseStat length=$20.;
	diseaseStat=disease_status_final;
	drop disease_status_final;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

proc sort data=linelist4; by cluster event_date;run;

/* Set title and footnote statements */
title1 'Cluster information';
title2 'Individuals included in the cluster - primary linelist';
footnote1 '* Event ID did not appear on any previous report';
footnote2 ;
/* Output person linelist to word document */
proc report  data=linelist4 nowd ;
column cluster new eventid  diseasestat investStat event_date age 
	gender type street_1 boroshort zip censustract;
define cluster / order 'Cluster' width=1;
define New / 'New event*' width=1;
define diseasestat /'Disease status' width=5;
define investStat / 'Investigation status' width=4;
define eventid /'Event ID' width=8;
define event_date / 'Event date' format=mmddyy10. width=10;
define age / 'Age' width=3;
define gender / 'Sex' width=2;
define type / 'Address type' width=8;
define street_1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;


title1 'Cluster information';
title2 'Individuals included in the cluster - supplemental linelist';
footnote1 '* Event ID did not appear on any previous report';
footnote2 ;
proc report data=linelist4 nowd;
column cluster eventid diseasestat event_date boroshort unique_hcfs unique_tests;
	define cluster/ order "Cluster" width=1;
	define eventid/ "Event ID" width=8;
  	define diseasestat/ "Disease Status" width=5;
  	define event_date/ "Event Date" width=10;
  	define boroshort/ "Boro" width=10;
	define unique_hcfs/ "Health Care Facilities" width=15;
	define unique_tests/ "Lab Test Types" width=15;
	compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;


/* Count number of new cluster addresses to print in output */
%let new_cluster_add=%sysfunc(open(linelist6));
%let num_new_cluster_add=%sysfunc(attrn(&new_cluster_add,nobs));
%let end=%sysfunc(close(&new_cluster_add));

/* If any addresses to be output then run */
%if &num_new_cluster_add>0 %then %do;

/* Format for output */
data linelist7; 
	set linelist6;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib DiseaseStat length=$20.;
	diseaseStat=disease_status_final;
	drop disease_status_final;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

proc sort data=linelist7; by cluster zip;run;

/* Set title and footnote statements */
title1 'Individuals not included in cluster by residential address at time of report who have another home or work address in the cluster';
title2;
footnote1 ;
footnote2 ;
/* Output list of new addresses to word document */
proc report  data=linelist7 nowd ;
column cluster eventid  diseasestat investStat event_date  age 
	gender street1 boroshort zip censustract;
define cluster / order 'Cluster' width=1;
define diseasestat /'Disease status' width=5;
define investStat / 'Investigation status' width=4;
define eventid /'Event ID' width=8;
define event_date / 'Event date' format=mmddyy10. width=10;
define age / 'Age' width=3;
define gender / 'Sex' width=2;
define street1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;
%end;



/* This is where we list additional relevant addresses for events in the cluster */
/* Count number of new cluster addresses to print in output */
%let rev_cluster_add=%sysfunc(open(New_unique_secondary_addrs));
%let num_rev_cluster_add=%sysfunc(attrn(&rev_cluster_add,nobs));
%let end=%sysfunc(close(&rev_cluster_add));

/* If any additional relevant addresses to be output then run */
%if &num_rev_cluster_add>0 %then %do;


/* Format for output */
data New_unique_secondary_addrs2; 
	set New_unique_secondary_addrs;
	attrib eventID length = $15.;
	eventID=event_ID;
	drop event_id;
	attrib Type length=$20.;
	Type=type_disp;
	drop type_disp;
	attrib boroShort length=$7.;
	if boro = "BROOKLYN" then boroshort = "BK";
	if boro = "QUEENS" then boroshort = "QN";
	if boro = "STATEN ISLAND" then boroshort = "SI";
	if boro = "BRONX" then boroshort = "BX";
	if boro = "MANHATTAN" then boroshort = "MN";
	if boro = "NYC BOROUGH UNKNOWN" then boroshort = "NYC UNK";
	if boro = "UNKNOWN" then boroshort = "UNK";
	if gender='FEMALE' then gender ='F';
	if gender='MALE' then gender='M';
	if gender='TRANSGENDER' then gender='T';
	if gender='UNKNOWN' then gender='U';
	drop boro;
run;

/* Set title and footnote statements */
title1 'Individuals included in cluster by residential address at time of report who also have another home or work address in the cluster area';
title2;
footnote1 ;
footnote2 ;
/* Output list of additional relevant addresses to word document */
proc report  data=New_unique_secondary_addrs2 nowd ;
column cluster eventid type street_1 boroshort zip censustract;
define cluster / order 'Cluster' width=1;
define eventid /'Event ID' width=8;
define type / 'Address type' width=8;
define street_1 /'Address' width=10;
define boroshort /'Boro'  width=10;
define zip /'Zip' width=5;
define censustract / 'Census tract' width=13;
compute cluster; 
	if cluster=1 
	then call define (_ROW_, "style", "STYLE = [background=CXFC8D59]");
	if cluster=2
	then call define (_ROW_, "style", "STYLE = [background=CXd6ad4b]");
	if cluster=3
	then call define (_ROW_, "style", "STYLE = [background=CXfee08b]");
	if cluster=4
	then call define (_ROW_, "style", "STYLE = [background=CXfdfd65]");
	if cluster=5
	then call define (_ROW_, "style", "STYLE = [background=CXffffbf]");
	if cluster=6
	then call define (_ROW_, "style", "STYLE = [background=CXe6f598]");
	if cluster=7
	then call define (_ROW_, "style", "STYLE = [background=CXb7f291]");
	if cluster=8
	then call define (_ROW_, "style", "STYLE = [background=CX99d594]");
	if cluster=9
	then call define (_ROW_, "style", "STYLE = [background=CX51d06d]");
	if cluster=10
	then call define (_ROW_, "style", "STYLE = [background=CX4b9cd8]");
endcomp;
run;
%end;

/* Close word document */
ods rtf close;
ods listing;

%mend PersonLineList_mPCR;




/******** Remaining macros only apply if outputting google earth file ********/

%Macro TractParamLatLong;
"[Input]"
/";												case data filename"
/"CaseFile=&INPUT.casefile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt"
/";												control data filename"
/"ControlFile="
/";												time precision (0=None, 1=Year, 2=Month, 3=Day, 4=Generic)"
/"PrecisionCaseTimes=3"
/";												study period start date (YYYY/MM/DD)"
/"StartDate="startdt
/";												study period end date (YYYY/MM/DD)"
/"EndDate="EndDt
/";												population data filename"
/"PopulationFile="
/";												coordinate data filename"
/"CoordinatesFile=&INPUT.coordfile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt"
/";												use grid file? (y/n)"
/"UseGridFile=n"
/";												grid data filename"
/"GridFile="
/";												coordinate type (0=Cartesian, 1=latitude/longitude)"
/"CoordinatesType=1"

//"[Analysis]"
/";												analysis type ( 1=Purely Spatial, 2=Purely Temporal,"
/";																3=Retrospective Space-Time, 4=Prospective Space-Time,"
/";																5=Spatial Variation in Temporal Trends, 6=Prospective Purely Temporal)"
/"AnalysisType=4"
/";												model type (0=Discrete Poisson, 1=Bernoulli, 2=Space-Time Permutation,"
/";															3=Ordinal, 4=Exponential, 5=Normal, 6=Continuous Poisson, 7=Multinomial)"
/"ModelType=2"
/";												scan areas (1=High Rates(Poison,Bernoulli,STP); High Values(Ordinal,Normal);"
/";															Short Survival(Exponential), 2=Low Rates(Poison,Bernoulli,STP);"
/";															Low Values(Ordinal,Normal); Long Survival(Exponential), 3=Both Areas)"
/"ScanAreas=1"
/";												time aggregation units (0=None, 1=Year, 2=Month, 3=Day, 4=Generic)"
/"TimeAggregationUnits=3"
/";												time aggregation length (Positive Integer)"
/"TimeAggregationLength=&&TIMEAGG&i"

//"[Output]"
/";analysis main results output filename"
/"ResultsFile=" OUTFILENAME2
/";												output Google Earth KML file (y/n)"
/"OutputGoogleEarthKML=n"
/";												output shapefiles (y/n)"
/"OutputShapefiles=n"
/";												output cluster information in ASCII format? (y/n)"
/"MostLikelyClusterEachCentroidASCII=y"
/";												output cluster information in dBase format? (y/n)"
/"MostLikelyClusterEachCentroidDBase=y"
/";												output location information in ASCII format? (y/n)"
/"CensusAreasReportedClustersASCII=y"
/";												output location information in dBase format? (y/n)"
/"CensusAreasReportedClustersDBase=y"
/";												output risk estimates in ASCII format? (y/n)"
/"IncludeRelativeRisksCensusAreasASCII=y"
/";												output risk estimates in dBase format? (y/n)"
/"IncludeRelativeRisksCensusAreasDBase=y"
/";												output simulated log likelihoods ratios in ASCII format? (y/n)"
/"SaveSimLLRsASCII=n"
/";												output simulated log likelihoods ratios in dBase format? (y/n)"
/"SaveSimLLRsDBase=n"

//"[Multiple Data Sets]"
/"; 											multiple data sets purpose type (0=Multivariate, 1=Adjustment)"
/"MultipleDataSetsPurposeType=0"

//"[Data Checking]"
/";												study period data check (0=Strict Bounds, 1=Relaxed Bounds)"
/"StudyPeriodCheckType=0"
/";												geographical coordinates data check (0=Strict Coordinates, 1=Relaxed Coordinates)"
/"GeographicalCoordinatesCheckType=0"

//"[Spatial Neighbors]"
/";												use neighbors file (y/n)"
/"UseNeighborsFile=n"
/";												neighbors file"
/"NeighborsFilename="
/";												use meta locations file (y/n)"
/"UseMetaLocationsFile=n"
/";												meta locations file"
/"MetaLocationsFilename="
/";												multiple coordinates type (0=OnePerLocation, 1=AtLeastOneLocation, 2=AllLocations)"
/"MultipleCoordinatesType=0"

//"[Spatial Window]"
/";												maximum spatial size in population at risk (<=50%)"
/"MaxSpatialSizeInPopulationAtRisk=&&MAXGEOG&i"
/";												restrict maximum spatial size - max circle file? (y/n)"
/"UseMaxCirclePopulationFileOption=n"
/";												maximum spatial size in max circle population file (<=50%)"
/"MaxSpatialSizeInMaxCirclePopulationFile=&&MAXGEOG&i"
/";												maximum circle size filename"
/"MaxCirclePopulationFile="
/";												restrict maximum spatial size - distance? (y/n)"
/"UseDistanceFromCenterOption=&&RESTRICTSPATIAL&i"
/";												maximum spatial size in distance from center (positive integer)"
/"MaxSpatialSizeInDistanceFromCenter=&&MAXSPATIAL&i"
/";												include purely temporal clusters? (y/n)"
/"IncludePurelyTemporal=n"
/";												window shape (0=Circular, 1=Elliptic)"
/"SpatialWindowShapeType=0"
/";												elliptic non-compactness penalty (0=NoPenalty, 1=MediumPenalty, 2=StrongPenalty)"
/"NonCompactnessPenalty=1"
/";												isotonic scan (0=Standard, 1=Monotone)"
/"IsotonicScan=0"

//"[Temporal Window]"
/";												minimum temporal cluster size (in time aggregation units)"
/"MinimumTemporalClusterSize=&&MINTEMP&i"
/";												how max temporal size should be interpretted (0=Percentage, 1=Time)"
/"MaxTemporalSizeInterpretation=1"
/";												maximum temporal cluster size (<=90%)"
/"MaxTemporalSize=&&MAXTEMP&i"
/";												include purely spatial clusters? (y/n)"
/"IncludePurelySpatial=n"
/";												temporal clusters evaluated (0=All, 1=Alive, 2=Flexible Window)"
/"IncludeClusters=1"
/";												flexible temporal window start range (YYYY/MM/DD,YYYY/MM/DD)"
/"IntervalStartRange=2000/1/1,2000/12/31"
/";												flexible temporal window end range (YYYY/MM/DD,YYYY/MM/DD)"
/"IntervalEndRange=2000/1/1,2000/12/31"

//"[Space and Time Adjustments]"
/";												time trend adjustment type (0=None, 1=Nonparametric, 2=LogLinearPercentage,"
/";																			3=CalculatedLogLinearPercentage, 4=TimeStratifiedRandomization,"
/";																			5=CalculatedQuadraticPercentage)"
/"TimeTrendAdjustmentType=0"
/";												time trend adjustment percentage (>-100)"
/"TimeTrendPercentage=0"
/";												time trend type - SVTT only (Linear=0, Quadratic=1)"
/"TimeTrendType=0"
/";												adjust for weekly trends, nonparametric"
/"AdjustForWeeklyTrends=&&WEEKLYTRENDS&i"
/";												spatial adjustments type (0=No Spatial Adjustment, 1=Spatially Stratified Randomization)"
/"SpatialAdjustmentType=0"
/";												use adjustments by known relative risks file? (y/n)"
/"UseAdjustmentsByRRFile=n"
/";												adjustments by known relative risks file name (with HA Randomization=1)"
/"AdjustmentsByKnownRelativeRisksFilename="

//"[Inference]"
/";												p-value reporting type (Default p-value=0, Standard Monte Carlo=1, Early Termination=2,"
/";																		Gumbel p-value=3)"
/"PValueReportType=0"
/";												early termination threshold"
/"EarlyTerminationThreshold=50"
/";												report Gumbel p-values (y/n)"
/"ReportGumbel=n"
/";												Monte Carlo replications (0, 9, 999, n999)"
/"MonteCarloReps=0"
/";												adjust for earlier analyses(prospective analyses only)? (y/n)"
/"AdjustForEarlierAnalyses=n"
/";												prospective surveillance start date (YYYY/MM/DD)"
/"ProspectiveStartDate=1900/1/1"
/";												perform iterative scans? (y/n)"
/"IterativeScan=n"
/";												maximum iterations for iterative scan (0-32000)"
/"IterativeScanMaxIterations=0"
/";												max p-value for iterative scan before cutoff (0.000-1.000)"
/"IterativeScanMaxPValue=0.00"

//"[Border Analysis]"
/";												calculate Oliveira's F"
/"CalculateOliveira=n"
/";												number of bootstrap replications for Oliveira calculation (minimum=100, multiple of 100)"
/"NumBootstrapReplications=1000"
/";												p-value cutoff for cluster's in Oliveira calculation (0.000-1.000)"
/"OliveiraPvalueCutoff=0.05"

//"[Power Evaluation]"
/";												perform power evaluation - Poisson only (y/n)"
/"PerformPowerEvaluation=n"
/";												power evaluation method (0=Analysis And Power Evaluation Together,"
/";																		 1=Only Power Evaluation With Case File,"
/";																		 2=Only Power Evaluation With Defined Total Cases)"
/"PowerEvaluationsMethod=0"
/";												total cases in power evaluation"
/"PowerEvaluationTotalCases=600"
/";												critical value type (0=Monte Carlo, 1=Gumbel, 2=User Specified Values)"
/"CriticalValueType=0"
/";												power evaluation critical value .05 (> 0)"
/"CriticalValue05=0"
/";												power evaluation critical value .001 (> 0)"
/"CriticalValue01=0"
/";												power evaluation critical value .001 (> 0)"
/"CriticalValue001=0"
/";												power estimation type (0=Monte Carlo, 1=Gumbel)"
/"PowerEstimationType=0"
/";												number of replications in power step"
/"NumberPowerReplications=1000"
/";												power evaluation alternative hypothesis filename"
/"AlternativeHypothesisFilename="
/";												power evaluation simulation method for power step (	0=Null Randomization, 1=N/A,"
/";																									2=File Import)"
/"PowerEvaluationsSimulationMethod=0"
/";												power evaluation simulation data source filename"
/"PowerEvaluationsSimulationSourceFilename="
/";												report power evaluation randomization data from power step (y/n)"
/"ReportPowerEvaluationSimulationData=n"
/";												power evaluation simulation data output filename"
/"PowerEvaluationsSimulationOutputFilename="

//"[Spatial Output]"
/";												automatically launch Google Earth - gui only (y/n)"
/"LaunchKMLViewer=y"
/";												create compressed KMZ file instead of KML file (y/n)"
/"CompressKMLtoKMZ=n"
/";												whether to include cluster locations kml output (y/n)"
/"IncludeClusterLocationsKML=y"
/";												threshold for generating separate kml files for cluster locations (positive integer)"
/"ThresholdLocationsSeparateKML=1000"
/";												report hierarchical clusters (y/n)"
/"ReportHierarchicalClusters=y"
/";												criteria for reporting secondary clusters(0=NoGeoOverlap, 1=NoCentersInOther,"
/";														2=NoCentersInMostLikely,  3=NoCentersInLessLikely, 4=NoPairsCentersEachOther,"
/";														5=NoRestrictions)"
/"CriteriaForReportingSecondaryClusters=1"
/";												report gini clusters (y/n)"
/"ReportGiniClusters=n"
/";												gini index cluster reporting type (0=optimal index only, 1=all values)"
/"GiniIndexClusterReportingType=0"
/";												spatial window maxima stops (comma separated decimal values[<=50%] )"
/"SpatialMaxima=1,2,3,4,5,6,8,10,12,15,20,25,30,40,50"
/";												max p-value for clusters used in calculation of index based coefficients (0.000-1.000)"
/"GiniIndexClustersPValueCutOff=0.05"
/";												report gini index coefficents to results file (y/n)"
/"ReportGiniIndexCoefficents=n"
/";												restrict reported clusters to maximum geographical cluster size? (y/n)"
/"UseReportOnlySmallerClusters=n"
/";												maximum reported spatial size in population at risk (<=50%)"
/"MaxSpatialSizeInPopulationAtRisk_Reported=50"
/";												restrict maximum reported spatial size - max circle file? (y/n)"
/"UseMaxCirclePopulationFileOption_Reported=n"
/";												maximum reported spatial size in max circle population file (<=50%)"
/"MaxSizeInMaxCirclePopulationFile_Reported=50"
/";												restrict maximum reported spatial size - distance? (y/n)"
/"UseDistanceFromCenterOption_Reported=n"
/";												maximum reported spatial size in distance from center (positive integer)"
/"MaxSpatialSizeInDistanceFromCenter_Reported=1"

//"[Temporal Output]"
/";												output temporal graph HTML file (y/n)"
/"OutputTemporalGraphHTML=y"
/";												temporal graph cluster reporting type (0=Only most likely cluster,"
/";																					   1=X most likely clusters, 2=Only significant clusters)"
/"TemporalGraphReportType=2"
/";												number of most likely clusters to report in temporal graph (positive integer)"
/"TemporalGraphMostMLC=1"
/";												significant clusters p-value cutoff to report in temporal graph (0.000-1.000)"
/"TemporalGraphSignificanceCutoff=0.01"

//"[Other Output]"
/";												report critical values for .01 and .05? (y/n)"
/"CriticalValue=n"
/";												report cluster rank (y/n)"
/"ReportClusterRank=n"
/";												print ascii headers in output files (y/n)"
/"PrintAsciiColumnHeaders=n"
/";												user-defined title for results file"
/"ResultsTitle="

//"[Elliptic Scan]"
/";												elliptic shapes - one value for each ellipse (comma separated decimal values)"
/"EllipseShapes="
/";												elliptic angles - one value for each ellipse (comma separated integer values)"
/"EllipseAngles="

//"[Power Simulations]"
/";												simulation methods (0=Null Randomization, 1=N/A, 2=File Import)"
/"SimulatedDataMethodType=0"
/";												simulation data input file name (with File Import=2)"
/"SimulatedDataInputFilename="
/";												print simulation data to file? (y/n)"
/"PrintSimulatedDataToFile=n"
/";												simulation data output filename"
/"SimulatedDataOutputFilename="

//"[Run Options]"
/";												number of parallel processes to execute (0=All Processors, x=At Most X Processors)"
/"NumberParallelProcesses=0"
/";												suppressing warnings? (y/n)"
/"SuppressWarnings=n"
/";												log analysis run to history file? (y/n)"
/"LogRunToHistoryFile=y"
/";												analysis execution method  (0=Automatic, 1=Successively, 2=Centrically)"
/"ExecutionType=0"
%Mend TractParamLatLong;


%macro callSatscanLatLong;
%macro dummy; %mend dummy;

/* Run SaTScan batch file */
x "&SATSCAN.SpatialLatLong.bat"; Run; 

/* read in the SaTScan output */

/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OUTCOLLatLong
            DATAFILE= "&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today.LatLong.col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

/* GIS file: One row per census tract with following fields */
/*	Census tract, cluster number, p-value, recurrence interval, observed cases */
/* 	in cluster, expected cases in cluster, observed/expected ratio in cluster, */
/*	observed cases in census tract, expected cases in census tract, */
/*	observed/expected ratio in census tract */ 
PROC IMPORT OUT= WORK.OUTGISLatLong
            DATAFILE= "&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today.LatLong.gis.dbf" 
            DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;
%mend callSatscanLatLong;

%macro GoogleEarth;
%macro dummy; %mend dummy;

%if &disease_code="LEG" %then %do;
/* Pull from cooling tower registry (Env) */
	PROC IMPORT OUT= WORK.coolingtowers
	            DATATABLE= "Buildings_Inspectable" 
	            DBMS=ACCESS REPLACE;
	     DATABASE="XXXXXXXXXXXXXXXXXXXXXXXXX.accdb"; 
	     SCANMEMO=YES;
	     USEDATE=NO;
	     SCANTIME=YES;
	RUN;

/* Format for mapping in google earth */
	data coolingtowers_GEmap
		(keep = bin businessname activesystems address latitude longitude inspectiondate inspectionduedate feature feature_name);
	set coolingtowers;
		inspectiondate=datepart(LastBldgVisit);
		format inspectiondate mmddyy10.;
		inspectionduedate=datepart(NextInspectionDue);
		format inspectionduedate mmddyy10.;
		format bin_char $8.;
		bin_char=strip(put(bin,best12.));
		bin_char=tranwrd(bin_char,"000000","XXXXXX");
		drop bin;
		rename bin_char=bin;
		if businessname=" " then businessname="UNKNOWN";
		businessname=tranwrd(businessname,"&","AND");
		address=tranwrd(address,"&","AND");
		format feature $50.;
		format feature_name $50.;
		if SystemsNeverInspected=0 then do;
			feature="CoolingTowerInspected";
			feature_name="Ever Inspected";
		end;
		if YearlyInspectionPct=0 or &todaynum-datepart(NextInspectionDue)>-30 then do;
			feature="CoolingTowerInspectionDue";
			feature_name="New Inspection Due";
		end;
		if SystemsNeverInspected=1 then do;
			feature="CoolingTowerNotInspected";
			feature_name="Never Inspected";
		end;
		if 0<YearlyInspectionPct<100 then do;
			feature="CoolingTowerOngoing";
			feature_name="Inspection Ongoing";
		end;
	run;

	proc sql;
	select put(max(inspectiondate),mmddyy10.) into :latest_inspection
	from coolingtowers_GEmap;
	quit;

	data coolingtowers_GEmap2;
	set coolingtowers_GEmap;

	/* deleting invalids to prevent strange mapping*/
		if LATITUDE in (-999, 0) or LATITUDE=. then Delete;
	/* Format text for cooling tower bubbles */
		format MAP_FORMAT $50. KML_TEXT $500. ;
		MAP_FORMAT="#"||feature;
		KML_TEXT=catx(" ",
			"<Placemark><name>BIN: ",BIN,"</name><styleUrl>",MAP_FORMAT,"</styleUrl><description>",
			"Business: ",strip(businessname),
			", Address: ",strip(address),
			", # of Cooling Towers: ",activesystems,
			", Inspection Status: ",feature_name,
			", Last Building Visit: ",put(inspectiondate,mmddyy10.),
			", Next Inspection Due: ",put(inspectionduedate,mmddyy10.),
			"</description><Point><coordinates>",LONGITUDE,",",LATITUDE,",100</coordinates></Point></Placemark>");
	run;

	proc sort data=coolingtowers_GEmap2;
		by feature_name;
	run;
	/* Make folder tags for cooling tower layer */
	data coolingtowers_GEmap3;
	set coolingtowers_GEmap2;
		by feature_name;
		format XML $20000.;
		if first.feature_name then CT_OPEN=cats("<Folder><name>",strip(feature_name),"</name><visibility>0</visibility>");
		if last.feature_name then CT_CLOSE="</Folder>";
		format XML $20000.;
		XML=cats(CT_OPEN, KML_TEXT, CT_CLOSE);
		keep XML;
	run;
%end;

	/* Format linelist data for mapping in google earth */
	proc sql;
	create table linelist_GEmap as
		select distinct event_id,
					disease_code,
					disease_status_final,
					event_date,
 					event_date as map_event_date format yymmdd10.,
					&todaynum-&&lagtime&i as map_event_end_date format yymmdd10.,
					age,
 					street_1,
					street_2,
					city,
					state,
					zip,
					boro,
					type,
					lat as latitude,
					long as longitude,
					case
						when type in("Other Home","Other Work") then "Other"
						else type
					end as type
		from events
		where disease_code = "&&disease_code&i" & event_date >= &simactive & event_date <= &simend
			and disease_status_final in('CONFIRMED', 'PROBABLE', 'SUSPECT', 'PENDING')
	%if "&&agegroup&i" = "Under5" %then %do;
		and age < 5 and age ~= .
	%end;
	%if "&&agegroup&i" = "5to18" %then %do;
		and age >= 5 and age <= 18
	%end;
	%if "&&agegroup&i" = "Under18" %then %do;
		and age < 18 and age ~= .
	%end;
		order by disease_status_final, event_id;
	quit;

	data linelist_GEmap2;
	set linelist_GEmap;
		by disease_status_final event_id;

	/*flagging invalids to prevent strange mapping*/
		if LATITUDE in (-999, 0)  or LATITUDE=. then Delete;
	/* Format text for event bubbles */
		format MAP_FORMAT $50. KML_TEXT $500. ;
			MAP_FORMAT="#"||propcase(strip(disease_status_final))||propcase(compress(type));
			KML_TEXT=catx(" ",
			"<Placemark><name>Event: ",event_id,"</name><styleUrl>",MAP_FORMAT,"</styleUrl><description>",
			"Age: ",age,
			", Status: ",propcase(strip(disease_status_final)),
			", Event Date: ",put(event_date,mmddyy10.),
			", Address Type: ",type,
			"</description><Point><coordinates>",LONGITUDE,",",LATITUDE,",500</coordinates></Point><TimeSpan>",
			"<begin>",put(map_event_date,yymmdd10.),"</begin>",
			"<end>",put(map_event_end_date,yymmdd10.),"</end>",
			"</TimeSpan> </Placemark>");

		keep event_id disease_status_final event_date map_event_date
			map_event_end_date street_1 street_2 city state zip
			type MAP_FORMAT kml_text latitude longitude;
	run;

	proc sort data=linelist_GEmap2;
		by disease_status_final map_event_date;
	run;
	/* Make folder tags for event layer */
	data linelist_GEmap3;
	set linelist_GEmap2;
		by disease_status_final map_event_date;

		if first.disease_status_final then STATUS_OPEN=cats("<Folder><name>",propcase(disease_status_final),"</name>");
		if last.disease_status_final then STATUS_CLOSE="</Folder>";

		format XML $20000.;
		XML=cats(STATUS_OPEN, KML_TEXT, STATUS_CLOSE);
		keep XML;
	run;

/* To add visualization of cluster extent use radius and center (lat/long) from SaTScan output */
/*	and scale using kml_circle_tessellation dataset */
	proc sql;
	create table tessellation_points as
	select 	a.START_DATE,
			a.END_DATE,
			a.OBSERVED,
			a.EXPECTED,
			a.ODE,
			case
				when aa.RECURR_INT>365 then aa.RECURR_INT/365.25
				else aa.RECURR_INT
			end as RECURR_INT format 12.1,
			case
				when aa.RECURR_INT>365 then "years"
				else "days"
			end as RECURR_INT_UNITS,
			a.LATITUDE,
			a.LONGITUDE,
			a.RADIUS,
			b.*
		from OutColLatLong a left join outcol aa on a.cluster=aa.cluster
			left join support.BCD003_Kml_circle_tessellation b on a.cluster=b.cluster
		where a.cluster=1;
	quit;

/* Outputs 360 points of tessellated circle, centered and scaled to approximate cluster area */
	%macro adj_lat_long;
	%macro dummy; %mend dummy;
		data perimeter_lat_long;
		set tessellation_points;
		%do j=1 %to 361;
			format lat_adj&j long_adj&j $10.;
			lat_adj&j=put((latitude+(lat&j*radius)),10.4);
			long_adj&j=put((longitude+(long&j*radius)),10.4);
		%end;
		run;
	/* Make perimeter style tag */
		data perimeter_style_xml (keep = xml);
		format xml $20000. ;
			xml=catx(' ',
			'<Style id="cluster-1-style"><IconStyle><Icon></Icon></IconStyle><LabelStyle><scale>0</scale></LabelStyle><LineStyle><color>ff0000aa</color></LineStyle><PolyStyle><color>400000aa</color></PolyStyle><BalloonStyle><text><![CDATA[<b>$[snippet]</b><br/><table border="0"><tr><th style="text-align:left;white-space:nowrap;padding-right:5px;">Time frame</th><td style="white-space:nowrap;">$[Time frame]</td></tr><tr><th style="text-align:left;white-space:nowrap;padding-right:5px;">Number of cases</th><td style="white-space:nowrap;">$[Number of cases]</td></tr><tr><th style="text-align:left;white-space:nowrap;padding-right:5px;">Expected cases</th><td style="white-space:nowrap;">$[Expected cases]</td></tr><tr><th style="text-align:left;white-space:nowrap;padding-right:5px;">Observed / expected</th><td style="white-space:nowrap;">$[Observed / expected]</td></tr><tr><th style="text-align:left;white-space:nowrap;padding-right:5px;">Recurrence interval</th><td style="white-space:nowrap;">$[Recurrence interval]</td></tr></table>]]></text></BalloonStyle></Style>',
			'<StyleMap id="cluster-1-stylemap"><Pair><key>normal</key><styleUrl>#cluster-1-style</styleUrl></Pair><Pair><key>highlight</key><styleUrl>#cluster-1-style</styleUrl></Pair></StyleMap>'
			);
		run;
	/* Start perimeter tag */
		data perimeter_start_xml (keep = xml);
		set perimeter_lat_long;
		format xml $20000. ;
		xml=catx(' ',
				'<Placemark>',
				'<name>Cluster #1</name>',
				'<snippet>SaTScan Cluster #1</snippet>',
				'<visibility>1</visibility>',
				'<TimeSpan><begin>',start_date,'T00:00:00Z</begin><end>',end_date,'T23:59:59Z</end></TimeSpan>',
				'<styleUrl>#cluster-1-stylemap</styleUrl>',
				'<ExtendedData><Data name="Time frame"><value>',start_date,' to ',end_date,'</value></Data><Data name="Number of cases"><value>',observed,'</value></Data><Data name="Expected cases"><value>',expected,'</value></Data><Data name="Observed / expected"><value>',ode,'</value></Data><Data name="Recurrence interval"><value>',recurr_int,' ',recurr_int_units,'</value></Data></ExtendedData>'
				);
		run;
	/* Start multigeometry tag and fill in with scaled tessellation points */
		data perimeter_coordinates1_xml (keep = xml);
		set perimeter_lat_long;
			format xml $20000. ;
			xml=catx(' ',
			'<MultiGeometry>',
			'<Polygon><outerBoundaryIs><LinearRing><extrude>1</extrude><tessellate>1</tessellate><coordinates>',
			%do j=1 %to 180;
				long_adj&j,',',lat_adj&j,',500 ',
			%end;
			' ');
			xml=tranwrd(xml," , ",",");
			xml=tranwrd(xml," ,",",");
			run;

	/* Add second half of scaled tessellation points and end multigeometry tag */
			data perimeter_coordinates2_xml (keep = xml);
			set perimeter_lat_long;
				format xml $20000. ;
				xml=catx(' ',
				%do j=181 %to 361;
					long_adj&j,',',lat_adj&j,',500 ',
				%end;
				'</coordinates></LinearRing></outerBoundaryIs></Polygon>',
				'<Point><extrude>1</extrude><altitudeMode>relativeToGround</altitudeMode><coordinates>',long_adj1,',',lat_adj1,',0</coordinates></Point>',
				'</MultiGeometry>'
				);
				xml=tranwrd(xml," , ",",");
				xml=tranwrd(xml," ,",",");
			run;
	/* End perimeter tag */
			data perimeter_end_xml (keep = xml);
				format xml $20000. ;
				xml='</Placemark>';
			run;

	%mend adj_lat_long;

	%adj_lat_long



/* Make XML header */
	data xml_header;
		format xml $20000.;
		xml = '<?xml version="1.0" encoding="UTF-8"?>
			<kml xmlns="http://www.opengis.net/kml/2.2">
			<Document>';
	run;

/* Make legend layer for LEG (case and cooling tower status) using screen overlay tool */
	/* Change filepath to point to image file of legend */
%if &disease_code="LEG" %then %do; 
	data xml_legend;
		format xml $20000.;
		xml="<ScreenOverlay>
			<name>Legend: Case Status</name>
			<Icon> <href>file:///&SUPPORTMAP.BCD003_CaseandCTStatus_legend.png</href>
			</Icon>
			<overlayXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<screenXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<rotationXY x='0' y='0' xunits='fraction' yunits='fraction'/>
        	<size x='0' y='0' xunits='fraction' yunits='fraction'/>
			</ScreenOverlay>";
	run;
%end;
/* Make legend layer for non-LEG (case status only) using screen overlay tool */
	/* Change filepath to point to image file of legend */
%if &disease_code^="LEG" %then %do;
	data xml_legend;
		format xml $20000.;
		xml="<ScreenOverlay>
			<name>Legend: Case Status</name>
			<Icon> <href>file:///&SUPPORTMAP.BCD003_CaseStatus_legend.png</href>
			</Icon>
			<overlayXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<screenXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<rotationXY x='0' y='0' xunits='fraction' yunits='fraction'/>
        	<size x='0' y='0' xunits='fraction' yunits='fraction'/>
			</ScreenOverlay>";
	run;
%end;

/* Set display shape and color for LEG cases */
	%if &disease_code="LEG" %then %do;
	data new_folder_header;
		format xml $20000.;
		xml = "<Folder>
		<name>Citywide Cases</name>   
  			<Style id='ConfirmedHome'>
  			    <IconStyle>
					<color>ff0000E7</color>
					<colorMode>normal</colorMode>
					<scale>0.8</scale>
				<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
				</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
			</Style> 
   			<Style id='SuspectHome'>
      			<IconStyle>
        			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingHome'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ConfirmedWork'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>  
   			<Style id='SuspectWork'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingWork'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ConfirmedOther'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style> 
   			<Style id='SuspectOther'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingOther'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
 			";
		run;
	%end;

/* Set display shape and color for non-LEG cases */
	%if &disease_code^="LEG" %then %do;
	data new_folder_header;
		format xml $20000.;
		xml = "<Folder>
		<name>Citywide Cases</name>   
  			<Style id='ConfirmedHome'>
  			    <IconStyle>
					<color>ff0000E7</color>
					<colorMode>normal</colorMode>
					<scale>0.8</scale>
				<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
				</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
				</Style>
  			<Style id='ProbableHome'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>  
   			<Style id='SuspectHome'>
      			<IconStyle>
        			<color>ff42E4F0</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingHome'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ConfirmedWork'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ProbableWork'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>  
   			<Style id='SuspectWork'>
      			<IconStyle>
         			<color>ff42E4F0</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingWork'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ConfirmedOther'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='ProbableOther'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>  
   			<Style id='SuspectOther'>
      			<IconStyle>
         			<color>ff42E4F0</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='PendingOther'>
      			<IconStyle>
         			<color>ff000000</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
 			";
		run;
	%end;

/* If LEG then set display shape and color for cooling towers */
	%if &disease_code="LEG" %then %do;
	data ct_folder_header;
		format xml $20000.;
		xml = "<Folder>
		<name>Cooling Towers</name>
		<visibility>0</visibility>
	      <Style id='CoolingTowerInspected'>
		      <IconStyle>
		         <color>ff739E00</color>
	    	     <colorMode>normal</colorMode>
				 <scale>0.45</scale>
	        	<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
      		<Style id='CoolingTowerInspectionDue'>
      			<IconStyle>
         			<color>ffE9B456</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.45</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
  			 </Style>
   			<Style id='CoolingTowerNotInspected'>
      			<IconStyle>
         			<color>ffA779CC</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.45</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
  	 		</Style>
   			<Style id='CoolingTowerOngoing'>
      			<IconStyle>
	     			<color>ffB27200</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.45</scale>
         		<Icon>
            		<href>file:///&SUPPORTMAP.BCD003_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   		";
	run;
	%end;

/* Make folder close tag */
	data xml_folder_close;
		format xml $20000.;
		xml = '</Folder>';
	run;

/* Make XML close tag */
	data xml_document_kml_close;
		format xml $20000.;
		xml = '</Document></kml>';
	run;

/* Put together all XML elements in valid KML order. Only include cooling tower layer if a LEG cluster */
	data KML;
	set xml_header
		xml_legend
		perimeter_style_xml perimeter_start_xml perimeter_coordinates1_xml perimeter_coordinates2_xml perimeter_end_xml
		new_folder_header linelist_GEmap3 xml_folder_close
	%if &disease_code="LEG" %then %do;
		ct_folder_header coolingtowers_GEmap3 xml_folder_close
	%end;
	xml_document_kml_close;
run;

/* Export as KML file */
data _null_;
   set KML;
   file "&ARCHIVETODAY.satscan94_&&Disease_Code&i.._&&agegroup&i.._&&maxTemp&i.._&today..KML" lrecl=15000;
   put xml;
run;

%mend GoogleEarth;
