/********************************************************************************************************/
/*	PROGRAM NAME: ELR_Dropoff_SaTScan_Analysis_GitHub.sas												*/
/*	CREATED: 2017																						*/
/*	UPDATED: May 24, 2018																				*/
/*	PROGRAMMERS: Eric Peterson																			*/
/*				 Erin Andrews																			*/
/*	PURPOSE: Import and format data, run SaTScan analyses, import results, apply suppression rules		*/
/********************************************************************************************************/

/* Will delete rows added today if rerunning*/
data support.clusterhistory_dropoff_all;
set support.clusterhistory_dropoff_all;
if rundate= "&TODAY."d then delete;
run;

/* Pull all Maven labs within past 2 years + 30 days (max lag) up to today */
/* Exclude PHL */ 
/* Mergers and send-outs: */
/*		Facility 1 (CLIA1) --> Facility 2 (CLIA2) */
/*		Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
/*		Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
/*		Facility 5 (CLIA5) --> Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
/*		Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/*			merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */

data all_labs hep_labs (keep= event_id lab_clia lab_name disease_code test_name test_code test_description
						labdate specimen_number report_date specimen_date report_source observation_result_key);
set maven.dd_aow_labs;
/* Remove non-disease events and diseases that are not under surveillance */
where disease_code ^in('MIS','ZZZ','FOO','UNK','VS','ZZA','HDV','HEV','HOV','RESP')
/* Keep only reports from ECLRS */
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
/* Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/* 	merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */
	if lab_clia in("CLIA9","CLIA10") then lab_clia="CLIA8";
format labdate mmddyy8.;
format test_code $15.;
format test_name $50.;
if disease_code in("HBVC","HCVC","HBVA","HCVA") then do;
/* Hepatitis is routinely batch reported - use specimen collection date instead of reporting date */
	labdate=datepart(specimen_date);
	/* Analyze acute and chronic Hepatitis events together */
	if disease_code="HBVA" then disease_code="HBVC";
	if disease_code="HCVA" then disease_code="HCVC";
end;
/* Use report date for all other diseases */
else labdate=datepart(report_date);
if labdate GE &todaynum-(730+30) and labdate LE &todaynum.;
if labdate=. then delete;
output all_labs;
/* Keep only hep tests we are interested in for analysis - assign short test codes that follow SAS variable/dataset name rules */
if test_name in('AST/SGOT','Hep B NAAT/PCR','Hep B core IgM (HBcIGM)','Hep B e antigen (HBe antigen)','Hep B genotype',
		'Hep B surface antigen (HBsAg)','Hep C antibody screen (EIA)','Hep C genotype','Hep C virus NAAT/PCR') then do;
		if test_name = 'AST/SGOT' then test_code = 'AST_SGOT';
		else if test_name = 'Hep B NAAT/PCR' then test_code = 'HepB_PCR';
		else if test_name = 'Hep B core IgM (HBcIGM)' then test_code = 'HepB_core_IGM';
		else if test_name = 'Hep B e antigen (HBe antigen)' then test_code = 'HepB_e_Ag';
		else if test_name = 'Hep B genotype' then test_code = 'HepB_genotype';
		else if test_name = 'Hep B surface antigen (HBsAg)' then test_code = 'HepB_surface_Ag';
		else if test_name = 'Hep C antibody screen (EIA)' then test_code = 'HepC_Ab_screen';
		else if test_name = 'Hep C genotype' then test_code = 'HepC_genotype';
	/* Added separate analyses for positive and negative Hep C PCR tests 16FEB2018 */
		else if test_name = 'Hep C virus NAAT/PCR' and result_name in("Positive","Indeterminate","Equivocal") then test_code = 'HepC_PCR_pos';
		else if test_name = 'Hep C virus NAAT/PCR' and result_name="Negative" then test_code = 'HepC_PCR_neg';
		else delete;
	output hep_labs;
end;
run;

/* Join with event-level table to add DOB */
proc sql;
create table all_labs2 as
select a.*,
		datepart(b.birth_date) as dob format mmddyy10.,
		labdate-calculated dob as age_days
from all_labs a left join maven.dd_aow_events b on a.event_id=b.event_id
where a.lab_clia ^in(select CLIA from hospital_outNYC) and
/* Keep GBS only if <7 days old */
	(a.disease_code^="GBS" or (a.disease_code="GBS" and datepart(a.specimen_date)-datepart(b.birth_date)<7));
quit;

/* Keep one record per unique lab/disease/accessionnum */
proc sort data=all_labs2 nodupkey;
by lab_clia disease_code specimen_number;
run;

/* Pull all eclrs labs within past 2 years + 30 days up to today */
data eclrs (keep= sendingfacilityclia sendingfacilityname ProducerCliaID ProducerLabName ProviderAddressLine1
				disease dx_eclrs createdate collectiondate accessionnum localdesc observationresultkey dob);
set eclrs.cd;
where datepart(createdate) GE (&todaynum-(730+30)) and datepart(createdate) LE &todaynum and
/* Keep only production records */
	processingID= 'P' and
/* Delete not reportable and susceptablities */
	disease not in ('NOT REPORTABLE','SUSCEPTIBILITY-CD DISEASE UNKNOWN','WADSWORTH CD DISEASE UNK') and
