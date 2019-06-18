/************************************************************************************************/
/*	PROGRAM NAME: BCD004_GoogleEarth_LEG_Demo.sas						*/
/*	DATE CREATED: 2019									*/
/*	LAST UPDATED: 5/24/2019									*/
/*	PROGRAMMERS: Eric Peterson								*/
/*	PURPOSE: Create interactive Google Earth map of disease events and features of interest	*/
/************************************************************************************************/

data _null_;
call symput ('today',put(today(),date9.));
run;

/* **For this demo only** substitute "24MAY2019" (date mock data created) for "today" in order to display full range of date-determined formats */
%let today=24MAY2019;

/* Archive folder for output */
%LET OUTPUT		=S:\...\Archive;
/* Location of supporting files (datasets, legends, images for map icons) */
%LET SUPPORT	=S:\...\Support;
/* Location of supporting files in KML format */
%LET KMLSUPPORT	=S:/.../Support;

libname support "&SUPPORT";

/*  "Case" locations are derived from modified hurricane evacuation site data, available on NYC Open Data: */
/*	https://data.cityofnewyork.us/Public-Safety/Hurricane-Evacuation-Centers/ayer-cga7 */
/* Dates and case/patient/address attributes have been assigned at random. */
data LEG_democases;
set support.BCD004_LEG_cases_demo;
/* "event_date_end" defines when to remove from map when using time slider function. */
/*	In this example events stay on the map once they are added */
	format event_date_end mmddyy10.;
	event_date_end="&today"d;
/* add format to differentiate between recent and older events */
	format time_format $3.;
	if event_create_date>="&today"d then time_format="NEW";
	else if event_date<"&today"d-30 then time_format="OLD";
	else time_format="";
	format final_map_format $10.;
/* combine format conditions into one field */
	final_map_format="#"||strip(time_format)||strip(address_type);
run;

data LEG_cases_kmlformat;
set LEG_democases;
/* delete if coordinates are invalid or missing */
	if longitude in (-999, 0, .) then delete;

	/* Use catx to combine KML tags, text, and event data into a single text field */
	/* Placemark : marks a position on the earth's surface and contains the following elements:
	/* 		name: label for point */
	/*		styleUrl: sets format for representation of point on map */
	/*		description: defines contents of popup balloon attached to each point */
	/*		point: specifies the position of the point using latitude, longitude, and altitude (optional) */
	/*		timespan: defines the period a point will be displayed when using the time slider function */
	format KML_TEXT $20000. ;
		KML_TEXT=catx(" ",
			"<Placemark><name>Event: ",case_id,"</name><styleUrl>",FINAL_MAP_FORMAT,"</styleUrl><description>",
			"Age: ",age,
			", Status: ",disease_status,
			", Diagnosis Date: ",put(diagnosis_date,mmddyy10.),
			", Onset Date: ",put(onset_date,mmddyy10.),
			"</description><Point><coordinates>",longitude,",",latitude,",500</coordinates></Point>",
			/* If not using time slider feature remove timespan, begin, and end tags */
			"<TimeSpan>",
			"<begin>",put(event_date,yymmdd10.),"</begin>",
			"<end>",put(event_date_end,yymmdd10.),"</end>",
			"</TimeSpan>",
			/* */
			"</Placemark>");
	run;

/* Sort by variable you wish to use for folder organization in KML output */
	proc sort data=LEG_cases_kmlformat;
		by disease_status event_date;
	run;

/* Add KML tags for first and last event in each category to organize events into folders */
	data KML_LEG_CASES;
	set LEG_cases_kmlformat;
		by disease_status event_date;
		if first.disease_status then FORMAT_OPEN=cats("<Folder><name>",disease_status,"</name>");
		if last.disease_status then FORMAT_CLOSE="</Folder>";
		format KML $20000.;
		KML=cats(FORMAT_OPEN, KML_TEXT, FORMAT_CLOSE);
		keep KML;
	run;

/* Define XML header */
	data KML_HEADER;
		format KML $20000.;
		KML = '<?xml version="1.0" encoding="UTF-8"?>
			<kml xmlns="http://www.opengis.net/kml/2.2">
			<Document>';
	run;

/* Use ScreenOverlay option to display legend, point to location of png files */
/* More detail here: https://www.google.com/earth/outreach/learn/adding-legends-logos-and-banners-to-google-earth-with-screen-overlays/ */
	data KML_LEGEND;
		format KML $20000.;
		KML="<ScreenOverlay>
			<name>Legend: Case Status</name>
			<Icon> <href>file:///&KMLSUPPORT./BCD004_LEGStatus_legend.png</href>
			</Icon>
			<overlayXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<screenXY x='1' y='1' xunits='fraction' yunits='fraction'/>
        	<rotationXY x='0' y='0' xunits='fraction' yunits='fraction'/>
        	<size x='0' y='0' xunits='fraction' yunits='fraction'/>
			</ScreenOverlay>
			<ScreenOverlay>
			<name>Legend: Cooling Tower Status</name>
			<Icon> <href>file:///&KMLSUPPORT./BCD004_CTStatus_legend.png</href>
			</Icon>
			<overlayXY x='1' y='0' xunits='fraction' yunits='fraction'/>
        	<screenXY x='1' y='0' xunits='fraction' yunits='fraction'/>
        	<rotationXY x='0' y='0' xunits='fraction' yunits='fraction'/>
        	<size x='0' y='0' xunits='fraction' yunits='fraction'/>
			</ScreenOverlay>";
	run;

/* Define map formats for cases. Style ID must match value for "final_map_format" field, otherwise will show up as default */

