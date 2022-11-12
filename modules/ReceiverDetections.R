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
                                   actionButton( ns("fly"),    label = "Fly"),
                                   actionButton( ns("pause"),  label = "Pause"),
                                   actionButton( ns("resume"), label = "Resume"),
                                   actionButton( ns("stop"),   label = "Stop"),
                                   leafletOutput(ns("leaflet_map"), width = "100%", height="100%")
                          ),
                          
                          # TODO: enable this for a future spcies tab
                          #   tabPanel(i18n$t("ui_RCVR_detections_species_tab_label"), 
                          #            helpText(i18n$t("ui_RCVR_detections_species_tab_helptext")),
                          #            ##tableOutput(ns('species_out'))
                          #            
                          #   ),
                          
              ) #end tabsetPanel            
       ) #end mainPanel
    ) # end sidebarLayout
  ) #end fluidPage
  
} 
# end function def for UI_ReceiverDetections

#####################
#    SERVER PART    #
#####################

SERVER_ReceiverDetections <- function(id, i18n_r, lang) {
  
   moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
   
    
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
     myTagsToTable <- function(x) {
      
      if ( nrow(detections_df) <= 0 ) {
          #note <<- is assignment to global variable, also note receiverDeploymentID is global
          detections_df <<- receiverDeploymentDetections(receiverDeploymentID)
      }

      #sort detections so most recent appears at top of list notice we are woking with a global variable ( <<- )
      detections_df <<- detections_df[ order(detections_df$tagDetectionDate,decreasing = TRUE), ]
      
     #print("========= detections_df from receiverDeploymentDetections(receiverDeploymentID)  ====================")
     #print(detections_df)
     #print("================================================================+++++================================")
      
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
    }

    observeEvent( session$clientData, {
        #  message("**session started ***")
      myTagsToTable()
    }) #end observeEvent for session start
    
    
    ## requery motus button has been commented out as it was only for testing
    #  observeEvent(input$btnQuery, {
    #   message("**query button pressed ***")
    #   myTagsToTable()
    #  }) #end observeEvent for for requery button
    
    # Some UI elements should be updated on the Server side:
    # Update text values when language is changed
    observeEvent(lang(), {
      i18n_r()$set_translation_language(lang())
    })
    
    observeEvent(input$mytable_rows_selected,{
      #message("***** row selected 1 ******")
      #print(!is.null(input$mytable_rows_selected))
      #s <-  input$mytable_rows_selected
      #print(s)
   

      #see:https://stackoverflow.com/questions/55799093/select-and-display-the-value-of-a-row-in-shiny-datatable   
        selectedrowindex <- input$mytable_rows_selected
        selectedrowindex <- as.numeric(selectedrowindex)

        selectedrow <- paste(detections_subset_df[selectedrowindex,],collapse = ", ")
        #print(selectedrow)
        
        #biggerrow <- paste(detections_df[selectedrowindex,],collapse = ", ")
        #print(biggerrow)
        ## 'tagDetectionDate','tagDeploymentID','tagDeploymentName','species','tagDeploymentDate','lat','lon')
        ##selectedrow
        #print(class(biggerrow))
        #species <- biggerrow[[4]]
        #species <- paste(detections_df[selectedrowindex,4],collapse = ", ")
        #print(species)
       
        tagDepID <- detections_subset_df[selectedrowindex,2]
 
        tagdetails_df <- tagDeploymentDetails(tagDepID)  
        #print("================== tagdetails_df from tagDeploymentDetails(tagDepId) ======================")
        #print(tagdetails_df)
        #print("============================================================================================")

        output$tagdetail <- DT::renderDataTable(tagdetails_df,
                                                selection = "single", 
                                                options=list(dom = 'Bfrtip',
                                                             searching = F
                                                             ))
        ## note this is a local variable assignment
        tagflight_df <- tagDeploymentDetections(tagDepID)
        
        #add the tag and release point data to the flight path dataset
        #there has to be a better way but my R convert datetime to date skills arent up to it...
        releasepoint_df<-tagdetails_df[c("started","species","lat","lon")]
        my_date<-as_date(releasepoint_df$started)
        my_site<-"Tagged"
        my_lat = releasepoint_df$lat
        my_lon = releasepoint_df$lon
        tagflight_df[nrow(tagflight_df) + 1,] <- data.frame(my_date, my_site, my_lat, my_lon)
        
        #sort flight detections so most recent appears at bottom of the list
        tagflight_df <- tagflight_df[ order(tagflight_df$date, decreasing = FALSE), ]
       
        output$flightpath <- DT::renderDataTable(tagflight_df,
                                                 selection = "single", 
                                                 options=list(dom = 'Bfrtip',
                                                 searching = F
                                                 ))
     
        #print("================== tagflight_df from tagDeploymentDetections(tagDepId) ======================")
        #print(tagflight_df)
        #print("============================================================================================")
        
        #saveRDS(subset_df, file="subset.RDS")
        
        # make a geometry dataframe for the moving marker
        # this will be our 'coordinate reference system'
        projcrs <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
        
        # convert travel_df to a 'simple features dataframe' using the coordinate reference system
        # with columns: time,geometry
        # we willl add the markers in constructing the leaflet map
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
          
          # add 2nd set of markers that are bigger radius but completely transparent
          # to implement a larger touch-target for the touchscreen
          addCircleMarkers(
            lng=~lon,
            lat=~lat,
            radius=15,
            stroke=FALSE,
            fillOpacity=0.0,
            popup=label_text
          ) %>%
          
          #now add the MovingMarker
          addMovingMarker(data = flight_sf,
                          movingOptions = movingMarkerOptions(autostart = TRUE, loop = FALSE),
                          layerId="movingmarker",
                          duration=10000,
                          icon = birdIcon,
                          label="",
                          popup="")
        
        # render the output object named leaflet_map
        output$leaflet_map = renderLeaflet(myLeafletMap) 
        
    })  # end observeEvent for mytable_rows_selected

  }) #end moduleServer

}  # end SERVER_ReceiverDetections()




