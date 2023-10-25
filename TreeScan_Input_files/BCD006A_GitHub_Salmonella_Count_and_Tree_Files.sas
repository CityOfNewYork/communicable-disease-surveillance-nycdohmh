/* Generating tree file using sample SAL data */

/* sample data library */
libname saldata "...\TreeScan";

/* aggregate case counts by allele code and isolation date */
proc sql;
	create table case_count as
	select distinct *,
			count(*) as cases
	from saldata.bcd006a_github_salmonella_data
	group by allele_code, isolation_date;
quit;

/* Generate case input text file */
proc export data=case_count
	outfile="...\TreeScan\BCD006A_GitHub_Salmonella_Count_File.txt" replace; putnames=no; run;

/* Define first level of parent nodes for nodes with cases */
proc sql;
	create table tree as
	select distinct allele_code, substr(allele_code,1,length(allele_code)-length(scan(allele_code,-1,'.'))-1) format=$50. as parent
	from saldata.Sal_sample_data
	order by parent;
quit;

/* set as non-zero value so loop is executed at least once */
%let unknown_count=1;


%macro unknown_parents;
%macro dummy; %mend dummy;

/* find unknown parent nodes - repeat until unknown_parents dataset is empty */
%do %while (&unknown_count^=0);

/* select existing nodes and parents */
proc sql;
	create table allele_codes as select allele_code from tree order by allele_code;
quit;
proc sql;
	create table parents as select parent as allele_code from tree order by parent;
quit;

/* evaluate for missing connections between parents and root, define additional level of parent nodes */
data unknown_parents;
	merge parents (in=a) allele_codes (in=b);
	by allele_code;
	if a & ~b & allele_code ~= "";
	parent = substr(allele_code,1,length(allele_code)-length(scan(allele_code,-1,'.'))-1);
	if allele_code="SAL" then parent=" ";
run;

/* Count number of rows in unknown parents dataset */
%let dsid=%sysfunc(open(unknown_parents));
%let unknown_count=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));

/* if any new node/parent connections append to tree dataset */
	%if &unknown_count^=0 %then %do;

		data tree;
			set tree unknown_parents;
		run;

	%end;

/* if all connections between root, parents, and leaves are established loop will end */

%end;

%mend unknown_parents;

%unknown_parents;

/* eliminate duplicate pairs */
proc sql;
create table tree_final as
select distinct *
from tree
where allele_code^=parent;
quit;

/* Generate tree input text file */
proc export data=tree_final
	outfile="...\TreeScan\BCD006A_GitHub_Salmonella_Tree_File.txt" replace; putnames=no; run;

