###############################################################################
# Copyright 2022 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# **************************************************************************************
# ****  IN ADDITION - BY DOWNLOADING AND USING THIS SOFTWARE YOU ARE AGREEING TO: ******
# 1) Properly maintain citation and credit for the use of Motus data access tools courtesy
# of Bird Studies Canada. 2015. Motus Wildlife Tracking System. Port Rowan, Ontario.
# Available: http://www.motus-wts.org. 
# Citation: Birds Canada (2022). motus: Fetch and use data from the Motus Wildlife Tracking
# System. https://motusWTS.github.io/motus. 
# 
# 2) Any use or publication of the data presented through this application or its functions
# must conform to the terms of the Motus Collaboration Policy at https://motus.org/policy/
# and ensure proper recognition of Motus, Birds Canada, Motus researchers and projects.
# ***************************************************************************************
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

################################################################################
# 25-Apr-2022 Original
# 19-Jan-23  Added check for extra row caused by 'sort footer' in html results table
#            Also added second pass to extract the receiverDeploymentID from the
#            sitename "<a href" data
#20-Jan-2023 Process flightpath to remove excluded point from .scv file
#            that was read in global.R
################################################################################
# Purpose: function for getting all tag detections for any tag deployment
# given the MOTUS tag deployment ID.
# 
# eg:  https://motus.org/data/tagDeploymentDetections?id=32022
#
# returns daily 'summary' data which is basically the 'flight history' of a
# deployment of a tag using its tagDeploymentID

# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then to recover the receiverDeploymentID that
# is embedded in the the "<a href" data for the site name which is
# the returned 'ReceiverDeployment' column)
# 
# Returns an empty data frame if it cant process the results (see function
# empty_tagdetection_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

#see:https://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
rows = function(x) lapply(seq_len(nrow(x)), function(i) lapply(x,"[",i))



################################################################################
## create empty tagDeploymentDetections data frame
## called within tagDeploymentDetections() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: length and column names need to match exactly
## what is created by tagDeploymentDetections()
################################################################################

empty_tagDeploymentDetection_df <- function()
{
  df <- data.frame( matrix( ncol = 5, nrow = 1) )
  df <- df %>% drop_na()
  colnames(df) <- c('date', 'site', 'lat', 'lon', 'receiverDeploymentID')
  return (df)
}


