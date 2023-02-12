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
# https://bitbucket.org/satsconsult/clinrtoolsdemo/src/master/

# 
# Dashboard sources all modules
# Each module has it's own UI and Server part
# Additionally, common module UI is called for each module (output, source code, system version)
# 

# Add all server functions from each module here
server <- function(input, output, session) {

  # Load translations
  # setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  i18n <- Translator$new(translation_csvs_path = paste0("data/translations"),
                         separator_csv="|")
  i18n$set_translation_language(default_UI_lang)
 
  
  # render the versioning text string set in global.R to the
  # main page footer output
  output$footer<-renderText({gblFooterText})
  
  
  
  
  # On inactivity timeout, reset the dashboard UI to startup defaults
  observeEvent(input$timeOut, { 
    print(paste0("Session (", session$token, ") timed out at: ", Sys.time()))
    session$reload()
  })
  

  # Language picker
  observeEvent(input$lang_pick, {
    # 07Feb2023 workaround bug found in shiny.i18n package update_lang() function
    # order of arguments reversed issue.. specify arguments by name instead of
    # by position.
    update_lang(session=session, language=input$lang_pick)
    
    # Refresh readme file on the main home page tab of the navbar
    removeUI(selector ="#readmediv", immediate = TRUE)
    insertUI(immediate = TRUE,
             selector = '#readmehere', session=session,
             ui = div(id="readmediv",
                includeHTML( as.character(i18n$get_translations()["ui_mainpage_readmefile",input$lang_pick]) )
             )
    ) #end insertUI
    
  })  #end observeEvent
  
  
  # the receiver picker input reactive observer need to update
  # the main page title when a new receiver is picked
  # note the SERVER_ReceiverDetections() also has an event observer for
  # this input, see ReceiverDetections.R
  observeEvent(input$receiver_pick, {
    output$main_page_title<-renderText({
      dynamic_title <- input$receiver_pick
      paste(strMainTitle, dynamic_title)})
    
  })  #end observeEvent input$receiver_pick
  

  # Pass language selection into the module for Server-side translations
  # If not done, some UI elements will not be updated upon language change
  # Also pass the receiver picker as it will need to be observed by a reactive
  # event in SERVER_ReceiverDetection also
 SERVER_ReceiverDetections("ReceiverDetections"  ,i18n_r = reactive(i18n), lang = reactive(input$lang_pick), rcvr= reactive(input$receiver_pick))

 }

