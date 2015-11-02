# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- MIT License README file
- Changelog

### Changed
- README no longer contains the list of changes since it was getting a little long. Refer to this CHANGELOG.md document (which you probably are, considering you're reading this!)
- README no longer contains the credits as well. Not because it was getting long, but because I should separate these things out, I think.

## [0.8.1] - 10/30/2015
### Added
- Game will pause and stop showing the image if Game Window loses focus during gameplay.
- You can edit players' scores during a game, but it's very buggy and I'd suggest not using it :(
- If the console window crashes, messages about what images are showing up, who's buzzed in and player scores will still show up. (Untested)
- The current image info is reprinted to the console when you exit the "Manage Players" menu during gameplay.

### Changed
- "o" is now "y"
- Player scores stay up at the beginning and end of a game round.
- Players' scores and current images are saved in folders each time the program is opened. The files are still in scores, but now they have their own individual folders marked by the time the program was opened.

### Removed
- You can't use "ESC" to quit the game.
- You can't fullscreen with "f" during a game when not in image checking mode.

## [0.8.0] - 10/27/2015
### Added
- You can change pixel size and image time in the settings menu.
- Players' scores are saved in the "scores" directory in the Save Directory.
- Console menus have numbers as well as the previous commands to make movement between menus easier.
- Choose which joystick (buzzer) you want to use for the game at startup. Can optionally choose not to and play in "image checking" mode.

### Changed
- Controls have changed: 'o' = 'c', 'x' = 'n'

## [0.7.0] - 10/26/2015
It's a game!!!! The functionality is there!!! Have fun!!!!!

Only the trivia buttons will work with this iteration of the program. Control of officer duties is handled through the console, so please be aware of this change!!

### Added
- There are SFX.
- A message pops up, letting everyone know who got the buzz in first.

### Changed
- Almost all control is diverted to a console. Please open the program via command line for Mac and Linux.

## [0.6.4] - 10/24/2015
### Changed
- The console is used to manage players, start the game, among other things. Currently, only the trivia buttons, not the keyboard, can be used as buzzers.

### Fixed
- Pausing the game and then hitting one of the "next image" buttons will unpause the game so that the next image will pixelate.

### Not Fixed
- Buzzers still do not act in the way that they should...

## [0.6.3] - 9/26/2015
### Added
- If the trivia buttons are hooked up to the computer, the buttons can pause and unpause the game. ...That's it though...

## 0.6.2 - 11/2/2014
### Added
- can pause the pixelation

### Fixed
- when the image is revealed, the image is smoothed out (AKA it's not using Nearest Neighbor to render the image)
- fixed some mathematical formulas so images show all of it, not just... some of it (I'm bad at math)
- the given pixel size is consistent between images rather than changing based on the image size (...I'm bad at math.......)

## 0.6.1 - 10/25/2014
### Added
- can go to previous image
- load and reload images from an external folder

## 0.6.0 - 9/26/2014
initial creation

- pictures were hardcoded into the program

### Added
- can go to next image
- pixel size set to 70 for Day 1

[Unreleased]: https://github.com/goofanader/mna-anime-eyes/compare/v0.8.1-alpha...HEAD
[0.8.1]: https://github.com/goofanader/mna-anime-eyes/compare/v0.8.0-alpha...v0.8.1-alpha
[0.8.0]: https://github.com/goofanader/mna-anime-eyes/compare/8a0260a35591618a6b1e4aa68ac4a2df6a4c9b21...v0.8.0-alpha
[0.7.0]: https://github.com/goofanader/mna-anime-eyes/compare/2b703fb6fa55a6937377163e97d4e4a3120a18b5...8a0260a35591618a6b1e4aa68ac4a2df6a4c9b21
[0.6.4]: https://github.com/goofanader/mna-anime-eyes/compare/46cfa039eb0b4343f7f60d271de8e3c242ca1beb...2b703fb6fa55a6937377163e97d4e4a3120a18b5
[0.6.3]: https://github.com/goofanader/mna-anime-eyes/compare/a587c4818fea9528ac59942084e4527ca37893c2...46cfa039eb0b4343f7f60d271de8e3c242ca1beb
