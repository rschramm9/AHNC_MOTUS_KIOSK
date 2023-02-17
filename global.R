###############################################################################
# Copyright 2022-2023 Richard Schramm
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
gblFooterText <- "USFWS Ankeny Hill Nature Center MOTUS Kiosk.  vsn 3.1.0  16-Feb-2023"
############### will be rendered into footer by server() ########## 


library(shiny)

library(shinymeta)
library(shinyjs)
library(shiny.i18n)

library(shinyWidgets)   # for pickerInput Widget flag thing

library(rvest)  #for  web scraping
library(tidyr) #for  web scraping

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

###### read configuration key/value pairs
library(data.table)


# Add individual modules here
source("modules/utility_functions.R")
source("modules/ReceiverDetections.R")
source("modules/tagDeploymentDetails.R")          #tagDeploymentDetails
source("modules/tagDeploymentDetections.R")       #the flightpath
source("modules/receiverDeploymentDetections.R")  #whats been at our receiver
source("modules/MotusNews.R")  #whats been at our receiver

tryCatch( 
  {  
    #attempt to read file from current directory
    # use assign so you can access the variable outside of the function
    assign("configfrm", read.table(file='kiosk.cfg',header=FALSE,
                                   sep='=',col.names=c('Key','Value')), envir=.GlobalEnv) 
    print("Loaded configuration data from local file kiosk.cfg")
  },
  warning = function( w )
  {
    print()# dummy warning function to suppress the output of warnings
  },
  error = function( err ) 
  {
    print("Could not read cfg data from current directory, using defaults...")
    print("here is the err returned by the read:")
    print(err)
    #attempt to read from alternate template
    tryCatch(
      {
        # use assign so you can access the variable outside of the function
        #attempt to read file from current directorygit commit glo
        # use assign so you can access the variable outside of the function
        assign("configfrm", read.table(file='sample.cfg',header=FALSE,
                                       sep='=',col.names=c('Key','Value')), envir=.GlobalEnv) 
        print("Loaded installation data from sample template")
      },
      warning = function( w )
      {
        print()# dummy warning function to suppress the output of warnings
      },
      error = function( err )
      {
        print("Config file read error: Could not load configuration data. Exiting Program")
        print("here is the err returned by the read:")
        print(err)
        stop("There is an error reading your cfg file")
      }
    )
    
    
  })


#print("******* configfrm **********")
#str(configfrm)

configtbl <- data.table(configfrm, key='Key')
#print("---------  The configtbl ------------")
#print(configtbl)
#print("-------------------------------------")

