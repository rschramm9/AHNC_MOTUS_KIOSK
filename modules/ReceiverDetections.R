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


#####################
#      UI PART      #
#####################
library(DT)

library(anytime)

UI_ReceiverDetections <- function(id, i18n) {
  
  ns <- NS(id)
  
  fluidPage(
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("hr {border-top: 1px solid #000000;}"))
    ),
    
      titlePanel(
        div(
         span(
            i18n$t("ui_RCVR_title"), 
            style="color:#8FBC8F;font-style: italic;font-size: 25px; background-color:white",
            
            ### enable this span block if you want the ui button to "Requery Motus"
            # span(
            # actionButton(ns("btnQuery"),i18n$t("ui_RCVR_input_requery_button_caption"),
            #        style="position:absolute;left:350px;",
            #        ),
            # ) # end span2
         ) # end span1
      ) #end div
      
      ), #end titlepanel
    
    #), #end fluid row
     
    sidebarLayout(
      sidebarPanel(width = 4,
                   #hr(),
                   #helpText(i18n$t("ui_RCVR_input_requery_label_help_text")),
                   #actionButton(ns("btnCalculate"),i18n$t("ui_RCVR_input_requery_button_caption")),
                   #p(),
                   DT::dataTableOutput( ns('mytable') )
                   
      ),
      mainPanel(width = 8,
              
              tabsetPanel(type = "tabs",
                          tabPanel(i18n$t("ui_RCVR_detections_details_tab_label"), 
                                   helpText(i18n$t("ui_RCVR_detections_details_tab_helptext")),
                                   DT::dataTableOutput( ns('tagdetail') )
                          ),
                          tabPanel(i18n$t("ui_RCVR_detections_flightpath_tab_label"), 
                                   helpText(i18n$t("ui_RCVR_detections_flightpath_tab_helptext")),
                                   DT::dataTableOutput( ns('flightpath') )
                                   
                          ),
                          
                          # implement a map using leaflet
                          
                          # TODO: This worked but height="60vh" was determined by trial and error
                          # see: https://stackoverflow.com/questions/36469631/how-to-get-leaflet-for-r-use-100-of-shiny-dashboard-height/36471739#36471739
                          # tabPanel(i18n$t("ui_RCVR_detections_leaflet_tab_label"), 
                          #          helpText(i18n$t("ui_RCVR_detections_map_tab_helptext")),
                          #          leafletOutput(ns('leaflet_map'), width = "100%", height="60vh")
                          # ),
                          
                          # TODO: This works but height calc using 425px was determined by trial and error
                          # should be either configurable in kiosk.cfg or possibly needs to be changed based on
                          # the tabbed panel container height somehow.
                          tags$style(type = "text/css", paste0("#",ns('leaflet_map')), "{height: calc(100vh - 425px) !important;}"),
                          tabPanel(i18n$t("ui_RCVR_detections_leaflet_tab_label"), 
                                   helpText(i18n$t("ui_RCVR_detections_leaflet_tab_helptext")),
                                   actionButton( ns("fly"),    label = i18n$t("ui_RCVR_fly_button_caption")),
                                   actionButton( ns("stop"),   label = i18n$t("ui_RCVR_stop_button_caption")),
                                   actionButton( ns("pause"),  label = i18n$t("ui_RCVR_pause_button_caption")),
                                   actionButton( ns("resume"), label = i18n$t("ui_RCVR_resume_button_caption")),
                                   
                                   leafletOutput(ns("leaflet_map"), width = "100%", height="100%")
                          ),
                          
                          # TODO: enable this for a future spcies tab
                         tabPanel( i18n$t("ui_RCVR_detections_species_tab_label"), 
                                    # helpText(i18n$t("ui_RCVR_detections_species_tab_helptext")),
                                    htmlOutput(ns("species"))
               
                          ) #end tabPanel species
        
              ) #end tabsetPanel            
       ) #end mainPanel
    ) # end sidebarLayout
  ) #end fluidPage
}  # end function def for UI_ReceiverDetections

