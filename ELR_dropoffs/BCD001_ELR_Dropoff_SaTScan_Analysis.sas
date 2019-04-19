/********************************************************************************************
	PROGRAM NAME: BCD001_ELR_Dropoff_SaTScan_Analysis.sas									
	CREATED: 2017																			
	UPDATED: April 12, 2019																	
	PROGRAMMERS: Eric Peterson																
				 Erin Andrews																
********************************************************************************************/

/* Will delete rows added today if rerunning*/
data support.BCD001_dropoff_history;
set support.BCD001_dropoff_history;
if rundate= "&TODAY."d then delete;
run;

/* Pull all Maven labs, excluding PHL */ 
/* Mergers and send-outs: */
/*		Facility 1 (CLIA1) --> Facility 2 (CLIA2) */
/*		Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
/*		Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
/*		Facility 5 (CLIA5) --> Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
/*		Facility 11 (CLIA11) was misassigned to Facility 3 (CLIA3) for part of study period due to improper mapping in ECLRS data */
/*		Dialysis centers (CLIA12/13/14) submit quarterly, only include in 180/270 min/max temporal window analysis */

/* Discontinued */
/*		Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/*			merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */


data all_labs hep_labs (keep = event_id lab_clia lab_name disease_code test_name test_code test_description
						labdate specimen_number report_date specimen_date DOW report_source observation_result_key);
set maven.dd_aow_labs;
where disease_code ^in('MIS','ZZZ','FOO','UNK','VS','ZZA','HDV','HEV','HOV','RESP','CAUR')
	and report_source="ECLRS"
/* exclude PHL, missing CLIA, and CLIA used for testing */
	and lab_clia not in (" ", "null","CLIAPHL","TESTCLIA");
/* Lab mergers and send outs */
/* Facility 1 (CLIA1) --> Facility 2 (CLIA2) */
	if lab_clia="CLIA1" then lab_clia="CLIA2"; 
/* Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
	if lab_clia="CLIA3" and disease_code in("HBVC","HBVA") then lab_clia="CLIA4";
/* Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
	if lab_clia="CLIA5" and disease_code= "LYM" then lab_clia="CLIA6";
/* Facility 5 (CLIA5) --> Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
	if lab_clia ="CLIA5" and test_name in('Hep C virus NAAT/PCR',
										   'Hep C genotype') then lab_clia="CLIA7";

/* Discontinued */
/* Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/* 	merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */
/*	if lab_clia in("CLIA9","CLIA10") then lab_clia="CLIA8";*/

format labdate mmddyy8.;
format test_code $15.;
format test_name $50.;
/*  For hepatitis B/C use specimen collection date for analysis, look at acute and chronic together */
if disease_code in("HBVC","HCVC","HBVA","HCVA") then do;
	labdate=datepart(specimen_date);
	if disease_code="HBVA" then disease_code="HBVC";
	if disease_code="HCVA" then disease_code="HCVC";
end;
/* For all other diseases use report data for analysis */
else labdate=datepart(report_date);
/* Keep only if labdate is in past 3 years + 30 days (max study period + max lag + 1 year) */
if labdate GE &todaynum-(1095+30) and labdate LE &todaynum.;
if labdate=. then delete;
DOW= weekday(labdate);
/* Use one dataset for lab- and disease-level analyses */
output all_labs;
/* Restrict hepatitis test type analyses to specific test types, assign codes */
if test_name in('AST/SGOT','Hep B NAAT/PCR','Hep B core IgM (HBcIGM)','Hep B e antigen (HBe antigen)','Hep B genotype',
		'Hep B surface antigen (HBsAg)','Hep C antibody screen (EIA)','Hep C genotype','Hep C virus NAAT/PCR') then do;
	if test_name = 'AST/SGOT' then test_code = 'AST_SGOT';
	/* Added separate analyses for positive and negative Hep B PCR tests Mar 2019 */
	if test_name = 'Hep B NAAT/PCR' and result_name in("Positive","Indeterminate","Equivocal") then test_code = 'HepB_PCR_pos';
	if test_name = 'Hep B NAAT/PCR' and result_name="Negative" then test_code = 'HepB_PCR_neg';
	if test_name = 'Hep B core IgM (HBcIGM)' then do;
		test_code = 'HepB_core_IGM';
		labdate=datepart(report_date);
	end;
	if test_name = 'Hep B e antigen (HBe antigen)' then test_code = 'HepB_e_Ag';
	if test_name = 'Hep B genotype' then test_code = 'HepB_genotype';
	if test_name = 'Hep B surface antigen (HBsAg)' then test_code = 'HepB_surface_Ag';
	if test_name = 'Hep C antibody screen (EIA)' then test_code = 'HepC_Ab_screen';
	if test_name = 'Hep C genotype' then test_code = 'HepC_genotype';
	/* Added separate analyses for positive and negative Hep C PCR tests Feb 2018 */
	if test_name = 'Hep C virus NAAT/PCR' and result_name in("Positive","Indeterminate") then test_code = 'HepC_PCR_pos';
	if test_name = 'Hep C virus NAAT/PCR' and result_name="Negative" then test_code = 'HepC_PCR_neg';
/* Output dataset for test type-level analyses */
	output hep_labs;
end;
run;

/* Remove GBS cases >= 7 days old */
proc sql;
create table all_labs2 as
select a.*,
		datepart(b.birth_date) as dob format mmddyy10.,
		labdate-calculated dob as age_days
from all_labs a left join maven.dd_aow_events b on a.event_id=b.event_id
where (a.disease_code^="GBS" or (a.disease_code="GBS" and datepart(a.specimen_date)-datepart(b.birth_date)<7));
quit;

/* keep one record by lab/disease/accessionnum */
proc sort data=all_labs2 nodupkey;
by lab_clia disease_code specimen_number;
run;

/* pulling all eclrs reports in past 3 years + 30 days (max lag) up to today */
data eclrs (keep= sendingfacilityclia sendingfacilityname ProducerCliaID ProducerLabName ProviderAddressLine1 disease
				 createdate collectiondate DOW accessionnum localdesc observationresultkey dob);
set eclrs.cd;
where
/* Keep only production records */
	processingID= 'P' and
/* Delete not reportable and susceptablities */
	disease not in ('NOT REPORTABLE','SUSCEPTIBILITY-CD DISEASE UNKNOWN','WADSWORTH CD DISEASE UNK') and
/* Exclude NYS and NYC PHL, missing CLIA, and CLIA for testing */
	sendingfacilityclia not in(" ", "null","CLIAPHL","TESTCLIA");