/* Exclude Wadsworth, PHL, missing CLIA, and CLIA for testing */
	sendingfacilityclia not in(" ", "null","CLIAPHL","TESTCLIA");
/* Clean disease names to match disease code reference table */
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
	if disease in("TRANSMISSIBLE SPONGIFORM ENCEPHALOPATHY (CREUTZFELD-JAKOB DISEASE)") then disease="TRANSMISSIBLE SPONGIFORM ENCEPHALOPATHY";
	if disease in("VANCOMYCIN INTERMEDIATE STAPHYLOCOCCUS AUREUS",
				"STAPHYLOCOCCUS AUREUS WITH REDUCED SUSCEPTIBILITY TO VANCOMYCIN") then disease="VANCOMYCIN-INTERMEDIATE STAPHYLOCOCCAL AUREUS";
	if disease in("VIBRIO NON O1 CHOLERA",
				"VIBRIO-NON01 CHOLERA") then disease="VIBRIO (NON-CHOLERA)";
	if disease in("YERSINIOSIS (NON-PLAGUE)") then disease="YERSINIOSIS";
	if disease =: 'SHIGATOXIN' then disease= 'SHIGATOXIN-PRODUCING E.COLI';
	if disease =: 'SALMONELLA' then disease= 'SALMONELLA';
	dx_eclrs=compress(upcase(disease));
/* Lab mergers */
/* Facility 1 (CLIA1) --> Facility 2 (CLIA2) */
	if lab_clia="CLIA1" then lab_clia="CLIA2"; 
/* Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
	if lab_clia="CLIA3" and disease_code in("HBVC","HBVA") then lab_clia="CLIA4";
/* Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
	if lab_clia="CLIA5" and disease_code= "LYM" then lab_clia="CLIA6";
/* Facility 5 (CLIA5) --> Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
	if lab_clia ="CLIA5" and test_name in('Hep C virus NAAT/PCR',
										   'Hep C genotype') then lab_clia="CLIA7";
/* Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/* 	merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */
	if lab_clia in("CLIA9","CLIA10") then lab_clia="CLIA8";

/* Facility 1 (CLIA1) with Facility 2 (CLIA2) */
	if sendingfacilityclia ="CLIA1" then sendingfacilityclia="CLIA2"; 
/* Facility 3 (CLIA3) --> Facility 4 (CLIA4) for Hep B only */
	if sendingfacilityclia ="CLIA3" and disease= 'HEPATITIS B' then sendingfacilityclia="CLIA4";
/* Facility 5 (CLIA5) --> Facility 6 (CLIA6) for Lym only */
	if sendingfacilityclia ="CLIA5" and disease= 'LYME DISEASE' then sendingfacilityclia ="CLIA6";
/* Existing facility assigned two new CLIAs (CLIA9 and CLIA10) */
/* 	merge with old CLIA (CLIA8) until 1 year of baseline data is available - end 13FEB2019 */
	if sendingfacilityclia in("CLIA9","CLIA10") then sendingfacilityclia="CLIA8";
	dob=datepart(dateofbirth);
/* Delete test messages */
	if upcase(lastname) in("TEST","QUEST") or upcase(firstname) in("TEST","QUEST") then delete;
/* If GBS keep only if <7 days old */
	if collectdate-dob>=7 and disease="GROUP B STREP, INVASIVE" then delete;
run;

/* Merge to add disease codes used in Maven */
proc sql;
create table eclrs_recode as
select a.*, 
	b.disease_code,
	case
		when calculated disease_code in('HBVC','HCVC') then datepart(collectiondate)
		else datepart(createdate)
	end as labdate format mmddyy10.
from eclrs as a left join support.disease_names as b
on a.disease = b.disease_name
	where sendingfacilityclia ^in(select CLIA from hospital_outNYC);
quit;

/* Reassign CLIA in ECLRS data for hep test-specific sendouts using standardized test name in Maven data */
proc sql;
create table eclrs2 as
select a.*,
		b.lab_clia,
	case
/* Facility 6 (CLIA6) with Facility 7 (CLIA7) for HCV Genotype and NAAT/PCR testing only */
		when put(a.observationresultkey,8.)=b.observation_result_key and
			a.sendingfacilityclia='33D0690778' and
			b.test_name in('Hep C virus NAAT/PCR','Hep C genotype') then "31D0696246"
		else a.sendingfacilityclia
	end as cleaned_clia
/* observation result key is the unique ID used to link records in ELR database to Maven */
from eclrs_recode a left join hep_labs b on put(a.observationresultkey,8.)=b.observation_result_key;
quit;

data eclrs3;
set eclrs2;
	drop sendingfacilityclia;
	rename cleaned_clia=sendingfacilityclia;
run;

/* Keep one unique record by lab/disease/accessionnum */
proc sort data=eclrs3 nodupkey;
by sendingfacilityclia disease accessionnum;
run;

/* Join with most recent eclrs CLIA file to get standardized lab name */
proc sql;
create table all_labs3 as
select a.*, b.sendingfacilitynamestd
from all_labs2 a left join clia_facilityname b
	on a.lab_clia=b.clia;