#####################
#    SERVER PART    #
#####################

SERVER_ReceiverDetections <- function(id, i18n_r, lang, rcvr) {
  
   moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
    
    #print("-----Initial selected species - module global scope -------------------")
    selected_species <- "unknown"
    species_key <- "unknown"
 
    
     # icon location an size from kiosk.cfg, set in global.R
    birdIcon <- makeIcon(
      iconUrl = strMovingMarkerIcon,
      iconWidth = numMovingMarkerIconWidth, iconHeight = numMovingMarkerIconHeight,
      iconAnchorX = 0, iconAnchorY = 0,
      shadowUrl = strMovingMarkerIcon,
      shadowWidth = numMovingMarkerIconWidth, shadowHeight = numMovingMarkerIconHeight,
      shadowAnchorX = 0, shadowAnchorY = 0
    )
    
    ################### methods to control MovingMarkers (bird in flight)
    observeEvent(input$fly, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"startMoving","movingmarker")
    })
    
    observeEvent(input$pause, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"pauseMoving","movingmarker")
    })
    
    observeEvent(input$resume, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"resumeMoving","movingmarker")
    })
    
    observeEvent(input$stop, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"stopMoving","movingmarker")
    })
    
    #####################################################################
    
    # Some code for UI observers, 

    # A non-reactive function that will be available to each user session
    # populate detections_df and detections_subset_df as needed and render to sidebar table
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    #function to take the species key and the current language setting and try
    #to load a species info html file containiong a photo and some interesting facts
    #about the currently selected bird 
    updateSpeciesInfo <- function() {    
   
    #file like "/Users/rich/Projects/AHNC_MOTUS_KIOSK/www/docs/species_unknown_en.html") 

    #get the default 'species_unknown' html filename matching the current language    
    xxx <- i18n_r()$t("species_unknown")  
    #substitute the word 'unknown' in the filename with the species key
    yyy <- str_replace(xxx,"unknown",species_key)

    #if the species-specific file exists, use it, else use the species unknown file
    if (file.exists(yyy)) {
      zzz <- includeHTML(yyy)
    } else {
      zzz <- includeHTML(xxx)
    }
    
    output$species <- renderUI(zzz)
   } #end updateSpeciesInfo()
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------  
   # A non-reactive function that will be available to each user session
   # populate global detections_df and detections_subset_df as needed and render to sidebar table
   myTagsToTable <- function(x) {

   #note <<- is assignment to global variable, also note receiverDeploymentID is global
   detections_df <<- receiverDeploymentDetections(receiverDeploymentID)

   #sort detections so most recent appears at top of list notice we are woking with a global variable ( <<- )
   detections_df <<- detections_df[ order(detections_df$tagDetectionDate,decreasing = TRUE), ]

   #subset the data frame to form a frame with only the columns we want to show
   # note also it's a global assignment 
   detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]
         
   output$mytable <- DT::renderDataTable(detections_subset_df,
                                            selection = list(mode = 'single',
                                            selected = c(1) ),
                                            extensions = c('ColReorder', 'FixedHeader', 'Scroller'),
                                            colnames = c("Date", "TagDepId", "Species") ,
                                            rownames=FALSE,
                                            options=list(dom = 'Bfrtip',
                                                         searching = F,
                                                         pageLength = 25,
                                                         searchHighlight = TRUE,
                                                         colReorder = TRUE,
                                                         fixedHeader = TRUE,
                                                         filter = 'bottom',
                                                         #buttons = c('copy', 'csv','excel', 'print'),
                                                         paging    = TRUE,
                                                         deferRender = TRUE,
                                                         scroller = TRUE,
                                                         scrollX = TRUE,
                                                         scrollY = 700
                                            ))
    } # end function myTagsToTable

   #-------------------------------------------------------------------------------------------------------------
   #   
   #-------------------------------------------------------------------------------------------------------------  
     
    observeEvent( session$clientData, {
      #  message("**session started ***")
      myTagsToTable()
    }) #end observeEvent for session start
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------    
    ## requery motus button has been commented out as it was only for testing
    #  observeEvent(input$btnQuery, {
    #   message("**query button pressed ***")
    #   myTagsToTable()
    #  }) #end observeEvent for for requery button
    
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    # Some UI elements should be updated on the Server side:
    # Update text values when language is changed
    #note lang() is handle to the language input picklist passed in from server.R
    observeEvent(lang(), {
      i18n_r()$set_translation_language(lang())
      updateSpeciesInfo()
    }) #end observeEvent(lang()
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    observeEvent(input$mytable_rows_selected,{

      #see:https://stackoverflow.com/questions/55799093/select-and-display-the-value-of-a-row-in-shiny-datatable   
        selectedrowindex <- input$mytable_rows_selected
        selectedrowindex <- as.numeric(selectedrowindex)
        selectedrow <- paste(detections_subset_df[selectedrowindex,],collapse = ", ")
    
        #this could return NA is the subset is empty... we will have to trap
        #those below by testing this value
        tagDepID <- detections_subset_df[selectedrowindex,2]
 
        #updating the species information tab.
        #when a new row is selected in the tag deployments table
        #extract the selected species name and see if we can build a species name 'key'
        #that updateSpeciesInfo() can substitute into the default 'species_unknown_xx,html'
        #filename to pull in a new html file documenting the the species.
        # NOTE: global assignment operator as species_key is needed outside of this
        # functions scope 
        
        #get the selected species and strip unwanted chars and then lowercase() it
        #e.g."Swainson's Thrush" becomes key = "swainsonsthrush"
        selected_species <- detections_subset_df[selectedrowindex,3]
        #no special chars
        species_key <<- gsub('[^[:alnum:] ]','',selected_species)
        #no tabs or newline
        species_key <<- gsub('[\t\n]','',species_key)
        #no spaces
        species_key <<- gsub(' ','', species_key)
        #lowercase
        species_key <<- tolower(species_key)
        
        updateSpeciesInfo()
        
        if (is.na(tagDepID )) {
            mydf <- data.frame( matrix( ncol = 9, nrow = 1) )
            colnames(mydf) <- c('tagid', 'project', 'contact', 'started','species','lat','lon','ndays', 'nreceivers')
            tagdetails_df <- mydf
        } else {
           #next get and render the tagDeploymentDetails (who tagged, where, when etc)
           tagdetails_df <- tagDeploymentDetails(tagDepID)  
        }
        
        output$tagdetail <- DT::renderDataTable(tagdetails_df,
                                                selection = "single", 
                                                options=list(dom = 'Bfrtip',
                                                             searching = F
                                                             ))
        
        #if the tag deployment id is null there wont be any flight data, so just make an empty one
        if (is.na(tagDepID )) {
             mydf <- data.frame( matrix( ncol = 4, nrow = 1) )
             colnames(mydf) <- c('date', 'site', 'lat', 'lon')
             tagflight_df<-mydf
       } else {
             #next get all of the detections associated with this tag deployment
             # note this is a local variable assignment
             tagflight_df <- tagDeploymentDetections(tagDepID)
       
             #add the tag deployment release point data to the flight path dataset
             #there has to be a better way but my R convert datetime to date skills arent up to it...
             releasepoint_df<-tagdetails_df[c("started","species","lat","lon")]
             my_date<-as_date(releasepoint_df$started)
             my_site<-"Tagged"
             my_lat = releasepoint_df$lat
             my_lon = releasepoint_df$lon
             tagflight_df[nrow(tagflight_df) + 1,] <- data.frame(my_date, my_site, my_lat, my_lon)

             #sort flight detection so most recent appears at bottom of the list
             tagflight_df <- tagflight_df[ order(tagflight_df$date, decreasing = FALSE), ]

       } #end if

 
       # and render it
        output$flightpath <- DT::renderDataTable(tagflight_df,
                                                 selection = "single", 
                                                 options=list(dom = 'Bfrtip',
                                                              searching = F,
                                                              "pageLength" = 18
                                                              ) #end options
                                                 ) #end render()
     
        #saveRDS(subset_df, file="subset.RDS")
        
        if (is.na(tagDepID )) {   
            myLeafletMap = leaflet() %>% addTiles() #render the empty map
        } else {  #render the real map
        # next make the moving markers for the flightpath and then later assemble with the leaflet map
        
        # make a geometry dataframe for the moving marker
        # this will be our 'coordinate reference system'
        projcrs <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
        
        # convert travel_df to a 'simple features dataframe' using the coordinate reference system
        # with columns: time,geometry
        # we will add the markers in constructing the leaflet map
        flight_sf <<- st_as_sf(x = tagflight_df,                         
                               coords = c("lon", "lat"),
                               crs = projcrs)

        # labels for leaflet map popups
        label_text <- glue(
          "<b>Name: </b> {tagflight_df$site}<br/>",
          "<b>Date: </b> {tagflight_df$date}<br/>",
          "<b>Latitude: </b> {tagflight_df$lat}<br/>",
          "<b>Longitude: </b> {tagflight_df$lon}<br/>") %>%
          lapply(htmltools::HTML)
        
        myLeafletMap = leaflet(data=tagflight_df) %>%
          addTiles() %>%
          
          addPolylines(lat= ~lat, lng = ~lon) %>%
          ### enable next line if we want site labels to appear as each new map is rendered
          ### addPopups(lat= ~lat, lng = ~lon, popup = ~site) %>%    
      
          addCircleMarkers(
            lng=~lon,
            lat=~lat,
            radius=5,
            stroke=FALSE,
            fillOpacity=0.5,
            #color=~color??, # color circle 
            popup=label_text
          ) %>%
          
          # OPTIONAL: for touchscreens: we add a 2nd set of markers that have bigger radius and 
          # are completely transparent to implement a larger touchable target.
          addCircleMarkers(
            lng=~lon,
            lat=~lat,
            
            radius=15,
            stroke=FALSE,
            fillOpacity=0.0,
            popup=label_text
          ) %>%
          
          #now add the MovingMarker layer
          addMovingMarker(data = flight_sf,
                          movingOptions = movingMarkerOptions(autostart = TRUE, loop = FALSE),
                          layerId="movingmarker",
                          duration=8000,
                          icon = birdIcon,
                          label="",
                          popup="")
        
        } # end else tagDepID is not null
        

        # render the output object named leaflet_map
        output$leaflet_map = renderLeaflet(myLeafletMap) 
 
    })  # end observeEvent for mytable_rows_selected
    
#-------------------------------------------------------------------------------------------------------------
#   
#-------------------------------------------------------------------------------------------------------------    
    # receivers picker input reactive observer
    # note the main page server.R also has an event observer for this input
    # note rcvr() is handle to the receivers input picklist passed in from server.R
    observeEvent(rcvr(), {
      # NOTE the use of global assignments
      strReceiverShortName <<- rcvr()  #global assignment

      # on new receiver selection via the picker
      # update the global string strReceiverShortName
      # and use it to filter the global dataframe of shortnames and ID's to update
      # the global variable receiverDeploymentID. Then call myTagsToTable()
      #to populate the sidebar with a new list of detections
      
      selectedreceiver <- filter(gblReceivers_df, Name == strReceiverShortName)      
      receiverDeploymentID <<- selectedreceiver["ID"]
      
      myTagsToTable()
 
    })  #end observeEvent input$receiver_pick
  
    
  }) #end moduleServer

}  # end SERVER_ReceiverDetections()




