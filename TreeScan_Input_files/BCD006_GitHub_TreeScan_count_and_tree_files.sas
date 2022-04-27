*********************************************************;
* create and save count and tree input files for TreeScan; 
*********************************************************;
* 1. Format sample data and aggregate by lineage and date
* 2. Export count file for TreeScan analysis
* 3. Prepare and export tree file for TreeScan analysis
*********************************************************;
libname save "\\...\Input files for GitHub";

data GitHub_sample_data;
set save.BCD006_GitHub_sample_data;
run;

/* Inspect data before generating input files - study period for sample data is Jan 1-31, 2022 */
proc freq data=GitHub_sample_data;
tables collection_date lineage;
run;

/* aggregate count on lineage and specimen collection date */
proc sql;
create table GitHub_sample_count as
select distinct lineage,
				collection_date format mmddyy10.,
				count(*) as count
from GitHub_sample_data
group by lineage, collection_date;
quit;

/* Save source dataset for count */
data save.BCD006_GitHub_sample_count;
set GitHub_sample_count;
run;

/* export count dataset for treescan analysis */
proc export data=GitHub_sample_count
	outfile="\\...\Input files for GitHub\BCD006_GitHub_sample_count_file.txt" replace; putnames=no;
run;

/* Create Tree file for TreeScan */
*********************************************;
/* For first iteration of tree file select all lineage values with cases and define parent by removing last node in lineage */
proc sql;
	create table all_lineages as
	select distinct lineage, substr(lineage,1,length(lineage)-length(scan(lineage,-1,'.'))-1) format=$20. as parent
	from GitHub_sample_count
	order by parent;
quit;

/* Need to define relationships between branches/nodes if not indicated in lineage */
/* e.g. in sample data, A is the parent of B, but that relationship is not encoded in the lineage values */
data tree;
	set all_lineages;
	/* A serves as base of tree so set parent to null */
	if lineage = "A" then parent = "";
	if lineage = "B" then parent = "A";
run;

/* set unknown count macro variable to a non-zero value prior to running macro */
%let unknown_count=1;

/* Tree file must include all nodes between base and every populated node */
/* This macro will identify additional intermediate nodes between defined parents and base of tree */
%macro unknown_parents;
%macro dummy; %mend dummy;

/* find unknown parent nodes - repeat until unknown_parents dataset is empty */
%do %while (&unknown_count^=0);

proc sql;
	create table lineages as select lineage from tree order by lineage;
quit;
proc sql;
	create table parents as select parent as lineage from tree order by parent;
quit;
data unknown_parents;
	merge parents (in=a) lineages (in=b);
	by lineage;
	if a & ~b & lineage ~= "";
	parent = substr(lineage,1,length(lineage)-length(scan(lineage,-1,'.'))-1);
	if lineage = "A" then parent = "";
	if lineage = "B" then parent = "A";
run;

/* Count number of rows in unknown parents dataset */
%let dsid=%sysfunc(open(unknown_parents));
%let unknown_count=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));

	%if &unknown_count^=0 %then %do;

		data tree;
			set tree unknown_parents;
		run;

	%end;

%end;

%mend unknown_parents;

%unknown_parents;

/* Remove any duplicate parent-child node pairings */
proc sort data=tree nodup; by lineage parent; run;

/* export tree dataset for treescan analysis */
proc export data=tree
	outfile="\\...\Input files for GitHub\BCD006_GitHub_sample_tree_file.txt" replace; putnames=no;
run;

/* save source dataset for tree */
data save.BCD006_GitHub_sample_tree;
	set tree;
run;