QUIT;

/* If no standardized facility name use value in lab_name field */
data all_labs4;
set all_labs3;
	if sendingfacilitynamestd = " " then sendingfacilitynamestd=lab_name;
run;


/******** Lab-level Analysis ********/
/*Lab level analysis will include yesterday back to one year ago and exclude MRSA, FLU, and RSV */
data lab_casefile /* all diseases except MRSA, FLU, RSV */
	 other_diseases; /* MRSA, FLU, RSV only, keep to check if complete lab dropoff is real */
set all_labs4;
where labdate GE "&LASTYEAR."d and labdate LE "&YTDAY."d;
if disease_code not in ('MRSA','FLU','RSV') then output lab_casefile;
else output other_diseases;
run;

/* Identify labs that only report Hepatitis, exclude from lab-level analysis */
proc sql;
select distinct quote(strip(lab_clia))
	into :notjusthep separated by ", "
from lab_casefile
where disease_code^in("HBVC","HCVC");
quit;

proc sort data= lab_casefile; by lab_clia; run;

/* Case file for satscan, with one unique row per lab result */
/* Include if lab reports diseases other than/in addition to Hepatitis */
     data _null_;
           set lab_casefile;
		   where lab_clia in(&notjusthep);
           dummy='1';
         file "&INPUT.\Lab_dropoff_case_&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
            format lab_clia $50. ;
            format dummy $1.;
            format labdate yymmdds10.;
            put lab_clia $ @;
            put dummy @;
            put labdate;
     run;

/* Dataset with one row per unique CLIA included in analysis */
proc sql;
create table lab_coord as
select distinct lab_clia
from lab_casefile
where lab_clia in(&notjusthep);
quit;

/* Assign dummy x,y coordinates 10 units apart to each lab */
data lab_coordfile (keep= lab_clia x_coordinate y_coordinate);
set lab_coord;
x_coordinate+10;
y_coordinate+10;
if _n_=1 then do;
        x_coordinate=100000;
        y_coordinate=100000;
end;
run;

/* COORDINATE FILE text file for satscan */
	data _null_;
	set lab_coordfile;
		file "&INPUT.\Lab_dropoff_coordinate_&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
			format lab_clia $50. ;
			format x_coordinate 13.6;
			format y_coordinate 13.6;
			put lab_clia $ @;
			put x_coordinate @;
			put y_coordinate;
	run;

/*Make parameter and batch file to call in SaTScan */
	data _NULL_;     
		startdt=put("&lastyear."d, yymmdds10.);
		EndDt=put("&ytday."d, yymmdds10.);
		file "&INPUT.\Lab_dropoff_parameter_&TODAY..txt";
		put
			%ParamLab
			file "&SATSCAN.\Lab_Dropoff.bat";
		string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&INPUT.\Lab_dropoff_parameter_&TODAY..txt"||'"';
		put string;
	run;

/* Run SaTScan batch file */
x "&SATSCAN.\Lab_Dropoff.bat"; Run; 

/* read in the SaTScan output */
/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Lab CLIA, dummy X & Y coordinates, radius(ft) (1 by default), cluster start & end dates, */
/*		number CLIAs in cluster (1 by default), test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OutCol_dropoff 
            DATAFILE= "&OUTPUT.\Lab_dropoff_output_&today..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;


/* Format SaTScan output */
data clusterinfo_dropoff; 
	set OutCol_dropoff ;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD, which SAS cannot read. */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8. ;
	drop start_date end_date ;
run;

/* Keep signals that meet these conditions:
If observed = 0 then
1) p-value <= 0.01, 2) average number of expected cases in the temporal window is >= 1

If observed ^= 0 then
1) p-value <= 0.01, 2) average number of expected cases per day in the temporal window is >= 1,
3) Observed over Expected ratio <= 0.1, 4) expected >= 50 */

data clusterinfo2_dropoff; 
	set clusterinfo_dropoff;
	avg_expected= (expected/numclusterdays); format avg_expected 8.;
	if 	(observed=0 and p_value <= 0.01 and avg_expected >=1)
			or
		(observed^=0 and p_value <= 0.01 and avg_expected >=1 and
		ODE <=0.1 and expected >=50);
	drop cluster X Y radius number_loc test_stat Gini_clust;
	rename LOC_ID=CLIA;
run;

/* Count # of signals meeting conditions */
%let lab_check=%sysfunc(open(clusterinfo2_dropoff));
%let num_lab_signals=%sysfunc(attrn(&lab_check,nobs));
%let lab_end=%sysfunc(close(&lab_check));

/* determine date of last report for labs with signal and get facility name */
proc sql;
create table last_report as
select distinct a.CLIA,
		b.sendingfacilitynamestd,
		max(b.labdate) as last_report format mmddyy8.
from clusterinfo2_dropoff as a, all_labs4 as b
where a.CLIA=b.lab_clia 
group by a.CLIA;
quit;

/* Only keep one name */
proc sort data=last_report nodupkey;
by CLIA;
run;

/* determine date of last report in ECLRS data for labs with signal */
proc sql;
create table last_report_eclrs as
select distinct a.CLIA,
		max(b.labdate) as last_report_eclrs format mmddyy8.
