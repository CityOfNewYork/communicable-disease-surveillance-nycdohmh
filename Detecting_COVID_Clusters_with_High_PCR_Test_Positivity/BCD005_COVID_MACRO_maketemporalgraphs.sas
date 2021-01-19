/* Generate temporal graph for each cluster for RTF output */

%macro maketemporalgraphs;
%macro dummy; %mend dummy;

proc sql noprint;
	select strip(put(max(cluster),8.))
	into :max_cluster
	from linelist4;
quit;

/* Case counts by date and census tract */
proc sql;
	create table cases_agg as
	select distinct censustract as loc_id,
					event_date,
					count(*) as cases
	from cases
	where &graphstart<=event_date<=&graphend
	group by event_date, censustract;
quit;

/* Test and positive test counts by date and census tract */
proc sql;
	create table tests_agg as
	select distinct a.study_date as event_date,
			a.loc_id,
			case
				when b.censustract is not null then count(*)
				else 0
			end as total_tests,
			case
				when b.censustract is not null then sum(case when b.status="CASE" then 1 else 0 end)
				else 0
			end as total_positive_tests
	from Study_dates_loc_ids a left join all_labs_geocoded_final b
		on a.study_date=b.event_date and a.loc_id=b.censustract
	where &graphstart<=a.study_date<=&graphend
	group by a.loc_id, a.study_date
	order by a.loc_id, a.study_date;
quit;

/* merge cluster number with census tract */
proc sql;
	create table tests_clusters as
		select a.event_date,
				a.loc_id,
				a.total_tests,
				a.total_positive_tests,
			case
				when b.cluster is not null then b.cluster
				else 99
			end as cluster
	from tests_agg a left join outgis b
		on a.loc_id=b.loc_id;
quit;

/* merge case, test, and positive test counts by date and census tract with cluster info */
/* case counts and positive test counts should match */
proc sql;
	create table cases_clusters as
	select a.*,
			case
				when b.cluster is not null then b.cluster
				else 99
			end as cluster,
			c.clusterstartdate,
			c.clusterenddate,
			case
				when b.cluster is not null and
					c.clusterstartdate<=a.event_date<=c.clusterenddate
					then b.cluster
				else 0
			end as in_cluster
	from cases_agg a
		left join outgis b on a.loc_id=b.loc_id
		left join clusterinfograph c on b.cluster=c.cluster
	order by a.loc_id, a.event_date;
quit;

proc sql noprint;
	select strip(put(row2,8.)) into :cluster_cases1-:cluster_cases&max_cluster.
	from demo_summary_counts;
quit;

%do m=1 %to &max_cluster;

%if &&cluster_cases&m.>0 %then %do;

/* Determine if census tracts/dates inside and outside cluster and calculate counts and % positivity */
proc sql;
	create table ct_counts_cluster_&m. as
	select distinct a.event_date,
					a.cluster,
					case
						when a.cluster=&m then sum(b.cases)
						else .
					end as cluster_cases_in_&m.,
					case
						when a.cluster^=&m then sum(b.cases)
						else .
					end as cluster_cases_out_&m.,
					case
						when a.cluster=&m then sum(a.total_tests)
						else .
					end as cluster_tests_in_&m.,
					case
						when a.cluster^=&m then sum(a.total_tests)
						else .
					end as cluster_tests_out_&m.,
					case
						when a.cluster=&m then sum(a.total_positive_tests)
						else .
					end as cluster_pos_tests_in_&m.,
					case
						when a.cluster^=&m then sum(a.total_positive_tests)
						else .
					end as cluster_pos_tests_out_&m.
	from tests_clusters a left join cases_clusters b
		on a.event_date=b.event_date and a.loc_id=b.loc_id and a.cluster=b.cluster
	where a.cluster=&m or (a.cluster^=&m and
			a.loc_id^in(select loc_id from tests_clusters where cluster=&m))
	group by a.event_date, a.cluster;
quit;

proc sql;
	create table ct_counts_cluster_&m. as
	select distinct a.*,
			case
				when a.cluster=&m. and b.clusterstartdate<=a.event_date<=b.clusterenddate
					then cluster_cases_in_&m.
				else .
			end as cluster_cases_indates_&m. label="Cluster cases",
			case
				when a.cluster=&m. and (a.event_date<b.clusterstartdate or a.event_date>b.clusterenddate)
					then cluster_cases_in_&m.
				else .
			end as cluster_cases_outdates_&m. label="Cases in area outside cluster dates",
			case
				when &simactive<=a.event_date<=&simend
					then "Inside"
				else "Outside"
			end as temporal_window,
			case
				when &simstart<=a.event_date<=&simend
					then "Inside"
				else "Outside"
			end as study_period
	from ct_counts_cluster_&m. a left join cases_clusters b
		on a.event_date=b.event_date and a.cluster=b.cluster;
