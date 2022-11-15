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

# This app's structure utilizes techniques for creating a multilanguage
# modularized app as described by Eduard Parsadanyan in his article at: 
# https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
# and was learned via exploring his ClinRTools modularized demo found at:
# https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/

# This app uses the i18n package to perform language translations
# i18n package is Copyright Copyright (c) 2016 Appsilon Sp. z o.o.
# and distributed under MIT license. see:https://github.com/Appsilon/shiny.i18n


# Globals: libraries, modules etc.


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
print("---------  The configtbl ------------")
print(configtbl)
print("-------------------------------------")

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
    #for now assume its length=1, but later we may want to support many
    list1 <- keyValueToList(configtbl,'ReceiverDeploymentID')
    if( is.null(list1) ){
      badCfg <- 1 
      receiverDeploymentID <- NULL
    } else {
      receiverDeploymentID <- as.numeric(list1[1]) #assume length=1
    }
    #print(paste0("ReceiverDeploymentID:",receiverDeploymentID))
    
    
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
     

     #print("------------ ReceiverShortName ----------------")
     #for now assume its length=1, but later we may want to support many
     list1 <- keyValueToList(configtbl,'ReceiverShortName')
     if( is.null(list1) ){
       badCfg <- 1
       strReceiverShortName<-NULL
     } else {
         #I ultimately want a string
         strReceiverShortName<- toString(list1[1])  
     }
     #print(paste0("ReceiverShortName:",strReceiverShortName))
     
     #print("-----------------Done processing config----------------------------------")
     
     
     #halt if config processing didn't finish cleanly
     if( badCfg == 1){
       stop("There is an error in your kiosk cfg file")
     }
     
     
# Initially populate the dataframes here
# we want these to be global variables... (note the <<- ) 
     
#print("======== in global.R  try to load detectionf_df ========")
detections_df <<- receiverDeploymentDetections(receiverDeploymentID)
#print (detections_df)
#print("============================================")

detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]
