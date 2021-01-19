*************************************************************************************************;
*	PROGRAM NAME: COVID_ANALYSIS_citywide_percent_positivity_graphs		 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/14/2021																		*;
*	 PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		PURPOSE:Output trends of percent positivity for 21 and 63 day study periods				*;
*		PARENT: Called via %include statement in COVID_Analysis									*;
*************************************************************************************************;

%global tempstart tempstartdate tempend tempenddate;
data _null_;
	call symputx ('tempstart',&todaynum-&maxstudyperiod);
	call symputx ('tempstartdate',put((&todaynum-&maxstudyperiod),date9.));
	call symputx ('tempend',&todaynum-&minlagtime);
	call symputx ('tempenddate',put((&todaynum-&minlagtime),date9.));
	call symputx ('refline4weeksdate',put((&todaynum-(27+&minlagtime)),mmddyy10.));
	call symputx ('refline6weeksdate',put((&todaynum-(41+&minlagtime)),mmddyy10.));
	call symputx ('refline8weeksdate',put((&todaynum-(55+&minlagtime)),mmddyy10.));
run;

%put &tempstart &tempstartdate &tempend &tempenddate
	&refline4weeksdate &refline6weeksdate &refline8weeksdate;

proc sql;
	create table pct_positivity_citywide as
	select distinct event_date,
					count(*) as tests,
					sum(case when status="CASE" then 1 else 0 end) as positive_tests,
					calculated positive_tests/calculated tests as pct_positive format=percent7.1 label="Percent Positive"
	from all_labs_geocoded_final
	group by event_date;
quit;

proc sql;
	select 1.1*max(pct_positive) into :max_pct_pos
	from pct_positivity_citywide
	where &tempstart<=event_date<=&tempend;
quit;

ods listing close;
ods escapechar='^';
title; footnote;
goptions reset=goptions device=png300 target=png300 ftext='Calibri' ftitle='Calibri/bold' htitle=2 xmax=8.5 in ymax=6.7 in;	

ods rtf body = "&ARCHIVE.&today.\COVID_percent_positivity_trend_&today..rtf";
ods rtf file = "&ARCHIVE.&today.\COVID_percent_positivity_trend_&today..rtf";

ods text ="^S={outputwidth=100% fontweight=bold fontsize=12pt just=left}Percent positivity &tempstartdate to &tempenddate:";

proc sgplot data=pct_positivity_citywide;
	vline event_date / response=pct_positive lineattrs=(color=black thickness=2) break;
    xaxis integer values=("&tempstartdate"d to "&tempenddate"d by 1)
		label="Specimen Collection Date" fitpolicy=rotatethin;
	refline "&refline4weeksdate" "&refline6weeksdate" "&refline8weeksdate" /
		axis=x lineattrs=(thickness=3 color=darkred pattern=dash) label=("4 weeks" "6 weeks" "8 weeks");
	yaxis min=0 max=&max_pct_pos label="Percent positivity";
run;
quit;

ods rtf close;