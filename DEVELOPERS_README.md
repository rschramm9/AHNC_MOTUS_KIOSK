# Developers Notes


### Ankeny Hill Nature Center MOTUS Kiosk ###
This document is a collection of notes, ramblings, code snippets, problems encountered, future 'to do list' etc by the author to remind myself of what I did and why.   While mostly to assist me I include it in the project repository as possibly future developers and maintainers of the kiosk software might benefit from it.


### Who do I talk to? ###

* Owner/Originator:  Richard Schramm - schramm.r@gmail.com

### General Requirements ###

R-1) A dashboard application that runs in the public area of the Nature Center as a dedicated full-screen kiosk.
R-2) Presents bird flight data in tabular and graphic (maps)
R-3) Runs unattended by staff. Kiosk is simple enough to navigate that a child or parents can figure it out
R-4) Touchscreen interface, no mouse or keyboard. Mouse and keyboard will be locked away from public use.
R-5) System boots directly to kiosk on power-up
R-6) Prohibit users from accessing any other desktop or operating system cmd windows or settings
R-7) Prohibit users from 'browsing' to any other websites, pages, URLs etc
R-8) System returns to kiosk homepage and known defaults after some timeout
R-9) Support multi-language user interface
R-10) Support for Windows OS so computer can be used for other special purposes (e.g. Powerpoint presentations by Nature Center staff).
R-11) Support for development on Mac OSX as my personally preferred home system. 
R-12) An 'escape' from kiosk mode that allows an administrator to attach kybd/mouse and access the OS as a privileged user.
R-13) Optional access for Nature Center staff to do powerpoint presentations etc (with kbd/mouse)
R-14) Kiosk should only access 'public facing' Motus data via http per the Motus collaborator policy.
R-15) No Motus account authentication is highly desirable
R-16) Low cost hardware and open-source tools. Preferably no recurring fees etc

The design goal for Ankeny is to present a very friendly touchscreen UI with no keyboard,
 mouse or 'gestures' required.  We want something a precocious child and grandparent
 can navigate. 

So when considering adding new 'features', simplicity in the human interface is our priority.

### Approach ###

The 'system' can be broken into sub-topic areas.
* The operating system
* The kiosk system that 'hosts' the application
* The programing/language environment that the application runs in.
* The application that runs inside the kiosk to render the user interface and obtains
 the data from motus.org
* The development environment.

### Implementation Specifics ###
##### Operating System
Windows OS was selected as it meets requirements R-10 and R-14.

Nothing precludes you from choosing a different operation system. I have developed and run everything quite well on Mac OSX.  It should also be able to be run on small generic linux machines although I have not attempted to verify. 

NOTE: A significant amount of sysadmin level setup is needed with Windows-10 to get the kiosk app fully up and running smoothly. Including user account creation, directory creation, registry edits and group policy management , taskManager job setups, timeout and screen-saver behaviours, installing git, R and other 3rd party tools and packages etc.  It may sound duanting but it is sort of a one-time thing you can hopefully farm-out to someone who has familiarity with doing those kinds of things perhaps in a small office environment. All of this Windows-specific setup will be documented separately - hopefully with enough detail that a somewhat courageous intermediate windows user can follow..

See: WINDOWS_FIRSTBOOT_README.md

##### The Kiosk System 
Several options we examined. Those with $$ costs or subscriptions were rejected.

Microsoft's kiosk configuration option did not appear to easily meet R-10,11,12,13

I selected OpenKiosk to provide a kiosk shell that opens whenever user=MOTUS_KIOSK logs in 
See: https://openkiosk.mozdevgroup.com

The OpenKiosk is a basically a browser with configurable restrictions that will host our application. In
particular, see the 'Help' tab on that page.

##### The programming/language environment

Many language environments offer web dashboard-like frameworks.  The Motus users are heavily
invested in R. Initial thinking was we would need to use the Motus R package to access
the data so development began in R.  While the app can be run in the simple R 'console', R-Studio provides
a rich development and also integrates with the R package "shiny" which is what the
actual webapp has been developed in. 

NOTE: It turned out the Motus R package (as of 10/2022) has no API call to access flight data for individual tagged 'visiting' birds detected by our receiver that are not part of our Motus project.
Also the Motus collaboration agreement specifies we should only provide data from the 
public "Basic open-access dataset". That dataset is the coarse "summary-level detection information". 

Since all of the desired information was available via simple http requests to the public motus.org servers which we can then 'scrape' data from the returns .  We do not really need the Motus R package.  This does expose the kiosk app  to 'breakage' if folks at motus.org significantly change their web site.

Development continued in R as significant progress had been made on the dashboard. It is hoped that the Motus team will eventually provide a stable published API call to the "summary-level detection information" dataset we need.

##### The multi-language support

For multi-language support this app uses the i18n package to perform language translations see:https://github.com/Appsilon/shiny.i18n and also the article:  https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/

