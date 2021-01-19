/* Export person linelist into excel file */

%macro MakePersonLineList;
%macro dummy; %mend dummy;

proc printto log="&ARCHIVE.logs\Satscan_COVID_&today._output_loop&i..txt"; run; 

proc sql;
create table linelist_export as
select primary_cluster label='Primary Cluster',
		secondary_cluster label='Secondary Cluster',
		new label='New',
		interview_status label='Interview status',
		eventid label='Event ID',
		event_date label='Diag date',
		symptomatic label='Symptoms',
		age label='Age',
		sex label='Sex', 
		race_ethnicity label='Race/Ethnicity',
		nocc_name label='NOCC',
		censustract label='Census Tract'
from linelist4
order by primary_cluster, secondary_cluster, nocc_name, censustract;
quit;

	proc export data = linelist_export
		outfile = "&ARCHIVE.&today\satscan_COVID_spacetime_&&analysis_print&i.._linelist_&today..xlsx"
		dbms = xlsx replace label;
		sheet = "Cluster events";
	run;

%mend MakePersonLineList;