# FederalReserve_Z1

Absorbs data from federal reserve z1 releases. The format at face value is quite inhospitable to data science, requiring significant
human action to merge and select data.

Creation of a centralised searchable data dictionary, with a single database source for all information.

In addition I have taken the step to define a unique column identifier used to link between a central data dictionary and database, as there are inconsistencies with the naming of fields being non-unique between unique data within data sources.

Notably, two files required further correction owing to errors by the FED. These are in the form of naming mismatches between
what is expected in the datafile through dictionary information and what is actually present in datafiles.

Data is standardised into granular date formatting to allow for merging of datasets, with further conversion from the base formatt into
internationally recognised formats.

CPI and seasonal correction information is obtained from:
https://www.bls.gov/cpi/tables/seasonal-adjustment/home.htm
