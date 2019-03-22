/************************************************************************************************/
/*	PROGRAM NAME: BCD003_Satscan94Analysis									 					*/
/*	DATE CREATED: 2017																			*/
/*	LAST UPDATED: 3/22/2019																		*/
/*	 PROGRAMMERS: Deborah Kapell                                         						*/
/*                 Eric Peterson                                                				*/
/*                  				                                                 			*/
/*		 PURPOSE: Runs SaTScan analysis for all specified diseases								*/
/*		 		  using satscan v9.4, space-time permutation                   	 				*/
/************************************************************************************************/

/* delete today's lines from archived datasets if this is rerun on the same day */
proc sql;
delete * from support.BCD003_satscanlinelist_94
where rundate=&todaynum;
quit;
proc sql;
delete * from support.BCD003_clusterhistory_94
where rundate=&todaynum;
quit;

/* Make filter for diseases evaluated by SaTScan */
proc sql;
	select distinct quote(strip(disease_code))
	into :satscan_diseases separated by ","
	from support.BCD003_diseaselist;
quit;

/* Max value of baseline+lagtime gives cutoff for initial data pull */
proc sql;
	select max(baseline+(lagtime-1))
	into :maxstudyperiod
	from support.BCD003_diseaselist;
quit;

/*  Pull events of disease of interest from AOW events table, excluding:  			*/
/*		1. Non-NYC addresses					   									*/
/*	`	2. Contacts and possible exposures 		   									*/
/*		3. Unresolved LEG & ZIK cases			   									*/
/*		4. LEG cases from past outbreaks 		   									*/
/*		5. STEC cases with Multiplex PCR-based test only 	   						*/
/*		6. Events outside the maximum study period window							*/
/*		7. Nosocomial or travel-related exposures									*/
data events_pre;
set maven.dd_aow_events;
	where disease_code in(&satscan_diseases) and
		(((disease_code not in("LEG","RMS","ZIK") and disease_status_final not in('CONTACT', 'POSSIBLE_EXPOSURE'))
		or (disease_code in("LEG") and disease_status_final not in('CONTACT', 'POSSIBLE_EXPOSURE', 'UNRESOLVED'))
				or (disease_code="RMS" and disease_status_final in('CONFIRMED', 'PROBABLE', 'SUSPECT'))
				or (disease_code="ZIK" and disease_status_final in('CONFIRMED', 'PROBABLE')))
			and datepart(event_date)>=(&todaynum-&maxstudyperiod));
	event_date=datepart(event_date);
	format event_date mmddyy10.;
	if CENSUS_TRACT_2000^=" " then CENSUS_TRACT_2000_NUM=input(CENSUS_TRACT_2000,??BEST12.);
/* Removing LEG cases from period of Outbreak A */
	if disease_code="LEG" and event_date>='08JUL2015'd and event_date<='03AUG2015'd then delete;
/* Removing LEG cases in Facility A */
	if disease_code="LEG" and event_id in("100308152","100308722","100310829","100310830",
										  "100310831","100311061","100313746") then delete;
/* Removing LEG cases from period of Outbreak B */
	if disease_code="LEG" and event_date>='25APR2015'd and event_date<='15MAY2015'd then delete;
/* Removing LEG cases from period of Outbreak C */
	if disease_code="LEG" and event_date>='04NOV2014'd and event_date<='31DEC2014'd then delete;
/* Removing LEG cases from period of Outbreak D */
	if disease_code="LEG" and event_date>='14SEP2015'd and event_date<='21SEP2015'd then delete;
/* Removing travel-associated GIA cases */
	if disease_code="GIA" and event_id in("100444872","100444873","100445227","100513779") then delete;
/* Removing 3 nosocomial LEG cases */
	if disease_code="LEG" and event_id in("100455186","100459777","100455523") then delete;
	format type $10.;
	type="Home";
/* Exclude events that are out of jurisdiction */
	if boro not in ('OUTSIDE NYC');
run;

