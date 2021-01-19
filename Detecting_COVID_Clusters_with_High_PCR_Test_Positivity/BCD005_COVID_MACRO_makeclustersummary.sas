/* Print cluster summary tables in rtf output */

%macro MakeClusterSummary;
%macro dummy; %mend dummy;

ods rtf startpage=now;
/* Set options and title statements */
title1  "Cluster information";
title2 height=1.5 "Cluster #1 is the most likely cluster, i.e. the cluster least likely to be due to chance";
footnote1 font='Arial' height=2 '*Recurrence interval represents the expected length of follow-up required to see one cluster at least as unusual as the observed cluster by chance.';
footnote2 font='Arial' justify=left height=0.8 "Secondary clusters are defined as having no cluster center in another cluster. Secondary clusters with no unique cases are displayed on the map but suppressed from cluster summary tables.";

/* Format select variables for output */
proc sql; 
	create table clusterinfoGraph as
	select distinct cluster
		,primary_cluster as primary_cluster_num
		,strip(put(primary_cluster,8.)) as primary_cluster
		,case
			when cluster^=primary_cluster then strip(put(cluster,8.))
			else " "
		end as secondary_cluster
		,clusterstartdate
		,clusterenddate
		,numclusterdays
		,NumCases
		,total_cases
		,pct_positive
		,pct_pos_pastweek
		,centroidnocc_name
		,radiusMile format = 5.2
		,radiusKm format= 6.2
		,ode format=4.2
		,recurr_int
	from clusterhistory;
quit;

/* Output linelist of cluster information to word document - row color corresponds to color of cluster on map */
proc report data=clusterinfoGraph nowd;
	column 	primary_cluster_num primary_cluster cluster secondary_cluster centroidnocc_name
			total_cases NumCases clusterstartdate clusterenddate
			numclusterdays radiusMile radiusKm pct_positive pct_pos_pastweek ode recurr_int;
	define primary_cluster_num / order noprint;
	define primary_cluster / '1^{super o} Cluster' width=1;
	define cluster / order noprint;
	define secondary_cluster / '2^{super o} Cluster' width=1;
	define centroidnocc_name / 'Centered in NOCC' width=5;
	define total_cases / 'Total Cases' width=5;
	define numcases / 'Unique Cases' width=5;
	define clusterstartdate /'Start date' width = 18;
	define clusterenddate/ 'End date' width=18;
	define NumClusterDays/'# days in cluster' width=5;
	define radiusMile/'Radius (miles)' width=5 ;
	define radiuskm/'Radius (km)' width=5 ;
	define pct_positive/'Percent Positivity Inside Cluster' width=5 ;
	define pct_pos_pastweek/'Percent Positivity Inside Cluster in past week' width=5 ;
	define ode / "Observed over Expected" width=4;
	define recurr_int / 'Recurrence interval (days)*' width=5;
run;

title;
footnote;



data demo_summary_counts;
set all_cnts_&&analysis_print&i..;
/* Fill in missing numeric with zeros */
	array all _numeric_;
	do over all;
	if all = . then all = 0;
	end;
/* Fill in missing proc means fields with N/A */
	array char row7;
	do over char;
	if char=" " then char="N/A";
	end;
/* Fill in missing n (%) fields with 0 (0) */
	array char_num row9 row10 row11 row12 row13 row16 row17
		row20 row21 row22 row23 row24 row25 row27 row28 row29 row31 row32 row33;
	do over char_num;
	if char_num in(" ", "0 (.%)") then char_num="0 (0%)";
	end;
	format order 8.;
	order=input(scan(strip(column),-1," "),8.);
run;

proc sort data=demo_summary_counts;
by order;
run;

/* flip rows and columns for report */
proc transpose data=demo_summary_counts out=demo_summary_report name=row;
	var row1-row33;
	id column;
run;


/* Using the escape char allow for formatting of selected text in a cell */
ods escapechar='^';

%global pcthiststartdate pcthistenddate;
data _null_;
call symputx ('pcthiststartdate',put((&todaynum.-(28+7)),mmddyy5.));
call symputx ('pcthistenddate',put((&todaynum.-7),mmddyy5.));
call symputx ('pcthiststartdate2',put((&todaynum.-9),mmddyy5.));
call symputx ('pcthistenddate2',put((&todaynum.-3),mmddyy5.));
run;

%put &pcthiststartdate2 &pcthistenddate2;