##### The Application
 The application is built in R-Studio using the R package "Shiny" (see: https://shiny.rstudio.com/)
 Shiny is an R package that makes it easy to build interactive web apps straight from R.
 You can host standalone apps on a webpage or build dashboards. When run on the local machine
 from a cmd line it will start a 'shiny server' on a local machine URL that you can point your browser to.
 Most importantly to us we can point OpenKiosk to that URL to display it as our dashboard.

You can also use R-Studio to deploy the whole application to Shiny.io to have it hosted as a publicly
 accessible web site via a www http request.  I did this for awhile so that the rest of my team could comment during development.

It is important to recognize the distinction between the Shiny dashboard application and the kiosk being provided by OpenKiosk.

There is a complete seperation of concerns... there are many ways to run and display the dashboard content - its just an app on an http server.  One of the ways to display the content and interact with it is via OpenKiosk. OpenKiosk is the tool I have chosen to to host the dashboard in a very locked-down fashion.  



### Understanding the Kiosk Dashboard structure  ###

This app's structure utilizes techniques for creating a multilanguage
and modularized app as described by Eduard Parsadanyan in his article at: 
https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
 and via exploring his ClinRTools modularized demo found at:
 https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/

Shiny dashboard apps typically have at least three .R source code files
1.	ui.R
2.	server.R
3.	global.R (optional)
See: https://shiny.rstudio.com/tutorial/written-tutorial/lesson1/ 

By ‘modularized’ here I mean – as demonstrated in the ClinRTools demo is a 
technique where the ui.R and server.R are minimal ‘skeletons’ – containing 
layout code the dashboard (banner, navbar etc) and top-level server code. 
Remainder of the ui and server code that is specific to what appears on the
ReceiverDetections  ‘sub-panel’ (or tab) are coded as functions in
 ReceiverDetections.R in the “modules” directory. The intent is to de-clutter
  the ui.R and server.R  and better contain the tab-specific code.

If you examine ReceiverDetections.R, you will find a UI_  function and a SERVER_ function. 
The UI_ builds the dashboard sidebar, and the tab panels showing detection details,
 flight history, and map.

The SERVER_ function  implements the code that populates the detections sidebar
and fills in the details on the three tabs ‘tag detail’, flightpath, and map.

Other module directory files contain functions to http query Motus, scrape
the results and return them as dataframes. 

All of the files needed from the modules directory  are ‘sourced ‘into the R session 
in global.R at startup.


### TODO List  ###

* Flight path
The flight path data needs to be filtered to remove wild points... impossible flight path etc.
not sure of the best algorithm to use.

* Flight path map
Would be great to have better looking maps, possibly with major city names or...

* Add a 'species' tab to the data panel to provide 'natural history' info/photo about
the animal detected? Info and photos probably have copyright issues to address. Possibly need a
local database or CSV file to query based on the common 'species name' to something more rigourous



### Coastlines and NaturalEarth Shape files ###

I had a lot of difficulty using rnatural earth when I pushed the app to
the web for testing.  I came across some help on stack exchange that recommended actually
downloading the shape files and storing them locally.

I obtained them from https://www.naturalearthdata.com/downloads/ and store them in 
the sub-folder "map-data"

roughly like in: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html
```code
# download the data 
download.file("http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/physical/ne_50m_coastline.zip", 
              destfile = 'coastlines.zip')

# unzip the file
unzip(zipfile = "coastlines.zip", 
      exdir = 'ne-coastlines-50m')
```
so far Im using the 50m physical lakes and coastline data sets.

great help found in:in: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html

My problems with the push seemed to be the combination of ggplot and rnautural earth packages.
If I used rnatural earth with sp.plot it pushed to shiny.io just fine
If changed plotting to use ggplot to make better maps, the push failed.
This ONLY effected pushes to shiny.io
So  I changed a bunch of packages… - roughly following this:
roughly like in: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html

```code
# SEE: https://nceas.github.io/oss-lessons/spatial-data-gis-law/3-mon-intro-gis-in-r.html
library(rgdal)
library(raster)
library(ggplot2)
library(rgeos)
library(mapview)
library(leaflet)
library(broom) # if you plot with ggplot and need to turn sp data into dataframes
options(stringsAsFactors = FALSE)


### download the 50m data set
download.file("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/physical/ne_50m_coastline.zip",
 destfile = 'coastlines_50m.zip')
unzip(zipfile = "coastlines_50m.zip", 
          exdir = 'ne-coastlines-50m')

download.file("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/physical/ne_50m_lakes.zip",
  destfile = 'lakes_50m.zip')
unzip(zipfile = "lakes_50m.zip", 
           exdir = 'ne-lakes-50m')

### download the 10m data set
download.file("http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_coastline.zip", 
              destfile = 'coastlines_10m.zip')
unzip(zipfile = "coastlines_10m.zip", 
      exdir = 'ne-coastlines-10m')

download.file("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes.zip",
  destfile = 'lakes_10m.zip')
unzip(zipfile = "lakes_10m.zip", 
            exdir = 'ne-lakes-10m')

### load the data 
coastlines <- readOGR("ne-coastlines-50m/ne_50m_coastline.shp")
lakes <- readOGR("ne-lakes-50m/ne_50m_lakes.shp")
### view spatial attributes
##class(coastlines)

```

Other issues:
Issues… I cant get ggplot to color fill countries

See maybe: https://www.riinu.me/2022/02/world-map-ggplot2/

### R Package Install issues

Sometimes package xxxx installs hang with message such as:

> ```
> Error in library(xxxx) : there is no package called 'xxxx'
> ```

See: https://stackoverflow.com/questions/47395807/error-there-is-no-package-called-and-trying-to-use-install-packages-to-so

This means that you don't have the package `readr` installed on your computer.

You then installed it with

```r
install.packages('xxxx', dependencies = TRUE)
or 
install.packages('xxxx', dependencies = TRUE, repos='http://cran.rstudio.com/')
```

which is good. Most packages are not "stand-alone", they use other packages too, called dependencies. Because you used the default `dependencies = TRUE`, all the dependencies (and their dependencies) were also installed.

You can look at the CRAN page for `readr`: [https://CRAN.R-project.org/package=readr](https://cran.r-project.org/package=readr) to see its dependencies (anything in the "Depends" or "Imports" fields is required). And of course you need the dependencies of those dependencies, etc. Now that `readr` is installed along with its dependencies, you can run `library(readr)` to load it.

 