from clusterinfo2_dropoff as a, eclrs3 as b
where a.CLIA=b.sendingfacilityclia 
group by a.CLIA;
quit;

/* calculate # of reports in past year for labs with signal */
proc sql;
create table num_reports as
select distinct a.CLIA,
		count(*) as past_count
from clusterinfo2_dropoff as a, all_labs4 as b, last_report as c
where a.CLIA=b.lab_clia and a.CLIA=c.CLIA and
	((a.observed=0 and b.labdate>(c.last_report-365)) or
	 (a.observed^=0 and b.labdate>(a.clusterstartdate-365)))
group by a.CLIA;
quit;

/* calculate # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table batch_report as
select distinct a.lab_clia as clia, count(distinct a.labdate) as batch
from lab_casefile as a, last_report as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14 
group by b.clia;
quit;

/* calculate number of reports between the date of last report and yesterday for this time last year */
proc sql;
create table count_lastyear  as
select distinct a.lab_clia as clia, count(*) as lastyear_reports
from all_labs4 as a, last_report as b, clusterinfo2_dropoff as c
where a.lab_clia=b.CLIA and a.lab_clia=c.CLIA and
	a.disease_code not in ('MRSA','FLU','RSV') and
	/* If complete dropoff use last report date */
		((c.observed=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (b.last_report-364)) or
	/* If partial dropoff use cluster start date */
		(c.observed^=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia;
quit;

/* merge signal linelist with labs table to get diseases reported 14 days before last report */
proc sql;
create table recent_diseases as
select distinct a.lab_clia as CLIA,
				disease_code
from all_labs4 as a, last_report as b
where 0 <(b.last_report - a.labdate) <= 14 and b.clia= a.lab_clia
order by clia, disease_code;
quit;

proc transpose data= recent_diseases out= recent_diseases_wide ;
by CLIA;
var disease_code;
run;
%macro lab_recent_diseases;
%macro dummy; %mend dummy;
/*concatenating the disease_code variables into 1 column */
data recent_diseases_final (keep=CLIA report_disease);
set recent_diseases_wide;
length report_disease $255.;
%if &num_lab_signals>0 %then %do;
report_disease= catx(", ", OF col:);
%end;
run;
%mend lab_recent_diseases;

%lab_recent_diseases

/* join last report in labs table, # of reports, # of report days, # of reports from concurrent period last year, diseases */
/*	reported in two weeks prior to reporting dropoff, and last report in ECLRS */
proc sql;
create table lab_dropoff_output_final as
select a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		f.*,
		(&todaynum.-b.last_report) as days_since_report,
		case
		/* Suppress signal if number of reports in past year is 12 or less (complete dropoff)
			lab reported only 1 or 2 days in two weeks prior to reporting dropoff
			of number of reports in concurrent period last year was less than 5 */
			when (c.past_count<13 and a.observed=0) or
				d.batch in(1,2) or
				e.lastyear_reports <5 then 'Y'
			else 'N'
		end as suppress 
from clusterinfo2_dropoff a
	left join last_report b on a.CLIA=b.CLIA
	left join num_reports c on a.CLIA=c.CLIA
	left join batch_report d on a.CLIA=d.CLIA
	left join count_lastyear e on a.CLIA=e.CLIA
	left join recent_diseases_final f on a.CLIA=f.CLIA
	left join last_report_eclrs g on a.CLIA=g.CLIA
/* Keep if signal is a complete dropoff with: */
	/*no reports of MRSA, FLU, or RSV in reporting dropoff period */
where ((a.observed=0 and a.CLIA ^in(select distinct b.lab_clia from last_report a, other_diseases b
									where a.clia=b.lab_clia and (a.last_report < b.labdate))
	/* and no reports in ECLRS in reporting dropoff period */
		and g.last_report_eclrs<a.clusterstartdate
	/* and there are no reports from the lab today */
		and a.CLIA ^in(select distinct b.sendingfacilityclia from last_report a, eclrs3 b
						where a.clia=b.sendingfacilityclia
						group by b.sendingfacilityclia
							having max(labdate)=&todaynum)))
/* Or signal is for a partial dropoff */
	or a.observed^=0; 			
quit;

/******** Disease-level Analyses ********/
/*import parameters for each disease */
proc sql; 
	create table diseaseListCurrent as
	select distinct c.disease_code, s.recurrence,s.mintemp,s.maxtemp,s.baseline,s.montecarlo,s.lagtime
	from all_labs4 as c inner join support.disease_parameters as s
	on c.disease_code = s.disease_code
	order by c.disease_code;
quit;

/* Macro variables of analysis parameters for each iteration of analysis */
data _NULL_;
	set diseaseListCurrent;
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

/*macro will loop through each unique disease and analysis parameter setting */
%do i=1 %to &endloop;
	data _null_;
		* START AND END DATE OF ANALYSIS;
		%global simstart;
		  simstart=&todaynum-(&&baseline&i+(&&lagtime&i-1));     /* Start of study period */
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		%global simend;
		  simend  =&todaynum- &&lagtime&i;     				/* End of study period */
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
	run;

proc sql;
create table casefile_&&disease_code&i as
select *
	from all_labs4
	where disease_code = "&&disease_code&i" & labdate >= &simstart & labdate <= &simend;
quit;

/* If no cases of disease in study period skip to end of loop */

%let check=%sysfunc(open(casefile_&&disease_code&i));
%let num_check=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));

