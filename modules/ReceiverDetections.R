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

# 
# TODO
# - split main interface into module-specific left panel and generic outputs for main panel
# - add stratified randomization

#####################
#      UI PART      #
#####################
library(DT)

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
                          tabPanel(i18n$t("ui_RCVR_detections_map_tab_label"), 
                                   helpText(i18n$t("ui_RCVR_detections_map_tab_helptext")),
                  
                                   plotOutput(ns('map'), width = "100%")
                                  
                          ),
                          
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
# end funcion def for UI_ReceiverDetections







#####################
#    SERVER PART    #
#####################

SERVER_ReceiverDetections <- function(id, i18n_r, lang) {
  
   moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns

    # Some code for UI observers, 
    
    
    # A non-reactive function that will be available to each user session
    # populate detections_df and detections_subset_df as needed and render to sidebar table
     myTagsToTable <- function(x) {
      
      if ( nrow(detections_df) <= 0 ) {
          #note <<- is assignment to global variable, also note rcvrID is global
          detections_df <<- receiverDeploymentDetections(rcvrID)  
      }
       
      #sort detections so most recent appears at top of list
      detections_df <<- detections_df[ order(detections_df$tagDetectionDate,decreasing = TRUE), ]
       
       #subset the data frame to form a frame with only the columns we want to show
      #also a global assignment 
      detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]
      
    
      #output$mytable <- DT::renderDataTable(detections_subset_df, selection = "single",
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
   
    ######################################################
    observeEvent( session$clientData, {
        #  message("**session started ***")
      myTagsToTable()
    }) #end observeEvent for session start
    
    observeEvent(input$btnQuery, {
      message("**query button pressed ***")
      myTagsToTable()
    }) #end observeEvent for for requery button
    
    # Some UI elements should be updated on the Server side:
    # Update Radiobuttons and arm text values when language is changed
    observeEvent(lang(), {
      i18n_r()$set_translation_language(lang())
      
      #updateRadioButtons(session, "DESIGN", label = i18n_r()$t("ui_RAND_input_method"),
      #                   choices =
      #                     setNames(c("simple","block"),
      #                             i18n_r()$t(c("ui_RAND_input_methodsimple","ui_RAND_input_methodblocked")) ),
      #                   selected=input$DESIGN)

    })
    
    observeEvent(input$mytable_rows_selected,{
      #message("***** row selected 1 ******")
      #print(!is.null(input$mytable_rows_selected))
      #s <-  input$mytable_rows_selected
      #print(s)
   
      print(detections_df)
      #see:https://stackoverflow.com/questions/55799093/select-and-display-the-value-of-a-row-in-shiny-datatable   
      ####output$selectedItem <- renderText({
      #message("***** row selected 3 ******")
        selectedrowindex <- input$mytable_rows_selected
        #print(class(selectedrowindex))
        
        selectedrowindex <- as.numeric(selectedrowindex)
        #print(selectedrowindex)
       
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

        #print(class(tagDepID))
        #print(tagDepID)
        
        
       ### })
    
        
        tagdetails_df <- tagDeploymentDetails(tagDepID)  
        
       
        output$tagdetail <- DT::renderDataTable(tagdetails_df,
                                                selection = "single", 
                                                options=list(dom = 'Bfrtip',
                                                             searching = F
                                                             ))
        ## note this is a local variable assignment
        tagflight_df <- tagDeploymentDetections(tagDepID)
        
        #sort flight detections so most recent appears at bottom of the list
        tagflight_df <- tagflight_df[ order(tagflight_df$date, decreasing = FALSE), ]
       
        
        
        output$flightpath <- DT::renderDataTable(tagflight_df,
                                                 selection = "single", 
                                                 options=list(dom = 'Bfrtip',
                                                              searching = F
                                                 ))
        
        # see: https://motuswts.github.io/motus/articles/06-exploring-data.html
        # set limits to map based on locations of detections, ensuring they include the
        # deployment locations
        xmin <- min(tagflight_df$lon, na.rm = TRUE) - 2
        xmax <- max(tagflight_df$lon, na.rm = TRUE) + 2
        ymin <- min(tagflight_df$lat, na.rm = TRUE) - 1
        ymax <- max(tagflight_df$lat, na.rm = TRUE) + 1
      
        print(xmin)
        print(xmax)
        print(ymin)
        print(ymax)
        
        print(tagflight_df)
        
        coastlines_df <- SpatialLinesDataFrame(coastlines, coastlines@data) 
        data_sf <- coastlines_df %>%
          st_as_sf()
        
        
        
        # map
        output$map<-renderPlot(
          

         ggplot(data = data_sf) +
           geom_sf() +
       
           coord_sf(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = FALSE) +
           theme_bw() + 
           labs(x = "", y = "") +
           geom_path(data = tagflight_df, 
                     aes(x = lon, y = lat, 
                         #group = as.factor(tagid),
                         colour = as.factor(tagDepID))) +
           geom_point(data = tagflight_df,
                      aes(x = lon, y = lat), 
                      shape = 16, colour = "black") +
     
           scale_colour_discrete("TagDeploymentID") 
         
        ) #end renderPlot
        
     
    })  # end observeEvent   tableRowsSelect
    

  })

}