/* Disease name cleaning */
	if disease in("ANAPLASMOSIS") then disease="ANAPLASMOSIS, HUMAN GRANULOCYTIC";
	if disease in("ARBOVIRAL INFECTIONS") then disease="ARBOVIRAL INFECTION";
	if disease in("CYCLOSPORIASIS") then disease="CYCLOSPORA";
	if disease in("ESCHERICHIA COLI, NON-O157",
				"ESCHERICHIA COLI NON-O157",
				"ESCHERICHIA COLI, NOT O157",
				"ESCHERICHIA COLI 0157",
				"ESCHERICHIA COLI, SHIGATOXIN POSITIVE",
				"ESCHERICHIA COLI, SHIGATOXIN PRODUCING (STEC)")
				then disease="SHIGATOXIN-PRODUCING E. COLI (E.G., 0157)";
	if disease in("STREPTOCOCCUS, GROUP A") then disease="GROUP A STREP, INVASIVE";
	if disease in("STREPTOCOCCUS, GROUP B") then disease="GROUP B STREP, INVASIVE";
	if disease in("HAEMOPHILUS INFLUENZA INVASIVE DISEASE",
				"HAEMOPHILUS INFLUENZAE INVASIVE DISEASE")
				then disease="HAEMOPHILUS INFLUENZAE, INVASIVE";
	if disease in("HEPATITIS D") then disease="HEPATITIS DELTA";
	if disease in("HEPATITIS E") then disease="HEPATITIS E VIRUS";
	if disease in("HEPATITIS OTHER/UNSPECIFIED") then disease="HEPATITIS, UNSPECIFIED";
	if disease in("LEGIONELLOSIS") then disease="LEGIONELLA";
	if disease in("MELIODIDOSIS") then disease="MELIOIDOSIS";
	if disease in("MENINGITIS, BACTERIAL OTHER") then disease="MENINGITIS, BACTERIAL, OTHER";
	if disease in("MENINGOCOCCAL DISEASE") then disease="NEISSERIA MENINGITIDIS";
	if disease in("NON-REPORTABLE") then disease="NOT REPORTABLE";
	if disease in("RICKETTSIAL POX") then disease="RICKETTSIALPOX";
	if disease in("RSV") then disease="RESPIRATORY SYNCYTIAL VIRUS";
	if disease in("SHIGELLOSIS") then disease="SHIGELLA";
	if disease in("SALMONELLA SP",
				"SALMONELLA UNKNOWN") then disease="SALMONELLA";
	if disease in("TRANSMISSIBLE SPONGIFORM ENCEPHALOPATHY (CREUTZFELD-JAKOB DISEASE)") 
				then disease="TRANSMISSIBLE SPONGIFORM ENCEPHALOPATHY";
	if disease in("VANCOMYCIN INTERMEDIATE STAPHYLOCOCCUS AUREUS",
				"STAPHYLOCOCCUS AUREUS WITH REDUCED SUSCEPTIBILITY TO VANCOMYCIN")
				then disease="VANCOMYCIN-INTERMEDIATE STAPHYLOCOCCAL AUREUS";
	if disease in("VIBRIO NON O1 CHOLERA",
				"VIBRIO-NON01 CHOLERA") then disease="VIBRIO (NON-CHOLERA)";
	if disease in("YERSINIOSIS (NON-PLAGUE)") then disease="YERSINIOSIS";
	if disease =: 'SHIGATOXIN' then disease= 'SHIGATOXIN-PRODUCING E.COLI';
	if disease =: 'SALMONELLA' then disease= 'SALMONELLA';

/* Lab mergers */
/* Facility 1 (CLIA1) with Facility 2 (CLIA2) */
	if sendingfacilityclia ="CLIA1" then sendingfacilityclia="CLIA2"; 
/* Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
	if sendingfacilityclia ="CLIA3" and disease= 'HEPATITIS B' then sendingfacilityclia="CLIA4";
/* Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
	if sendingfacilityclia ="CLIA5" and disease= 'LYME DISEASE' then sendingfacilityclia ="CLIA6";

/* Discontinued */
/* Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/* 	merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */
/*	if sendingfacilityclia in("CLIA9","CLIA10") then sendingfacilityclia="CLIA8";*/

/*  For hepatitis B/C use specimen collection date for analysis, look at acute and chronic together */
if disease in("HEPATITIS B","HEPATITIS C") then labdate=datepart(collectiondate);
/* For all other diseases use report data for analysis */
else labdate=datepart(createdate);
/* Keep only if labdate is in past 3 years + 30 days (max study period + max lag + 1 year) */
if labdate GE &todaynum-(1095+30) and labdate LE &todaynum.;
if labdate=. then delete;
/* Delete test messages */
	if upcase(lastname) in("TEST","QUEST") or upcase(firstname) in("TEST","QUEST") then delete;
/* If GBS keep only if <7 days old */
	dob=datepart(dateofbirth);
	if collectdate-dob>=7 and disease="GROUP B STREP, INVASIVE" then delete;
run;

/* Merge to add disease codes used in Maven */
proc sql;
create table eclrs_recode as
select a.*, 
	b.disease_code
from eclrs as a left join support.BCD001_disease_names as b
on a.disease = b.disease_name;
quit;

/* 		Reassign CLIA in ECLRS data for hep test-specific sendouts using standardized test name in Maven data */
proc sql;
create table eclrs2 as
select a.*,
		b.lab_clia,
	case
/* Facility 6 (CLIA6) with Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
		when put(a.observationresultkey,8.)=b.observation_result_key and
			a.sendingfacilityclia='CLIA6' and
			b.test_name in('Hep C virus NAAT/PCR','Hep C genotype') then "CLIA7"
/* Facility 11 (CLIA11) was misassigned to Facility 3 (CLIA3) due to improper mapping in ECLRS data */
		when a.sendingfacilityclia="CLIA3" and
			a.ProducerCliaID="CLIA11" then "CLIA11"
		else a.sendingfacilityclia
	end as cleaned_clia
/* observation result key is the unique ID used to link records in ELR database to Maven */
from eclrs_recode a left join hep_labs b on put(a.observationresultkey,8.)=b.observation_result_key;
quit;

/* Replace CLIA with corrected value */
data eclrs3;
set eclrs2;
	drop sendingfacilityclia;
	rename cleaned_clia=sendingfacilityclia;
run;

/* Keep one unique record by lab/disease/accessionnum */
proc sort data=eclrs3 nodupkey;
by sendingfacilityclia disease accessionnum;
run;

/*	Reports from Facility 11 (CLIA11) were misassigned to Facility 3 (CLIA3) starting March 2018, with CLIA11 entered */
/*	as the ordering facility (producerfacilityclia) rather than the testing facility (sendingfacilityclia). */
/*	Ordering facility CLIA is only available in the ECLRS database, so these reports must first be identified in */
/*	ECLRS, then corrected in Maven data by linking using a unique ID (observation_result_key)*/
proc sql;
create table all_labs2a as
select b.*,
		case
			when put(a.observationresultkey,8.)=b.observation_result_key and
				b.lab_clia="CLIA3" and
				a.sendingfacilityclia="CLIA11" then "CLIA11"
			else b.lab_clia
		end as cleaned_clia
from all_labs2 b left join eclrs3 a
	on put(a.observationresultkey,8.)=b.observation_result_key;
quit;

/* Replace CLIA with corrected value */
data all_labs2a;
set all_labs2a;
	drop lab_clia;
	rename cleaned_clia=lab_clia;
run;

/* Join with most recent eclrs CLIA file to get standardized lab name */
proc sql;
create table all_labs3 as
select a.*, b.sendingfacilitynamestd
from all_labs2a a left join clia_facilityname b
	on a.lab_clia=b.clia;
QUIT;

/* If no standardized facility name use value in lab_name field */
data all_labs4;
set all_labs3;
	if sendingfacilitynamestd = " " then sendingfacilitynamestd=lab_name;
run;

/*Study period for lab level analysis is yesterday to one year ago */
proc sql;
create table lab_casefile as
select distinct lab_clia,
				labdate,
				dow,
				count(*) as count
from all_labs4
/* Exclude high volume/strongly seasonal diseases and Hepatitis B/C which use a different date for analysis */
where disease_code not in ('MRSA','FLU','RSV','HBVC','HCVC') and
	labdate GE "&LASTYEAR."d and labdate LE "&YTDAY."d
group by lab_clia, labdate
order by lab_clia, labdate;
/* Additional table used for complete dropoffs to determine if lab is reporting at all */
create table other_diseases as
select *
from all_labs4
where disease_code in ('MRSA','FLU','RSV','HBVC','HCVC') and
	labdate GE "&LASTYEAR."d and labdate LE "&YTDAY."d;
