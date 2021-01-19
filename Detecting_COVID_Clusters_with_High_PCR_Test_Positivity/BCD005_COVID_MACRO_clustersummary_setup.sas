/* Set up data for cluster summary tables */

%macro clustersummary_setup;
%macro dummy; %mend dummy;
proc sql;
create table total_cases as
select a.*,
		b.count_cluster,
		case
			when strip(a.eventid)=strip(b.event_id) and a.cluster=b.count_cluster then 1
			else 0
		end as unique_case
from linelist4 a left join total_cluster_cases b
	on strip(a.eventid)=strip(b.event_id);
quit;

data total_cases;
set total_cases;
	if count_cluster<10 then do;
		column="Cluster  "||strip(put(count_cluster,8.));
	end;
	if count_cluster>=10 then do;
		column="Cluster "||strip(put(count_cluster,8.));
	end;
	rename cluster=unique_cluster;
	rename count_cluster=cluster;
run;

/* Loop over each cluster in output to get summary statistics */
proc sql noprint;
select strip(put(max(cluster),8.))
into :max_cluster
from linelist4;
quit;

/* This macro pulls values from proc means and concatenates into a character variable with median and range or median, range, and N */
/* var=name of field, name=short name of field, rownum=target row for value in report, symp=conditions for inclusion based on symptomatic yes or no */ 
%macro output_proc_means (data=, var=,name=,rownum=);
%macro dummy;%mend dummy;

%do m=1 %to &max_cluster;

proc means data=&data n median min max noprint;
	where &var is not missing and cluster=&m;
	var &var;
	output out=&data._&name._&m. n=n_&name. median=median_&name. min=min_&name. max=max_&name.;
run;

%if &name.=age %then %do;

data &data._text_&name._&m. (keep = column row&rownum.);
set &data._&name._&m.;
	format column $15.;
	%if &m<10 %then %do;
		column="Cluster  &m.";
	%end;
	%if &m>=10 %then %do;
		column="Cluster &m.";
	%end;
	format row&rownum. $25.;
	row&rownum.=strip(median_&name.)||" ("||strip(min_&name.)||"-"||strip(max_&name.)||")";
run;

%end;

%if &name.^=age %then %do;

data &data._text_&name._&m. (keep = column row&rownum.);
set &data._&name._&m.;
	format column $15.;
	%if &m<10 %then %do;
		column="Cluster  &m.";
	%end;
	%if &m>=10 %then %do;
		column="Cluster &m.";
	%end;
	format row&rownum. $25.;
	row&rownum.=strip(median_&name.)||" ("||strip(min_&name.)||"-"||strip(max_&name.)||") / N="||strip(n_&name.);
run;

%end;

%end;

%mend output_proc_means;

%output_proc_means (data=total_cases, var=age, name=age, rownum=7);

/* This macro calculates counts and %s for cluster summary rows */
%macro count_calc;
%macro dummy; %mend dummy;

%do m=1 %to &max_cluster;

proc sql noprint;
	select count(*)	into :ncov_cases
	from total_cases
	where cluster=&m.;
	select count(*) into :ncov_cases_sex
	from total_cases
	where cluster=&m. and sex in("M","F");
	select count(*) into :ncov_cases_age
	from total_cases
	where cluster=&m. and age is not null;
	select count(*) into :ncov_cases_raceeth
	from total_cases
	where cluster=&m. and race_ethnicity^="Unknown";
	select count(*) into :ncov_cases_symp
	from total_cases
	where cluster=&m. and symptomatic in("Yes","No");
quit;

proc sql noprint;
	create table newly_tested_&m. as
	select distinct a.*,
					b.cluster,
					c.clusterstartdate as clusterstartdate format date9.,
					c.clusterenddate as clusterenddate format date9.
	from all_labs_geocoded_final a, outgis b, clusterinfo c
	where b.cluster=&m. and
		a.censustract=b.loc_id and b.cluster=c.cluster and
		c.clusterstartdate<=a.event_date<=c.clusterenddate;
	create table newly_tested_&m. as
	select distinct cluster, clusterstartdate, clusterenddate, count(*) as newly_tested, 
		sum(positive_test)/count(*) as pct_positive format percent7.1
	from newly_tested_&m.;
	select newly_tested, pct_positive, clusterstartdate, clusterenddate
	into :newly_tested, :inside_positivity, :clusterstartdate, :clusterenddate
	from newly_tested_&m.;