################################################################################
#
################################################################################
tagDeploymentDetections <- function(tagDeploymentID, useReadCache=1, cacheAgeLimitMinutes=60) 
{

  #possible detections returns are limited to 100 by default
  #if so - might try https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000' ?
  #where n is a hidden argument(see page source)
url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000') ,collapse="")    
##url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',32025) ,collapse="")


cacheFilename = paste0(config.CachePath,"/tagDeploymentDetections_",tagDeploymentID,".Rda")


df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R

if( is.data.frame(df)){
  DebugPrint("tagDeploymentDetections returning cached file")
  return(df)
} #else was NA

#prepare an empty dataframe we can return if we encounter errors parsing query results
onError_df <- empty_tagDeploymentDetection_df()

# we either already returned the valid cache df above and never reach this point,
# or the cache system wasnt used or didnt return a cached dataframe,
# so need to call the URL 

InfoPrint(paste0("make call to motus.org using URL:",url))

result <- lapply(url, readUrlWithTimeout)   #see utility_functions.R

if( is.na(result)){
  DebugPrint("readUrl() no results - returning empty df (is.na(result) ***")
  return(onError_df)
}

DebugPrint("begin scraping html results")

#result is a list object, extract the html output and assign to 'page'
page <- result[[1]]

#first test if its an xml document
ans<-is(page,"xml_document")
if(ans==TRUE){ 
  DebugPrint("We got an xml document page")
}else{
  DebugPrint("We dont have an xml document - returning onError df")
  return(onError_df)
}

# next test for a redirect to motus HomePage 
# eg. if called with an ID that doesnt exist,
# motus.org may just redirect us to the motus.org home page. Here I test for the homepage title
ans=testPageTitlenodes(page, "Motus Wildlife Tracking System")
if (ans==TRUE) {
  WarningPrint("Motus redirected to homepage. Likely no tag deployment found with ID. Returning empty df (Redirected) ")
  return(onError_df)
}

# next check for any pnode containing:
# for numeric id can get "No tag deployment found" 
# for non-numeric id can get "No tag deployment found with ID")
ans=testPagePnodes(page, "No tag deployment")
if (ans==TRUE) {
  WarningPrint("returning empty df (warning No tag deployment found with ID)")
  return(onError_df)
}

##if in future we care, implement this test
##next test page title was as expected
#ans=testPageTitlenodes(page, "Detections - Tag deployment")
#if (ans==TRUE){
#  DebugPrint("Motus responded with expected page title - continue testing response")
#}

DebugPrint("end initial html result testing")


# *************************************************************








tbls <- page %>% html_nodes("table")

##print(length(tbls))
#[1] 1

tbl1 <- html_table(tbls[[1]],fill=TRUE)
##print(tbl1)

num.cols<-dim(tbl1)[2]
num.rows<-dim(tbl1)[1]
#print(dim(tbl1))

# create five empty 'vectors'
date<-c()
site<-c()
lat<-c()
lon<-c() 
receiverDeploymentID<-c()

#> print(class(tbl1[[1]][i]))  
#[1] "character"
# table entries are all class "character"

# html results node may have a 'row' of sort controls as a 'table footer' 
# if it is there, then the first column of the last row will be the
# string 'Detection date'
# We need the true number of detection records to process in the
# for loop that follows
hasFooter <- str_detect(toString( tbl1[[1]][num.rows]), "Detection date" )
if(hasFooter == 1){
  nrecords <- num.rows -1
} else {
  nrecords <- num.rows
}



#build four vectors from table data
#for(i in 1:num.rows){
n <- 0
for(i in 1:nrecords){
  n <- n+1
  date <- c( date,  tbl1[[1]][i]  )
  site <- c( site,  tbl1[[2]][i] )
  lat <-  c( lat,  tbl1[[3]][i]  )
  lon <-  c( lon,  tbl1[[4]][i] )
}
#print(date)
#print(site)
#print(lat)
#print(lon)

#convert strings to correct type
date <- as.Date(date)
lat <-  gsub("[^0-9.-]", "", lat)
lat <- as.numeric(lat)
lon <-  gsub("[^0-9.-]", "", lon)
lon <- as.numeric(lon)

# ----------------------------------------------------------
# process the page a second time for the receiverDeploymentID's that
# are embedded in the anchor tag of the site name cells.
# get all the table rows, with <a href=
a_nodes <- page %>%
  html_nodes("table") %>% html_nodes("tr") %>% html_nodes("a") %>%
  html_attr("href") #as above

#print(a_nodes)
#print("length of a_nodes is:")
#print (length(a_nodes))
# loop through the table rows and extract the tagDeployment URL
# that looks like:  "receiverDeployment?id=9195"
# parse it to extract the numeric receiverDeploymentID
# and append it to the list...
n <- 0
for (node in a_nodes) {
  #print(node)
  #print(class(node))
  ans <- str_detect( toString(node), "receiverDeployment" )
  if(ans) {
    n <- n+1
    theID <- as.numeric( sub("\\D*(\\d+).*", "\\1", node) )
    receiverDeploymentID<- c( receiverDeploymentID, theID  )
    #cat("n:",n," length:", length(receiverDeploymentID), "theId:",theID, "\n")
  }
}
#got them...
#print(receiverDeploymentID)

df <-data.frame(date,site,lat,lon,receiverDeploymentID)

# flight data exclusions from .csv file read by global.R
if( length(gblExclude_df > 0 )){
  for(i in 1:nrow(gblExclude_df)) {
      row <- gblExclude_df[i,]
      theDate=row[[1]]
      theID=row[[2]]
      theSite=row[[3]]
      ##print(paste0("exclude"," date:",theDate, "  id:", theID,"  site:", theSite))
      df <- df[!(df$receiverDeploymentID == theID & df$date == theDate),] 
   }
}
#print("***** final df ******")
#print(df)

#finally, delete any rows with nulls
df <- df %>% drop_na()

if(config.EnableWriteCache == 1){
  DebugPrint("writing new cache file.")
  saveRDS(df,file=cacheFilename)
}
DebugPrint("tagDeploymentDetections done.")
return(df)
}