quit;

/* Case file for satscan, with one unique row per lab from ECLRS labs table */
data _null_;
set lab_casefile;
	file "&ARCHIVE.\&today.\INPUT\Lab_dropoff_case_&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
	format lab_clia $50.;
	format count $4.;
	format labdate yymmdds10.;
	format dow $1.;
	put lab_clia $ @;
	put count @;
	put labdate @;
	put DOW;
run;

/* Keep one row per CLIA for coordinate file */
proc sql;
create table lab_coord as
select distinct lab_clia
from lab_casefile;
quit;

/* Assign dummy x,y coordinates to each CLIA */
data lab_coordfile (keep= lab_clia x_coordinate y_coordinate);
set lab_coord;
counter= _N_;
x_coordinate+10;
y_coordinate+10;
if counter=1 then do;
        x_coordinate=100000;
        y_coordinate=100000;
end;
run;

/* Coordinate file for satscan */
	data _null_;
	set lab_coordfile;
		file "&ARCHIVE.\&today.\INPUT\Lab_dropoff_coordinate_&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
			format lab_clia $50. ;
			format x_coordinate 13.6;
			format y_coordinate 13.6;
			put lab_clia $ @;
			put x_coordinate @;
			put y_coordinate;
	run;
/* Macro for lab-level analyses */
/*		length: text to distinguish seperate analyes (e.g. "short" "mid" "long") */
/*		maxtemp: parameter setting for maximum temporal window */
/*		pvalue: threshold for significant signals, 1/recurrence interval */
%macro lab_level_analysis (length=, maxtemp=, pvalue=);
%macro dummy; %mend dummy;

data _NULL_;     
	startdt=put("&lastyear."d, yymmdds10.);
	EndDt=put("&ytday."d, yymmdds10.);
	file "&ARCHIVE.\&today.\INPUT\Lab_&length._dropoff_parameter_&TODAY..txt";
	outfilename="&ARCHIVE.\&today.\OUTPUT\Lab_&length._dropoff_output_&TODAY..txt";
	put
		%ParamLab;
	file "&SATSCAN.\Lab_Dropoff.bat";
	string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&ARCHIVE.\&today.\INPUT\Lab_&length._dropoff_parameter_&TODAY..txt"||'"';
	put string;
run;

/* Run SaTScan batch file */
x "&SATSCAN.\Lab_Dropoff.bat"; Run; 

/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Lab CLIA, dummy X & Y coordinates, radius(ft) (1 by default), cluster start & end dates, */
/*		number CLIAs involved (1 by default), test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OutCol_&length._dropoff 
            DATAFILE= "&ARCHIVE.\&today.\OUTPUT\Lab_&length._dropoff_output_&today..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

/* Format satscan output of dropoff signals */
data clusterinfo_&length._dropoff; 
	set OutCol_&length._dropoff ;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8.;
	format maxtemp $10.;
	maxtemp="&maxtemp";
	label maxtemp="Maximum Temporal Window";
	drop start_date end_date;
run;

/* Keep signals that meet these conditions:
If observed = 0 then
1) p-value <= 0.01, 2) average number of expected cases in the temporal window is >= 1

If observed ^= 0 then
1) p-value <= 0.01, 2) average number of expected cases per day in the temporal window is >= 1,
3) Observed over Expected is below threshold curve, 4) expected >= 50 */

data clusterinfo2_&length._dropoff; 
	set clusterinfo_&length._dropoff;
	avg_expected= (expected/numclusterdays); format avg_expected 8.;
	ln_ri=log(recurr_int);
	if 	(observed=0 and p_value <= &pvalue and avg_expected >=1)
			or
		(observed^=0 and p_value <= &pvalue and avg_expected >=1 and
/* Threshold curve is a quadratic equation defined using a priori observed over expected threshold for natural log of min and max */
/* recurrence intervals with a third ln(RI) value selected based on feedback from past signals used to determine curve */
/* Where minimum recurrence interval=100 (ln(RI)=4.605170186), ODE cutoff=0.1 */
/* Where maximum recurrence interval=1*10^17 (ln(RI)=39.143946581), ODE cutoff=0.4 */
/* To define curve, where recurrence interval=643710979 (ln(RI)=20.282760393), ODE cutoff=0.3 */
	/* http://www.1728.org/threepts.htm */
		ode<=((-0.0002158492547228264*(ln_ri**2))+(0.018129103886981426 *ln_ri)+0.021090034303852603)
		and expected >=50);
	drop cluster X Y radius number_loc test_stat Gini_clust;
	rename LOC_ID=CLIA;
run;

%let lab_check=%sysfunc(open(clusterinfo2_&length._dropoff));
%let num_lab_signals=%sysfunc(attrn(&lab_check,nobs));
%let lab_end=%sysfunc(close(&lab_check));

/* determine date of last report in Maven */
proc sql;
create table last_report_&length as
select distinct a.CLIA,
		b.sendingfacilitynamestd,
		max(b.labdate) as last_report format mmddyy8.
from clusterinfo2_&length._dropoff as a, all_labs4 as b
where a.CLIA=b.lab_clia 
group by a.CLIA;
quit;

/* determine date of last report in ECLRS */
proc sql;
create table last_report_eclrs_&length as
select distinct a.CLIA,
		max(b.labdate) as last_report_eclrs format mmddyy8.
from clusterinfo2_&length._dropoff as a, eclrs3 as b
where a.CLIA=b.sendingfacilityclia 
group by a.CLIA;
quit;

/* count # of reports in past year */
proc sql;
create table num_reports_&length as
select distinct a.CLIA,
		count(*) as past_count
from clusterinfo2_&length._dropoff as a, all_labs4 as b, last_report_&length as c
where a.CLIA=b.lab_clia and a.CLIA=c.CLIA and
	((a.observed=0 and b.labdate>(c.last_report-365)) or
	 (a.observed^=0 and b.labdate>(a.clusterstartdate-365)))
group by a.CLIA;
quit;