quit;

proc sql noprint;
	create table pct_pos_pastweek_&m. as
	select distinct a.*,
					b.cluster,
					c.clusterstartdate as clusterstartdate format date9.,
					c.clusterenddate as clusterenddate format date9.
	from all_labs_geocoded_final a, outgis b, clusterinfo c
	where b.cluster=&m. and
		a.censustract=b.loc_id and b.cluster=c.cluster and
		(&todaynum.-&&lagtime&i-7)<a.event_date<=(&todaynum.-&&lagtime&i);
	create table pct_pos_pastweek_&m. as
	select distinct cluster, sum(positive_test)/count(*) as pct_positive format percent7.1
	from pct_pos_pastweek_&m.;
quit;

proc sql noprint;
	create table pct_pos_history_&m. as
	select distinct a.*,
					b.cluster,
					c.clusterstartdate as clusterstartdate format date9.,
					c.clusterenddate as clusterenddate format date9.
	from all_labs_geocoded_final a, outgis b, clusterinfo c
	where b.cluster=&m. and
		a.censustract=b.loc_id and b.cluster=c.cluster and
		(&todaynum.-(28+7))<=a.event_date<(&todaynum.-7);
	create table pct_pos_history_&m. as
	select distinct *, sum(positive_test)/count(*) as pct_positive format percent7.1
	from pct_pos_history_&m.;
	select pct_positive
	into :inside_positivity_history
	from pct_pos_history_&m.;
quit;

proc sql noprint;
	create table outside_positive_&m. as
	select *,
					count(*) as total_tests
	from all_labs_geocoded_final
	where strip(censustract)^in(select distinct strip(loc_id) from outgis where cluster=&m) and
		"&clusterstartdate"d<=event_date<="&clusterenddate"d;
	select strip(put(sum(positive_test)/total_tests,percent7.1)) into :outside_positivity
	from outside_positive_&m.;
quit;

