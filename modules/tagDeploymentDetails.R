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
# 08-May-2022 Handles missing values- now missing vals are 'unknown'
#             instead of NA, so rows dont get deleted from dataframe
################################################################################
# Purpose: function for getting all tag detections for any tag deployment
# given the MOTUS tag deployment ID.
# 
# eg:  https://motus.org/data/tagDeploymentDetails?id=32022
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections.  parse the basic table data 
# 
# Returns an empty data frame if it cant process the results (see function
# empty_tagdetails_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

################################################################################
## create empty tagDeploymentDetails data frame
## called within tagDeploymentDetails() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: BOTH length AND column names need to match exactly
## what is created by tagDeploymentDetails()
################################################################################

empty_tagDeploymentDetails_df <- function()
{
  mydf <- data.frame( matrix( ncol = 9, nrow = 1) )
  colnames(mydf) <- c('tagid', 'project', 'contact', 'started','species','lat','lon','ndays', 'nreceivers')
  return (mydf)
}

################################################################################
# given table with two columns: key and value, will return the value for
#the key (if found) else "unknown"
################################################################################
find4me <-function(mytbl,target){
  idxarray <-which(mytbl == target, arr.ind = TRUE)
  if( nrow(idxarray) > 0 ){
    idx=idxarray[1]
    result <-mytbl[[2]][idx]
  } else {
    message("Result not found")
    message(target)
    result <- "unknown"
  }
  return(result)
  
}


################################################################################
#
################################################################################
tagDeploymentDetails <- function(tagDeploymentID) 
{
  
  url <- paste( c('https://motus.org/data/tagDeployment?id=',tagDeploymentID) ,collapse="")    
  ##url <- paste( c('https://motus.org/data/tagDeployment?id=',32025) ,collapse="")
  message("***** tadDeploymentDetails 1 ******")
  print(url)
  
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
        message(paste("tagDeploymentDetails Processed URL:", url))
      }
    )    
    return(out)
  }
  result <- lapply(url, readUrl)
  #print(class(result))
  
  if( is.na(result)){
    df <- empty_tagDeploymentDetection_df()
    print("*** tagDeploymentDetails returning empty df ***")
    return(df)
    
  }
  
  page <- result[[1]]
  #print(class(page))
  
  
  
  #get all the <p> nodes and look for warnings
  pnodes <- html_nodes(page, "p")
  
  # if called with a tagDeploymentID that doenst exist,
  # motus.org may just redirect us to the home page.
  # I search for a <p>tag that is NOT found on a homepage but
  # is on the on the normal results page.
  # so if it NOT found.. i can imply ive been redirected to home page
  
  # note.. turn off warnings that str_detects about
  #  argument is not an atomic vector; coercing
  warn = getOption("warn")
  options(warn=-1)
  ans <- str_detect( pnodes, "Show detections in:" )
  options(warn=warn)
  
  newans <- any(ans, na.rm = TRUE)  #colapse vector to one element
  if (newans <= 0) {
    print("Redirected, No tag deployment found with ID")
    ##create data frame with 0 rows 
    df = empty_tagDeploymentDetails_df()
    print("tagDeploymentDetails returning empty df")
    return (df)
    
  }
  
  
  
  
  ##### check for any pnode containing  ########
  # for numeric tagid can get "No tag deployment found" 
  # for non-numeric tagid can get "No tag deployment ID found")
  
  
  # note.. turn off warnings tha str_detects about
  #  argument is not an atomic vector; coercing
  
  warn = getOption("warn")
  options(warn=-1)
  ans <- str_detect( pnodes, "No tag deployment" )
  options(warn=warn)
  
  #print( ans )
  
  newans <- any(ans, na.rm = TRUE)  #colapse vector to one element
  #print (newans)
  
  if (newans > 0) {
    print("No tag deployment found with ID")
    ##create data frame with 0 rows 
    mydf = empty_tagDeploymentDetails_df()
    print("tagDeploymentDetails returning empty df")
    return (mydf)
    
  }
  
  # *************************************************************
  tbls <- page %>% html_nodes("table")
  
  tbl1 <- html_table(tbls[[1]],fill=TRUE)
  
  #message("***** tadDeploymentDetails  tbl1 ******")
  #print(class(tbl1))
  #print(tbl1)
  
  num.cols<-dim(tbl1)[2]
  num.rows<-dim(tbl1)[1]
  
  #print(dim(tbl1))
  
  tagid <- find4me(tbl1,"Tag:")
  project <- find4me(tbl1,"Project:")
  contact <- find4me(tbl1,"Project contact:")
  started <- find4me(tbl1,"Deployment started:")
  species <- find4me(tbl1,"Species:")
  ndays <- find4me(tbl1,"Days detected:")
  nreceivers <- find4me(tbl1,"Receivers detected by:")
  location <- find4me(tbl1,"Location:")
  
  #location is string like: "Lat.: 49.1225°, Lon.: -125.8867° (map)"
  #so we extract to variables lat and lon
  if( str_detect(location, "unknown") ) {
    lat <- "unknown"
    lon <- "unknown"
    message("location is unknown")
  } else {
    s <- str_extract_all(location,"\\(?[0-9,.-]+\\)?")[[1]]
    #print(s)
    # note.. turn off warnings about
    #  "introduced by coercion"
    warn = getOption("warn")
    options(warn=-1)
    latlon <- as.numeric(s)
    options(warn=warn)
    #print(latlon)
    lat <- latlon[2] 
    lon <- latlon[5]
  } #end if location is unknown
  
  #create empty frame with one row of nulls
  mydf <- empty_tagDeploymentDetails_df()
  #print("---- emptydf ----")
  #print(mydf)
  
  
  #append a row with our values
  mydf[2, ]<- list(tagid ,project, contact, started, species, lat, lon, ndays, nreceivers )
  #finally, delete any rows with nulls
  mydf <- mydf %>% drop_na()
  
  #print("the new mydf")
  #print (mydf)
  
  #print ("done")
  return(mydf)
  
}