
require(openxlsx)
require(reshape2)
require(ggplot2)

# download datadump for Z1 release, March 10th 2022
# this can be easily automated to most recent, especially using a get request and regex, or identifying prior quarter end from Sys.Date(), but hardcoding for now

temp = tempfile()
download.file("https://www.federalreserve.gov/releases/z1/20220310/z1_csv_files.zip",temp)
unzip(temp)

rm(temp)

# Importing delimited files, data dictionaries

setwd("data_dictionary")

datadicts = list.files()
datadict = read.delim(datadicts[1],header=F)

datadict[,ncol(datadict)+1] = gsub("[.]txt","",datadicts[1])

for(n in 2:length(datadicts)){
  #skip any empty files, example being l215.txt
  if(file.info(datadicts[n])$size > 0){
    datadict_temp = read.delim(datadicts[n],header=F)
    datadict_temp[,ncol(datadict_temp)+1] = gsub("[.]txt","",datadicts[n])

    datadict = rbind(datadict,datadict_temp)
  }
}
rm(datadict_temp)

colnames(datadict) = c("DataKey","DataDescription","FileLocation","DataFileCategory","Unit","datatable")

#shift focus to datafiles
#first swap directories from unzipping
setwd('..')
setwd("csv")

datafiles = list.files()
z1_database = read.csv("all_sectors_levels_q.csv",stringsAsFactor=F)

datafiles = datafiles[-which(datafiles == "all_sectors_levels_q.csv")]

#concatenating filename with datakey, as datakeys are in fact not unique. Worse still they can refer to different data streams
colnames(z1_database)[2:ncol(z1_database)] = paste0(colnames(z1_database)[2:ncol(z1_database)],"_","all_sectors_levels_q")


# loop through every data file, merging with existing data until all is contained in one source
for(n in 1:length(datafiles)){
  datafiles_temp = read.csv(datafiles[n],stringsAsFactor=F)
  
  #any data? Can't rule out an empty file causing issues
  if(nrow(datafiles_temp) > 0){

    #create unique field names
    colnames(datafiles_temp)[2:ncol(datafiles_temp)] = paste0(colnames(datafiles_temp)[2:ncol(datafiles_temp)],"_",gsub("[.]csv","",datafiles[n]))

    #coerce annual data to quarterly format
    if(!any(grepl(":",datafiles_temp[,1]))){  datafiles_temp[,1] = paste0(datafiles_temp[,1],":Q4") }

    #any date fields in either the temp file or our growing database which are not in its counterpart?
    unmatched_z1 = unique(z1_database[which(!z1_database[,1] %in% datafiles_temp[,1]),1])
    unmatched_temp = unique(datafiles_temp[which(!datafiles_temp[,1] %in% z1_database[,1]),1])

    #if temp file is missing some rows, for example caused by data being annual format instead of quarterly
    if(length(unmatched_z1) > 0){ 
      rown = nrow(datafiles_temp)
      datafiles_temp[(rown+1):(rown+length(unmatched_z1)),] = NA 
      datafiles_temp[(rown+1):(rown+length(unmatched_z1)),1] = unmatched_z1
    }

    #vice versa
    if(length(unmatched_temp) > 0){
      rown = nrow(datafiles_temp)
      unmatched_z1[(rown+1):(rown+length(unmatched_temp)),] = NA 
      unmatched_z1[(rown+1):(rown+length(unmatched_temp)),1] = unmatched_temp
    }

    #merge on date column, column 1
    z1_database = cbind(z1_database,datafiles_temp)
  }
}

rm(rown)
rm(unmatched_temp)
rm(datafiles_temp)

#creating a field in our data dictionary which matches to unique database fields
datadict$colname = paste0(datadict$DataKey,"_",datadict$datatable)


#correcting a data error on the SECs part between data dictionary file and datafile, for files b101h and b101n
#keys are assigned codes_Q, but are codes_A in the datafiles
if(!any(datadict$colname[which(datadict$datatable == "b101h")] %in% colnames(z1_database))){ datadict$colname[which(datadict$datatable == "b101h")] = gsub("Q_","A_",datadict$colname[which(datadict$datatable == "b101h")]) }
if(!any(datadict$colname[which(datadict$datatable == "b101n")] %in% colnames(z1_database))){ datadict$colname[which(datadict$datatable == "b101n")] = gsub("Q_","A_",datadict$colname[which(datadict$datatable == "b101n")]) }

#which(colnames(z1_database) == "FL192000005.A_b101h")

#backup original dates in case of future issues
z1_database_olddates = as.character(z1_database$date)

#some regex to fix dates, create time series format
datefix_year = as.numeric(gsub("(\\d{4})(:Q)(\\d$)","\\1",z1_database$date))
datefix_month = as.numeric(gsub("(\\d{4})(:Q)(\\d$)","\\3",z1_database$date))*3
datefix_month[which(nchar(datefix_month) == 1)] = paste0("0",datefix_month[which(nchar(datefix_month) == 1)])
datefix_day = ifelse(datefix_month == "06",30,31)

z1_database$datefix = paste0(datefix_year,"-",datefix_month,"-",datefix_day)

#reorder database, fixed date then data, without old date field
z1_database = z1_database[,c(ncol(z1_database),2:(ncol(z1_database)-1))]

for(n in 2:ncol(z1_database)){
	if(!all(is.na(z1_database[,n]))){
		#if(any(z1_database[,n] == "ND")){ z1_database[which(z1_database[,n] == "ND"),n] = NA }
		z1_database[,n] = as.numeric(z1_database[,n])
	}
}