/* count # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table batch_report_&length as
select distinct a.lab_clia as clia, count(distinct a.labdate) as batch
from lab_casefile as a, last_report_&length as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14 
group by b.clia;
quit;

/* get the number of reports between the date of last report and yesterday for this time in prior year */
proc sql;
create table count_lastyear_&length as
select distinct a.lab_clia as clia, count(*) as lastyear_reports
from all_labs4 as a, last_report_&length as b, clusterinfo2_&length._dropoff as c
where a.lab_clia=b.CLIA and a.lab_clia=c.CLIA and
	a.disease_code not in ('MRSA','FLU','RSV','HBVC','HCVC') and
	((c.observed=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (b.last_report-364)) or
		(c.observed^=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia;
quit;

/* get the longest gap between reports in prior year */
proc sql;
create table lab_dates_&length as
select distinct a.lab_clia as clia, a.labdate
from all_labs4 as a, last_report_&length as b, clusterinfo2_&length._dropoff as c
where a.lab_clia=b.CLIA and a.lab_clia=c.CLIA and
	a.disease_code not in ('MRSA','FLU','RSV','HBVC','HCVC') and
	((c.observed=0 and a.labdate >= (b.last_report-364)));
create table lab_dates_lag_&length as
select a.clia, a.labdate, p.labdate as labdate_lag,
	a.labdate-p.labdate as labdate_gap
from (select *, monotonic() as IND from lab_dates_&length) a
	left join (select *,monotonic() as ind from lab_dates_&length) p
	on a.clia=p.clia and a.ind=p.ind+1;
create table lab_reporting_gap_&length as
select distinct clia, labdate_gap as max_reporting_gap format 8.,
				strip(put(labdate_lag,mmddyy8.))||"-"||
				strip(put(labdate,mmddyy8.)) as max_reporting_gap_dates
	from lab_dates_lag_&length
	where labdate_gap^=.
	group by clia
		having labdate_gap=max(labdate_gap)
	order by clia, labdate;
quit;

/* If more than one reporting gap of same length, keep the most recent */
data lab_reporting_gap_recent_&length;
set lab_reporting_gap_&length;
	by clia;
	if last.clia=1;
run;



/* Get diseases reported 14 days before last report */
proc sql;
create table recent_diseases_&length as
select distinct a.lab_clia as CLIA,
				disease_code
from all_labs4 as a, last_report_&length as b
where 0 <(b.last_report - a.labdate) <= 14 and b.clia= a.lab_clia
order by clia, disease_code;
quit;

proc transpose data= recent_diseases_&length out= recent_diseases_wide_&length ;
by CLIA;
var disease_code;
run;
%macro lab_recent_diseases;
%macro dummy; %mend dummy;
/*concatenate disease_code variables into 1 column */
data recent_diseases_final_&length (keep=CLIA report_disease);
set recent_diseases_wide_&length;
length report_disease $255.;
%if &num_lab_signals>0 %then %do;
report_disease= catx(", ", OF col:);
%end;
run;
%mend lab_recent_diseases;

%lab_recent_diseases

/* join lab-level signals with last report, # of reports, # of report days, # of reports from concurrent period last year, diseases */
/*	reported in two weeks prior to reporting dropoff, last report in ECLRS, and longest reporting gap */
proc sql;
create table lab_&length._dropoff_output as
select a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		f.*,
		(&todaynum.-b.last_report) as days_since_report,
		h.max_reporting_gap,
		h.max_reporting_gap_dates,
		case
		/* Suppress signal if number of reports in past year is 12 or less (complete dropoff)
			or number of reports in concurrent period last year was less than 5 */
			when (c.past_count<13 and a.observed=0) or
				a.expected <5
					then 'Y'
			else 'N'
		end as suppress 
from clusterinfo2_&length._dropoff a
	left join last_report_&length b on a.CLIA=b.CLIA
	left join num_reports_&length c on a.CLIA=c.CLIA
	left join batch_report_&length d on a.CLIA=d.CLIA
	left join count_lastyear_&length e on a.CLIA=e.CLIA
	left join recent_diseases_final_&length f on a.CLIA=f.CLIA
	left join last_report_eclrs_&length g on a.CLIA=g.CLIA
	left join lab_reporting_gap_recent_&length h on a.clia=h.clia
where ((a.observed=0 and a.CLIA ^in(select distinct b.lab_clia from last_report_&length a, other_diseases b
					where a.clia=b.lab_clia and (a.last_report < b.labdate))
		and g.last_report_eclrs<a.clusterstartdate
		and a.CLIA ^in(select distinct b.sendingfacilityclia from last_report_&length a, eclrs3 b
					where a.clia=b.sendingfacilityclia
					group by b.sendingfacilityclia
						having max(labdate)=&todaynum))) or a.observed^=0; 			
quit;

%mend lab_level_analysis;

%lab_level_analysis (length=short, maxtemp=14, pvalue=0.01);
%lab_level_analysis (length=mid, maxtemp=126, pvalue=0.01);

/* If signal identified in both short and mid max temp windows only keep short signal */
proc sql;
create table lab_mid_dropoff_output_final as
select a.*
from lab_mid_dropoff_output a left join lab_short_dropoff_output b
	on a.clia=b.clia
where b.clia= " ";
quit;

/* merge lab signals from short and mid max temp windows */
data lab_dropoff_output;
set lab_short_dropoff_output lab_mid_dropoff_output_final;
run;


/* Disease-level */

/*importing a list of parameters for each disease */
proc sql; 
	create table diseaseListCurrent as
	select distinct c.disease_code, s.recurrence,s.mintemp,s.maxtemp,s.baseline,s.montecarlo,s.lagtime
	from all_labs4 as c inner join support.BCD001_disease_parameters as s
	on c.disease_code = s.disease_code
	order by c.disease_code, s.maxtemp;
quit;

/* Separate datasets/analyses based on maxtemp parameter */
data diseaseListCurrent_short diseaseListCurrent_mid diseaseListCurrent_long;
set diseaseListCurrent;
	if maxtemp<=56 then output diseaseListCurrent_short;
	else if maxtemp=126 then output diseaseListCurrent_mid;
	else if maxtemp=270 then output diseaseListCurrent_long;
run;

/* Macro for disease-level analyses */
/*		length: text to distinguish seperate analyes (e.g. "short" "mid" "long") */
/*		casecoordfile: text for case/coord files to use as inputs, useful if analyses use same study period with different parameter settings */
/*		pvalue: threshold for significant signals, 1/recurrence interval */
%macro disease_level_analyses (length=, casecoordfile=, pvalue=);
%macro dummy; %mend dummy;

proc sort data=diseaseListCurrent_&length;
by disease_code;
run;

/* Macro variables for iterative processing by disease */
data _NULL_;
	set diseaseListCurrent_&length;
	by disease_code;
	if first.disease_code then do;
		i+1;
		call symputx ('disease_code'||left(put(i,5.)),strip(disease_code));
		call symputx ('lagtime'||left(put(i,5.)),lagtime);
		call symputx ('recurrence'||left(put(i,5.)),recurrence);
		call symputx ('endloop' ,left(put(i,5.)));
		call symputx ('minTemp'||left(put(i,5.)),minTemp);
		call symputx ('maxTemp'||left(put(i,5.)),maxTemp);	
		call symputx ('monteCarlo'||left(put(i,5.)),monteCarlo);
		call symputx ('baseline'||left(put(i,5.)),baseline);
	end;
run;

%macro split;
%macro dummy; %mend dummy;

/* Loop to perform analyses by diseaase */
%do i=1 %to &endloop;
	data _null_;
		* START AND END DATE OF ANALYSIS;
		%global simstart;
		  simstart=&todaynum-(&&baseline&i+(&&lagtime&i-1));     /* First date analyzed in simulation */
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		%global simend;
		  simend  =&todaynum- &&lagtime&i;     				/* Last date analyzed in simulation */
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
	run;

/* mid analyses use same case file as short, no need to output duplicate files */
%if &length in(short long) %then %do;
proc sql;
create table casefile_&length._&&disease_code&i as
select distinct lab_clia,
				labdate,
				dow,
				count(*) as count
	from all_labs4
	where disease_code = "&&disease_code&i" & labdate >= &simstart & labdate <= &simend
%if &&disease_code&i=HCVC %then %do;
/* Remove dialysis centers from short and mid length max temp windows */
	%if &&maxTemp&i<270 %then %do;
		and lab_clia^in("CLIA12", "CLIA13", "CLIA14")
	%end;
/* Remove CLIA14, which started reporting in Jan 2018, until 01JAN2020 to allow time for two year study period to fill in */
	%if &&maxTemp&i=270 %then %do;
		%if &todaynum<%sysfunc(inputn(01JAN2020,date9.)) %then %do;
			and lab_clia^in("CLIA14")
		%end;
	%end;
%end;
group by lab_clia, labdate
order by lab_clia, labdate;
quit;
%end;

%let check=%sysfunc(open(casefile_&casecoordfile._&&disease_code&i));
%let num_check=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));
/* Only continue if case file has observations */
%if &num_check = 0 %then %goto exit ;

