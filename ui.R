
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
# UI "skeleton" of the whole app.
# Individual module UI is attached via UI_<module_name> functions
# 

## languages supported is determined by presence of translations csv files
## available in the data/translations dir

# load the translations here
i18n <- Translator$new(translation_csvs_path = paste0("data/translations"),
                       separator_csv="|")

active_ui_lang <- grep("ui",i18n$get_languages(), invert = TRUE, value = TRUE)

# then set the default
i18n$set_translation_language(default_UI_lang)  #set in global.R

# this language data frame  gets used in the language selector defined below in
# ui_titlebar() section
#  *** these must match EXACTLY the translations
#      present in in the data/translation dir
#
df <- data.frame(
  val = c("en","es")
  #val=setNames(active_ui_lang,active_ui_lang)
)

## and the country flags - careful to match the df above
## - and note the css class is jhr
df$img = c(
  "<img src='images/flags/ENUS.png' width=30px height=20px><div class='jhr'>English</div></img>",
  "<img src='images/flags/MX.png' width=30px height=20px><div class='jhr'>Spanish</div></img>"
) 



###############################################################################
# Define Main "Home Page Readme" ui panel.
# It just holds a div for a Readme text blob at the moment that the server
# fill manage from html text files in the www/docs directory
###############################################################################
ui_mainpage <- fluidPage(
  
  #this needs to be here or else some parts of ui
  #dont get translated (eg. the navbar)
  shiny.i18n::usei18n(i18n),
  
  tags$div(id = 'readmehere',
           div(id="readmediv",
               tags$h4(i18n$t("ui_mainpage_loading")))
  )
)  # end of main page layout


###############################################################################
## define the navbar portion of the ui.  holds the tab panels
## and the ui_mainpage (defined above) all others are as functions
## defined in modules
## *** note how the language translation is passed into the function**
###############################################################################
ui_navbar <-  div( class="navbar1", navbarPage("", theme="custom-navbar.css", #position = "fixed-top",
                  
                 tabPanel(i18n$t("ui_nav_page_main"),
                          ui_mainpage
                 ),
       
                 tabPanel(i18n$t("ui_RCVR_title")
                          , UI_ReceiverDetections("ReceiverDetections", i18n=i18n)
                 ),
                
                 
      ),
) #end the ui_navbar definition

###############################################################################
##  define the title panel that holds the logo, main title and the
## language selector.  It will appear on all pages.
###############################################################################
ui_titlebar <- fluidRow(
  
  titlePanel(   
    tagList(

      #img(src = "images/logos/ankenyhill_logo.png", height = 80),
      img(src = strMainLogoFile, height = numMainLogoHeight),
      
      #span("MOTUS KIOSK", style="color:#8FBC8F;font-style: italic;font-size: 25px;",
      span(strMainTitle, style="color:#8FBC8F;font-style: italic;font-size: 25px;",
           span(
             tags$div(  tags$style(".jhr{
                       display: inline;
                       vertical-align: middle;
                       padding-left: 10px;
                        }")),
            
              pickerInput(inputId = "lang_pick",
                         label = "",
                         width = 170,
                         choices = df$val,
                         choicesOpt = list( content=df$img),
                         options = pickerOptions(container = "body")
             ),
            
            
             style = "position:absolute;right:2em;"
           ) #end span2
      ), #end span1
      
    ) # end taglist
    
  ), #end titlepanel
  
  
 ## looks a bit nicer with a separator but it takes up space so comment out 
 # hr(),
  
)  #end the ui_title fluidRow

###############################################################################
## assemble the UI from the pieces
###############################################################################
ui <- fluidPage(
  
  ui_titlebar,
  ui_navbar
  
)   # end of ui definition


