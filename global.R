###############################################################################
# Copyright 2022-2023 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# #
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

# This app's structure utilizes techniques for creating a multilanguage
# modularized app as described by Eduard Parsadanyan in his article at: 
# https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
# and was learned via exploring his ClinRTools modularized demo found at:
# https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/

# This app uses the shiny.i18n package to perform language translations
# shiny.i18n package is Copyright Copyright (c) 2023 Appsilon Sp. z o.o.
# and distributed under MIT license. see:https://github.com/Appsilon/shiny.i18n
# Citation: Nowicki J, Krzemiński D, Igras K, Sobolewski J (2023).
# shiny.i18n: Shiny Applications Internationalization.
# https://appsilon.github.io/shiny.i18n/, https://github.com/Appsilon/shiny.i18n.

# Globals: libraries, modules etc.

############### Put github release version and data here ##########
gblFooterText <- "USFWS Ankeny Hill Nature Center MOTUS Kiosk.  vsn 4.2.10  26-Sep-2023"
############### will be rendered into footer by server() ########## 


library(shiny)

library(shinymeta)
library(shinyjs)
library(shiny.i18n)

library(shinyWidgets)   # for pickerInput Widget flag thing

library(rvest)  #for  web scraping
library(tidyr) #for  web scraping

### read URLs with timeouts
library(httr)


#### for leaflet map
library(leaflet)
library(leaflet.extras2) #for movingmarker
# movingmarkers needs flight_ df converted f to a 'simple features dataframe'
#using the coordinate reference system with columns: time,geometry
library(sf) #for making flightpath for movingmarker

### glue for building leaflet labels
library(glue)

library(lubridate) # for working with dates

library(tidyverse)

options(stringsAsFactors = FALSE)

default_UI_lang <- "en"

LOG_LEVEL_DEBUG=5  #print debug messages
LOG_LEVEL_INFO=4 #print info messages
LOG_LEVEL_WARNING=3 #print warning messages
LOG_LEVEL_ERROR=2
LOG_LEVEL_FATAL=1
LOG_LEVEL_NONE=0
LOG_LEVEL = LOG_LEVEL_INFO #set an inital log level, after we read the config file we will overide this

###### read configuration key/value pairs
library(data.table)