/* mid analyses use same coordinate file as short, no need to output duplicate files */
%if &length in(short long) %then %do;
/* Keep one row per CLIA for coordinate file */
proc sql;
create table coord_&length._&&disease_code&i as
select distinct lab_clia
from casefile_&length._&&disease_code&i;
quit;

/* Assign dummy x,y coordinates to each CLIA */
data coordfile_&length._&&disease_code&i (keep= lab_clia x_coordinate y_coordinate);
	set coord_&length._&&disease_code&i;
			x_coordinate+10;
			y_coordinate+10;
			if _n_=1 then do;
		        x_coordinate=100000;
		        y_coordinate=100000;
	            format lab_clia $50. ;
	            format x_coordinate 13.6;
	            format y_coordinate 13.6;
	            put lab_clia $ @;
	            put x_coordinate @;
	            put y_coordinate @;
			end;
run;
%end;

%let check=%sysfunc(open(coordfile_&casecoordfile._&&disease_code&i));
%let num_check2=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));
/* Only continue if there are two or more CLIAs in the coordinate file */
%if &num_check2 < 2 %then %goto exit;

%if &length in(short long) %then %do;
/* Case file by disease for satscan */
data _null_;
set casefile_&length._&&disease_code&i;
	file "&ARCHIVE.\&today.\INPUT\Disease_&length._dropoff_case_&&disease_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
	format lab_clia $50. ;
	format count $4.;
	format labdate yymmdds10.;
	format dow $1.;
	put lab_clia $ @;
	put count @;
	put labdate @;
	put DOW;
run;

/* Coordinate file by disease for satscan */
proc export data= coordfile_&length._&&disease_code&i
        	outfile = "&ARCHIVE.\&today.\INPUT\Disease_&length._dropoff_coordinate_&&disease_code&i.._&TODAY..txt" 
			DBMS= TAB replace;
			putnames= no;
		run;
%end;

/* Output SaTScan parameter file and update SaTScan batch file */
data _NULL_;  
	startdt=put(&simstart, yymmdds10.);
	EndDt=put(&simend, yymmdds10.);
	file "&ARCHIVE.\&today.\INPUT\Disease_&length._dropoff_parameter_&&disease_code&i.._&TODAY..txt";
	outfilename="&ARCHIVE.\&today.\OUTPUT\Disease_&length._dropoff_output_&&disease_code&i.._&TODAY..txt";
	put
		%ParamDx;
	file "&SATSCAN.\Dx_Dropoff.bat";
	string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&ARCHIVE.\&today.\INPUT\Disease_&length._dropoff_parameter_&&disease_code&i.._&TODAY..txt"||'"';
	put string;
run;

/* Execute SaTScan batch file */
x "&SATSCAN.\Dx_Dropoff.bat"; Run; 

/* Import SaTScan output */
/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OutCol_Dis_&length._&&disease_code&i
            DATAFILE= "&ARCHIVE.\&today.\OUTPUT\Disease_&length._dropoff_output_&&disease_code&i.._&TODAY..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

data OutCol_Dis_&length._&&disease_code&i;
set OutCol_Dis_&length._&&disease_code&i;
format disease_code $4.;
disease_code= "&&disease_code&i";
label disease_code="Disease Code";
format maxtemp $10.;
maxtemp= "&&maxtemp&i";
label maxtemp="Maximum Temporal Window";
run;

%exit:
%end;

%mend split;
%split

/* Combine all disease-level signals into one dataset */
data all_dis_&length._clusters;
set outcol_dis_&length:;
run;

/* Format satscan output of disease dropoff signals */
data all_dis_&length._clusters2; 
	set all_dis_&length._clusters;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8. ;
	drop start_date end_date;
run;

/* Keep signals that meet these conditions:
If observed = 0 then
1) p-value <= 0.01

If observed ^= 0 then
1) p-value <= 0.01, 2) Observed over Expected is below threshold curve */
data all_dis_&length._clusters3; 
set all_dis_&length._clusters2;
	avg_expected= (expected/numclusterdays); format avg_expected 8.;
	ln_ri=log(recurr_int);
	if 	(observed=0 and p_value <= &pvalue)
			or
		(observed^=0 and p_value <= &pvalue and
/* Threshold curve is a quadratic equation defined using a priori observed over expected threshold for natural log of min and max */
/* recurrence intervals with a third ln(RI) value selected based on feedback from past signals used to determine curve */
/* Where minimum recurrence interval=100 (ln(RI)=4.605170186), ODE cutoff=0.1 */
/* Where maximum recurrence interval=1*10^17 (ln(RI)=39.143946581), ODE cutoff=0.4 */
/* To define curve, where recurrence interval=643710979 (ln(RI)=20.282760393), ODE cutoff=0.3 */
	/* http://www.1728.org/threepts.htm */
		ode<=((-0.0002158492547228264*(ln_ri**2))+(0.018129103886981426 *ln_ri)+0.021090034303852603));
	drop cluster X Y radius number_loc test_stat Gini_clust;
	rename LOC_ID=CLIA;
run;


/* determine date of last report in Maven */
proc sql;
create table dis_&length._last_report as
select distinct a.CLIA,
		a.disease_code,
		b.sendingfacilityname2,
		max(b.labdate) as last_report format mmddyy8.
from all_dis_&length._clusters3 as a, all_labs4 as b
where a.CLIA=b.lab_clia and a.disease_code=b.disease_code
group by a.CLIA, a.disease_code;
quit;

/* determine date of last report in ECLRS */
proc sql;
create table dis_&length._last_report_eclrs as
select distinct a.CLIA,
		a.disease_code,
		max(b.labdate) as last_report_eclrs format mmddyy8.
from all_dis_&length._clusters3 as a, eclrs3 as b
where a.CLIA=b.sendingfacilityclia and a.disease_code=b.disease_code
group by a.CLIA, a.disease_code;
quit;

/* count # of reports in past year */
proc sql;
create table dis_&length._num_reports as
select distinct a.CLIA,
		a.disease_code,
		count(*) as past_count
from all_dis_&length._clusters3 as a, all_labs4 as b, dis_&length._last_report as c
where a.CLIA=b.lab_clia and a.disease_code=b.disease_code
	and a.CLIA=c.CLIA and a.disease_code=c.disease_code
	and ((a.observed=0 and b.labdate >= (c.last_report-365)) or
		(a.observed^=0 and b.labdate >= (a.clusterstartdate-365)))
group by a.CLIA, a.disease_code;
quit;

