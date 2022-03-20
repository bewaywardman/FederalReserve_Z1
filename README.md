# FederalReserve_Z1
Absorbs data from federal reserve z1 releases. Aims being to create a centralised data dictionary, and a single database source for all information.
Ultimately, the format at face value is inhospitable to data science.

Generation of a unique column ID, used to link between central data dictionary and database.

Notably, two files required corrections owing to errors by the FED. These are in the form of naming mismatches between
what is expected in the datafile and what is actually present in datafiles.

Conversion of annual data into quarterly formatting to allow for merging of datasets, further conversion from base formatting into
internationally recognised formats.

CPI and seasonal correction information is obtained from:
https://www.bls.gov/cpi/tables/seasonal-adjustment/home.htm
