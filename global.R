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


####install.packages("rnaturalearthdata")


library(shiny)
# library(shiny.router)
library(shinymeta)
library(shinyjs)
library(shiny.i18n)

library(shinyWidgets)   # for pickerInput Widget flag thing

library(rvest)  #for  web scraping
library(tidyr) #for  web scraping


#### adding plots
library(lubridate) # for working with dates


library(sf) # mapping
#####library(rnaturalearth) # mapping


# SEE: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html
library(rgdal)
library(raster)
library(ggplot2)
library(rgeos)
library(mapview)
library(leaflet)
library(broom) # if you plot with ggplot and need to turn sp data into dataframes
options(stringsAsFactors = FALSE)


###library(viridis) # colour palettes for plotting
####
library(tidyverse)

default_UI_lang <- "en"


###### read configuration key/value pairs
library(data.table)
tryCatch( 
  {  
    #attempt to read file from current directory
    # use assign so you can access the variable outside of the function
    assign("configfrm", read.table(file='kiosk.cfg',header=FALSE,
                                   sep='=',col.names=c('Key','Value')), envir=.GlobalEnv) 
    print("Loaded installation data from local storage")
  },
  warning = function( w )
  {
    print()# dummy warning function to suppress the output of warnings
  },
  error = function( err ) 
  {
    print("Could not read cfg data from current directory, using defaults...")
    
    #attempt to read from alternate template
    tryCatch(
      {
        # use assign so you can access the variable outside of the function
        #attempt to read file from current directory
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
        print("Could not load configuration data. Exiting Program")
      }
    )
    
    
  })


#configfrm <- read.table(file='kiosk.cfg',header=FALSE,
#                        sep='=',col.names=c('Key','Value'))

#print("******* configfrm **********")
#str(configfrm)

configtbl <- data.table(configfrm, key='Key')

#print("******* config table **********")
#str(configtbl)

strMainLogoFile <- toString(configtbl['MainLogoFile'][1,2])
#print(strMainLogoFile)

strMainTitle <- toString(configtbl['MainTitle'][1,2])
#print(strMainLogoFile)

# get the value for the key, convert to numeric
lstValue <- configtbl['MainLogoHeight'][1,2]
numMainLogoHeight<- as.numeric(unlist(lstValue))
#print(numMainLogoHeight)

# get the value for the key, convert to numeric
lstValue <- configtbl['ReceiverID'][1,2]
rcvrID <- as.numeric(unlist(lstValue))
#rcvrID <- 7948   #Bullards Bridge 


# Add common utilities
#####source("modules/common_utils.R")


### load the data 
coastlines <- readOGR("map-data/ne-coastlines-50m/ne_50m_coastline.shp")
lakes <- readOGR("map-data/ne-lakes-50m/ne_50m_lakes.shp")

# Add individual modules here
source("modules/ReceiverDetections.R")
source("modules/tagDeploymentDetails.R")          #tagDeploymentDetails
source("modules/tagDeploymentDetections.R")       #the flightpath
source("modules/receiverDeploymentDetections.R")  #whats been at our receiver


# Initially populate the dataframes and we want these to be global variables...
detections_df <<- receiverDeploymentDetections(rcvrID)
detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]
