# Configuration Guide

### For the Ankeny Hill Nature Center Kiosk App v4.1.0 

**This** document is a guide on how to configure get the 'Motus Kiosk' Shiny web app.

### Who do I talk to?

-   Owner/Originator: Richard Schramm - [schramm.r@gmail.com](mailto:schramm.r@gmail.com){.email}

### 1.0 - Preliminaries

##### 1.1 - Locate your site's motus receiver deployment ID.

To locate all of your desired receiver's deployment IDs: Go to motus.org Then : ExploreData\>Projects

Find your ProjectID, then click on the link that takes you to your project's description. Look for the item named "Receivers" and click the link next to it saying ""(Table)". Locate the ID# for your active receiver deployment. ( *NOTE: a Receiver may have multiple Deployments - we are looking for the currently active deploymentID, (not the receiverID) )*

##### 1.2 - Make your own configuration file using your receiver ID.

In the project's top-level directory is a file called sample.cfg It contains the default set of key value pairs that do things like set the target motus receiver deployment using its Motus database ID.

The contents of the ***sample.cfg*** file are shown. *Please dont modify this file* - **create your own kiosk.cfg** file as described below.

- Copy the template file ***sample.cfg*** to a file named ***kiosk.cfg***

- Edit your ***kiosk.cfg*** file to contain your own site's ID, your banner logo file and title etc.

  Below is the content of an entire sample configuration file as of Version 4.1.0

```
ReceiverDeploymentID=9195,7948,8691
ReceiverShortName="Ankeny Hill OR", "Bullards Bridge OR", "Nisqually Delta WA"
MainLogoFile="images/logos/ankenyhill_logo.png"
NavbarColor="#8FBC8F"
TitlebarColor="#8FBC8F"
MainLogoHeight=140
MainTitleEnglish="Motus Receiver at:"
MainTitleSpanish="Receptor Motus en:"
MainTitleFrench="Récepteur Motus à:"
HomepageEnglish="www/homepages/ankeny_homepage_en.html"
HomepageSpanish="www/homepages/ankeny_homepage_es.html"
HomepageFrench="www/homepages/ankeny_homepage_fr.html"
MovingMarkerIcon="images/icons/motus-bird.png"
MovingMarkerIconWidth=22
MovingMarkerIconHeight=22
InactivityTimeoutSeconds=3600
EnableReadCache=1
EnableWriteCache=1
CachePath="data/cache"
ActiveCacheAgeLimitMinutes=60
InactiveCacheAgeLimitMinutes=10080
CheckMotusIntervalMinutes=10
HttpGetTimeoutSeconds=10
LogLevel=LOG_LEVEL_INFO
```



### 2.0 - Configurable Items

##### 2.1 - Receivers

You can configure your kiosk for browsing a single or multiple receivers. Below shows the configuration settings for a single receiver followed by a sample configuration for multiple receivers.

Note that your are setting two configuration parameters and there must be an exact one-to-one correspondence between the element lists. 

``` code
ReceiverDeploymentID=9195
ReceiverShortName="Ankeny Hill OR"
```

``` code
ReceiverDeploymentID=9195,7948,8691,7474,7950
ReceiverShortName="Ankeny Hill OR", "Bullards Bridge OR", "Nisqually Delta WA", "Oysterville WA", "Tokeland WA"
```



##### 2.2 - Titles and Navbar Settings

These setting control the apperance of the title bar and navigation banner.

*Note the the color is entered in 'hex format'*  The color shown is Ankeney Hill Nature Center's green.

```
MainLogoFile="images/logos/ankenyhill_logo.png"
NavbarColor="#8FBC8F"
TitlebarColor="#8FBC8F"
MainLogoHeight=140
MainTitleEnglish="Motus Receiver at:"
MainTitleSpanish="Receptor Motus en:"
MainTitleFrench="Récepteur Motus à:"
```

##### 2.3 - "Home" tab content

The descriptive content that appears in the in the main page body when ever the "Home" tab is open comes from a language dependent .html file in the project sub-directory www/homepages.

```
HomepageEnglish="www/homepages/default_homepage_en.html"
HomepageSpanish="www/homepages/default_homepage_es.html"
HomepageFrench="www/homepages/default_homepage__fr.html"
```

There should be one file for each language that the application supports - currently: English, Spanish and French.  Feel free to copy and edit the default pages provided.  And make sure to set the correct filenames in your configuration file

Edit these files carefully with an html editor or a text editor of your choice.

*Someplace visible in your kiosk you **must** give proper credit to the Motus folks and Birds Canada and should include a statement regarding Acceptable Use.* I have chosen to put that in the section "Credits" on the "Home" screen.

##### 2.4 - Moving Marker

These parameters set the icon and size of the marker the follows the flightpath of a bird on the leaflet map tab.

```
MovingMarkerIcon="images/icons/motus-bird.png"
MovingMarkerIconWidth=22
MovingMarkerIconHeight=22
```

##### 2.5 - Inactivity Timeout

This parameter controls a timeout for inactivity of the user  interface.  If there is no touchscreen/mouse activity for the set period, the application will reset to the home screen and defaults. 

```
InactivityTimeoutSeconds=3600
```

##### 2.6 - Cache Settings

These parameters control use of a local data storage cache. Caching is a way to improve user interface responsiveness and to reduce unnecessary data request calls out to motus.org. 

- Setting EnableReadCache=1 will cause application data requests to first return use any cached data it finds that meets the aging criteria. 
-  If cache is enabled for read it is used in two modes.

1) ActiveCache can be set to expire after a breif period. i.e. if you dont expect motus.org data to update more than once a day, you might set the active cache to expire after several hours. 
1) InactiveCache uses the same cached data files, but allows for a much longer timeout. The idea here is if  networking is lost, or if motus.org is unavailable due to maintenance etc. you may still want the application to show cached data even if it is much older (days or weeks?)

```
EnableReadCache=1
EnableWriteCache=1
CachePath="data/cache"
ActiveCacheAgeLimitMinutes=60
InactiveCacheAgeLimitMinutes=10080
```

-  Setting EnableWriteCache=1 causes any successful HTTP request for data from Motus.org to be written to the data cache on the local file system.  

  *NOTE: If you are pushing your app to a web hosting service such as shinyapps.io, the local file system is not available for writing.  In this case files in the cache system when the app was last pushed to the service are available, but since the web users sessions are restarted frequently, new data would not persist.  In these cases it is advisable to set EnableWriteCache=0 and possibly set the InActiveCacheAgeLimit to a higher number*   

##### 2.7 - Motus.org Response Timeout

This parameter controls the timeout waiting for a response to a motus.org data query.  Occasionally Motus.org may be down for maintenance etc or otherwise unreachable on the network. Rather than just hanging the user interface, this timeout will cancel the request and return control back to the user

```
HttpGetTimeoutSeconds=10
```

##### 2.8 - Check Motus Interval

This parameter controls the the period that the app will make a small data query to motus.org just to test connectivity. This is mostly a debugging tool, the status gets displayed on the homepage footer in the lower right corner.

```
CheckMotusIntervalMinutes=10
```

##### 2.9 - LogLevel

```
LogLevel=LOG_LEVEL_INFO
```

This parameter controls the level of messages written to the console or log file.  There is an order to the severity of messages in the system.  eg if the level is WARNING, only WARNING, ERROR and FATAL messages are written. 

The log level must must be one of :

```
LOG_LEVEL_DEBUG
LOG_LEVEL_INFO
LOG_LEVEL_WARNING
LOG_LEVEL_ERROR
LOG_LEVEL_FATAL
LOG_LEVEL_NONE
```