/**** This section excludes events meeting disease specific criteria or with only negative results ****/
/**** All or part of this section could be removed with minor changes to downstream code ****/

/* LEG tests other than serology */
data leg_tests_excl_serology;
set maven.dd_aow_labs;
	where disease_code="LEG" and
		prxmatch("m/(IGG|IGM|ANTIBODY|SEROLOGY)/i",test_name)=0;
run;


/* To exclude events with only negative results - pull all results */
proc sql;
create table all_labs as
	select distinct event_id,
			upcase(strip(result_name)) as result_name
	from maven.dd_aow_labs
	where event_id in(select event_id from events_pre);
quit;

/* determine max number of results per event */
proc sql;
select strip(put(max(lab_count),8.))
into :max_results
from (select count(*) as lab_count from all_labs
		group by event_id);
quit;

/* transpose to wide format */
proc transpose data=all_labs out=all_labs_wide;
	by event_id;
	var result_name;
run;

/* Check all results for string "NEGATIVE" (except GRAM NEGATIVE) and code as negative=0, else =1 */
/* Sum 1/0 variable across all results - if all results are negative and not missing then keep */
%macro neg_results;
%macro dummy;%mend dummy;
/* Concatenate unique tests */
data neg_results_only (keep = event_id all_results);
set all_labs_wide;
	format all_results $500.;
	%do i=1 %to &max_results;
		if index(col&i.,"NEGATIVE")>0 and index(col&i.,"GRAM NEGATIVE")=0 then neg&i.=0;
		else if col&i.=" " then neg&i.=0;
		else neg&i.=1;
	%end;
	all_neg=sum(of neg1-neg&max_results);
	all_results = catx('; ',of col:);
	if all_neg=0 and all_results^=" ";
run;
%mend neg_results;

%neg_results


/* Keep only Encephalitis events reported by providers via Electronic Universal Reporting Form (EURF)  */
proc sql; 
	create table enp_rc as
	select distinct event_id
	from maven.dd_aow_reports 
	where event_id in(select distinct event_id from events_pre) and
		reporting_method='EURF' and disease_code='ENP'
	order by event_id;
quit;

/* Keep only LYM events will no indication of travel outside jurisdiction */
proc sql;
create table lym_notravel as
select distinct event_id
from maven.dd_lym_travel
where event_id in(select distinct event_id from events_pre) and
		TRAVEL_OUTSIDE_COUNTRY ="No" and TRAVEL_OUTSIDE_CITY ="No";
quit;

/* Apply disease-specific exclusions for ENP, LEG, LYM and remove events with only negative results */
proc sql;
create table events as
select *
	from events_pre
	where (disease_code^in("ENP" "LYM" "LEG") or
			(disease_code="ENP" and event_id in(select distinct event_id from enp_rc)) or 
			(disease_code="LEG" and disease_status_final^="PENDING") or
			(disease_code="LEG" and disease_status_final="PENDING" and
				event_id in(select distinct event_id from leg_tests_excl_serology)) or
			(disease_code="LYM" and event_id in(select distinct event_id from lym_notravel)))
			and event_id^in(select event_id from neg_results_only);
quit;

/**** End of disease specific and negative results exclusions ****/



/****	This section evaluates events for successful geocoding, and if not geocoded 			****/
/****	looks for a geocoded secondary address to replace the primary address					****/
/****	These lines could be removed without affecting the functioning of the code				****/

/* Pull all geocoded secondary addresses for people that have event in "events" dataset */
/*	where the geocoding status is not pending */
	proc sql;
	create table all_secondary_addresses as
		select distinct a.party_id,
						b.*,
						case
							when type_disp="Home" then 0
							when type_disp="Home (Secondary)" then 1
							when type_disp="Work" then 2
							when type_disp="Work (Secondary)" then 3
							when type_disp="Other" then 4
						end as hierarchy
		from events a, maven.DD_ADDRESS_HISTORY b
		where a.party_id=b.party_id
			and (index(type_disp,"Work")>0 or index(type_disp,"Home")>0 or type_disp="Other")
			and b.CUSTOM_FIELD1^=" " and b.CUSTOM_FIELD2^=" " and b.geocode_status_disp^="Pending";
	quit;