/* count # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table dis_&length._batch_report as
select distinct a.lab_clia as clia,
		b.disease_code,
		count(distinct a.labdate) as batch
from all_labs4 as a, dis_&length._last_report as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14
group by b.clia, b.disease_code;
quit;

/* get the number of reports between the date of last report and yesterday for same interval in prior year */
proc sql;
create table dis_&length._count_lastyear  as
select distinct a.lab_clia as clia, a.disease_code, count(*) as lastyear_reports
from all_labs4 as a, dis_&length._last_report as b, all_dis_&length._clusters3 as c
where a.lab_clia=b.CLIA and a.disease_code=b.disease_code and
	a.lab_clia=c.CLIA and a.disease_code=c.disease_code and
	((c.observed=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (b.last_report-364)) or
		(c.observed^=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia, a.disease_code;
quit;

/* get the longest gap between reports in prior year */
proc sql;
create table dis_&length._dates as
select distinct a.lab_clia as clia, a.disease_code, a.labdate
from all_labs4 as a, dis_&length._last_report as b, all_dis_&length._clusters3 as c
where a.lab_clia=b.CLIA and a.disease_code=b.disease_code and
	a.lab_clia=c.CLIA and a.disease_code=c.disease_code and
	((c.observed=0 and a.labdate >= (b.last_report-364)));
create table dis_&length._dates_lag as
select a.clia, a.disease_code, a.labdate, p.labdate as labdate_lag,
	a.labdate-p.labdate as labdate_gap
from (select *, monotonic() as IND from dis_&length._dates) a
	left join (select *,monotonic() as ind from dis_&length._dates) p
	on a.clia=p.clia and a.disease_code=p.disease_code and a.ind=p.ind+1;
create table dis_&length._reporting_gap as
select distinct clia, disease_code, labdate_gap as max_reporting_gap format 8.,
				strip(put(labdate_lag,mmddyy8.))||"-"||
				strip(put(labdate,mmddyy8.)) as max_reporting_gap_dates
	from dis_&length._dates_lag
	where labdate_gap^=.
	group by clia, disease_code
		having labdate_gap=max(labdate_gap)
	order by clia, disease_code, labdate;
quit;

/* If more than one reporting gap of same length, keep the most recent */
data dis_&length._reporting_gap_recent;
set dis_&length._reporting_gap;
	by clia disease_code;
	if last.clia=1 or last.disease_code=1;
run;

/* join disease-level signals dataset with last report in labs table, # of reports, # of report days, */
/* # of reports from concurrent period in prior year, last report in ECLRS and longest reporting gap */
proc sql;
create table dis_&length._dropoff_output as
select distinct a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		(&todaynum.-b.last_report) as days_since_report,
		g.max_reporting_gap,
		g.max_reporting_gap_dates,
		case
			when (c.past_count<13 or
				a.expected <5 or
				/* Suppress if signals for seasonal diseases when out of season */
				(a.disease_code in("FLU","RSV") and month(a.rundate) in(5,6,7,8,9,10)) or
				(a.disease_code in("BAB","EHR","HGA","HME","LYM","RMS","WNV") and month(a.rundate) in(10,11,12,1,2,3,4,5)))
				and a.observed=0
				then 'Y'
			when (a.expected <5 or
				/* Suppress if signals for seasonal diseases when out of season */
				(a.disease_code in("FLU","RSV") and month(a.rundate) in(5,6,7,8,9,10)) or
				(a.disease_code in("BAB","EHR","HGA","HME","LYM","RMS","WNV") and month(a.rundate) in(10,11,12,1,2,3,4,5)))
				and a.observed^=0
				then 'Y'
			else 'N'
		end as suppress
from all_dis_&length._clusters3 a
	left join dis_&length._last_report b on a.CLIA=b.CLIA and a.disease_code=b.disease_code
	left join dis_&length._num_reports c on a.CLIA=c.CLIA and a.disease_code=c.disease_code
	left join dis_&length._batch_report d on a.CLIA=d.CLIA and a.disease_code=d.disease_code
	left join dis_&length._count_lastyear e on a.CLIA=e.CLIA and a.disease_code=e.disease_code
	left join dis_&length._last_report_eclrs f on a.CLIA=f.CLIA and a.disease_code=f.disease_code
	left join dis_&length._reporting_gap_recent g on a.CLIA=g.CLIA and a.disease_code=g.disease_code
where (a.observed=0 and f.last_report_eclrs<a.clusterstartdate
					and a.CLIA ^in(select distinct b.sendingfacilityclia from all_dis_&length._clusters3 a, eclrs3 b
					where a.clia=b.sendingfacilityclia and a.disease_code=b.disease_code
					group by b.sendingfacilityclia, b.disease_code
						having max(labdate)=&todaynum))
		or a.observed^=0; 			
quit;

%mend disease_level_analyses;

%disease_level_analyses (length=short, casecoordfile=short, pvalue=0.01);
%disease_level_analyses (length=mid, casecoordfile=short, pvalue=0.01);
%disease_level_analyses (length=long, casecoordfile=long, pvalue=0.01);

/* If signal identified in both short and mid max temp windows only keep short signal */
proc sql;
create table dis_mid_dropoff_output_final as
select a.*
from dis_mid_dropoff_output a left join dis_short_dropoff_output b
	on a.clia=b.clia and a.disease_code=b.disease_code
where b.clia= " ";
quit;

/* merge disease signals from short, mid, and long max temp windows */
data disease_dropoff_output;
set dis_short_dropoff_output dis_mid_dropoff_output_final dis_long_dropoff_output;
run;

/* Pull all flu reports for CLIAs with partial dropoffs in FLU reporting */
proc sql;
create table all_flu as
select *,
		case
			when weekday(labdate)=1 then labdate+6
			when weekday(labdate)=2 then labdate+5
			when weekday(labdate)=3 then labdate+4
			when weekday(labdate)=4 then labdate+3
			when weekday(labdate)=5 then labdate+2
			when weekday(labdate)=6 then labdate+1
			when weekday(labdate)=7 then labdate
		end as labweek format mmddyy10.
from all_labs4
where disease_code="FLU" and lab_clia in(select clia from disease_dropoff_output
										where disease_code="FLU" and observed^=0)
order by lab_clia;
quit;

data all_flu2;
set all_flu;
label lab_clia="CLIA";
run;



/* Test Type level */

/* join with CLIA file to get standardized lab name */
proc sql;
create table hep_labs2 as
select a.*, b.sendingfacilityname2
from hep_labs as a, clia_filename as b
where a.lab_clia=b.sendingfacilityclia;
QUIT;

/* keep one record by lab/test/accessionnum */
proc sort data=hep_labs2 out=hep_labs3 nodupkey;
by lab_clia test_code specimen_number;
run;


/*add parameters for each test type */
proc sql; 
	create table testypeListCurrent_short as
	select distinct test_code,
		case
			when test_code="HepB_core_IGM" then 1
			else 30
		end as lagtime,
		100 as recurrence,
		case
			when test_code="HepB_core_IGM" then 7
			else 28
		end as mintemp,
		case
			when test_code="HepB_core_IGM" then 28
			else 56
		end as maxtemp,
		999 as montecarlo,
		case
			when test_code="HepB_PCR_neg" and (today()-(30+365))<("01OCT2018"d-30) then (today()-30)-"01OCT2018"d
			else 365
		end as baseline
	from hep_labs3
	where test_code ^=" "
	order by test_code;
quit;


proc sql; 
	create table testypeListCurrent_mid as
	select distinct test_code,
		case
			when test_code="HepB_core_IGM" then 1
			else 30
		end as lagtime,
		100 as recurrence,
		case
			when test_code="HepB_core_IGM" then 7
			else 28
		end as mintemp,
		126 as maxtemp,
		999 as montecarlo,
		case
			when test_code="HepB_PCR_neg" and today()<("01OCT2018"d+30) then (today()-30)-"01OCT2018"d
			else 365
		end as baseline
	from hep_labs3
	where test_code ^=" "
	order by test_code;
quit;


proc sql; 
	create table testypeListCurrent_long as
	select distinct test_code,
		30 as lagtime,
		100 as recurrence,
		180 as mintemp,
		270 as maxtemp,
		999 as montecarlo,
		730 as baseline
	from hep_labs3
	where test_code in('HepC_genotype', 'HepC_Ab_screen', 'HepC_PCR_pos', 'HepC_PCR_neg')
	order by test_code;
quit;

/* Macro for test type-level analyses */
/*		length: text to distinguish seperate analyes (e.g. "short" "mid" "long") */
/*		casecoordfile: text for case/coord files to use as inputs */
/*		pvalue: threshold for significant signals, 1/recurrence interval */
%macro testtype_level_analysis (length=, casecoordfile=, pvalue=);
%macro dummy; %mend dummy;

proc sort data=testypeListCurrent_&length;
by test_code;
run;

/* Macro variables for iterative processing by test type */
data _NULL_;
	set testypeListCurrent_&length;
	by test_code;
	if first.test_code then do;
		i+1;
		call symputx ('test_code'||left(put(i,5.)),strip(test_code));
		call symputx ('lagtime'||left(put(i,5.)),lagtime);
		call symputx ('recurrence'||left(put(i,5.)),recurrence);
		call symputx ('endloop' ,left(put(i,5.)));
		call symputx ('minTemp'||left(put(i,5.)),minTemp);	
		call symputx ('maxTemp'||left(put(i,5.)),maxTemp);	
		call symputx ('monteCarlo'||left(put(i,5.)),monteCarlo);
		call symputx ('Baseline'||left(put(i,5.)),baseline);
	end;
run;

%macro splittesttype;
%macro dummy; %mend dummy;

/* Loop to perform analyses by test type */
%do i=1 %to &endloop;

	data _null_;
		* START AND END DATE OF ANALYSIS;
		%global simstart;
		  simstart=&todaynum-(&&baseline&i+(&&lagtime&i-1));     /* First date analyzed in simulation */
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		%global simend;
		  simend  =&todaynum- &&lagtime&i;     				/* Last date analyzed in simulation */
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
	run;

/* mid analyses use same case file as short, no need to output duplicate files */
%if &length in(short long) %then %do;
proc sql;
create table casefile_&length._&&test_code&i as
select distinct lab_clia,
				labdate,
				dow,
				count(*) as count
    from hep_labs3
	where test_code = "&&test_code&i" & labdate >= &simstart & labdate <= &simend
/* Remove dialysis centers from short and mid length max temp windows */
	%if &&maxTemp&i<270 %then %do;
		and lab_clia^in("CLIA12", "CLIA13", "CLIA14")
	%end;
/* Remove CLIA14, which started reporting in Jan 2018, until 01JAN2020 to allow time for two year study period to fill in */
	%if &&maxTemp&i=270 %then %do;
		%if &todaynum<%sysfunc(inputn(01JAN2020,date9.)) %then %do;
			and lab_clia^in("CLIA14")
		%end;
	%end;
group by lab_clia, labdate
order by lab_clia, labdate;
quit;
%end;

%let check=%sysfunc(open(casefile_&casecoordfile._&&test_code&i));
%let num_check=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));
/* Only continue if case file has observations */
%if &num_check = 0 %then %goto exit ;

