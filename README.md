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
- Sprites and animated sprites
- Gamepad API

## Roadmap

- Featureset
	- Tiled file format support
        - [ ] Load a tilemap from a file
        - [ ] Convert Tiled tiles to libau tiles
        - [ ] Mark all tiles in "background" layers as not solid
        - [ ] Return a list of all-non-tile objects
- Documentation
	- Write documentation for each module
	- Document power-of-two textures
	- Document SDL libraries
	- Generate and host the documentation on a github page
	- Link to the documentation from the README