/* Keep secondary addresses that are not Primary home addresses if */
/*	current address in "events" dataset is not geocoded */
	proc sql;
	create table secondary_addresses as
		select distinct b.*
		from events a, all_secondary_addresses b
		where a.party_id=b.party_id and b.type_disp^="Home" and
			a.x_coord is missing and a.y_coord is missing;
	quit;
	proc sort data=secondary_addresses;by party_id hierarchy descending end_date;run;
/* Keep most recent geocoded secondary address for each party, prioritizing secondary home, */
/*	primary work, secondary work, and other. Format to match fields in "events" dataset */
	data secondary_address (keep=party_id x_coord y_coord lat long street_1 street_2 city state boro zip country uhf bin block
						community_district rpad_building_class CENSUS_TRACT_2000 CENSUS_TRACT_2000_NUM CENSUS_TRACT_2010 hierarchy);
	set secondary_addresses;
		by party_id hierarchy descending end_date;
		if first.party_id;
		rename CUSTOM_FIELD1=x_coord;
		rename CUSTOM_FIELD2=y_coord;
		format lat $50.;
		format long $50.;
		lat=strip(put(latitude,best12.));
		long=strip(put(longitude,best12.));
		rename street1=street_1;
		rename street2=street_2;
		format boro $50.;
		if county="Kings County (Brooklyn)" then boro="BROOKLYN";
		if county="Queens County (Queens)" then boro="QUEENS";
		if county="Richmond County (Staten Island)" then boro="STATEN ISLAND";
		if county="Bronx County (Bronx)" then boro="BRONX";
		if county="New York County (Manhattan)" then boro="MANHATTAN";
		rename POSTAL_CODE_PREFIX=zip;
		rename CUSTOM_FIELD6=uhf;
		CENSUS_TRACT_2000_NUM=input(tract,??BEST12.);
		rename tract=CENSUS_TRACT_2000;
		rename custom_field3=CENSUS_TRACT_2010;
		rename custom_field4=BIN;
		rename custom_field5=community_district;
		rename custom_field7=rpad_building_class;
	run;

/* Count number of secondary addresses to be added to events dataset */
%let sec_add=%sysfunc(open(secondary_address));
%let num_secondary_address=%sysfunc(attrn(&sec_add,nobs));
%let end=%sysfunc(close(&sec_add));

/* Macro to replace non-geocoded address at time of report with geocoded secondary address elements if any exist */
%macro add_secondary_address (data1,data2);
%macro dummy; %mend dummy;
%if &num_secondary_address > 0 %then %do;
	proc sort data=&data1;by party_id;run;

/* Add geocoded work address fields to events in place of address at time of report that did not geocode */ 
	data &data1 (drop=hierarchy);
	merge &data1 (in=a) &data2 (in=b);
		by party_id;
		if boro not in ('OUTSIDE NYC' 'NA');
		if a and b and hierarchy = 1 then type = "Other Home";
		if a and b and hierarchy in(2,3) then type = "Work";
		if a and b and hierarchy = 4 then type = "Other";
	run;
%end;
%mend add_secondary_address;

/* Run macro with specific datasets */
%add_secondary_address(events,secondary_address);

/**** End of secondary address section ****/

/**** Import coordinate files ****/

/* Import x/y coordinate file */
PROC IMPORT OUT= WORK.NYcoord 
            DATAFILE= "&SUPPORT.BCD003_TractNYCoord.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=NO;
     DATAROW=1; 
RUN;

/* rename and reformat X/Y coordinate variables */
data nycoord_rename (keep=loc_id x_coord y_coord);
set nycoord;
	format loc_id $11.;
	format x_coord $50.;
	format y_coord $50.;
	loc_id=strip(put(var1,best12.));
	x_coord=strip(put(var2,z7.0));
	y_coord=strip(put(var3,z7.0));
