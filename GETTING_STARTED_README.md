# Getting Started


### Ankeny Hill Nature Center Motus web app ###
This document is a guide on how to get the 'Motus Kiosk' Shiny web app build tools installed, the kiosk app out of source control (git), and how to do the first build.

At the end you should have the web app up-and-running using  R-Studio on the local computer.

Deployment and configuration of the app to a kiosk-like display using OpenKiosk is described in the companion document DEPLOYMENT_README.md in the project's top level directory.


### Who do I talk to? ###

* Owner/Originator:  Richard Schramm - schramm.r@gmail.com

### Preliminaries ###

The 'kiosk system' can be viewed as built on these .

* The operating system
* The kiosk is a container (special kind of web browser) that 'hosts' the web application (OpenKiosk)
* The programing language adn development environment that the application runs in (R, and R-Studio)
* The web application that runs inside the kiosk window to render the user interface and obtain
  the data from motus.org ('the code and supporting files')
* The motus.org remote data server. 

##### Operating System
Windows OS was specified as a requirement for the Ankeny Hill Nature Center.

Nothing precludes you from choosing a different operation system. I have developed and run everything quite well at home under Mac OSX (v12.6) and deployed to Windows 10 target.  It should also be able to be run on small generic linux machines although I have not attempted to verify. 

##### The OpenKiosk
The OpenKiosk is a basically a specialized web browser with configurable restrictions that will connect to our web application (via an http connect to a port on a web server).

See: https://openkiosk.mozdevgroup.com

There are many other ways to display the application including simple Chrome or Firefox browsers or even pushing the web app to remote web server etc.

It is important to recognize this distinction between the Shiny dashboard web application and the kiosk being provided by OpenKiosk.

##### The programming/language environment

The Motus developers work in the R programing language. R-Studio provides a rich development environment and also integrates with the R package "Shiny" - which is what the actual web app (dashboard) has been developed in. 

##### Motus.org

The Motus Collaboration Policy (https://motus.org/policy/) specifies we should only provide data from the 
public "Basic open-access dataset". That dataset is the coarse "summary-level detection information". 

All of the desired tagged bird detection information is available via simple http requests to the public motus.org servers.  

##### The Application
 The application is built in R-Studio using the R package "Shiny" (see: https://shiny.rstudio.com/)
 Shiny is an R package that makes it easy to build interactive web apps straight from R.
 You can host standalone apps on a webpage or build dashboards. When run on the local machine
 from a cmd line it will start a 'shiny server' on a local machine URL that you can point your browser to.

### How do I get started? ###

##### Install R for your platform

(see: https://www.r-project.org/)

##### Install R-studio IDE Free Edition for your platform

 (see:https://www.rstudio.com/products/rstudio/download/)

##### Get the code

The project and code is available on a github repository  at :

You will need a github account to clone the repository.
Presumably if you are viewing this file you have that figured out.

You also need to install git on the machine you wish to download the project to. (See: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Create a directory for the project - for example on Windows I use C:\Users\MOTUS_KIOSK\Projects as my top-level directory

Open a command window such as Cmd.exe and type:

```code
cd  C:\Users\MOTUS_KIOSK\Projects
git clone https://github.com/rschramm9/AHNC_MOTUS_KIOSK.git
```

Git may pop up an authentication options window – provide your git credentials via a web browser.
Once authenticated, the download should proceed along the lines of:

```code
Cloning into 'AHNC_MOTUS_KIOSK'...
remote: Enumerating objects: 11, done.
remote: Counting objects: 100% (11/11), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 11 (delta 4), reused 5 (delta 1), pack-reused 0
Receiving objects: 100% (11/11), 13.99 KiB | 2.33 MiB/s, done.
Resolving deltas: 100% (4/4), done.
```

A complete copy of the repository should now be in subdirectory at: C:\Users\MOTUS_KIOSK\Projects\AHNC_MOTUS_KIOSK

##### Your first build

Run the R-Studio IDE.  Once open, Click File > New Project 

From the shown "New Project Wizard"  select “Existing Directory”

“Browse”  **INTO** the folder: C:\Users\MOTUS_KIOSK\Projects\AHNC_MOTUS_KIOSK and click “Open”

Once back in the wizard, Click “Create Project” button

 From the IDE  Right-side  “Files” Panel/Tab,  Click to open the file global.R

Check at the top of the main source code window for a warning regarding several packages that may need to be installed… Go ahead and click the “Install”  Wait while it installs numerous package dependencies. This can take around 4 to 5 minutes….

 Repeat the above check for other packages needing to be installed (if any) for files:

ui.R

server.R

modules/receiverDeploymentDetections.R

modules/ReceiverDetections.R

modules/tagDeploymentDetails.R

modules/tagDeploymentDetections.R

Close the tabs for all source code files **EXCEPT**  global.R, ui.R and server.R

With one of those three files selected for view in the code window, notice a green arrow labeled “Run App” should be visible -click that.

After RStudio builds the app it should pop-up the app in its own browser window. 

Two other things to note...

1-When the app is running - on the Console tab will be a red stop-sign. Use that to halt the app to make changes or reload the config file etc

2-Just after the app starts up, if you scroll down thru the output in the Console tab, you will find:

"Listening on http://127.0.0.1:####". This is the temporary URL server and port that Shiny assigns.  You may be curious to try cutting that URL to your clipboard and pasting it into any browser on any machine on your local network.  It should work!

#### Configuration ####

##### Locate your site's motus receiver ID.

To locate  your receiver's ID:  Go to motus.org Then : ExploreData>Projects

Find your ProjectID, then click on the link that takes you to your project's description.  Look for the item named "Receivers" and click the link next to it saying ""(Table)"

##### Make your own configuration file.

In the project's top-level directory is a file called sample.cfg  It contains the default set of key value pairs
that do things like set the target motus receiver using its Motus database ID.

* Copy the template file ***sample.cfg*** to a file named ***kiosk.cfg***

* Edit your kiosk.cfg file to contain your site's information .

* Restart the web application.

The contents of sample.cfg file are shown below .

```code
ReceiverID=7948
MainLogoFile="images/logos/ankenyhill_logo.png"
MainLogoHeight=140
MainTitle="Test Data"
```


