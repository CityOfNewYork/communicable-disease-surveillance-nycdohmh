# Generating Count and Tree Files for TreeScan

## Project File Inventory

### `BCD006_GitHub_TreeScan_count_and_tree_files.sas` - SAS program that reads in sample SARS-CoV-2 variant data, aggregates cases by lineage/variant and specimen collection date, and outputs count and tree files

### `BCD006_GitHub_sample_data.sas7bdat` - Artificial sample SARS-CoV-2 variant data with specimen collection date and lineage, the minimum required fields to perform TreeScan analysis, along with artificial unique ID

### `BCD006_GitHub_sample_count_file.txt` - Tab-delimited SARS-CoV-2 variant count file with one row per unique lineage (column 1) and collection date (column 2) with aggregated case count (column 3)

### `BCD006_GitHub_sample_tree_file.txt` - Tab-delimited hierarchical tree file with all node (column 1) and parent (column 2) relationships necessary to construct tree with one root that contains all SARS-CoV-2 lineages in count file and their closest node one level up on the tree

### `BCD006_GitHub_sample_parameters.prm` - TreeScan parameter file for use with sample SARS-CoV-2 variant count and tree files. Parameters are set to run a prospective analysis using the tree and time scan options, aggregated by day, and conditioning on node and time. To run an analysis using these parameter settings on the artificial count and tree files, please update the Tree File and Count File fields on the “Input” tab and Results File field on the “Output” tab to reflect the location of the downloaded sample input files.

### `BCD006A_GitHub_Salmonella_Count_and_Tree_Files.sas` - SAS program that reads in sample _Salmonella_ allele code data, aggregates cases by allele code and isolation date, and outputs count and tree files

### `BCD006A_GitHub_Salmonella_Sample_Data` - Sample _Salmonella_ data with mock serotype and modified allele code and isolation date values

### `BCD006A_GitHub_Salmonella_Count_File` - Tab-delimited _Salmonella_ allele code count file with one row per unique isolation date (column 1) and allele code (column 2) with aggregated case count (column 3)

### `BCD006A_GitHub_Salmonella_Tree_File` - Tab-delimited hierarchical tree file with all node (column 1) and parent (column 2) relationships necessary to construct tree with one root that contains all _Salmonella_ allele codes in count file and their closest node one level up on the tree

### `BCD006A_GitHub_Salmonella_Parameter_File` – TreeScan parameter file for use with sample _Salmonella_ count and tree files. Parameters are set to run a prospective analysis using the tree and time scan options, aggregated by day, and conditioning on node and time. To run an analysis using these parameter settings on the artificial count and tree files, please update the Tree File and Count File fields on the “Input” tab and Results File field on the “Output” tab to reflect the location of the downloaded sample input files.


## Summary

### [TreeScan](http://www.treescan.org)<sup>TM</sup> is freely downloadable, open source software that implements the tree-based scan statistic, a data mining method primarily used by CDC, FDA, and academic scientists to detect and evaluate unanticipated adverse reactions to pharmaceutical drugs and vaccines. This method scans, for example, a hierarchical tree of ICD-10 codes, looking for excess risk over any time range after drug or vaccine exposure of any potential adverse event and groups of related adverse events, while adjusting for multiple testing.

### NYC DOHMH Bureau of Communicable Disease (BCD) research scientists engaged the TreeScan software developers and fundraised to support a series of new TreeScan public releases (currently v.2.3) to add additional features, which are documented [here]( https://www.treescan.org/cgi-bin/treescan/register.pl/treescan.versionhistory.pdf?todo=process_version_history_download).

### BCD conducts weekly TreeScan analyses to prospectively detect (1) emerging SARS-CoV-2 variants and (2) clusters of Salmonella with closely related allele codes, which are described in detail [here](https://academic.oup.com/ije/article/54/2/dyaf032/8110348). The “BCD006” files correspond to the SARS-CoV-2 analysis, for which an [external file](https://github.com/cov-lineages/pango-designation/blob/master/lineage_notes.txt) is necessary to determine the tree structure. The “BCD006A” files correspond to the _Salmonella_ analysis, for which the tree structure can be determined directly from the serotype and allele code in the count file.