run;

proc sort data=nycoord_rename;
	by loc_id;
run;

/* import lat/long coordinate file */
PROC IMPORT OUT= WORK.NYlatlong 
            DATAFILE= "&SUPPORT.BCD003_LatLongCoord.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=NO;
     DATAROW=1; 
RUN;

/* rename and reformat lat/long variables */
data nylatlong_rename (keep=loc_id lat long);
set nylatlong;
	format loc_id $11.;
	format lat $50.;
	format long $50.;
	loc_id=strip(put(var1,best12.));
	lat=strip(put(var2,best12.));
	long=strip(put(var3,best12.));
run;

proc sort data=nylatlong_rename;
	by loc_id;
run;

/* merge xy and latlong by census tract */
data ny_coord_latlong;
merge nycoord_rename nylatlong_rename;
	by loc_id;
run;


/* This step creates a dataset of diseases and unique analysis parameters that have at least one event in the active scanning window */
/* This will be used to create macro variables for performing seperate SaTScan analyses by unique disease-parameter combinations */
proc sql; 
	create table diseaseListCurrent as
	select distinct m.disease_code
		,s.recurrence
		,s.mintemp
		,s.maxtemp
		,s.maxgeog
		,s.baseline
		,s.montecarlo
		,s.lagtime
		,s.agegroup
		,s.restrictspatial
		,s.maxspatial
		,s.timeagg
		,s.weeklytrends
	from events as m
		,support.BCD003_diseaselist as s
	where m.disease_code = s.disease_code
	and event_date >=intnx('day',&todaynum,-((maxtemp-1)+lagtime)) and
			event_date <=intnx('day',&todaynum,-lagtime)
	group by m.disease_code,s.recurrence,s.maxtemp,s.maxgeog,s.baseline,
			s.montecarlo,s.lagtime,s.agegroup,s.restrictspatial,s.timeagg
		having max(CENSUS_TRACT_2000_NUM)^=.
	order by disease_code;
quit;

/* create macro variables to loop through */
data _NULL_;
	set diseaseListCurrent;
	by disease_code maxTemp agegroup recurrence;
	if first.disease_code | first.maxTemp | first.agegroup then do;
		i+1;
		call symputx ('disease_code'||left(put(i,5.)),strip(disease_code));
		call symputx ('lagtime'||left(put(i,5.)),lagtime);
		call symputx ('recurrence'||left(put(i,5.)),recurrence);
		call symputx ('endloop' ,left(put(i,5.)));
		call symputx ('minTemp'||left(put(i,5.)),minTemp);	
		call symputx ('maxTemp'||left(put(i,5.)),maxTemp);	
		call symputx ('maxGeog'||left(put(i,5.)),maxGeog);
		call symputx ('monteCarlo'||left(put(i,5.)),monteCarlo);
		call symputx ('Baseline'||left(put(i,5.)),baseline);
		call symputx ('agegroup'||left(put(i,5.)),agegroup);
		call symputx ('restrictspatial'||left(put(i,5.)),restrictspatial);
		call symputx ('maxspatial'||left(put(i,5.)),maxspatial);
		call symputx ('timeagg'||left(put(i,5.)),timeagg);
		call symputx ('weeklytrends'||left(put(i,5.)),weeklytrends);
	end;
run;

/* Run SaTScan analyses, looping through unique disease-analysis parameter iterations */
/* This is where all the macros read in from the SaTScan94Macros code are called */
/* The "RunProgram" macro loops once for each line of the "diseaselistCurrent" dataset */
%macro RunProgram;
%macro dummy; %mend dummy;		
%do i=1 %to &endloop;
	data _null_;
		/* START AND END DATE OF ANALYSIS - set using disease-specific parametes for study period, */
		/*	maximum temporal window, and lag time */
		%global simstart;
		  simstart=&todaynum-(&&baseline&i+(&&lagtime&i-1));     /* First date analyzed in simulation */
		  call symputx('simstart',simstart);
		  call symputx('SimStartFormat',put(simstart,date7.));
		%global simend;
		  simend  =&todaynum- &&lagtime&i;     				/* Last date analyzed in simulation */
		  call symputx('simend',simend);
		  call symputx('SimEndFormat',put(simend,worddate18.));
		%global simActive;
		  simActive = (&todaynum- &&lagtime&i)- (&&maxtemp&i-1);	/* First date of active window */
		  call symputx('simactive',simactive);
		  call symputx('SimActiveFormat',put(simactive,date7.)); 
	run;

