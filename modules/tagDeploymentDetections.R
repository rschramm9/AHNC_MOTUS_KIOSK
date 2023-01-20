###############################################################################
# Copyright 2022 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
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
  df <- data.frame( matrix( ncol = 4, nrow = 1) )
  df <- df %>% drop_na()
  colnames(df) <- c('date', 'site', 'lat', 'lon', 'receiverDeploymentID')
  return (df)
}


################################################################################
#
################################################################################
tagDeploymentDetections <- function(tagDeploymentID) 
{

  #possible detections returns are limited to 100 by default
  #if so - might try https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000' ?
  #where n is a hidden argument(see page source)
url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000') ,collapse="")    
##url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',32025) ,collapse="")

#print(url)
#print(" ----------- entered tagDeplymentDetections.R -------")
#print(paste0("using tagDeploymentID:",tagDeploymentID))


readUrl <- function(url) {
  out <- tryCatch(
    {
      # The return value of `readLines()` is the actual value 
      # that will be returned in case there is no condition 
      # (e.g. warning or error). 
      # You don't need to state the return value via `return()` as code 
      # in the "try" part is not wrapped inside a function (unlike that
      # for the condition handlers for warnings and error below)
      read_html(url)
    },
    error=function(cond) {
      message(paste("URL caused ERROR  does not seem to exist:", url))
      message("Here's the original error message:")
      message(cond)
      return(NA)
    },
    warning=function(cond) {
      message(paste("URL caused a WARNING:", url))
      message("Here's the original warning message:")
      message(cond)
      return(NA)
    },
    finally={
      # NOTE:
      # Here goes everything that should be executed at the end,
      # regardless of success or error.
      # If you want more than one expression to be executed, then you 
      # need to wrap them in curly brackets ({...}); otherwise you could
      # just have written 'finally=<expression>' 
      message(paste("tagDeploymentDetections Processed URL:", url))
    }
  )    
  return(out)
}
result <- lapply(url, readUrl)
#print(class(result))

if( is.na(result)){
  df <- empty_tagDeploymentDetection_df()
  print("*** tagDeploymentDetections returning empty df ***")
  return(df)
}

page <- result[[1]]
#print(class(page))

#get all the <p> nodes and look for warnings
pnodes <- html_nodes(page, "p")
#print("length of pnodes is:")
#print (length(pnodes))
#print(pnodes[1])
#print(pnodes[2])

#print("printing pnodes")
#print(pnodes)

##### check for any pnode containing  ########
# for numeric tagid can get "No tag deployment found" 
# for non-numeric tagid can get "No tag deployment ID found")


# note.. turn off warnings tha str_detects about
#  argument is not an atomic vector; coercing

warn = getOption("warn")
options(warn=-1)
ans <- str_detect( toString(pnodes), "No receiver deployment" )
options(warn=warn)

#print( ans )

newans <- any(ans, na.rm = TRUE)  #colapse vector to one element
#print (newans)

if (newans > 0) {
  print("No tag deployment found with ID")
  ##create data frame with 0 rows 
  df = empty_tagDeploymentDetection_df()
  print("tagDeploymentDetections returning empty df")
  return (df)

}


tbls <- page %>% html_nodes("table")

##print(length(tbls))
#[1] 1

tbl1 <- html_table(tbls[[1]],fill=TRUE)
##print(tbl1)

num.cols<-dim(tbl1)[2]
num.rows<-dim(tbl1)[1]
#print(dim(tbl1))



#for(i in 1:num.rows){
#  print("-----------------")
#  print( tbl1[[1]][i] ) 
#  print( tbl1[[2]][i] )
#  print( tbl1[[3]][i]  )
#  print( tbl1[[4]][i] )
#}

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
if( length(exclude_df > 0 )){
  for(i in 1:nrow(exclude_df)) {
      row <- exclude_df[i,]
      theDate=row[[1]]
      theID=row[[2]]
      theSite=row[[3]]
      print(paste0("exclude"," date:",theDate, "  id:", theID,"  site:", theSite))
      df <- df[!(df$receiverDeploymentID == theID & df$date == theDate),] 
   }
}
#print("***** final df ******")
#print(df)

#finally, delete any rows with nulls
df <- df %>% drop_na()
return(df)
}