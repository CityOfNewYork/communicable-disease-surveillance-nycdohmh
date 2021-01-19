*************************************************************************************************;
*	PROGRAM NAME: COVID_Macros  										 						*;
*	DATE CREATED: 2020																			*;
*	LAST UPDATED: 1/14/2021																		*;
*	PROGRAMMERS: Eric Peterson, Alison Levin-Rector                           					*;
*                  				                                                 				*;
*		PURPOSE: Sets up macros for running SaTScan and preparing output files 	 				*;
*		PARENT: Called via %include statement in COVID_Master 									*;
*************************************************************************************************;

/* Define parameters for each unique SaTScan analysis */
%include "&CODE.\BCD005_COVID_MACRO_param.sas";

/* Format SaTScan output files */
%include "&CODE.\BCD005_COVID_MACRO_format_output.sas";
/* Set up the data for the person linelist */
%include "&CODE.\BCD005_COVID_MACRO_personlinelist_setup.sas";
/* Set up the data for the map */
%include "&CODE.\BCD005_COVID_MACRO_choropleth_setup.sas";
/* Set up the data for cluster summary tables */
%include "&CODE.\BCD005_COVID_MACRO_clustersummary_setup.sas";

/* Export person linelist to excel file */
%include "&CODE.\BCD005_COVID_MACRO_makepersonlinelist.sas";
/* Start creating RTF output file and print choropleth map first */
%include "&CODE.\BCD005_COVID_MACRO_makechoropleth.sas";
/* Print cluster summary tables to RTF output file */
%include "&CODE.\BCD005_COVID_MACRO_makeclustersummary.sas";
/* Generate temporal graph for each cluster for RTF output */
%include "&CODE.\BCD005_COVID_MACRO_maketemporalgraphs.sas";