/* some additional formatting before outputting for analysis in satscan */
	data maven_events;
		set events (keep=event_id party_id event_date disease_code disease disease_status_final street_1 x_coord y_coord  
			lat long BORO FIRST_NAME LAST_NAME INVESTIGATION_STATUS event_date GENDER AGE UHF zip census_tract_2000 type);
		mintemp = &&mintemp&i;
		maxtemp = &&maxtemp&i;
		agegroup = "&&agegroup&i";
		x=input(x_coord,8.);
		y=input(y_coord,8.);
		if disease_code = "&&disease_code&i";
		if "&&agegroup&i" = "AllAges" then output;
		if "&&agegroup&i" = "Under5" then do;
			if age < 5 & age ~= . then output;
		end;
		if "&&agegroup&i" = "5to18" then do;
			if age >= 5 & age <= 18 then output;
		end;
		if "&&agegroup&i" = "Under18" then do;
			if age < 18 & age ~= . then output;
		end;
	run;

/*  Pull events from maven_events table that fall in study window and:	*/
/*		1.  Recode Boro and Patient Initials	*/
/*		2.  Format day of week and census tract fields for SaTScan file	*/
	proc sort data = maven_events; by disease_code maxtemp agegroup; run;
	data SatScan1 notgeocoded;
		merge maven_events diseaseListCurrent;
		by disease_code maxtemp agegroup;
		if disease_code = "&&disease_code&i" & event_date >= &simstart & event_date <= &simend;
	/* Removing LEG cases from period of Outbreak E if they are outside the maximum temporal window */
		if disease_code="LEG" and event_date>='26JUN2018'd and event_date<='15JUL2018'd
			and event_date<today()-&&maxtemp&i then delete;
		active = "no ";
		if event_date>="&simActive" then active='yes';
		diseaseName = compress(disease);
		call symput('DiseaseName',diseaseName);
		attrib PtInit length= $5.;
		PtInit = compress(substr(first_name,1,1)||substr(last_name,1,1));
	/* If census tract is missing then output for evaluation of any previously geocoded addresses */
		if census_tract_2000 ='' then output notgeocoded;
	/* If census tract is useable then keep for analysis */
		if census_tract_2000 ^='' then do;
	/* Assign state code for use in making 11 digit census tract identifier */
			StateNum=strip('36');
		/* Marble Hill */
			if index(census_tract_2000,'309')~=0 and boro='BRONX' then Boro='MANHATTAN';
		/* Rikers Island men's jails */
			if census_tract_2000 in ('   1','000100') and zip='11370' then Boro='BRONX';
	/* Assign county code for use in making 11 digit census tract identifier */
			if boro = 'BRONX' then BoroCode=strip('005');
			if boro = 'QUEENS' then BoroCode=strip('081');
			if boro = 'BROOKLYN' then BoroCode=strip('047');
			if boro = 'MANHATTAN' then boroCode=strip('061');
			if boro = 'STATEN ISLAND' then borocode=strip('085');
	/* Make 11 digit census tract identifier by compiling state, county, tract fields */
			if prxmatch("m/\d\d\d\d\d\d/i",census_tract_2000)>0 then do;
				CensusTract = substr(compress(stateNum||BoroCode||census_tract_2000),1,11);
			end;
			if censustract=" " then delete;
	/* Drop individual state, county, tract fields */
			drop census_tract_2000 borocode statenum;
			output SatScan1;
		end;
	run;

