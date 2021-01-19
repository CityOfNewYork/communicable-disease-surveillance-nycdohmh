/* Set up the data for the person linelist with this macro */

%macro personlinelist_setup;
%macro dummy; %mend dummy;

/* select individuals in a significant census tract, merge cluster info by censustract and cluster */
proc sql; 
	create table cases2 as 
	select distinct s.*,
					og.cluster,
					ch.Clusterstartdate,
					ch.clusterenddate
	from cases as s
		,outgis3 as og
		,clusterhistory as ch
	where og.loc_id = s.censustract
	 and (ch.recurr_int>=&&recurrence&i or ch.cluster=1)
		and og.cluster=ch.cluster;
quit;

proc sort data=cases2 out=ClusterToCensus;
	by event_id cluster;
run;

/* If address in more than one cluster, retain affiliation with associated cluster most likely to be true */
data linelist1; 
	set clustertocensus;
	by event_id;
	if first.event_id=1;
run;

/* Exclude events with event date outside the cluster window */
data linelist2; 
	set linelist1;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	if event_date >= ClusterStartDate;
	if event_date <= ClusterEndDate;
	runDate=&todaynum; format rundate mmddyy10.;
	MaxTemp=&&maxtemp&i;
	mintemp=&&mintemp&i;
	format agegroup $7.;
	agegroup="&&agegroup&i";
	format analysis $25.;
	analysis="&&analysis&i";
	format analysis_print $32.;
	analysis_print="&&analysis_print&i";
	rr_threshold=&&rr_threshold&i;
run;

/* Merge to compare current events with events already in historical satscan linelist */
proc sort data=linelist2;by event_id;run;
proc sql;
	create table prev_linelist as
	select distinct event_id
	from support.BCD005_satscanlinelist_covid
	where analysis_print="&&analysis_print&i.."
	order by event_id;
quit;
/* Flag events as new for linelist output */
data linelist2;
	merge linelist2 (in=a) prev_linelist (in=b);
	by event_id;
	if a;
	new_count=0;
	if a & ~b then do;
		New = "*";
		new_count=1;
	end;
	if a then output linelist2;
run;

/* Count cases by cluster */
proc sql;
	create table total_cluster_cases as
	select a.*,
			b.cluster as count_cluster
	from linelist2 a left join outgis b
		on a.censustract=b.loc_id
	order by a.event_id, b.cluster;
quit;

proc sql;
	create table total_case_counts as
	select count_cluster as cluster,
			count(*) as total_cases
	from total_cluster_cases
	group by count_cluster
	order by count_cluster;
quit;

proc sql; 
	create table LineListIndividuals as
	select distinct event_id
		,disease_code
		,agegroup
		,event_date
		,cluster
		,rundate
		,mintemp
		,maxtemp
		,analysis_print
	from linelist2
	order by event_id, rundate;
quit;

/* Keep events new to SaTScan linelist by disease and analysis parameters */
proc sql; 
	create table NewIndividuals as
	select lli.*
	from linelistIndividuals as lli
	left join support.BCD005_satscanlinelist_covid as s
	on lli.event_id=s.event_id and lli.disease_code=s.disease_code
		and lli.analysis_print=s.analysis_print
	having s.event_id ='';
quit;

/* Append new individuals to historic SaTScan Linelist */
proc sort data=NewIndividuals; by event_id disease_code analysis_print ;run;
proc append base=support.BCD005_SatScanLineList_covid data=NewIndividuals;run;
proc sort data=support.BCD005_SatScanLineList_covid out=support.BCD005_SatScanLineList_covid nodupkey;
	by event_id disease_code analysis_print;
run;

/* Count number of cases per cluster */
proc sql;
	create table case_counts as
	select distinct cluster,
					count(*) as NumCases
	from linelist2
	group by cluster
	order by cluster;
quit;

/* ID events in multiple clusters */
proc sql;
	create table cases_multiple_clusters as
	select event_id,
			count_cluster,
			count(*) as num_clusters
	from total_cluster_cases
	group by event_id
	having calculated num_clusters>1;
quit;

/* Assign secondary clusters to primary based on # of shared cases and distance between centers */
proc sql;
	create table cases_secondary_clusters as
	select distinct a.event_id,
			min(a.count_cluster, b.count_cluster) as cluster_a,
			max(a.count_cluster, b.count_cluster) as cluster_b
	from cases_multiple_clusters a, cases_multiple_clusters b
	where a.event_id=b.event_id
	group by a.event_id
	having calculated cluster_a^=calculated cluster_b
	order by a.event_id;
quit;

proc sql;
	create table counts_secondary_clusters as
	select distinct a.cluster_a,
			a.cluster_b,
			sqrt((abs(b.x-c.x)**2)+(abs(b.y-c.y)**2)) as dist_btwn_cluster_cntrs,
			count(*) as shared_cases
	from cases_secondary_clusters a left join clusterinfo b
		on a.cluster_a=b.cluster
		left join clusterinfo c
		on a.cluster_b=c.cluster
	group by a.cluster_a, a.cluster_b;
quit;

