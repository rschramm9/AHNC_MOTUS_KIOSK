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
# Purpose: function for getting all tag detections at receiver given
# the MOTUS reciever deployment ID.
# eg https://motus.org/data/receiverDeploymentDetections?id=7948
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then for the tagDeploymentID that is embedded
# in the the "<a href" data
# 
# Returns an empty data frame if it cant process the results (see function
# empty_receiverdetection_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

################################################################################
## create empty receiverDeploymentDetections data frame
## called within receiverDeploymentDetections() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: length and column names need to match exactly
## what is created by receiverDeploymentDetections()
################################################################################
empty_receiverDeploymentDetection_df <- function()
{
  df <- data.frame( matrix( ncol = 7, nrow = 1 ) )
  colnames(df) <- c('tagDetectionDate','tagDeploymentID','tagDeploymentName','species','tagDeploymentDate','lat','lon')
  df <- df %>% drop_na()
  return (df)
}


################################################################################
# Purpose: function for getting all tag detections at receiver given
# the MOTUS receiver deployment ID.
# eg https://motus.org/data/receiverDeploymentDetections?id=7948
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then for the tagDeploymentID that is embedded
# in the the "<a href" data
# 
# Returns an empty data frame if it cant process the results (see function
# empty_receiverdetection_df()
#
################################################################################
receiverDeploymentDetections <- function(receiverID) 
{
  #url <- paste( c('https://motus.org/data/receiverDeploymentDetections?id=7948') ,collapse="")
  url <- paste( c('https://motus.org/data/receiverDeploymentDetections?id=', receiverID) ,collapse="")
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
        
        #message("this is the try")
        read_html(url)
      },
      error=function(cond) {
        # traps HTTP 404 returns
        message(paste("receiverDeploymentDetections URL caused ERROR does not seem to exist:", url))
        message("Here's the original error message:")
        message(cond)
        return(NA)
      },
      warning=function(cond) {
        message(paste("receiverDeploymentDetections URL caused a WARNING:", url))
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
        message(paste("receiverDeploymentDetections Processed URL:", url))
      }
    )    
    return(out)
  }
  result <- lapply(url, readUrl)
  #print(class(result))
  
  if( is.na(result)){
    df <- empty_receiverDeploymentDetection_df()
    print("*** receiverDeploymentDetections returning empty df ***")
    return(df)
    
  }
  
  page <- result[[1]]
  #print(class(page))
  
  #for motus.org, also need to look for some <p> .... </p) warning text...
  #get all the <p> nodes and look for warnings
  pnodes <- html_nodes(page, "p")
  #print("length of pnodes is:")
  #print (length(pnodes))
  #print(pnodes[1])
  #print(pnodes[2])
  
  
  
  ##### check for any pnode containing the following ########
  #for numeric receiver id can get: No receiver deployment found with ID = 7
  #for non numeric receiver id can get: No receiver deployment ID found
  
  # note.. turn off warnings tha str_detects about
  #  argument is not an atomic vector; coercing
  
  warn = getOption("warn")
  options(warn=-1)
  ans <- str_detect( pnodes, "No receiver deployment" )
  options(warn=warn)
  
  
  newans <- any(ans, na.rm = TRUE)  #collapse vector to one element

  if (newans > 0) {
    print("No receiver deployment found with that ID")
    ##create data frame with 0 rows 
    df = empty_receiverDeploymentDetection_df()
    print("receiverDeploymentDetections returning empty df")
    return (df)
  }
  
  # now extract the data table
  tbls <- page %>% html_nodes("table")
  
  tbl1 <- html_table(tbls[[1]],fill=TRUE)
  num.cols<-dim(tbl1)[2]
  num.rows<-dim(tbl1)[1]
  ##print(dim(tbl1))
  
  #for(i in 1:num.rows){
   ##print(i)
  #  print( tbl1[[1]][i] ) 
  #  print( tbl1[[2]][i] )
  #  print( tbl1[[3]][i]  )
  #  print( tbl1[[4]][i] )
  #}
  
  
  # create empty 'vectors'
  tagDetectionDate<-c()
  tagDeploymentName<-c()
  species<-c()
  tagDeploymentDate <-c()
  lat<-c()
  lon<-c()
  tagDeploymentID<-c()
  
  #> print(class(tbl1[[1]][i]))  
  #[1] "character"
  # table entries are all class "character"
  n <- 0
  
  #build six vectors from table data for text in each cell
  #need to go nrows-1 so dont extract the 'table footer' row
  for(i in 1:num.rows-1){
    n <- n+1
    tagDetectionDate <- c( tagDetectionDate,  tbl1[[1]][i]  )
    tagDeploymentName <- c( tagDeploymentName,  tbl1[[2]][i] )
    species <- c(species, tbl1[[3]][i] )
    tagDeploymentDate <-c( tagDeploymentDate, tbl1[[4]][i] )
    lat <-  c( lat,  tbl1[[5]][i]  )
    lon <-  c( lon,  tbl1[[6]][i] )
    ###cat("n:",n," length:", length(tagDetectionDate), "Date:", tbl1[[1]][i] ,"\n")
  }
  
  #convert things that are not meant to be strings to correct type
  tagDetectionDate <- as.Date(tagDetectionDate)
  tagDeploymentDate <- as.Date(tagDeploymentDate)
  lat <-  gsub("[^0-9.-]", "", lat)
  lat <- as.numeric(lat)
  lon <-  gsub("[^0-9.-]", "", lon)
  lon <- as.numeric(lon)
  
  # ----------------------------------------------------------
  #process the page a second time for the tagDeploymentID's that
  #are embedded in the anchor tag of the tagDeploymentName cells.
  # get all the table rows, with <a href=
  a_nodes <- page %>%
  html_nodes("table") %>% html_nodes("tr") %>% html_nodes("a") %>%
  html_attr("href") #as above
  
  #print(a_nodes)
  #print("length of a_nodes is:")
  #print (length(a_nodes))
  # loop through the table rows and extract the tagDeployment URL
  # that looks like:  "tagDeployment?id=36196"
  # parse it to extract the numeric tagDeploymentID
  # and append it to the list...
  n <- 0
  for (node in a_nodes) {
    #print(node)
    #print(class(node))
    ans <- str_detect( node, "tagDeployment" )
    if(ans) {
      n <- n+1
      theID <- as.numeric( sub("\\D*(\\d+).*", "\\1", node) )
      tagDeploymentID<- c( tagDeploymentID, theID  )
      #cat("n:",n," length:", length(tagDeploymentID), "theId:",theID, "\n")
    }
  }
  #got them...
  #print(tagDeploymentID)
  #---------------------------------------------------------- 
  
  
  df <-data.frame(tagDetectionDate,tagDeploymentID,tagDeploymentName,species,tagDeploymentDate,lat,lon)
  #delete nulls
  df <- df %>% drop_na()
  print(df)
  return(df)
  
}