/* If an event failed to geocode but had a previous home address that */
/*	geocoded successfully add to a list for QA */
	proc sql;
	create table previously_geocoded as
		select distinct a.event_id,
						a.disease_code,
						a.street_1,
						a.boro,
						a.disease_status_final,
						a.event_date
		from notgeocoded a, all_secondary_addresses b
		where a.party_id=b.party_id and b.type_disp="Home" and
			a.x_coord is missing and a.y_coord is missing
		order by event_id;
	quit;

/* Add previously geocoded events to archive dataset, value indicating homelessness or PO Boxes */
/*	flagging for review if new */ 
	proc sort data=support.BCD003_previously_geocoded; by event_id; run;
	data previously_geocoded_new rest;
	merge support.BCD003_previously_geocoded (in=a) previously_geocoded (in=b);
		by event_id;
		if b;
		if b and not a and
			prxmatch("m/(U( +)?N( +)?D( +)?O( +)?M|H( +)?O( +)?M( +)?E( +)?L( +)?E|H-O-M-E-L|HOMESLESS)/oi",street_1)=0 and
			prxmatch("m/(HOMLESS|HOMELES|HOMELE|HOMELS|INDIGENT|INDOMIC|(NON( +)?(-)?( +)?DOMIC)|TRANSIENT|UNIDOM)/oi",street_1)=0 and
			prxmatch("m/(UN( +)?(-)?( +)?DOM|U-N-D-O-M|UNDEM|UNDICILE|UNDIM|UNDIOM|UNDOC|UNDON|UNOMI|UMDOM|UNDORM|UDOM|UNDIM)/oi",street_1)=0 and
			prxmatch("m/NO( +)?ADDRESS/oi",street_1)=0 and
			prxmatch("m/P(.)?O(.)?( )?BOX/oi",street_1)=0
		then do;
			new ="*";
			output previously_geocoded_new;
		end;
		else output rest;
	run;

	proc append base=support.BCD003_previously_geocoded data=previously_geocoded_new;run;
	proc sort data=support.BCD003_previously_geocoded; by new; run;


/* Count number of events still in analysis dataset - if none skip to end of loop */
%let check=%sysfunc(open(satscan1));
%let num_check=%sysfunc(attrn(&check,nobs));
%let end=%sysfunc(close(&check));

%if &num_check = 0 %then %goto exit;

/* Sort and dedup by event_id, X/Y coordinates */
proc sort data=SatScan1 out=SatScan1_addresses nodupkey;
	by event_id x_coord y_coord;
run;

proc sql;
create table loc_ids_&&disease_code&i.._&&maxTemp&i.._&&agegroup&i.. as
	select event_id as loc_id,
			lat,
			long,
			x_coord,
			y_coord
	from SatScan1_addresses
	where x_coord^=" "
	order by event_id, x_coord, y_coord;
quit;

/* Concatenate event address coordinates and census tract coordinates */
data &&disease_code&i.._&&maxTemp&i.._&&agegroup&i.._coordinates;
set loc_ids_&&disease_code&i.._&&maxTemp&i.._&&agegroup&i.. ny_coord_latlong;
run;

/* create coordinate file */
data _null_;
	set &&disease_code&i.._&&maxTemp&i.._&&agegroup&i.._coordinates;
    	file "&INPUT.coordfile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
       format loc_id $11. ;
       format lat $12.;
	   format long $12.;
       format x_coord $7.;
	   format y_coord $7.;
       put loc_id $ @;
       put lat @;
	   put long @;
       put x_coord @;
	   put y_coord;
run; 