%if &num_check = 0 %then %goto exit ;

/* Dataset with one row per unique CLIA included in analysis */
proc sql;
create table coord_&&disease_code&i as
select distinct lab_clia
from casefile_&&disease_code&i;
quit;

/* Assign dummy x,y coordinates 10 units apart to each lab */
data coordfile_&&disease_code&i (keep= lab_clia x_coordinate y_coordinate);
	set coord_&&disease_code&i;
			x_coordinate+10;
			y_coordinate+10;
			if _n_=1 then do;
		        x_coordinate=100000;
		        y_coordinate=100000;
			end;
run;

/* Two or more labs reporting disease in study period required for analysis - else skip to end of loop */
%let check=%sysfunc(open(coordfile_&&disease_code&i));
%let num_check2=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));

%if &num_check2 < 2 %then %goto exit;

/* Output disease-specific case and coordinate files */
     data _null_;
           set casefile_&&disease_code&i;
           dummy='1';
         file "&INPUT.\Disease_dropoff_case_&&disease_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
            format lab_clia $50. ;
            format dummy $1.;
            format labdate yymmdds10.;
            put lab_clia $ @;
            put dummy @;
            put labdate;
     run;

	data _null_;
	set coordfile_&&disease_code&i;
		file "&INPUT.\Disease_dropoff_coordinate_&&disease_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
			format lab_clia $50. ;
			format x_coordinate 13.6;
			format y_coordinate 13.6;
			put lab_clia $ @;
			put x_coordinate @;
			put y_coordinate;
	run;

/* Generate disease-specific parameter file and modify batch file */
data _NULL_;  
		startdt=put(&simstart, yymmdds10.);
		EndDt=put(&simend, yymmdds10.);
		file "&INPUT.\Disease_dropoff_parameter_&&disease_code&i.._&TODAY..txt";
		put
			%ParamDx
		file "&SATSCAN.\Dx_Dropoff.bat";
		string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&INPUT.\Disease_dropoff_parameter_&&disease_code&i.._&TODAY..txt"||'"';
		put string;
run;

/* Run SaTScan batch file */
x "&SATSCAN.\Dx_Dropoff.bat"; Run; 

/* read in the SaTScan output */
/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= WORK.OutCol_Disease_&&disease_code&i
            DATAFILE= "&OUTPUT.\Disease_dropoff_output_&&disease_code&i.._&TODAY..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

data OutCol_Disease_&&disease_code&i;
set OutCol_Disease_&&disease_code&i;
length disease_code $4.;
format disease_code $4.;
disease_code= "&&disease_code&i";
label disease_code="Disease Code";
run;

%exit:
%end;

%mend split;
%split

/* Concatenate all disease-specific clusters */
data all_disease_clusters;
set outcol_disease:;
run;

/* Format SaTScan output */
data all_disease_clusters2; 
	set all_disease_clusters;
	cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD, which SAS cannot read. */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8. ;
	drop start_date end_date;
run;

/* Keep disease-level signals that meet these conditions:
If observed = 0 then
1) p-value <= 0.01

If observed ^= 0 then
1) p-value <= 0.01, 2) Observed over Expected ratio <= 0.1 */
data all_disease_clusters3; 
	set all_disease_clusters2;
	avg_expected= (expected/numclusterdays); format avg_expected 8.;
	if 	(observed=0 and p_value <= 0.01)
			or
		(observed^=0 and p_value <= 0.01 and ODE <=0.1);
	drop cluster X Y radius number_loc test_stat Gini_clust;
	rename LOC_ID=CLIA;
run;


/* determine date of last report for labs with signal */
proc sql;
create table disease_last_report as
select distinct a.CLIA,
		a.disease_code,
		b.sendingfacilitynamestd,
		max(b.labdate) as last_report format mmddyy8.
from all_disease_clusters3 as a, all_labs4 as b
where a.CLIA=b.lab_clia and a.disease_code=b.disease_code
group by a.CLIA, a.disease_code;
quit;

proc sort data=disease_last_report nodupkey;
by CLIA disease_code;
run;

/* determine date of last report for labs with signal in ECLRS */
proc sql;
create table disease_last_report_eclrs as
select distinct a.CLIA,
		a.disease_code,
		max(b.labdate) as last_report_eclrs format mmddyy8.
from all_disease_clusters3 as a, eclrs3 as b
where a.CLIA=b.sendingfacilityclia and a.disease_code=b.disease_code
group by a.CLIA, a.disease_code;
quit;

/* calculate # of reports in past year for labs with signal */
proc sql;
create table disease_num_reports as
select distinct a.CLIA,
		a.disease_code,
		count(*) as past_count
