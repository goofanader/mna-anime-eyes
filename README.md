# Anime Eyes: Console-tastic Version
Created 9/26/2014 by Phyllis Douglas (goofanader@gmail.com, me@phyllis.li)

Version: 0.8.0 (10/25/2015)

Minna no Anime's Anime Eyes program, written in LOVE2D. Get the latest release version from the release folder. It contains executables for Windows x32/x64, Mac OSX, and Linux.

Check out the club at http://minnanoanime.org

## Notice
There have been many changes since Version 0.7.&#42;, so please read this README to understand the new controls!!

## Requirements
This program has been tested on Windows x64 machines and Mac OSX 10.10.5 (Yosemite). I give no guarantees for any other OSes/variations.

For Linux, please install LOVE2D version 0.9.2 on your system. There is a .zip of LOVE2D included in this game's Linux distro. For the other OSes, it should run out of the box.

### Minimum Requirements
__OS:__ You must have at least Windows XP, Mac OSX 10.6 or Ubuntu 12.04/14.04–15.04 to run this program.

__Graphics:__ DirectX 9.0c+ capable graphics card with drivers that support OpenGL 2.1+.

## How to Start
1. Open the program.

    For Windows, this is as simple as double-clicking on the app.

    For Mac, please open the Terminal application. Then, traverse to the directory that holds this program. Run the following command:

        NyankoSearch.app/Contents/MacOS/love NyankoSearch

    For Linux, please open your terminal/console application. Then, traverse to the directory that holds this program. Run the following command:

        love NyankoSearch.love

2. Switch to the console window. Choose your joysticks to use for this game by entering the number of the joystick of choice (or "k" for no joysticks). Hit "enter" to make your choice.

   If no joysticks are plugged into the computer, it will default to using no joysticks and enter "image checking" mode. You can optionally choose that mode by selecting "keyboard" with "k".

2. If this is the first time you've opened the program or if you haven't added images already, place the images that you want in these folders, depending on OS:
    * __Windows XP:__ ```C:\Documents and Settings\<username here>\Application Data\LOVE\MnA_Anime_Eyes\images``` or ```%appdata%\LOVE\MnA_Anime_Eyes\images```
    * __Windows Vista and 7:__ ```C:\Users\<username here>\AppData\Roaming\LOVE\MnA_Anime_Eyes\images``` or ```%appdata%\LOVE\MnA_Anime_Eyes\images```
    * __Mac:__ ```/Users/<username here>/Library/Application Support/LOVE/MnA_Anime_Eyes/images```
    * __Linux:__ ```$XDG_DATA_HOME/love/MnA_Anime_Eyes/images``` or ```~/.local/share/love/MnA_Anime_Eyes/images```

    __Note that the "LOVE" folder might not exist__ and instead the MnA_Anime_Eyes folder will be the folder shown instead. Please use that folder.

    __Another note: If there's no MnA_Anime_Eyes or LOVE folder available__, run the program once, and it should create the folders for you (if it doesn't, please let me know).

    __One more thing! It only recognizes images, not folders.__ If you have the rounds put in their own folders, just copy-paste the images __inside the round folder__ into the "images" directory.

3. Press 'r' (and 'enter' if not in "image checking" mode) to load the images into the program if you added/changed images in the MnA_Anime_Eyes/images folder. It doesn't hurt to press it anyway :)

4. You'll probably want to go into fullscreen: press 'f' (and 'enter' if not in "image checking" mode) to do so.

### Joysticks Plugged In
Control for setting up the game is almost entirely done in the console. Please have the focus on this window during setup, unless prompted to switch to the Game Window.

3. You'll be presented with a menu of choices to choose from. You can select what choice you want via the number, the first letter (for some menu options), or the whole menu string.

    1. Players: Manage players
    2. S[tart]: Begin the round
    3. R[eload]: Reload the image folder
    4. F[ullscreen]: Toggle fullscreen
    5. Settings: Configure game settings
    6. Q[uit]: Exit the program

#### Players Menu
The following is the menu that'll show up if you select "Players":

1. A[dd]: Add a player/Change a player's name
2. C[hange]: Edit a player's points
3. D[elete]: Remove a player from the game
4. L[ist]: List all players
5. R[eturn]: Go back to previous menu

I'll only go through some of these as most of the commands in the program are self-explanatory.

__Note:__ You cannot test player's buttons, unfortunately. I'll see if I can implement that in the future.

##### Add a Player/Change a Player's Name
If you choose this choice and the buzzer button used to belong to someone else previously, __their points will be erased to zero.__ Please write down their point value if you need it after changing the name.

After entering in the new player's name, __you'll need to switch to the Game Window in order to register their buzzer with the program__. After the prompt has disappeared from the Game Window (or you hear the bell sound), switch back to the console.