proc sql;
create table summary_counts_&m. as
	select distinct a.column,
					"&newly_tested" as row1,
					count(*) as row2,
					" " as row3,
					"&inside_positivity" as row4,
					"&inside_positivity_history" as row5,
					"&outside_positivity" as row6,
					b.row7 as row7,
					" " as row8,
					strip(put(sum(a.age_0_17),8.))||" ("||strip(put(round((sum(a.age_0_17)/&ncov_cases_age.)*100),8.))||"%)" as row9,
					strip(put(sum(a.age_18_44),8.))||" ("||strip(put(round((sum(a.age_18_44)/&ncov_cases_age.)*100),8.))||"%)" as row10,
					strip(put(sum(a.age_45_64),8.))||" ("||strip(put(round((sum(a.age_45_64)/&ncov_cases_age.)*100),8.))||"%)" as row11,
					strip(put(sum(a.age_65_74),8.))||" ("||strip(put(round((sum(a.age_65_74)/&ncov_cases_age.)*100),8.))||"%)" as row12,
					strip(put(sum(a.age_75_plus),8.))||" ("||strip(put(round((sum(a.age_75_plus)/&ncov_cases_age.)*100),8.))||"%)" as row13,
					sum(a.age_unknown) as row14,
					" " as row15,
					strip(put(sum(a.sex_female),8.))||" ("||strip(put(round((sum(a.sex_female)/&ncov_cases_sex.)*100),8.))||"%)" as row16,
					strip(put(sum(a.sex_male),8.))||" ("||strip(put(round((sum(a.sex_male)/&ncov_cases_sex.)*100),8.))||"%)" as row17,
					sum(a.sex_unknown) as row18,
					" " as row19,
					strip(put(sum(a.raceeth_latinx),8.))||" ("||strip(put(round((sum(a.raceeth_latinx)/&ncov_cases_raceeth.)*100),8.))||"%)" as row20,
					strip(put(sum(a.raceeth_black),8.))||" ("||strip(put(round((sum(a.raceeth_black)/&ncov_cases_raceeth.)*100),8.))||"%)" as row21,
					strip(put(sum(a.raceeth_asian_pi),8.))||" ("||strip(put(round((sum(a.raceeth_asian_pi)/&ncov_cases_raceeth.)*100),8.))||"%)" as row22,
					strip(put(sum(a.raceeth_white),8.))||" ("||strip(put(round((sum(a.raceeth_white)/&ncov_cases_raceeth.)*100),8.))||"%)" as row23,
					strip(put(sum(a.raceeth_other),8.))||" ("||strip(put(round((sum(a.raceeth_other)/&ncov_cases_raceeth.)*100),8.))||"%)" as row24,
					strip(put(sum(a.raceeth_unknown),8.))||" ("||strip(put(round((sum(a.raceeth_unknown)/&ncov_cases.)*100),8.))||"%)" as row25,
					" " as row26,
					strip(put(sum(a.symptomatic_yes),8.))||" ("||strip(put(round((sum(a.symptomatic_yes)/&ncov_cases_symp.)*100),8.))||"%)" as row27,
					strip(put(sum(a.symptomatic_no),8.))||" ("||strip(put(round((sum(a.symptomatic_no)/&ncov_cases_symp.)*100),8.))||"%)" as row28,
					strip(put(sum(a.symptomatic_unk),8.))||" ("||strip(put(round((sum(a.symptomatic_unk)/&ncov_cases.)*100),8.))||"%)" as row29,
					" " as row30,
					strip(put(sum(a.interview_complete),8.))||" ("||strip(put(round((sum(a.interview_complete)/&ncov_cases.)*100),8.))||"%)" as row31,
					strip(put(sum(a.interview_pending),8.))||" ("||strip(put(round((sum(a.interview_pending)/&ncov_cases.)*100),8.))||"%)" as row32,
					strip(put(sum(a.interview_notdone),8.))||" ("||strip(put(round((sum(a.interview_notdone)/&ncov_cases.)*100),8.))||"%)" as row33
		from total_cases a left join total_cases_text_age_&m. b 
		on a.column=b.column
		where a.cluster=&m.;
quit;

%end;

%mend count_calc;
%count_calc

/* Concatenate */
data pct_pos_merge;
	set newly_tested_1-newly_tested_&max_cluster;
run;

data pct_pos_merge_pastweek;
	set pct_pos_pastweek_1-pct_pos_pastweek_&max_cluster;
	rename pct_positive=pct_pos_pastweek;
run;

data all_cnts_&&analysis_print&i..;
	set summary_counts_1-summary_counts_&max_cluster;
run;

* merge some things to clusterhistory;
proc sort data=pct_pos_merge; by cluster; run;
proc sort data=pct_pos_merge_pastweek; by cluster; run;
data clusterhistory;
	merge clusterhistory pct_pos_merge pct_pos_merge_pastweek;
	by cluster;
run;

/* Add percent positivity to cluster history */
data pct_pos_merge (keep = cluster analysis_print rundate pct_positivity);
	set all_cnts_&&analysis_print&i..;
	format cluster 8.0;
	cluster=input(scan(column,-1," "),8.0);
	format analysis_print $32.;
	analysis_print="&&analysis_print&i..";
	format rundate mmddyy10.;
	rundate=&todaynum;
	format pct_positivity percent7.1;
	pct_positivity=input(strip(row4),percent7.1);
run;

proc sort data=pct_pos_merge;
	by rundate analysis_print cluster;
run;

proc sort data=support.BCD005_clusterhistory_covid;
	by rundate analysis_print cluster;
run;

data support.BCD005_clusterhistory_covid;
	merge support.BCD005_clusterhistory_covid pct_pos_merge;
	by rundate analysis_print cluster;
run;

proc printto; run;

%mend clustersummary_setup;