/* mid analyses use same case file as short, no need to output duplicate files */
%if &length in(short long) %then %do;
/* case file by test type for SaTScan */
     data _null_;
           set casefile_&length._&&test_code&i;
         file "&ARCHIVE.\&today.\INPUT\Testtype_&length._dropoff_case_&&test_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
            format lab_clia $50. ;
            format count $4.;
            format labdate yymmdds10.;
            format dow $1.;
            put lab_clia $ @;
            put count @;
            put labdate @;
            put DOW;
     run;

/* Keep one row per CLIA for coordinate file */
proc sql;
create table coord_&length._&&test_code&i as
select distinct lab_clia as lab_clia
from casefile_&length._&&test_code&i;
quit;

/* Assign dummy x,y coordinates to each CLIA */
data coordfile_&length._&&test_code&i (keep= lab_clia x_coordinate y_coordinate);
	set coord_&length._&&test_code&i;
			counter= _N_;
			x_coordinate+10;
			y_coordinate+10;
			if counter=1 then do;
		        x_coordinate=100000;
		        y_coordinate=100000;
	            format lab_clia $50. ;
	            format x_coordinate 13.6;
	            format y_coordinate 13.6;
	            put lab_clia $ @;
	            put x_coordinate @;
	            put y_coordinate @;
			end;
run;
%end;

%let check=%sysfunc(open(coordfile_&casecoordfile._&&test_code&i));
%let num_check2=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));
/* Only continue if there are two or more CLIAs in the coordinate file */
%if &num_check2 < 2 %then %goto exit;

/* mid analyses use same coordinate file as short, no need to output duplicate files */
%if &length in(short long) %then %do;
/* Coordinate file by test type for SaTScan */
proc export data= coordfile_&length._&&test_code&i
        	outfile = "&ARCHIVE.\&today.\INPUT\Testtype_&length._dropoff_coordinate_&&test_code&i.._&TODAY..txt" 
			DBMS= TAB replace;
			putnames= no;
		run;
%end;

/* Output SaTScan parameter file and update SaTScan batch file */
data _NULL_;  
	startdt=put(&simstart, yymmdds10.);
	EndDt=put(&simend, yymmdds10.);
	file "&ARCHIVE.\&today.\INPUT\Testtype_&length._dropoff_parameter_&&test_code&i.._&TODAY..txt";
	outfilename="&ARCHIVE.\&today.\OUTPUT\Testtype_&length._dropoff_output_&&test_code&i.._&TODAY..txt";
	put
		%ParamTestType;
	file "&SATSCAN.\Test_Dropoff.bat";
	string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&ARCHIVE.\&today.\INPUT\Testtype_&length._dropoff_parameter_&&test_code&i.._&TODAY..txt"||'"';
	put string;
run;

/* Execute SaTScan batch file */
x "&SATSCAN.\Test_Dropoff.bat"; Run;

/* Import SaTScan output */
/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= OutCol_tt_&length._&&test_code&i
            DATAFILE= "&ARCHIVE.\&today.\OUTPUT\Testtype_&length._dropoff_output_&&test_code&i.._&TODAY..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

data OutCol_tt_&length._&&test_code&i;
set OutCol_tt_&length._&&test_code&i;
format test_code $15.;
test_code= "&&test_code&i";
label test_code="Test Code";
format maxtemp $10.;
maxtemp= "&&maxtemp&i";
label maxtemp="Maximum Temporal Window";
run;

%exit:
%end;

%mend splittesttype;
%splittesttype

/* Combine all test type-level signals into one dataset */
data all_tt_&length._clusters;
set outcol_tt_&length.:;
run;

/* Format satscan output of test type dropoff signals */
data all_tt_&length._clusters2; 
	set all_tt_&length._clusters;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8.;
	drop start_date end_date;
run;

/* Keep signals that meet these conditions:
If observed = 0 then
1) p-value <= 0.01

If observed ^= 0 then
1) p-value <= 0.01, 2) Observed over Expected is below threshold curve */
data all_tt_&length._clusters3;
set all_tt_&length._clusters2;
	ln_ri=log(recurr_int);
	if 	(observed=0 and p_value <= &pvalue)
			or
		(observed^=0 and p_value <= &pvalue and
/* Threshold curve is a quadratic equation defined using a priori observed over expected threshold for natural log of min and max */
/* recurrence intervals with a third ln(RI) value selected based on feedback from past signals used to determine curve */
/* Where minimum recurrence interval=100 (ln(RI)=4.605170186), ODE cutoff=0.1 */
/* Where maximum recurrence interval=1*10^17 (ln(RI)=39.143946581), ODE cutoff=0.4 */
/* To define curve, where recurrence interval=643710979 (ln(RI)=20.282760393), ODE cutoff=0.3 */
	/* http://www.1728.org/threepts.htm */
		ode<=((-0.0002158492547228264*(ln_ri**2))+(0.018129103886981426 *ln_ri)+0.021090034303852603));
	drop cluster X Y radius number_loc test_stat Gini_clust;
	rename LOC_ID=CLIA ;
