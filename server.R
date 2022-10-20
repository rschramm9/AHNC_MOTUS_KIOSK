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
  

  # Language picker
  observeEvent(input$lang_pick, {
    update_lang(session, input$lang_pick)
    #TODO: next line is apparently not required
    #i18n$set_translation_language(input$lang_pick)
    
    # Refresh readme file on the main home page tab of the navbar
    removeUI(selector ="#readmediv", immediate = TRUE)
    insertUI(immediate = TRUE,
             selector = '#readmehere', session=session,
             ui = div(id="readmediv",
                      includeHTML(
                        as.character(i18n$get_translations()["ui_mainpage_readmefile",input$lang_pick])
                                  )
                      )
    )
    
  })
  
  
  
  # Pass language selection into the module for Server-side translations
  # If not done, some UI elements will not be updated upon language change
 
 SERVER_ReceiverDetections("ReceiverDetections"  ,i18n_r = reactive(i18n), lang = reactive(input$lang_pick))

 }