/* Please note the change in format required when using hexadecimal color codes in KML */
/* Hexadecimal: RRGGBB (www.color-hex.com) */
/* KML: AABBGGRR where AA is a transparency code (FF=completely opaque, 00=completely transparent, gist.github.com/lopspower/03fb1cc0ac9f32ef38f4)*/

/* "href" tags used to define icons can point to image files saved to a folder on a computer or network drive, or to google maps archive. */
/*	All icons necessary to run this demo are included in the GitHub repository */
/* This site provides a helpful index of icons: http://tancro.e-central.tv/grandmaster/markers/google-icons/mapfiles-ms-micons.html */

	data KML_CASES_FOLDER_HEADER;
		format KML $20000.;
		KML = "<Folder>
		<name>Citywide Cases</name>
  			<Style id='NEWHOME'>
  			    <IconStyle>
					<color>ff0000E7</color>
					<colorMode>normal</colorMode>
					<scale>0.8</scale>
				<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_donut.png</href>
				</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
			</Style> 
   			<Style id='HOME'>
      			<IconStyle>
        			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='OLDHOME'>
      			<IconStyle>
        			<color>ffD2D2D2</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_donut.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='NEWWORK'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style> 
   			<Style id='WORK'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='OLDWORK'>
      			<IconStyle>
         			<color>ffD2D2D2</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_square.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
  			<Style id='NEWOTHER'>
      			<IconStyle>
         			<color>ff0000E7</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style> 
   			<Style id='OTHER'>
      			<IconStyle>
         			<color>ff009FE6</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   			<Style id='OLDOTHER'>
      			<IconStyle>
         			<color>ffD2D2D2</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.8</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_triangle.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
 		";
	run;

/* Spray shower sites are used as "cooling tower" locations. Data available on NYC Open Data: */
/*	https://data.cityofnewyork.us/City-Government/Spray-Showers/im58-6hb9 */
/* Dates and cooling tower inspection status are assigned at random. */
data coolingtowers_demo;
set support.BCD004_coolingtowers_demo;
	format final_map_format $10.;
	if inspection_status="Ever Inspected" then final_map_format="#EVER";
	if inspection_status="New Inspection Due" then final_map_format="#DUE";
	if inspection_status="Never Inspected" then final_map_format="#NEVER";
	if inspection_status="Inspection Ongoing" then final_map_format="#ONGOING";
run;


data cts_kmlformat;
set coolingtowers_demo;
/* delete if coordinates are invalid or missing */
	if longitude in (-999, 0, .) then delete;

	/* Use catx to combine KML tags, text, and cooling tower data into a single text field */
	format KML_TEXT $20000. ;
		KML_TEXT=catx(" ",
			"<Placemark><name>BIN: XXXXXXXX</name><styleUrl>",FINAL_MAP_FORMAT,"</styleUrl><description>",
			"Business: XXXXXXXXX",
			", Address: XXXXXXXXX",
			", # of Cooling Towers: N/A",
			", Inspection Status: ",inspection_status,
			", Last Inspection: ",put(last_inspection_date,mmddyy10.),
			", Next Inspection Due: ",put(next_inspection_date,mmddyy10.),
			"</description><Point><coordinates>",longitude,",",latitude,",100</coordinates></Point></Placemark>");
	run;

/* Sort by variable you wish to use for folder organization in KML output */
	proc sort data=cts_kmlformat;
		by inspection_status;
	run;

/* Add KML tags for first and last event in each category to organize events into folders */
	data KML_CTS;
	set cts_kmlformat;
		by inspection_status;
		if first.inspection_status then CT_OPEN=cats("<Folder><name>",strip(inspection_status),"</name><visibility>0</visibility>");
		if last.inspection_status then CT_CLOSE="</Folder>";
		format KML $20000.;
		KML=cats(CT_OPEN, KML_TEXT, CT_CLOSE);
		keep KML;
	run;

/* Define map formats for cooling towers. */
	data KML_CTS_FOLDER_HEADER;
		format KML $20000.;
		KML = "<Folder>
		<name>Cooling Towers</name>
		<visibility>0</visibility>
	      <Style id='EVER'>
		      <IconStyle>
		         <color>ff739E00</color>
	    	     <colorMode>normal</colorMode>
				 <scale>0.5</scale>
	        	<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
      		<Style id='DUE'>
      			<IconStyle>
         			<color>ffE9B456</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.5</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
  			 </Style>
   			<Style id='NEVER'>
      			<IconStyle>
         			<color>ffA779CC</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.5</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
  	 		</Style>
   			<Style id='ONGOING'>
      			<IconStyle>
	     			<color>ffB27200</color>
         			<colorMode>normal</colorMode>
		 			<scale>0.5</scale>
         		<Icon>
            		<href>file:///&KMLSUPPORT./BCD004_flag.png</href>
         		</Icon>
      			</IconStyle>
	  			<LabelStyle><scale>0</scale></LabelStyle>
   			</Style>
   		";
	run;

/* Folder closing tag */
	data KML_FOLDER_CLOSE;
		format KML $20000.;
		KML = '</Folder>';
	run;

/* Document and KML closing tags */
	data KML_DOCUMENT_CLOSE;
		format KML $20000.;
		KML = '</Document></kml>';
	run;

/* Combine KML elements into complete KML document */
	data KML;
	set KML_HEADER
		KML_LEGEND
		KML_CASES_FOLDER_HEADER
		KML_LEG_CASES
		KML_FOLDER_CLOSE
		KML_CTS_FOLDER_HEADER
		KML_CTS
		KML_FOLDER_CLOSE
		KML_DOCUMENT_CLOSE;
	run;

/* Export KML document readable in Google Earth */
	data _null_;
	   set KML;
	   file "&OUTPUT.\LEG_&today._demo.KML" lrecl=20000;
		put KML;
	run;