badCfg <- 0  #assume good config

    #print("------------ MainLogoFile ----------------")
    list1 <- keyValueToList(configtbl,'MainLogoFile')
    if( is.null(list1) ){
     badCfg <- 1 
     strMainLogoFile<-NULL
    } else {
     #I ultimately want a string
     strMainLogoFile<- toString(list1[1])  
    }
    #print(paste0("MainLogoFile:", strMainLogoFile))
  
    #print("------------ MainTitle ----------------")
    list1 <- keyValueToList(configtbl,'MainTitle')
    if( is.null(list1) ){
      badCfg <- 1 
      strMainTitle<-NULL
    } else {
      #I ultimately want a string
      strMainTitle<- toString(list1[1])  
    }
    #print(paste0("MainTitle:",strMainTitle))
    
    
    #print("------------ MainLogoHeight --------------")
    list1 <- keyValueToList(configtbl,'MainLogoHeight')
    if( is.null(list1) ){
      badCfg <- 1 
      numMainLogoHeight <- NULL
    } else {
      numMainLogoHeight <- as.numeric(list1[1]) #assume length=1
    }
    #print(paste0("MainLogoHeight:",numMainLogoHeight))
    

    #print("------------ ReceiverDeploymentID --------------")
    #the default target receiver is the first list item
    lstReceiverDeployments <- keyValueToList(configtbl,'ReceiverDeploymentID')
    if( is.null(list1) ){
      badCfg <- 1 
      receiverDeploymentID <- NULL
    } else {
      receiverDeploymentID <- as.numeric(lstReceiverDeployments[1]) #assume length=1
    }
    #print(paste0("global.R @170: ReceiverDeploymentID:",receiverDeploymentID))
    
    #print("------------ ReceiverShortName ----------------")
    #we can get a list, and the initial choice will be the first list element
    lstReceiverShortNames <- keyValueToList(configtbl,'ReceiverShortName')
    if( is.null(lstReceiverShortNames) ){
      badCfg <- 1
      strReceiverShortName<-NULL
    } else {
      #I ultimately want a string
      strReceiverShortName<- toString(lstReceiverShortNames[1])  
    }
    #print(paste0("ReceiverShortName:",strReceiverShortName))
    
     #print("------------ MovingMarkerIcon ----------------")
     list1 <- keyValueToList(configtbl,'MovingMarkerIcon')
     if( is.null(list1) ){
       badCfg <- 1 
       strMovingMarkerIcon<-NULL
     } else {
       #I ultimately want a string
       strMovingMarkerIcon<- toString(list1[1])  
     }
     #print(paste0("MovingMarkerIcon:",strMovingMarkerIcon))
     
     #print("------------ MovingMarkerIconWidth --------------")
     list1 <- keyValueToList(configtbl,'MovingMarkerIconWidth')
     if( is.null(list1) ){
       badCfg <- 1 
       numMovingMarkerIconWidth<-NULL
     } else {
       numMovingMarkerIconWidth <- as.numeric(list1[1]) #assume length=1
     }
     #print(paste0("MovingMarkerIconWidth:",numMovingMarkerIconWidth))
     
     
     #print("------------ MovingMarkerIconHeight --------------")
     list1 <- keyValueToList(configtbl,'MovingMarkerIconHeight')
     if( is.null(list1) ){
       badCfg <- 1 
       numMovingMarkerIconHeight<-NULL
     } else {
       numMovingMarkerIconHeight<- as.numeric(list1[1]) #assume length=1
     }
     #print(paste0("MovingMarkerIconHeight:",numMovingMarkerIconHeight))
     
     #print("------------ InactivityTimeoutSeconds --------------")
     list1 <- keyValueToList(configtbl,'InactivityTimeoutSeconds')
     if( is.null(list1) ){
       numInactivityTimeoutSeconds<-1800 #30 minutes
     } else {
       numInactivityTimeoutSeconds<- as.numeric(list1[1]) #assume length=1
     }
     #print(paste0("MovingMarkerIconHeight:",numMovingMarkerIconHeight))
     
     #print("-----------------Done processing config----------------------------------")
     
     #halt if config processing didn't finish cleanly
     if( badCfg == 1){
       stop("There is an error in your kiosk cfg file")
     }
     
     # these two lists support the receiver Picklist
     if( length(lstReceiverShortNames) != length(lstReceiverDeployments) ){
        stop("There is a problem with your kiosk.cfg file. THe ReceiverShortName list must be same length as ReceiverIDs list")
     }
     
     # the shortnames list contains the visible choices on the dropdown
     # here we make a dataframe from the shortnames and the deployment ids, later we
     # use the reactive picklist choice to filter the dataframe to get the desired deployment id
     gblReceivers_df <<- data.frame(unlist(lstReceiverShortNames),unlist(lstReceiverDeployments))
     #to name the columns we use names() function
     names(gblReceivers_df) = c("shortName","receiverDeploymentID")
     selectedreceiver <<- filter(gblReceivers_df, shortName == strReceiverShortName)
    
     # NOTE the use of global assignments
     receiverDeploymentID <<- selectedreceiver["receiverDeploymentID"]
   
     # Initially populate the dataframes here
     # we want these to be global variables... (note the <<- ) 

     detections_df <<- receiverDeploymentDetections(receiverDeploymentID)
     #print (detections_df)

     detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]

    
     tryCatch ( 
     {  
         f <- paste0(getwd(),"/exclude_detections",".csv")
         if (file.exists(f)){
            exclude_df <- read.table(file=f, sep = ",", as.is = TRUE, header=TRUE)
            exclude_df[[1]] <- as.Date(exclude_df[[1]])
         } else { exclude_df= NULL }
    
     },
     warning = function( w )
     {
         print() # dummy warning function to suppress the output of warnings
         exclude_df= NULL
     },
     error = function( err )
     {
       print("exclude_detections.csv read error")
       print("here is the err returned by the read:")
       print(err)
       exclude_df= NULL
     } )
    
      #data[,1] <- strptime(data[,1], "%Y-%m-%d")
    
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

   idleTimer();", numInactivityTimeoutSeconds*1000, numInactivityTimeoutSeconds, numInactivityTimeoutSeconds*1000)


    
    