from all_disease_clusters3 as a, all_labs4 as b, disease_last_report as c
where a.CLIA=b.lab_clia and a.disease_code=b.disease_code
	and a.CLIA=c.CLIA and a.disease_code=c.disease_code
	and ((a.observed=0 and b.labdate >= (c.last_report-365)) or
		(a.observed^=0 and b.labdate >= (a.clusterstartdate-365)))
group by a.CLIA, a.disease_code;
quit;


/* calculate # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table disease_batch_report as
select distinct a.lab_clia as clia,
		b.disease_code,
		count(distinct a.labdate) as batch
from all_labs4 as a, disease_last_report as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14
group by b.clia, b.disease_code;
quit;

/* calculate # of reports between the date of last report and yesterday for this time last year */
proc sql;
create table disease_count_lastyear  as
select distinct a.lab_clia as clia, a.disease_code, count(*) as lastyear_reports
from all_labs4 as a, disease_last_report as b, all_disease_clusters3 as c
where a.lab_clia=b.CLIA and a.disease_code=b.disease_code and
	a.lab_clia=c.CLIA and a.disease_code=c.disease_code and
	((c.observed=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (b.last_report-364)) or
		(c.observed^=0 and a.labdate <= ("&ytday."d-365) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia, a.disease_code;
quit;

/* join last report in labs table, # of reports, # of report days, */
/* # of reports from concurrent period last year and last report in ECLRS */
proc sql;
create table disease_dropoff_output_final as
select distinct a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		(&todaynum.-b.last_report) as days_since_report,
		case
			/* Suppress signal if number of reports in past year is 12 or less (complete dropoff),
			or lab reported 1 or 2 times in two weeks prior to dropoff (complete dropoff),
			or number of reports in concurrent period last year was less than 5
			or disease is seasonal and dropoff is outside elevated period in seasonal trend */
			when (a.observed=0 and
					(c.past_count<13 or d.batch in(1,2))) or
				e.lastyear_reports <5 or
				(a.disease_code in("FLU","RSV") and month(a.rundate) in(4,5,6,7,8,9,10)) or
				(a.disease_code in("BAB","EHR","HGA","HME","LYM","RMS","WNV") and month(a.rundate) in(10,11,12,1,2,3,4,5))
				then 'Y'
			else 'N'
		end as suppress 
from all_disease_clusters3 a
	left join disease_last_report b on a.CLIA=b.CLIA and a.disease_code=b.disease_code
	left join disease_num_reports c on a.CLIA=c.CLIA and a.disease_code=c.disease_code
	left join disease_batch_report d on a.CLIA=d.CLIA and a.disease_code=d.disease_code
	left join disease_count_lastyear e on a.CLIA=e.CLIA and a.disease_code=e.disease_code
	left join disease_last_report_eclrs f on a.CLIA=f.CLIA and a.disease_code=e.disease_code
/* Keep signal if a complete dropoff and:
	no reports of disease from lab to ECLRS on or after cluster start date */
	where (a.observed=0 and f.last_report_eclrs<a.clusterstartdate
	/* no reports of disease from lab today */
		and a.CLIA ^in(select distinct b.sendingfacilityclia from all_disease_clusters3 a, eclrs3 b
						where a.clia=b.sendingfacilityclia and a.disease_code=b.disease_code
						group by b.sendingfacilityclia, b.disease_code
							having max(labdate)=&todaynum))
	/* or if signal is a partial dropoff */
		or a.observed^=0; 			
quit;




/******** Test type-level Analyses ********/
/* Join with most recent eclrs CLIA file to get standardized lab name */
proc sql;
create table hep_labs2 as
select a.*, b.sendingfacilitynamestd
from hep_labs as a, clia_facilityname as b
where a.lab_clia=b.clia
 and a.lab_clia ^in(select CLIA from hospital_outNYC);;
QUIT;

/* If no standardized facility name use value in lab_name field */
data hep_labs3;
set hep_labs2;
	if sendingfacilitynamestd = " " then sendingfacilitynamestd=lab_name;
run;

/* keep one record for each unique lab/test/accessionnum */
proc sort data=hep_labs3 nodupkey;
by lab_clia test_code specimen_number;
run;

/* set parameters - same for all test types */
proc sql; 
	create table testypeListCurrent as
	select distinct h.test_code,
		30 as lagtime,
		100 as recurrence,
		28 as maxtemp,
		999 as montecarlo,
		365 as baseline
	from hep_labs3 as h
	where h.disease_code
	order by test_code;
quit;

/* Macro variables of analysis parameters for each iteration of analysis */
data _NULL_;
	set testypeListCurrent;
	by test_code;
	if first.test_code then do;
		i+1;
		call symputx ('test_code'||left(put(i,5.)),strip(test_code));
		call symputx ('lagtime'||left(put(i,2.)),lagtime);
		call symputx ('recurrence'||left(put(i,2.)),recurrence);
		call symputx ('endloop' ,left(put(i,3.)));
		call symputx ('maxTemp'||left(put(i,2.)),maxTemp);	
		call symputx ('monteCarlo'||left(put(i,2.)),monteCarlo);
		call symputx ('Baseline'||left(put(i,2.)),baseline);
	end;
run;

%macro splittesttype;
%macro dummy; %mend dummy;

/*macro will loop through each unique test type and analysis parameter setting */
%do i=1 %to &endloop;

	data _null_;
		* START AND END DATE OF ANALYSIS;
		%global simstart;
		  simstart=&todaynum-(&&baseline&i+(&&lagtime&i-1));     /* Start of study period */
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		%global simend;
		  simend  =&todaynum- &&lagtime&i;     				/* End of study period */
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
	run;

proc sql;
create table casefile_&&test_code&i as
select lab_clia, labdate format=yymmdds10., test_code
    from hep_labs3
	where test_code = "&&test_code&i" & labdate >= &simstart & labdate <= &simend;
quit;

/* If no results of test type in study period skip to end of loop */
%let check=%sysfunc(open(casefile_&&test_code&i));
%let num_check=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));

