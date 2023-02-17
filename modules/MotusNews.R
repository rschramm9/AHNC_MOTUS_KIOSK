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


UI_MotusNews <- function(id, i18n) {
  
  ns <- NS(id)
  
  fluidPage(
    
    #this needs to be here or else some parts of ui
    #dont get translated (eg. the navbar)
    shiny.i18n::usei18n(i18n),
    
    tags$head(
      tags$style(HTML("hr {border-top: 1px solid #000000;}"))
    ),

    
    tags$div(id = 'newsgoeshere',
             div(id="readmediv",
                 #tags$h4(i18n$t("ui_motusnews_loading")),
                 htmlOutput(ns("news"))
             )
    )
   
  ) #end fluidPage
  
}  # end function def for UI_MotusNews

#####################
#    SERVER PART    #
#####################

SERVER_MotusNews <- function(id, i18n_r, lang, rcvr) {
  
  moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
    

    # A non-reactive function that will be available to each user session
    # populate the motus news section with either a default page or 'current'
    #-------------------------------------------------------------------------------------------------------------  
    myRenderFunction <- function(x) {
      
      # dont need to know this at the mopment...
      # selected = i18n_r()$get_translation_language()  #e.g. 'en' or 'es'"
      

      # file like "/Users/rich/Projects/AHNC_MOTUS_KIOSK/www/news/stories/news_unknown_en.html") 
      # get the default 'news_unknown' html filename matching the current language
      # (see data/translations csv file)    
      xxx <- i18n_r()$t("ui_motusnews_unknown")  
      #substitute the word 'news_unknown' in the filename with the news key
      yyy <- str_replace(xxx,"news_unknown","current_news")
      
      # if the current_news file exists, use it, else use the news unknown file
      if (file.exists(yyy)) {
        zzz <- includeHTML(yyy)
      } else {
        zzz <- includeHTML(xxx)
      }
      output$news <- renderUI(zzz)

    } # end function myRenderFunction
   
  
    
    # Some UI elements should be updated on the Server side
    # -- when session starts
    # -- when language changes

    #-------------------------------------------------------------------------------------------------------------
    #   session start
    #-------------------------------------------------------------------------------------------------------------  
    observeEvent( session$clientData, {
      #  message("**session started ***")
      myRenderFunction()
    }) #end observeEvent for session start
  
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    # Update text values when language is changed
    # note lang() is handle to the language input picklist passed in from server.R
    observeEvent(lang(), {
      # we rely on server.R to set this?
      #i18n_r()$set_translation_language(lang())
 
      
      myRenderFunction()
    }) #end observeEvent(lang()

    
  }) #end moduleServer

}  # end SERVER_MotusNews




