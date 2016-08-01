# Introduction

AVrate is a tool to conduct audiovisual evaluation experiments on iOS.
It performs the playback of audiovisual content and then asks test persons to rate it. Inputs can be sliders, to rate on a position on a scale, or buttons, which can be clicked. Additionally, timing information about keyboard pressing can be used for detection tests. 

The playback will be executed by the system video player on the mobile device running this application or on a remote computer running AVrate.

The application is functional and can be used for testing. However, the configuration of the test interface from the tablet is still work in progress. Currently, the preferred way to configure a new test is by using the PC version of AVRate (see below). 



# Installation
+ double click on iOSAVRate.ipa, this will add AVRate to iTunes' application library. Then use iTunes to install the application on the device. (In iTunes, on the device page, go to application tab, then click install next to iOSAVRate and then synchronize)
+ Videos for standalone mode should be added on the device using iTunes. (In iTunes, on the library page, drag and drop your videos to the main window of iTunes (or on OSX, drag and drop your videos to the iTunes icon in the dock). Then, go to the device's page. There, you will be able to select the movie tab, then select the videos you want to have on the device and finally copy them on via the synchronization button) 


# Usage

You need to use AVRate (PC) to configure AVRate for iOS.

## On AVRate desktop, you will have to:
  - edit the xml file and set the device section to tablet
  - edit the xml file to define the rating scales
  - edit the xml lst file to define the playlist
  - with a device set to tablet in the AVRate xml, it is possible to playback the video on the tablet by adding the option <playondevice>true</playondevice>. If this option is not set, iOSAVrate will be a deported screen for the AVRate rating interface. 
  - select start. And AVRate will be waiting for a mobile device to connect.


## On iOSAVRate you will have to:

  - Go to the settings and specify the IP of the computer running AVRate
  - Two options are then possible: 
      1) iOSAVRate is used as a deported interface for AVRate desktop. In this scenario, select "done", and in the main page start a new test. 

      2) if the mobile device is used to playback the videos, then select standalone mode.  
      2.1) Use load settings to get the playlist and scales information
      2.2) Tap on done.
      2.3) To retrieve the scores stored on the device in standalone mode, go to settings, swipe from left to right and access to the standalone tab. It is then possible to send the scores by email. 


# Things to know
+ When sending a playlist to iOSAVRate, the playlist should contain the ** title ** of the movies, not the file name! Title of the movies can be set in the video library of iTunes or in command line using ffmpeg:

ffmpeg -i BigBuckBunny_640x360.m4v -vcodec copy -acodec copy -metadata title="here I define the title of the movie" BigBuckBunny_640x360_with_a_title.m4v



# Known issues
- If the IP of the AVRate server is incorrect, this might result in a freeze when trying to load settings. If a freeze happens, double click on home and kill the processus.
- If iOSAVRate is used as a remote of AVRate Server, and if the server (Window PC) running AVRate use a local (language) where floating numbers are separated with a coma (like French where PI is written 3,14159...), this will result in a freeze of the mobile application when submitting subjective scores... (iOSAVRate use a dot in floating number ; PI is written 3.14159... )
- AVRate server does not stop when the window is closed while it wait for a Tablet. The current solution is to kill the processus though the task manager...

# ToDo
+ Remove the clock on the top of the device when a video is played.
+ Mobile application in standalone crashes if there is no video in the library.
+ Customize interface from the device
+ On iPhones, in the setting menu, there is a conflict between the horizontal scroll in the menu and the table vertical scroll...  

# Possible problems
- If the application cannot be installed, make sure that the device (iPhone/iPod/iPad) used is one of the registered device. If not, you need to rebuild iOSAVrate with a distribution provisioning file which includes your device. ( ... Or jailbreak your device ...)


# License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