proc sql;
	create table primary_secondary_assignment as
	select distinct cluster_b as cluster,
			case
				when shared_cases=max(shared_cases) then cluster_a
			end as primary_cluster,
			dist_btwn_cluster_cntrs
	from counts_secondary_clusters
	group by cluster_b
	having calculated primary_cluster^=.
	order by cluster_b, dist_btwn_cluster_cntrs;
quit;

data primary_secondary_assignment;
	set primary_secondary_assignment;
	by cluster;
	if first.cluster=1;
run;

/* Add case count, and primary/secondary assignment to cluster history */
proc sort data=clusterhistory; by cluster; run;
data clusterhistory (drop=dist_btwn_cluster_cntrs);
	merge clusterhistory (in=a) case_counts (in=b) Primary_secondary_assignment (in=c) total_case_counts (in=d);
	by cluster;
	if a;
	if not c then primary_cluster=cluster;
run;


/* Assign secondary cluster IDs */
proc sql;
create table linelist3 as
select a.*
		,case
			when b.cluster is not null then strip(put(b.cluster,8.))
			else " "
		end as secondary_cluster
		,case
			when a.cluster^=b.cluster then strip(put(a.cluster,8.))
			else strip(put(b.primary_cluster,8.))
		end as primary_cluster
		,input(calculated primary_cluster,8.) as primary_cluster_num
from linelist2 a left join Primary_secondary_assignment b
			on a.cluster=b.cluster;
quit;

/* Format for cluster summary output */
proc sort data= linelist3; by event_id cluster; run;
data linelist4; 
	set linelist3;
	attrib eventID length = $9.;
	eventID=strip(event_ID);
	drop event_id;
	if sex='FEMALE' then sex ='F';
	else if sex='MALE' then sex='M';
	else sex='U';
	if age^=. then do;

		if age<=17 then age_0_17=1; else age_0_17=0;
		if age>=18 and age<=44 then age_18_44=1; else age_18_44=0;
		if age>=45 and age<=64 then age_45_64=1; else age_45_64=0;
		if age>=65 and age<=74 then age_65_74=1; else age_65_74=0;
		if age>=75 then age_75_plus=1; else age_75_plus=0;

	end;
	age_unknown=0; if age=. then age_unknown=1;
	
	/* Sex assigned at birth */
	sex_male=0; sex_female=0; sex_unknown=0;
	if sex="M" then sex_male=1;
	if sex="F" then sex_female=1;
	if sex^in("M","F") then sex_unknown=1;
	format column $15.;
	column="Cluster "||strip(put(cluster,8.));

	/* Race/Ethnicity */
	format race_ethnicity $25.;
	if ethnicity_final ='Hispanic/Latino' then race_ethnicity='Hispanic/ Latino';*'All Hispanic';
	else if race_final ='Black/African American' then race_ethnicity='Black/ African American';*'NH Black/AA';
	else if race_final ='White' then race_ethnicity='White';* 'NH White';
	else if race_final in ('Asian','Native Hawaiian/Pacific Islander' ) then race_ethnicity='Asian/ Pacific Islander';* 'NH Asian/PI';
	else if race_final in ('Multiracial','Native American/Alaskan Native') then race_ethnicity='Other';*'NH Other known';
	else if race_final in ('Other','Declined','Does not identify with any race','Missing/Unknown',' ') then race_ethnicity='Unknown';*'Other/Unknown';
	
	raceeth_latinx=0; if race_ethnicity="Hispanic/ Latino" then raceeth_latinx=1;
	raceeth_black=0; if race_ethnicity="Black/ African American" then raceeth_black=1;
	raceeth_white=0; if race_ethnicity="White" then raceeth_white=1;
	raceeth_asian_pi=0; if race_ethnicity="Asian/ Pacific Islander" then raceeth_asian_pi=1;
	raceeth_other=0; if race_ethnicity="Other" then raceeth_other=1;
	raceeth_unknown=0; if race_ethnicity="Unknown" then raceeth_unknown=1;

	/* Interview Status */
	format interview_status_print $25.;
	if interview_status in("Complete", "Partially Completed") then interview_status_print="Completed";
	if interview_status in(" ", "Pending", "Needs interview") then interview_status_print="Pending";
	if interview_status in("Refused", "Unable to interview patient or proxy", "Not needed") then interview_status_print="Not Interviewed";

	interview_complete=0; if interview_status_print="Completed" then interview_complete=1;
	interview_pending=0; if interview_status_print="Pending" then interview_pending=1;
	interview_notdone=0; if interview_status_print="Not Interviewed" then interview_notdone=1;

	/* Symptomatic */
	symptomatic_yes=0; if symptomatic="Yes" then symptomatic_yes=1;
	symptomatic_no=0; if symptomatic="No" then symptomatic_no=1;
	symptomatic_unk=0; if symptomatic^in("Yes","No") then symptomatic_unk=1;

run;

/* Add calculated counts and pct positivity to archived cluster history dataset */
proc sort data = clusterhistory; by disease_code analysis_print rundate cluster; run;
proc sort data = support.BCD005_clusterhistory_covid; by disease_code analysis_print rundate cluster; run;
data support.BCD005_clusterhistory_covid;
	merge support.BCD005_clusterhistory_covid (in=a) clusterhistory (in=b);
	by disease_code analysis_print rundate cluster;
	if a;
run;

%mend personlinelist_setup;
