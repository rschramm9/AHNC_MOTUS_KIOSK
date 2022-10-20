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
# 25-Apr-2022
################################################################################
# Purpose: function for getting all tag detections for any tag deployment
# given the MOTUS tag deployment ID.
# 
# eg:  https://motus.org/data/tagDeploymentDetections?id=32022
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections.  parse the basic table data 
# 
# Returns an empty data frame if it cant process the results (see function
# empty_tagdetection_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

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
  colnames(df) <- c('date', 'site', 'lat', 'lon')
  return (df)
}


################################################################################
#
################################################################################
tagDeploymentDetections <- function(tagDeploymentID) 
{

url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID) ,collapse="")    
##url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',32025) ,collapse="")

#print(url)

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
ans <- str_detect( pnodes, "No receiver deployment" )
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

# create four empty 'vectors'
date<-c()
site<-c()
lat<-c()
lon<-c()  

#> print(class(tbl1[[1]][i]))  
#[1] "character"
# table entries are all class "character"

#build four vectors from table data
for(i in 1:num.rows){
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
df <-data.frame(date,site,lat,lon)

#finally, delete any rows with nulls
df <- df %>% drop_na()

}