/* merge with coordinate file and see if any do not match */
/* save the unmatched events to an archive file for QA */
	proc import datafile = "&SUPPORT.BCD003_LatLongCoord.txt" out = coord replace; getnames=no; datarow=1; run;
	data coord;	set coord; censustract = input(var1,$15.); keep censustract; run;
	proc sort data = coord; by censustract; run;
	proc sort data = Satscan1; by censustract; run;
	data Satscan1 discordant;
		merge Satscan1 (in=a) coord (in=b);
		by censustract;
		if a & b then output Satscan1;
		if a & ~b then output discordant;
	run;
	data discordant;
		set discordant;
		keep event_id disease_code boro censustract event_date disease_status_final;
	run;
	proc sort data = discordant; by event_id; run;
	proc sort data = support.BCD003_not_merged; by event_id; run;
/* erase the previous day's dataset on the first loop so that fixed records come off the list */
	%if &i = 1 %then %do;
	data support.BCD003_not_merged;
		merge discordant (in=a) support.BCD003_not_merged;
		by event_id;
		if a & disease_code ~= '';
	run;
	%end;
	%if &i ~= 1 %then %do;
	data support.not_merged;
		merge discordant (in=a) support.BCD003_not_merged;
		by event_id;
		if disease_code ~= '';
	run;
	%end;
	proc sort data=Satscan1;by event_id;run;


/* create case file for SaTScan*/
	data _null_;
		set satscan1;
		dummy='1';
	    	file "&INPUT.casefile_&&disease_Code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt" delimiter='09'x DSD DROPOVER lrecl=32767;
	       format censusTract $11. ;
	       format dummy $1.;
	       format event_date yymmdds10.;
	       put censusTract $ @;
	       put dummy @;
	       put event_date;
	run; 

/* create macro variable for current disease being run in SaTScan with quotes */
	proc sql;
	select distinct quote(trim(disease_code))
		into :disease_code
		from satscan1;
	quit;

/* define start date, end date, prospective start date and filenames, and update parameter file for SaTScan run */
	data _NULL_;  
		startdt=put(&simstart, yymmdds10.);
		enddt=put(&simend, yymmdds10.);
		outfilename="&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today..TXT";
		/* Call macro with SaTScan parameter settings */
		file "&INPUT.param_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt";
		put %TractParam;
		/* Create the batch file that invokes SatScan and the parameter file */
		file "&SATSCAN.Spatial.bat";
		string='"'||"&SATSCAN.SaTScanBatch.exe"||'" "'||"&INPUT.param_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today..txt"||'"';
		put string;
	run;
	/* Run series of macros from SaTScan_macro file to call satscan and produce output */
		%callSatscan
		%switch
		%if &switch > 0 
			%then %do;		
				%CHOROPLETH_setup
			 	%linelist_setup
				%if &switch_RI>0 %then %do; 
		     		%newIndividuals
			 		%if &NumNew>0 %then %do;
			 		%if &count>2 %then %do;
					%addtolist
					%MakeChoropleth
					%MakeClusterLineList
					/* For Enterics affected by mPCR adoption use different linelist format */
						%if &disease_code in("AMB" "CAM" "CSP" "CYC" "GIA" "STEC" "VIB" "YER") %then %do; 
							%PersonLineList_mPCR
					  	%end;
					  	%else %do; 
							%PersonLineList
					  	%end;
							/* This section is only necessary if producing google earth output */
							/* If not using google earth comment out */
							data _null_;
								startdt=put(&simstart, yymmdds10.);
								enddt=put(&simend, yymmdds10.);
								outfilename2="&OUTPUT.SpatialOut_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today.LatLong.TXT";
								file "&INPUT.param_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today.LatLong.txt";
								put %TractParamLatLong;
								/* Create the batch file that invokes SatScan and the parameter file */
								file "&SATSCAN.SpatialLatLong.bat";
								string='"'||"&SATSCAN.SatScanBatch.exe"||'" "'||"&INPUT.param_&&disease_code&i..&&maxTemp&i.._&&agegroup&i.._&today.LatLong.txt"||'"';
								put string;
							run;
							%callSatscanLatLong
							%GoogleEarth
							/* End google earth output */
					%end;
					%end;
				%end;
			%end;
	%exit:
%end;
%mend RunProgram;

%RunProgram

