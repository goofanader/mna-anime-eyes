# Anime Eyes: Console-tastic Version
Created 9/26/2014 by Phyllis Douglas (goofanader@gmail.com, me@phyllis.li)

Version: 0.6.5 (10/25/2015)

## Requirements
This program has been tested on Windows x64 machines and Mac OSX 10.10.5 (Yosemite). I give no guarantees for any other OSes/variations.

For Linux, please install LOVE2D version 0.9.2 on your system. There is a .zip of LOVE2D included in this game's Linux distro. For the other OSes, it should run out of the box.

## How to Start
1. Open the program. You'll probably want to go into fullscreen: press 'f' to do so.

2. If this is the first time you've opened the program or if you haven't added images already, place the images that you want in these folders, depending on OS:
    * __Windows XP:__ ```C:\Documents and Settings\<username here>\Application Data\LOVE\MnA_Anime_Eyes\images``` or ```%appdata%\LOVE\MnA_Anime_Eyes\images```
    * __Windows Vista and 7:__ ```C:\Users\<username here>\AppData\Roaming\LOVE\MnA_Anime_Eyes\images``` or ```%appdata%\LOVE\MnA_Anime_Eyes\images```
    * __Mac:__ ```/Users/<username here>/Library/Application Support/LOVE/MnA_Anime_Eyes/images```
    * __Linux:__ ```$XDG_DATA_HOME/love/MnA_Anime_Eyes/images``` or ```~/.local/share/love/MnA_Anime_Eyes/images```

        __Note that the "LOVE" folder might not exist__ and instead the MnA_Anime_Eyes folder will be the folder shown instead. Please use that folder.

        __Another note: If there's no MnA_Anime_Eyes or LOVE folder available__, run the program once, and it should create the folders for you (if it doesn't, please let me know).

3. Press 'r' to load the images into the program if you added/changed images in the MnA_Anime_Eyes/images folder. It doesn't hurt to press it anyway :)

3. Press ']' when you're ready to begin.

## How to Run
Press ']' when someone gets the image correct. It'll show the image in its true glory. Press ']' again to continue to the next image.

If nobody gets the image by the time it's clear, press ']' to go the next image.

## Controls
* r - reload the images in the image folder
* p - pause/unpause the pixelation. Will unpause if the image is cleared by "]" or "[".
* f - enter/exit fullscreen for the monitor the program's located on
* ] - makes the image clear. press again to go to the next image
* [ - makes the image clear. press again to go to the previous image
* esc or q - quit the game

## Notes
* This version is hardcoded to have a beginning pixel size of 70
* This version is hardcoded to have a time limit of 18 seconds per image
* This version is hardcoded to have the images randomly appear

## To-Do
- Create a window for officers to interact with
- hook-up arcade buttons/buzzers to the program
- make it so that officers can create different sessions for the program (Anime Eyes vs. Anime Eyes testing vs. Halloween... etc.)
- fix fullscreen on multi-windows for Windows

## Updates
### 10/24/2015
- Pausing the game and then hitting one of the "next image" buttons will unpause the game so that the next image will pixelate.
- The console is used to manage players, start the game, among other things. Currently, only the trivia buttons, not the keyboard, can be used as buzzers.
- Buzzers still do not act in the way that they should...

### 9/26/2015
- If the trivia buttons are hooked up to the computer, the buttons can pause and unpause the game. ...That's it though...

### 11/2/2014
- can pause the pixelation
- when the image is revealed, the image is smoothed out (AKA it's not using Nearest Neighbor to render the image)
- fixed some mathematical formulas so images show all of it, not just... some of it (I'm bad at math)
- the given pixel size is consistent between images rather than changing based on the image size (...I'm bad at math.......)

### 10/25/2014
- can go to previous image
- load and reload images from an external folder

### 9/26/2014
- initial creation
- can go to next image
- pictures were hardcoded into the program
- pixel size set to 70 for Day 1