%if &num_check = 0 %then %goto exit ;

/* Dataset with one row per unique CLIA included in analysis */
proc sql;
create table coord_&&test_code&i as
select distinct lab_clia as lab_clia
from casefile_&&test_code&i;
quit;

/* Assign dummy x,y coordinates 10 units apart to each lab */
data coordfile_&&test_code&i (keep= lab_clia x_coordinate y_coordinate);
	set coord_&&test_code&i;
			x_coordinate+10;
			y_coordinate+10;
			if _n_=1 then do;
		        x_coordinate=100000;
		        y_coordinate=100000;
			end;
run;

/* Two or more labs reporting disease in study period required for analysis - else skip to end of loop */
%let check=%sysfunc(open(coordfile_&&test_code&i));
%let num_check2=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));

%if &num_check2 < 2 %then %goto exit;

/* Output disease-specific case and coordinate files */
     data _null_;
           set casefile_&&test_code&i;
           dummy='1';
         file "&INPUT.\Testtype_dropoff_case_&&test_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
            format lab_clia $50. ;
            format dummy $1.;
            format labdate yymmdds10.;
            put lab_clia $ @;
            put dummy @;
            put labdate;
     run;

	data _null_;
	set coordfile_&&test_code&i;
		file "&INPUT.\Testtype_dropoff_coordinate_&&test_code&i.._&TODAY..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
			format lab_clia $50. ;
			format x_coordinate 13.6;
			format y_coordinate 13.6;
			put lab_clia $ @;
			put x_coordinate @;
			put y_coordinate;
	run;

/* Generate disease-specific parameter file and modify batch file */
data _NULL_;  
		startdt=put(&simstart, yymmdds10.);
		EndDt=put(&simend, yymmdds10.);
		file "&INPUT.\Testtype_dropoff_parameter_&&test_code&i.._&TODAY..txt";
		put
			%ParamTestType
		file "&SATSCAN.\Test_Dropoff.bat";
		string='"'||"&SATSCAN.\SatScanBatch.exe"||'" "'||"&INPUT.\Testtype_dropoff_parameter_&&test_code&i.._&TODAY..txt"||'"';
		put string;
run;

/* Run SaTScan batch file */
x "&SATSCAN.\Test_Dropoff.bat"; Run;

/* Col file: One row per identified cluster with following fields: */
/*		Cluster number, Central census tract, X & Y coordinates, radius(ft), cluster start & end dates, */
/*		number of census tracts involved, test statistic, p-value, recurrence interval, observed cases, */
/*		expected cases, observed/expected ratio */
PROC IMPORT OUT= OutCol_testtype_&&test_code&i
            DATAFILE= "&OUTPUT.\Testtype_dropoff_output_&&test_code&i.._&TODAY..col.dbf" 
		    DBMS=DBF REPLACE;
     GETDELETED=NO;
RUN;

data OutCol_testtype_&&test_code&i;
set OutCol_testtype_&&test_code&i;
format test_code $15.;
test_code= "&&test_code&i";
label test_code="Test Code";
run;

%exit:
%end;

%mend splittesttype;
%splittesttype

/* Concatenate all test type-specific clusters */
data all_testtype_clusters;
set outcol_testtype:;
run;

/* Format SaTScan output */
data all_testtype_clusters2; 
	set all_testtype_clusters;
cluster=compress(cluster);
	end_date=compress(end_date);
	start_date=compress(start_date);  
/* The start_date and end_date variables in satscan output are string variables in form YYYY/MM/DD, which SAS cannot read */
	Clusterstartdate=mdy(input(scan(start_date,2,"/"),2.),input(scan(start_date,3,"/"),2.),input(scan(start_date,1,"/"),4.));
	format clusterstartdate mmddyy10.;
	Clusterenddate=mdy(input(scan(end_date,2,"/"),2.),input(scan(end_date,3,"/"),2.),input(scan(end_date,1,"/"),4.));
	format clusterenddate mmddyy10.;
	NumClusterDays=(clusterenddate-clusterstartdate)+1;
	runDate="&today."d; format runDate mmddyy8. ;
	/* Keep test-type clusters that meet the following conditions:
		If observed = 0 then
		1) p-value <= 0.01

		If observed ^= 0 then
		1) p-value <= 0.01, 2) Observed over Expected ratio <= 0.1 */
	if (observed=0 and p_value <= 0.01)
			or
		(observed^=0 and p_value <= 0.01 and ODE <=0.1);
	drop cluster X Y radius number_loc test_stat Gini_clust start_date end_date;
	rename LOC_ID=CLIA ;
