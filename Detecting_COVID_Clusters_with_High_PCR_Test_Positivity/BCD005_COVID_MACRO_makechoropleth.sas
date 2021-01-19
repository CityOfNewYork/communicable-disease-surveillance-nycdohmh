/* Start creating RTF output and print choropleth map first */

%macro MakeChoropleth;
%macro dummy; %mend dummy;

/* Open word file for output */
ods listing close;

ods path(prepend) work.templat(update);

proc template;
   define style styles.blackbordercolor;
   parent=styles.meadow;
      class usertext from usertext /
         bordertopcolor=white
         borderbottomcolor=white
         borderleftcolor=white
         borderrightcolor=white;
	class data /
		borderleftcolor=black
		bordertopcolor=black
		borderrightcolor=black
		borderbottomcolor=black;
   class Header   /                                              
		bordertopcolor = cxffffff
		borderleftcolor = cxffffff 
		borderrightcolor = cxffffff
		borderbottomcolor=black
		backgroundcolor = cxffffff;
	class GraphAxisLines /
      contrastcolor = black
      color = black;
	class GraphValueText /
      color = black;
	class GraphBorderLines /
      contrastcolor = black;
	class graphwalls / frameborder=off;
   end;
run;

/* For in-line formatting */
ods escapechar='^';

ods rtf body = "&ARCHIVE.&today.\satscan_COVID_&&analysis_print&i.._&today..rtf";
ods rtf file = "&ARCHIVE.&today.\satscan_COVID_&&analysis_print&i.._&today..rtf";

ods rtf style=styles.blackbordercolor;
ods rtf startpage=no;

/* Set options and title statements */
goptions reset=goptions device=png300 target=png300 ftext='Calibri' ftitle='Calibri/bold' htitle=2 xmax=8.5 in ymax=6.7 in;	
title1 height=1.5 "COVID-19 percent positivity clusters, RR>=&&rr_threshold&i, with specimen collection dates through &Simendformat";
title2 height=1.3 "Confirmed cases";


/* Set map patterns by # of clusters included on map (including non-cluster area) */
%global max_pattern;
proc sql noprint;
create table map_patterns as
select distinct cluster,
				case
					when cluster=99 then "CXECEDEC"
					else "CXFC8D59"
				end as pattern
from RemoveRecurrence5;
select max(monotonic()) into :max_pattern trimmed
from map_patterns;
quit;

%do k=1 %to &max_pattern;
%global pattern&k.;
%end;

proc sql noprint;
select distinct strip(pattern)
	into :pattern1-:pattern&max_pattern
from map_patterns
order by cluster;
quit;

/* Set patterns */
%do k=1 %to &max_pattern;
pattern&k. value=msolid color=&&pattern&k..;
%end;

data annotate_num; 
	set clusterhistory;
	length function $ 6 style $ 8 color $ 8 text $ 50;
	retain xsys ysys '2' hsys '3' when 'a';
	function='label'; style='arial'; text='+'; size=1; cborder='ctext';
	color = "CX000000";
	text = strip(cluster);
run;

%if &&analysis&i in(stp stp_long stp_nonpar stp_spatial) %then %do;
	%let analysis_option=poisson-based;
%end;


/* Set footnotes */
OPTIONS NOCENTER  nonumber  ls=140 ps=51 nodate;
footnote1 font='Arial' justify=left height=0.8 "Statistic: Prospective space-time &analysis_option scan statistic   Spatial resolution: census 2010 tracts   Study period: &&studyperiod&i days";
footnote2 font='Arial' justify=left height=0.8 "Minimum temporal cluster size (days): &&mintemp&i    Maximum temporal cluster size (days): &&maxtemp&i";
%if &&restrictspatial&i=n & &&setrisklimit&i= y %then %do;
footnote3 font='Arial' justify=left height=0.8 "Maximum spatial cluster size (% of persons tested): &&maxgeog&i    Restrict clusters to relative risk >= &&rr_threshold&i";
%end;
%if &&restrictspatial&i=y %then %do;
footnote3 font='Arial' justify=left height=0.8 "Maximum spatial cluster size (% of persons tested): &&maxgeog&i    Maximum spatial cluster size as distance from cluster center: &&maxspatial&i";
%end;
footnote4 font='Arial' justify=left height=0.8 "Inference method: Default p-value    Maximum number of Monte Carlo simulations: &&montecarlo&i";
footnote5 font='Arial' justify=left height=0.8 "Only recurrence interval >= &&recurrence&i days are shown    Criteria for reporting secondary clusters: no cluster center in other clusters";
footnote6 font='Arial' justify=left height=0.8 "Secondary clusters with no unique cases are displayed on the map but suppressed from cluster summary tables.";
footnote7 font='Arial' justify=left height=0.8 "Time aggregation (days)= &&timeagg&i    Adjusted for space by day-of-week interaction= &&weeklytrends&i.";
%if &&analysis&i in(stp stp_long) %then %do;
footnote8 font='Arial' justify=left height=0.8 "Adjusted for purely spatial variation non-parametrically and for log-linear purely temporal trend";
%end;
%if &&analysis&i in(stp_nonpar) %then %do;
footnote8 font='Arial' justify=left height=0.8 "Adjusted for purely temporal variation non-parametrically";
%end;

/* Generate map in output */
proc gmap map=RemoveRecurrence5 data=RemoveRecurrence5 anno=annotate_num; 
	id cluster;
	choro cluster/ levels=&max_pattern
	coutline=gray
		CDEFAULT = white	
		cempty=blue
		cempty=black
		nolegend;
run; 
quit;
%mend MakeChoropleth;