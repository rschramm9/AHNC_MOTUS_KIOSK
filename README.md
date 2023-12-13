# AHNC_MOTUS_KIOSK (Obsolete as of 12December2023)
# Current repo MOTUS_KIOSK at https://github.com/rschramm9/MOTUS_KIOSK

## this repo is being preserved as others may have need of it

## Ankeny Hill Nature Center MOTUS Kiosk System

This project creates a public display or "kiosk"" for a Motus receiver station for the US Fish and Wildlife Service (USFWS) Ankeny Hill Nature Center.  The goal is to engage public visitors to the site with a simple near-realtime display of migratory bird tag detection events. It presents a very simple limited number of screens that are easy to navigate via a touchscreen display.

The Motus Wildlife Tracking System (Motus) is an international collaborative research network that uses coordinated automated radio telemetry to facilitate research and education on the ecology and conservation of migratory animals. Motus is a program of Birds Canada in partnership with collaborating researchers and organizations. Learn more at https://motus.org

![Figure1](./documentation/md_images/RM_KioskHomepage.png)

*Figure 1 - Kiosk homepage*

![Figure2](./documentation/md_images/RM_KioskReceiverDetections.png)

*Figure 2 - The Kiosk Receiver Detections tab panel

![Figure3](./documentation/md_images/RM_KioskReceiverDetectionsMap.png)

*Figure 3 - The Kiosk Receiver Detections map panel



###  Acknowledgements and Restrictions on Data Use or Publication

***Any use or publication of the data presented through this application must***
***conform to the terms of the Motus Collaboration Policy*** at https://motus.org/policy/
and ensure proper recognition of Motus, Birds Canada, Motus researchers and projects.
You should have received a copy of the Motus Collaboration Policy document in this
projects home directory when you downloaded the source code. Look for the file
or find it at https://motus.org/policy/

### Contributors

* Richard Schramm,  original author
* Patrick Lorch, Sr. Research Biologist, Southern Sierra Research Station  plorch@southernsierraresearch.org 

### Who can I talk to about it? ###

* Richard Schramm - schramm.r@gmail.com


### Copyright and License

Copyright 2022 Richard Schramm - Corvallis, Oregon USA

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program source code when you obtained the software.

Please read BOTH the included LICENSE file and LICENSE_ADDITIONAL_PERMISSIONS.  By downloading this software you are agreeing to be bound by all licensing terms as stated in these two documents.


### Hardware & Software Requirements

I have quite successfully built and run the application in full kiosk mode on low-end  Intel NUC PC computers with Window 10 Pro pre-installed. These are easily purchased used on eBay for as little as $100.   I have also built and run the application on Apple Mac OSX (but not as a locked down kiosk).

These are the machines I have used:

- NUC6CAY Celeron J3455 Processor 1.5Ghz 8GB Ram 120GB SSD w/wifi and Windows10 Pro (eBay $100)

* NUC7i5BNH MiniPC QUadCore i5-78260U 8Gb w/128Gb SSD w/wifi and  Windows 10 Pro. (eBay $185)

* CHUWI Larkbox PRO miniPC 6GbRam QuadCore 2.7Ghz Celeron J4125 with wifi and Windows 10 (Home Ed) $139 Amazon -- not recommended due to possible reliablity concerns, but its cute!

* Apple Macbook Pro (circa 2018) 2.9 Ghz Intel core i9  32Gb w/macOS  12.6  (my development system)

The touchscreen I use is : Dell 24 Touchscreen Model P2418HT (Dell.com $350)

USB Keyboard and Mouse

I *strongly* recommend Windows-10 PRO edition.  Home Edition works too but with some additional headaches getting set up.

### Where to Start?

Easily 70% of the kiosk installation is getting Windows configured to work smoothly in kiosk mode. The 30% effort (or less) is getting the app built.  If you want to skip all of the Windows and kiosk-specific setup and just go explore the app in R and RStudio, see BUILDING_THE_APP_README.md

For the full kiosk behavior we need, start at **WINDOWS_FIRSTRUN_README.md** in the project's top level directory. 



