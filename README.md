# libau

## An open-source cross-platform 2D game library

The project is written in D to take advantage of its ability for both low and high level programming.

## Required tools to build

- [dub](https://code.dlang.org/download), the D package manager
- [A D compiler](https://dlang.org/download.html), usually DMD

## Feature List

- Texture loading and rendering
- Automatic batched rendering
- Camera / viewport system
- Polygon, rectangle, and circle rendering
- Basic geometry module with circles, rects, etc.
- TTF Font rendering
- Sound playing API
- Streaming music API
- 2D tilemap for pixel-perfect geometry checking
- Particle system
- A basic Immediate Mode UI system
	- A button with different hover and pressed states
	- A slider that can allow for a non-discrete set of values
	- A carousel with a set of rotating values
- Automatic letterboxing
- User-created shaders

## Roadmap

- Featureset
    - Sprites and animated sprites
        - [ ] Animations
        - [ ] Animation managers
        - [ ] Sprites with transforms
        - [ ] Animated sprites
	- Gamepad API
        - [ ] Initialize gamepads with SDL
        - [ ] Add gamepad input polling to the window
	- Tiled file format support
        - [ ] Load a tilemap from a file
        - [ ] Convert Tiled tiles to libau tiles
        - [ ] Mark all tiles in "background" layers as not solid
        - [ ] Return a list of all-non-tile objects
	- Binding windows to global
		- [ ] Add a compile-time-flag to Window to bind it as global
		- [ ] Add functions to access the global window
- Documentation
	- Write documentation for each module
	- Document power-of-two textures
	- Document SDL libraries
	- Generate and host the documentation on a github page
	- Link to the documentation from the README
- Improvements
    - Remove all floating point from the user-facing code
        - [ ] Add a scale to the window
        - [ ] Convert dimensions using the scale
        - [ ] Convert mouse using the scale
        - [ ] Convert drawing using the scale