# Add individual modules here
source("modules/configUtils.R")
source("modules/utility_functions.R")
source("modules/ReceiverDetections.R")
source("modules/tagDeploymentDetails.R")          #tagDeploymentDetails
source("modules/tagDeploymentDetections.R")       #the flightpath
source("modules/receiverDeploymentDetections.R")  #whats been at our receiver
source("modules/MotusNews.R")  #whats been at our receiver
source("modules/receiverDeploymentDetails.R")
source("modules/AboutMotus.R")  
source("modules/tagTrack.R")  

     # read the configuration file (see configUtils.R)
     #print("global calling getConfig")
     badCfg = getConfig()
     #halt if config processing didn't finish cleanly
     if( badCfg == TRUE){
       FatalPrint("There is a fatal error in your cfg file")
       stop("Stopping because there is a serious error in your cfg file")
     } #else { 
       #printConfig()
       #}
     #print("-----------------Done processing config----------------------------------")
     #set your desired log level in your config file
     #convert the string from config file to numeric constant from above
     LOG_LEVEL=switch(
       config.LogLevel,
       "LOG_LEVEL_DEBUG"=LOG_LEVEL_DEBUG,
       "LOG_LEVEL_INFO"=LOG_LEVEL_INFO,
       "LOG_LEVEL_WARNING"=LOG_LEVEL_WARNING,
       "LOG_LEVEL_ERROR"=LOG_LEVEL_ERROR,
       "LOG_LEVEL_FATAL"=LOG_LEVEL_FATAL,
       "LOG_LEVEL_NONE"=LOG_LEVEL_NONE,
     )
     
     
     # read a csv file for any bad or tags by tagID we want the gui to
     # ignore. any receiver detection of a tag with matching TagID
     # would have all detections of this tag at the receiver ignored
     # eg for a 'test tag' used a site where we dont want to show the public user
     # our test data
     f <- paste0(getwd(),"/data/ignore_tags",".csv") 
     gblIgnoreTag_df <<- ReadCsvToDataframe(f)
    
     # read a csv file for any bad or tags by tagDeploymentID we want the gui to
     # ignore. any receiver detection of a tag with matching tagDeploymentID
     # would have all detections of this tag at the receiver ignored
     # eg for a 'test tag' that may be redeployed later on an animal
     # where we dont want to show the public user the test data
     f <- paste0(getwd(),"/data/ignore_tag_deployments",".csv")
     gblIgnoreTagDeployment_df <<- ReadCsvToDataframe(f)
     
     # read a csv file for any known bad tag detections at some receiver that we want the gui to ignore
     # these are individual detections of a tag at some receiver - eg wild point where the animal 
     # flies across the continent in a day = a false detections that motus hasnt filtered
     # this hack isnt scalable but for now....
     f <- paste0(getwd(),"/data/ignore_date_tag_receiver_detections",".csv")
     gblIgnoreDateTagReceiverDetections_df <<- ReadCsvToDataframe(f)


     # construct data frame to support the available receivers picklist
     # the shortnames list contains the visible choices on the dropdown
     # here we make a dataframe from the shortnames and the deployment ids, later we
     # use the reactive picklist choice to filter the dataframe to get the desired deployment id
     gblReceivers_df <<- data.frame(unlist(config.ReceiverShortNames),unlist(config.ReceiverDeployments))
     #to name the columns we use names() function
     names(gblReceivers_df) = c("shortName","receiverDeploymentID")
     config.ReceiverShortName<- toString(config.ReceiverShortNames[1])   #start with the first receiver on the list
     selectedreceiver <<- filter(gblReceivers_df, shortName == config.ReceiverShortName)
     
     # NOTE the use of global assignments
     receiverDeploymentID <<- selectedreceiver["receiverDeploymentID"]
     InfoPrint(paste0("Start with receiver:", config.ReceiverShortName, "  ID:", receiverDeploymentID))

     # for testing connection status to motus.org, I will always use this ID
     defaultReceiverID<<-receiverDeploymentID 
       
     # Initially populate the dataframes here
     # we want these to be global variables... (note the <<- ) 
     InfoPrint(paste0("global.R Make initial call to motus for receiverDeploymentDetections of receiver:", receiverDeploymentID))
     detections_df <<- receiverDeploymentDetections(receiverDeploymentID, config.EnableReadCache, config.ActiveCacheAgeLimitMinutes)
     if(nrow(detections_df)<=0) {  # failed to get results... try the inactive cache
       InfoPrint("initial receiverDeploymentDetections request failed - try Inactive cache")
       detections_df <<- receiverDeploymentDetections(receiverDeploymentID, config.EnableReadCache, config.InactiveCacheAgeLimitMinutes)
     }

     detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]

   

     ## javascript idleTimer to reset gui when its been inactive 
     ## see also server.R  observeEvent(input$timeOut)
     #numInactivityTimeoutSecond <- 30 #seconds
     inactivity <- sprintf("function idleTimer() {
     var t = setTimeout(resetMe, %s);
     window.onmousemove = resetTimer; // catches mouse movements
     window.onmousedown = resetTimer; // catches mouse movements
     window.onclick = resetTimer;     // catches mouse clicks
     window.onscroll = resetTimer;    // catches scrolling
     window.onkeypress = resetTimer;  //catches keyboard actions

     function resetMe() {
       Shiny.setInputValue('timeOut', '%ss')
     }

     function resetTimer() {
       clearTimeout(t);
       t = setTimeout(resetMe, %s);  // time is in milliseconds (1000 is 1 second)
     }
   }

   idleTimer();", config.InactivityTimeoutSeconds*1000, config.InactivityTimeoutSeconds, config.InactivityTimeoutSeconds*1000)


    
    