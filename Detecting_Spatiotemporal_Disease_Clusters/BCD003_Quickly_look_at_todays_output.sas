%LET SUPPORT		=...\SaTScan\SupportingFiles\;

libname support "&SUPPORT.";

title "SaTScan v.9.4";
proc print data=support.BCD003_Clusterhistory_94;
	where rundate=today();
run;

/*Address cleaning*/
title "Addresses with bubble-up problems, for cleaning in Maven";
proc print data=support.BCD003_not_merged;
run;

title "Previously geocoded addresses for cleaning in Maven";
proc print data=support.BCD003_previously_geocoded;
where new ne " ";
run;

/*Run this code after cleaning events with previously geocoded addresses:*/
/*
data support.previously_geocoded;
set support.previously_geocoded;
     new=" ";
run;
*/
