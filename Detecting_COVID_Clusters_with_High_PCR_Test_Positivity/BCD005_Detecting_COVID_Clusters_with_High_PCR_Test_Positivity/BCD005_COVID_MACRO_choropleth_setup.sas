/* Set up the data for the map with this macro */

%macro CHOROPLETH_setup;
%macro dummy; %mend dummy;

/* read in NYC census tracts from shapefile */
proc mapImport DATAFILE="&SUPPORT.BCD005_nyct2010.shp"  
	out=CityCensusTracts;
run;

data CityCensusTracts;
	set CityCensusTracts;
	rename geoid=tract;
run;

proc sql;
create table cluster_tracts as
	select *
	from outgis3
	where recurr_int>=&&recurrence&i;
quit; 

/* Merge all NYC census tracts with associated cluster and recurrence interval */
proc sort data=citycensustracts; by tract segment; run;
proc sort data=cluster_tracts out=outgis4 nodupkey; by tract; run;
proc sql; 
	create table RemoveRecurrence1 as 
	select ct.*
		,og.cluster
		,og.recurr_int
	from citycensustracts as ct
	left join outgis4 as og
	on ct.tract = og.tract;
quit;
/* If census tract is not part of a cluster label as cluster 99 for mapping purposes */  
data RemoveRecurrence2; 
	set RemoveRecurrence1;
	if recurr_int<&&recurrence&i then cluster=99;
	if x ^=.;
run;

/* "proc gremove" eliminates borders between census tracts that share cluster affiliation */
proc sort data=RemoveRecurrence2 out=RemoveRecurrence3; by cluster tract; run;
proc gremove data=RemoveRecurrence3 out=RemoveRecurrence4;
	by cluster;
	id tract;
run;
data RemoveRecurrence5; 
	set RemoveRecurrence4;
	ClusterMap=0;
	if cluster ^= 99 then Clustermap=cluster;
run;

%mend choropleth_setup;