run;

/* determine date of last report for labs with signal */
proc sql;
create table testtype_last_report as
select distinct a.CLIA,
		a.test_code,
		b.sendingfacilitynamestd,
		max(b.labdate) as last_report format mmddyy8.
from all_testtype_clusters2 as a, hep_labs3 as b
where a.CLIA=b.lab_clia and a.test_code=b.test_code
group by a.CLIA, a.test_code;
quit;

proc sort data=testtype_last_report;
by CLIA test_code;
run;

/* calculate # of reports in past year for labs with signal */
proc sql;
create table testtype_num_reports as
select distinct a.CLIA,
		a.test_code,
		count(b.labdate) as past_count
from all_testtype_clusters2 as a, hep_labs3 as b, testtype_last_report as c
where a.CLIA=b.lab_clia and a.test_code=b.test_code
	and a.CLIA=c.CLIA and a.test_code=c.test_code
	and ((a.observed=0 and b.labdate >= (c.last_report-365)) or
		 	(a.observed^=0 and b.labdate >= (a.clusterstartdate-365)))
group by a.CLIA, a.test_code;
quit;

/* calculate # of days in two weeks prior to last report date to identify batch reporters */
proc sql;
create table testtype_batch_report as
select distinct a.lab_clia as clia,
				b.test_code,
		count(distinct a.labdate) as batch
from all_labs4 as a, testtype_last_report as b
where a.lab_clia=b.CLIA and
		(b.last_report- a.labdate)>= 0 and (b.last_report- a.labdate) <14
group by b.clia, b.test_code;
quit;

/* calculate # of reports between the date of last report and yesterday for this time last year */
proc sql;
create table testtype_count_lastyear  as
select distinct a.lab_clia as clia, a.test_code, count(*) as lastyear_reports
from hep_labs3 as a, testtype_last_report as b, all_testtype_clusters2 as c
where a.lab_clia=b.CLIA and a.test_code=b.test_code and
	a.lab_clia=c.CLIA and a.test_code=c.test_code and
	((c.observed=0 and a.labdate <= ("&ytday."d-(365+30)) and a.labdate >= (b.last_report-364)) or
		(c.observed^=0 and a.labdate <= ("&ytday."d-(365+30)) and a.labdate >= (c.clusterstartdate-364)))
group by a.lab_clia, a.test_code;
quit;

/* join last report in labs table, # of reports, # of report days, */
/* # of reports from concurrent period last year */
proc sql;
create table testtype_dropoff_output_final as
select a.*,
		b.*,
		c.*,
		d.*,
		e.*,
		(&todaynum.-b.last_report) as days_since_report,
		case
			/* Suppress signal if number of reports in past year is 12 or less (complete dropoff),
			or lab reported 1 or 2 times in two weeks prior to dropoff (complete dropoff),
			or number of reports in concurrent period last year was less than 5 */
			when (a.observed=0 and
					(c.past_count<13 or d.batch in(1,2))) or
				e.lastyear_reports <5
				then 'Y'
			else 'N'
		end as suppress 
from all_testtype_clusters2 a
	left join Testtype_last_report b on a.CLIA=b.CLIA and a.test_code=b.test_code
	left join testtype_num_reports c on a.CLIA=c.CLIA and a.test_code=c.test_code
	left join testtype_batch_report d on a.CLIA=d.CLIA and a.test_code=d.test_code
	left join testtype_count_lastyear e on a.CLIA=e.CLIA and a.test_code=e.test_code
/* Keep signal if a complete dropoff and no reports of disease from lab in lag period */
where (a.observed=0 and a.CLIA ^in(select distinct b.lab_clia from testtype_last_report a, hep_labs3 b
									where a.clia=b.lab_clia and a.test_code=b.test_code
									group by b.lab_clia, b.test_code
										having max(labdate)>=(&todaynum-30)))
/* or partial dropoff */
		or a.observed^=0; 			
quit;



data all_clusters_final (drop=disease_code test_code ode);
set lab_dropoff_output_final (in=a) disease_dropoff_output_final (in=b) testtype_dropoff_output_final (in=c);
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

/* The current week will be compared against signals identified in previous week to determine if a signal is new */
proc sql;
select max(rundate)
	into :lastweek
	from support.clusterhistory_dropoff_all;
create table last_week_linelist as
	select * 
	from support.clusterhistory_dropoff_all
	where rundate=&lastweek and suppress= 'N';
quit;

/* assign new_dropoff indicator to new events */
proc sql;
create table all_clusters_final_new as
select distinct a.*,
	CASE 
		when a.CLIA=b.CLIA and
			a.type=b.type and
			a.detail=b.detail
		then 'no'
		else 'yes'
	end as new_dropoff
from all_clusters_final a left join last_week_linelist b
	on a.CLIA=b.CLIA and a.type=b.type and a.detail=b.detail;
quit;
	
/* Append cluster details to clusterhistory file */
proc append base=support.Clusterhistory_dropoff_all data=all_clusters_final_new ;run;
proc sort data= support.Clusterhistory_dropoff_all; by rundate; run;

