# Ankeny Kiosk Windows Final Deployment


### Ankeny Hill Nature Center Motus web app - Final Deployment ###
This document is a guide on how to get the 'Motus Kiosk' Shiny web app deployed into OpenKiosk on Microsoft Windows 10.

 It is the third of the three documents that I use to describe the full setup of the kiosk. 

The first is WINDOWS_FIRSTRUN_README.md that describes all the tweaks and setting to MS Windows10

The second is BUILDING_THE_APP_README.md that describes installation of the build tools and constructing the Shiny web app.

*All of the work described in the first two documents should be completed before attempting what is in this document.*

If you are wanting to modify or further develop the application there is a fouth document named DEVELOPERS_README.md that may be helpful.


### Who do I talk to? ###

* Owner/Originator:  Richard Schramm - schramm.r@gmail.com

### Preliminaries ###

##### The OpenKiosk
The OpenKiosk is a basically a specialized web browser with configurable restrictions that will connect to our Shiny web application (via an http connect to a port on a web server).

See: https://openkiosk.mozdevgroup.com

##### The Web Application
 The application is built in R-Studio using the R package "Shiny" (see: https://shiny.rstudio.com/)
 Shiny is an R package that makes it easy to build interactive web apps straight from R.

When run on the local machine from a command line it will start a 'shiny server' on a local machine URL that we will point OpenKiosk to. We are etting up a MS Windows task to start our shiny server on boot up. 

We are setting  OpenKiosk to start at every login of user MOTUS_KIOSK to connect to our shiny server via http. OpenKiosk will be run within a full-screen window that is configured to prevent the user from doing anything except use our intended application. 

### How do I get started? ###

##### Complete all steps of WINDOWS_FIRSTRUN_README.md

This and all other accompanying documentation assumes a particular Windows10 user account username=MOTUS_KIOSK and project directory structure: C:\Users\MOTUS_KIOSK\Projects\AHNC_MOTUS_KIOSK

##### Complete all steps of BUILDING_THE_APP_README.md

It is assumed here that you are now able to run the AHNC_MOTUS_KIOSK project in R-Studio running on your target machine and the project has been downloaded from github resides in the above directory belonging to the MOTUS_KIOSK user.

#### Install OpenKiosk on your platform.

* *Read and note this before proceeding:*

```
When open kiosk runs it may appear to lock you out of viewing other windows (including possibly this document! Have you got a pencil handy? The secret to unlock:
- Shift F1 puts an administrator login banner up in the upper-left. Enter ‘admin’ as the password
- Shift F9 puts quit banner up - look over at the Upper-right – there is a “quit” button

(Note )on my macOSX keyboard its fn+Shift+F1 and fn+Shift+F9)
```

Download and install OpenKiosk from https://openkiosk.mozdevgroup.com/

It’s a long download that ends up in your downloads folder – something like OpenKiosk91.7.0-2022-02-22-x86_64.exe

Double-click the installer. Windows may show “Windows protected your PC”,  just click “More info” and select “Run anyway”

Accept the license, and click through all the standard default installation wizards.

Go to C:\Program Files and run OpenKiosk by double-clicking it – It will run in its own browser an it will likely look like your locked onto that screen… (that’s a good thing!)

Shift F1 puts administrator login banner up in the upper-left. Enter ‘admin’ as the password.

While on the admin page, select "OpenKiosk" selector on the sidebar panel.

Verifiy Settings are:

- "Enable Attract Screen" False (unchecked box)
- ~~"Enable Full Screen" False (unchecked box) << that is not a mistake - it should be set false~~
- "Enable Redirect Screen" False (unchecked box)
- "Enable URL Filters" False (unchecked box)
- Set homepage to : localhost:8081  << this port must agree with the shiny app startup task we will create in next section!
- "Enable Javascript" True (checked box)
- "Enable Network Protocol Filters". Both blob and data should be checked
- Section "Reset Session" check the box for "Set Inactive terminal" and reset after 5 minutes
- Section "Reset Session" check the box for "Enable Countdown" and show for 10 seconds
- Section "Reset Session" check the box for "Enable Countdown on Manual Reset" (True)
- "Enable Tabbed Browsing" False (box unchecked)
- "Enable URL Toolbar" False (box unchecked)
- In the "Quit" section, "Enable Quit Button Password" True (checked box)
- "Allow Multiple Displays" False
- Password section - you may wish to change the admin password - but r*emember it - there is no password recovery mechanism!!*

"Quit" the OpenKiosk (button on upper right of the main panel)



#### Set the shiny kiosk app to run at at boot

Shiny kiosk App.R is the background server application needed by the kiosk web pages. So we want it to start at boot so it’s there and ready whenever the kiosk gui is displayed by OpenKiosk (eg.when ever the motus_kiosk user logs in)

·   Login as administrator Admin

.   Right-click the TaskScheduler icon and choose "Run as administrator"

·   In TaskScheduler - Highlight "Task Scheduler Library" on the right side panel

·   In TaskScheduler Main Menubar:  Action > Create Task 

·   - On the "General" tab

.			-  The task will be named MOTUS_KIOSK_SERVER

·   		-	Check the option  ‘Run whether user is logged on or not”

·   		-	Check that it is set to run under the Admin account.

·   - On the "Triggers" tab

·   		- Click "New" button and then set "Begin the task" to run at “Startup”

·   		- Make sure the checkbox near the bottom of the panel here is “Enabled” (checked)

·   		- Press "OK" button for the trigger.

·   - On the "Actions" tab

·   		- Click "New" button and then set  it’s Action to be “Start a  Program”

·  		 - In the "Program/script" use the browse button and navigate to:

​			 “C:\Program Files\R\R-4.2.1\bin\R.exe”    (or which ever installed  version of R is) and select it

. 		**>>> Verifiy** the Browse function filled in the Program/script field with the surrounding double-quotes as shown above

·   		-Now fill the the Action "Add arguments" field as written below (with quotes as shown):  Note the port number selected must match the OpenKiosk default homepage set in previous section.

```code
-e “options(shinys.port)=8081;shiny::runApp(‘C:/Users/MOTUS_KIOSK/Projects/AHNC_MOTUS_KIOSK’)
```

·   		- Press "OK"  for the action button.

·   - On the "Settings" tab

·   		- Uncheck the box "Stop the task if it runs longer than x days"

Click the final "OK" and Windows will ask you for the Admin account password, then create the task. 

**TODO::::::::::::::::   Test:**

**Use task manager to manually run task SHINEY_KIOSK**

**Then browse to:  http:://localhost:8081**

**Reboot then repeat the browse to:  http:://localhost:8081**

 

## Make user MOTUS_KIOSK auto start kiosk gui on login

 

The kiosk gui that the user sees is displayed by OpenKiosk which is a completely locked down display so the public cant access anything on the computer except the gui we show them.

 

First need to find the MOTUS_KIOSK ‘security identifier’ or SID.

·   *** you must be logged in a MOTUS_KIOSK **

·   Open CMD.exe

·   Type: wmic useraccount get name,sid

·   Look at results and copy down the sid for MOTUS_KIOSK

e.g:  S-1-5-21-195043977-3097296022-4082461035-1012

-open the txt file, past in the new SID to the reg add cmd

-cut and past the whole reg add cmd

It should say all is good

Log ut, then log back in

Should popup the kiosk app (may say unable to connect… if so it may

Just meant it took too long for the shiny app to start… hit ‘Try Again’ blue button

Should now have full screen kiosk app.

 

First time – need to fix settings for motus_kiosk use of open kiosk.

·   Click in kiosk window, then type: Shift + F1

·   Type admin password in box, upper-left corner admin

·   In OPenKiosk Tab

o  **Check** EnableFullScreen

o  UnCheck Enable Tabbed Browsing

o  UnCheck Enable URL toolbar

·   In Home tab

o  Set homepage to : localhost:8081. << must agree with the shiny app startup task!

Exit ‘Settings’, Then then type: Shift + F9. (retype openkiosk password)

Return to windows desktop.. log out, the relogin