#### Settings Menu
The following is the menu that'll show up if you select "Settings":

1. Change pixel size (the program starts with "100" which is the usual setting for Halloween Party)
2. Change length of time for an image to be onscreen (the program starts with "18")
3. Toggle Randomly Ordered Images (the program starts with random images)
4. Return to previous menu

__Note:__ If you select #3, it will reload the images automatically.

#### Start Command
The game will prompt you to use the Game Window as the currently-focused program. __It is imperative that you do so as all control will now be done through the Game Window.__ Immediately after switching, the game will start.

#### How to Run
1. An image will slowly come into focus. The answer for the image is (hopefully) in the filename, which will be displayed on the console screen.

2. If a player buzzes in, the Game Window and console will let both parties know who buzzed in. The player can then answer.

    I haven't implemented a timer during these sections, so whenever the officer feels like it's enough time, press the "n" button to detract points from the player.

    Press "o" if they're correct, "n" if they're wrong.

3. If the player was wrong, play will continue until someone gets it correct or the image comes into full view.

4. If the image slowly came into focus and shows the full image, players have 3 seconds to answer before the points screen shows up. __This is different from ShippoSearch's implementation, which paused after the image is fully shown.__

5. Announce the correct answer if no one got it while the screen is on the points screen.

6. Hit the "]" button to go to the next image, and repeat steps 1-6 again until all images in a round are finished.

7. Control will go back to the console.

    The players' scores and the list of images used will be saved in the MnA_Anime_Eyes directory's "scores" folder. The filenames are of the time when the round finished.

        Format: MM-DD-YYYY_HH-MM-SS.ini

    Unfortunately, at this time, the scores will not be left on the screen, so either show the .ini file or be aware when the last image is being shown. __The program will not tell you which image is the last one, though.__ I'll add that as something TODO.

##### Controls During a Round
* c - correct
* n - not correct
* p - pause/unpause the pixelation. Will unpause if the image is cleared by "]" or "[".
* f - enter/exit fullscreen for the monitor the program's located on
* ] - makes the image clear. press again to go to the next image
* esc or q - quit the game

### Image Checking Mode
This mode is what this program was like before Version 0.8.0.

Make sure that you're in the Game Window and not the console. Press ']' when you're ready to begin.

#### How to Run
Press ']' when someone gets the image correct. It'll show the image in its true glory. Press ']' again to continue to the next image.

If nobody gets the image by the time it's clear, press ']' to go the next image.

#### Controls
* r - reload the images in the image folder
* p - pause/unpause the pixelation. Will unpause if the image is cleared by "]" or "[".
* f - enter/exit fullscreen for the monitor the program's located on
* ] - start viewing images. makes the image clear. press again to go to the next image
* [ - makes the image clear. press again to go to the previous image
* esc or q - quit the game

## Notes
* This version is hardcoded to start with a beginning pixel size of 100
* This version is hardcoded to start with a time limit of 18 seconds per image
* This version is hardcoded to start with the images being in random order

For the three things above, you can change those after the program loads up.

## Credits
* Original program: [ShippoSearch by Nur Monson](https://github.com/samiamwork/ShippoSearch)
    Most of this program's functionality is based off of ShippoSearch and trying to replicate it. The image pixelation used in ShippoSearch is from a Mac OSX library, so I had to try and replicate it using shaders...
* Chime sound: [hypocore on freesound.org](https://www.freesound.org/people/hypocore/sounds/164088/)
* Rounded rectangle shape: [Robin on LOVE2D Forums](https://love2d.org/forums/viewtopic.php?t=11511)
* Middleclass Lua file: [kikito](https://github.com/kikito/middleclass)
* Help with the shader: Andrew Elliott
* Everything else: [Phyllis Douglas](http://twitter.com/goofanader)

## To-Do
- [See the issue tracker for a list of things Phyllis has to do!](https://github.com/goofanader/mna-anime-eyes/issues)

## Updates
### 10/27/2015
- You can change pixel size and image time in the settings menu.
- Players' scores are saved in the "scores" directory in the Save Directory.
- Console menus have numbers as well as the previous commands to make movement between menus easier.
- Controls have changed: 'o' = 'c', 'x' = 'n'
- Choose which joystick (buzzer) you want to use for the game at startup. Can optionally choose not to and play in "image checking" mode.

### 10/25/2015
- It's a game!!!! The functionality is there!!! Have fun!!!!!
- Only the trivia buttons will work with the current iteration of the program.
- Almost all control is diverted to a console. Please open the program via command line for Mac and Linux.
- There are SFX.
- A message pops up, letting everyone know who got the buzz in first.

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
