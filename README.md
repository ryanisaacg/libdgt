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
- Sprites and animated sprites

## Roadmap

- Featureset
	- Letterboxing
        - [ ] Convert the window size to the aspect ratio
        - [ ] Construct the viewport with the given size
	- Gamepad API
        - [ ] Initialize gamepads with SDL
        - [ ] Add gamepad input polling to the window
	- User-created shaders
        - [ ] Add a function in the GL backend to switch the shader
        - [ ] Add a function in the window to switch the shader
	- Non-power-of-two textures
        - [ ] Detect if a texture is not power of two
        - [ ] Create the smallest power-of-two texture possible to hold it
        - [ ] Blit the loaded texture onto the power-of-two surface
	- Tiled file format support
        - [ ] Load a tilemap from a file
        - [ ] Convert Tiled tiles to libau tiles
        - [ ] Mark all tiles in "background" layers as not solid
        - [ ] Return a list of all-non-tile objects
- Documentation
	- Write documentation for each module
	- Generate and host the documentation on a github page
	- Link to the documentation from the README
- Improvements
	- Do initial loading in parallel
        - [ ] Create a thread for each load
        - [ ] Join all threads before continuing
    - Remove all floating point from the user-facing code
        - [ ] Add a scale to the window
        - [ ] Convert dimensions using the scale
        - [ ] Convert mouse using the scale
        - [ ] Convert drawing using the scale