quit;


proc sql;
	create table ct_counts_cluster_&m._graph as
	select distinct event_date,
					sum(cluster_cases_in_&m.) as cluster_cases_in_&m.,
					sum(cluster_tests_in_&m.) as cluster_tests_in_&m.,
					sum(cluster_pos_tests_in_&m.) as cluster_pos_tests_in_&m.,
					case
						when calculated cluster_pos_tests_in_&m.^in(0,.) then
							calculated cluster_pos_tests_in_&m./calculated cluster_tests_in_&m.
						when calculated cluster_pos_tests_in_&m. in(0,.) then 0
						else .
					end as cluster_pct_pos_in_&m. format percent7.1 label="Positivity inside cluster area",
					sum(cluster_cases_out_&m.) as cluster_cases_out_&m.,
					sum(cluster_tests_out_&m.) as cluster_tests_out_&m.,
					sum(cluster_pos_tests_out_&m.) as cluster_pos_tests_out_&m.,
					case
						when calculated cluster_pos_tests_out_&m.^in(0,.) then
							calculated cluster_pos_tests_out_&m./calculated cluster_tests_out_&m.
						when calculated cluster_pos_tests_out_&m. in(0,.) then 0
						else .
					end as cluster_pct_pos_out_&m. format percent7.1 label="Positivity outside cluster area",
					sum(cluster_cases_indates_&m.) as cluster_cases_indates_&m. label="Cluster cases",
					sum(cluster_cases_outdates_&m.) as cluster_cases_outdates_&m.
					%if &&analysis&i=st %then %do;
						label="Cases in area outside study period"
					%end;
					%if &&analysis&i in(stp stp_long stp_nonpar stp_spatial) %then %do;
						label="Cases in area outside temporal window"
					%end;
					,
					temporal_window,
					study_period
	from ct_counts_cluster_&m.
	group by event_date;
quit;

proc sql noprint;
	select round(1.1*max(cluster_cases_in_&m.)), sum(cluster_cases_indates_&m.)
	into :max_axis, :cases_in_cluster
	from ct_counts_cluster_&m._graph;
quit;

%if &cases_in_cluster=. %then %goto nograph;

proc sql noprint;
	select strip(compress(centroidnocc_name,"'"))
	into :nocc_name
	from clusterhistory
	where cluster=&m;
quit;

title1 "Cluster %sysfunc(strip(&m.)) - %sysfunc(strip(&nocc_name.))";

ods rtf startpage=now;
ods text="Cluster case counts and percent positivity of cases inside area of Cluster %sysfunc(strip(&m.)) centered in %sysfunc(strip(&nocc_name.)) vs. outside cluster area";

proc sgplot data=ct_counts_cluster_&m._graph;
	title "Cluster case counts and percent positivity of cases inside area of Cluster %sysfunc(strip(&m.)) centered in %sysfunc(strip(&nocc_name.)) vs. outside cluster area";
	vbar event_date / response=cluster_cases_indates_&m. fillattrs=(color="&&pattern&m..") outlineattrs=(color=black thickness=1);
	vbar event_date / response=cluster_cases_outdates_&m. fillattrs=(color=white) outlineattrs=(color=black thickness=1);
	vline event_date / response=cluster_pct_pos_in_&m. y2axis lineattrs=(color=black thickness=2) break;
	vline event_date / response=cluster_pct_pos_out_&m. y2axis lineattrs=(pattern=shortdash color=black thickness=3) break;
            xaxis integer values=("&graphstartdate"d to "&graphenddate"d by 1) label="Specimen Collection Date"
				fitpolicy=rotatethin;
			yaxis integer min=0 max=&max_axis label="Cluster cases^{unicode '00b9'x}";
			y2axis min=0 label="Percent positivity^{unicode '00b9'x}";
			keylegend / across=2 position=bottomleft location=outside title='' noborder;

footnote1 "^{unicode '00b9'x}Case counts and percent positivity for yesterday are not displayed due to data lags.";

run;
quit;

%nograph:

%end;

%end;

ods rtf close;
ods listing;

proc printto; run;

%mend maketemporalgraphs;