/* This is also in the clustersummary_setup code but it was throwing an error that it did not exist so running again here */
proc sql noprint;
select strip(put(max(cluster),8.))
into :max_cluster
from linelist4;
quit;

/* label rows for report */
data demo_summary_report_label;
set demo_summary_report;
	format field $150.;
	if row="row1" then field=	"^S={fontweight=bold}Number of Persons Newly Tested";
	if row="row2" then field=	"^S={fontweight=bold}Total Cases";
	if row="row3" then field=	"^S={fontweight=bold}Percent Positivity";
	if row="row4" then field=	"  -  Inside Cluster";
	if row="row5" then field=	"  -  Inside Cluster for prior 4 weeks at 1-week lag (&pcthiststartdate-&pcthistenddate)";
	if row="row6" then field=	"  -  Outside Cluster";
	if row="row7" then field=	"^S={fontweight=bold}Median Age (Range)";
	if row="row8" then field=	"^S={fontweight=bold}Age Group";
	if row="row9" then field=	"  -  0 to 17";
	if row="row10" then field=	"  -  18 to 44";
	if row="row11" then field=	"  -  45 to 64";
	if row="row12" then field=	"  -  65 to 74";
	if row="row13" then field=	"  -  75 and over";
	if row="row14" then field=	"  -  Unknown";
	if row="row15" then field=	"^S={fontweight=bold}Sex";
	if row="row16" then field=	"  -  Female";
	if row="row17" then field=	"  -  Male";
	if row="row18" then field=	"  -  Unknown";
	if row="row19" then field=	"^S={fontweight=bold}Race/Ethnicity";
	if row="row20" then field=	"  -  Hispanic/Latinx";
	if row="row21" then field=	"  -  Black/African American";
	if row="row22" then field=	"  -  Asian/Pacific Islander";
	if row="row23" then field=	"  -  White";
	if row="row24" then field=	"  -  Other";
	if row="row25" then field=	"  -  Unknown";
	if row="row26" then field=	"^S={fontweight=bold}Symptomatic";
	if row="row27" then field=	"  -  Yes";
	if row="row28" then field=	"  -  No";
	if row="row29" then field=	"  -  Unknown";
	if row="row30" then field=	"^S={fontweight=bold}Interview Status";
	if row="row31" then field=	"  -  Complete";
	if row="row32" then field=	"  -  Pending";
	if row="row33" then field=	"  -  Not Interviewed";
	label field="^S={color=white}.";
	%do m=1 %to &max_cluster;
		%if &m<10 %then %do;
			label cluster__&m.="^S={fontweight=bold}Cluster &m.";
			rename cluster__&m.=cluster_&m.;
		%end;
		%if &m>=10 %then %do;
			label cluster_&m.="^S={fontweight=bold}Cluster &m.";
		%end;
	%end;
run;


ods rtf startpage=now;

title1  "Demographic summary by cluster:";
footnote1 font='Arial' height=1 "The denominator for demographic percentages is restricted to cases with known (not missing) values,except for % unknown for race/ethnicity and symptomatic, the denominator is all cluster cases.";



%macro cluster_demo_report;
%macro dummy; %mend dummy;

proc sql noprint;
select strip(put(row3,8.)) into :cluster_cases1-:cluster_cases&max_cluster.
from demo_summary_counts;
quit;

/* Print 10 clusters per page */
%global cluster_report_loop;
proc sql noprint;
select strip(put(ceil(max(cluster)/10),8.))
into :cluster_report_loop
from linelist4;
quit;

data _null_;
do i=1 to &cluster_report_loop;
	call symputx ('startloop'||left(put(i,8.)),put(1+(10*(i-1)),8.));
	call symputx ('endloop'||left(put(i,8.)),put(10*i,8.));
	if i=&cluster_report_loop then do;
		call symputx ('endloop'||left(put(i,8.)),put(&max_cluster.,8.));
	end;
end;
run;

%do r=1 %to &cluster_report_loop;

ods rtf startpage=now;

proc report data=demo_summary_report_label;
column field
%do m=&&startloop&r %to &&endloop&r;
	%if &&cluster_cases&m.>0 %then %do;
		cluster_&m.
	%end;
%end;
;
define field / style(column)={width=1.8in} left;
%do m=&&startloop&r %to &&endloop&r;
	%if &&cluster_cases&m.>0 %then %do;
		define cluster_&m. / style(column)={width=.65in} center;
	%end;
%end;
run;

%end; 

title;
footnote;

%mend cluster_demo_report;

%cluster_demo_report

%Mend MakeClusterSummary;