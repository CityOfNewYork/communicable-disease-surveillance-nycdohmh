*************************************************************************************************;
*	PROGRAM NAME: COVID_ANALYSIS_data_prep								 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/14/2021																		*;
*	 PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		PURPOSE: Prepares dataset for analysis													*;
*		PARENT: Called via %include statement in COVID_Analysis									*;
*************************************************************************************************;

/* Define max value of study period across all analyses */
proc sql;
	select max(studyperiod+(lagtime-1)), min(lagtime)
	into :maxstudyperiod, :minlagtime
	from diseaselist;
quit;
%put &maxstudyperiod &minlagtime;

/* Import full analysis dataset */
data all_labs_geocoded;
	set datasets.BCD005_all_labs_geocoded;
run;

/* Subset to PCR tests within analysis timeframe and geography */
proc sql;
	create table all_labs_geocoded_final as
	select event_id,
			status,
			event_date,
			age,
			sex,
			race_final,
			ethnicity_final,
			symptomatic,
			interview_status,
			censustract,
			nocc_name,
			case
				when status="CASE" then 1
				else 0
			end as positive_test
	from all_labs_geocoded
	where censustract^ in("00000000000","0", " ") and event_date>=&todaynum-&maxstudyperiod;
quit;
