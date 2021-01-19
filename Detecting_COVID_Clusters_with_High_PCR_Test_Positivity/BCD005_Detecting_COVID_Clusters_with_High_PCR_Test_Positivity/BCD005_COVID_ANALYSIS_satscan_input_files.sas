*************************************************************************************************;
*	PROGRAM NAME: COVID_ANALYSIS_satscan_input_files					 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/14/2021																		*;
*	 PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		PURPOSE: Create SaTScan case file and population file for analysis						*;
*		PARENT: Called via %include statement in COVID_Analysis									*;
*************************************************************************************************;

/* Separate datasets for cases only and all tests for analysis */
data cases studyperiod_tests;
	set all_labs_geocoded_final;
	format disease_code $45.;
	disease_code="&&disease_code&i..";
	if status="CASE" then output cases;
	if event_date >= &simstart & event_date <= &simend then output studyperiod_tests;
run;

* set up data for temporal graph;
/* For poisson-based analyses temporal graph should cover study period + one day */
%global graphstart graphstartdate graphend graphenddate;
data _null_;
call symputx ('graphstart',&simend-(&&studyperiod&i-1));
call symputx ('graphstartdate',put((&simend-(&&studyperiod&i-1)),date9.));
call symputx ('graphend',&simend+1);
call symputx ('graphenddate',put((&simend+1),date9.));
run;

/* Date scaffold to fill in graph dates with 0 */
data study_dates;
format study_date mmddyy10.;
do i=&simstart to &graphend by 1;
	study_date=i;
	output;
end;
run;

/* Subset cases in study period and join to dates */
proc sql;
	create table &&analysis_print&i.._cases as
	select a.*,
			a.censustract as loc_id
	from studyperiod_tests a left join study_dates b
		on a.event_date=b.study_date
	where a.status="CASE"
	order by a.event_id;
quit;

/* Aggregate counts by census tract and event date */
proc sql;
	create table &&analysis_print&i.._cases_agg as
	select distinct loc_id,
					event_date,
					count(*) as cases
	from &&analysis_print&i.._cases
	group by loc_id, event_date
	order by loc_id, event_date;
quit;

/* create case file for SaTScan */
data _null_;
	set &&analysis_print&i.._cases_agg;
	file "&INPUT.casefile_COVID_&&analysis_print&i.._&today..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
	format loc_id $11. ;
	format cases 8.0;
	format event_date yymmdds10.;
	put loc_id $ @;
	put cases @;
	put event_date;
run;

/* dataset of all dates and all census tracts */
proc sql;
create table study_dates_loc_ids as
select a.study_date,
		b.loc_id
from study_dates a, NYC_CENSUSTRACTS b;

/* dataset of all dates, censustracts, and tests, removing earlier household cases
	if no tests for a date and censustract then 0 */
create table study_dates_loc_ids_all as
select a.loc_id,
		a.study_date as event_date,
		case
			when b.event_date is not null then 1
			else 0
		end as test
from study_dates_loc_ids a left join studyperiod_tests b
	on a.loc_id=b.censustract and a.study_date=b.event_date;
quit;

/* aggregate tests by event date and census tract */
proc sql;
	create table &&analysis_print&i.._pop as
	select distinct loc_id,
			event_date,
			sum(test) as population
	from study_dates_loc_ids_all
	group by loc_id, event_date
	order by loc_id, event_date;
quit;

/* Output SaTScan population file */
data _null_;
	set &&analysis_print&i.._pop;
	where event_date<=&simend;
	file "&INPUT.popfile_COVID_&&analysis_print&i.._&today..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
	format loc_id $11. ;
	format event_date yymmdds10.;
	format population 8.0;
	put loc_id $ @;
	put event_date @;
	put population;
run; 