run;

/* determine date of last report */
proc sql;
create table tt_&length._last_report as
select distinct a.CLIA,
		a.test_code,
		b.sendingfacilityname2,
		max(b.labdate) as last_report format mmddyy8.
from all_tt_&length._clusters3 as a, hep_labs3 as b
where a.CLIA=b.lab_clia and a.test_code=b.test_code
group by a.CLIA, a.test_code;
quit;

/* count # of reports in past year */
proc sql;
create table tt_&length._num_reports as
select distinct a.CLIA,
		a.test_code,
		count(b.labdate) as past_count
from all_tt_&length._clusters3 as a, hep_labs3 as b, tt_&length._last_report as c
where a.CLIA=b.lab_clia and a.test_code=b.test_code
	and a.CLIA=c.CLIA and a.test_code=c.test_code
	and ((a.observed=0 and b.labdate >= (c.last_report-365)) or
		 	(a.observed^=0 and b.labdate >= (a.clusterstartdate-365)))
group by a.CLIA, a.test_code;
quit;


/* calculate # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table tt_&length._batch_report as
select distinct a.lab_clia as clia,
				b.test_code,
		count(distinct a.labdate) as batch
from hep_labs3 as a, tt_&length._last_report as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14
group by b.clia, b.test_code;
quit;

/* get the number of reports between the date of last report and yesterday for this time in prior year */
proc sql;
create table tt_&length._count_lastyear  as
select distinct a.lab_clia as clia, a.test_code, count(*) as lastyear_reports
from hep_labs3 as a, tt_&length._last_report as b, all_tt_&length._clusters3 as c
where a.lab_clia=b.CLIA and a.test_code=b.test_code and
	a.lab_clia=c.CLIA and a.test_code=c.test_code and
	((c.observed=0 and a.labdate <= ("&ytday."d-(365+30)) and a.labdate >= (b.last_report-364)) or
		(c.observed^=0 and a.labdate <= ("&ytday."d-(365+30)) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia, a.test_code;
quit;

/* get the longest gap between reports in prior year */
proc sql;
create table tt_&length._dates as
select distinct a.lab_clia as clia, a.test_code, a.labdate
from hep_labs3 as a, tt_&length._last_report as b, all_tt_&length._clusters3 as c
where a.lab_clia=b.CLIA and a.test_code=b.test_code and
	a.lab_clia=c.CLIA and a.test_code=c.test_code and
	((c.observed=0 and a.labdate >= (b.last_report-364)));
create table tt_&length._dates_lag as
select a.clia, a.test_code, a.labdate, p.labdate as labdate_lag,
	a.labdate-p.labdate as labdate_gap
from (select *, monotonic() as IND from tt_&length._dates) a
	left join (select *,monotonic() as ind from tt_&length._dates) p
	on a.clia=p.clia and a.test_code=p.test_code and a.ind=p.ind+1;
create table tt_&length._reporting_gap as
select distinct clia, test_code, labdate_gap as max_reporting_gap format 8.,
				strip(put(labdate_lag,mmddyy8.))||"-"||
				strip(put(labdate,mmddyy8.)) as max_reporting_gap_dates
	from tt_&length._dates_lag
	where labdate_gap^=.
	group by clia, test_code
		having labdate_gap=max(labdate_gap)
	order by clia, test_code, labdate;
quit;

/* If more than one reporting gap of same length, keep the most recent */
data tt_&length._reporting_gap_recent;
set tt_&length._reporting_gap;
	by clia test_code;
	if last.clia=1 or last.test_code=1;
run;

/* join test type-level signals dataset with last report in labs table, # of reports, # of report days, */
/* # of reports from concurrent period in prior year and longest reporting gap */
proc sql;
create table tt_&length._dropoff_output as
select a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		(&todaynum.-b.last_report) as days_since_report,
		f.max_reporting_gap,
		f.max_reporting_gap_dates,
		case
			when (c.past_count<13 or
				a.expected <5)
				and a.observed=0
				then 'Y'
			when (a.expected <5)
				and a.observed^=0
				then 'Y'
			else 'N'
		end as suppress 
from all_tt_&length._clusters3 a
	left join tt_&length._last_report b on a.CLIA=b.CLIA and a.test_code=b.test_code
	left join tt_&length._num_reports c on a.CLIA=c.CLIA and a.test_code=c.test_code
	left join tt_&length._batch_report d on a.CLIA=d.CLIA and a.test_code=d.test_code
	left join tt_&length._count_lastyear e on a.CLIA=e.CLIA and a.test_code=e.test_code
	left join tt_&length._reporting_gap_recent f on a.CLIA=f.CLIA and a.test_code=f.test_code
where (a.observed=0 and a.CLIA ^in(select distinct b.lab_clia from tt_&length._last_report a, hep_labs3 b
					where a.clia=b.lab_clia and a.test_code=b.test_code
					group by b.lab_clia, b.test_code
						having max(labdate)>=(&todaynum-30)))
		or a.observed^=0; 			
quit;

%mend testtype_level_analysis;

%testtype_level_analysis(length=short, casecoordfile=short, pvalue=0.01);
%testtype_level_analysis(length=mid, casecoordfile=short, pvalue=0.01);
%testtype_level_analysis(length=long, casecoordfile=long, pvalue=0.01);

/* If signal identified in both short and mid max temp windows only keep short signal */
proc sql;
create table tt_mid_dropoff_output_final as
select a.*
from tt_mid_dropoff_output a left join tt_short_dropoff_output b
	on a.clia=b.clia and a.test_code=b.test_code
where b.clia=" ";
quit;

/* merge test type signals from short, mid, and long max temp windows */
data testtype_dropoff_output;
set tt_short_dropoff_output tt_mid_dropoff_output_final tt_long_dropoff_output;
run;

/* combine lab- disease- and test type-level signals into one dataset */
data all_clusters (drop=disease_code test_code ode);
set lab_dropoff_output (in=a) disease_dropoff_output (in=b) testtype_dropoff_output (in=c);
	format detail $50. type $20.;
	if a then do;
		detail="All";
		if observed=0 then type="Lab-complete";
		if observed^=0 then type="Lab-partial";
	end;
	if b then do;
		detail=disease_code;
		if observed=0 then type="Disease-complete";
		if observed^=0 then type="Disease-partial";
	end;
	if c then do;
		detail=test_code;
		if observed=0 then type="Testtype-complete";
		if observed^=0 then type="Testtype-partial";
	end;
	array nums _numeric_;
	do over nums;
		if nums=. then nums=0;
	end;
run;

/* Pull signals from last week for comparison */
proc sql;
create table last_week_linelist as
	select * 
	from support.BCD001_dropoff_history
	where rundate=&lastrun and suppress= 'N';
quit;

/* assign new_dropoff indicator to new events based on previous report */
proc sql;
create table all_clusters_new as
select distinct a.*,
	CASE 
		when a.CLIA=b.CLIA and
			a.type=b.type and
			a.detail=b.detail
		then 'no'
		else 'yes'
	end as new_dropoff
from all_clusters a left join last_week_linelist b
	on a.CLIA=b.CLIA and a.type=b.type and a.detail=b.detail;
quit;

data all_clusters_final_new (drop=ln_ri);
set all_clusters_new;
run;

/* Append saved cluster details to clusterhistory file for complete drop-offs */
proc append base=support.BCD001_dropoff_history  data=all_clusters_final_new ;run;
proc sort data= support.BCD001_dropoff_history; by rundate; run;

