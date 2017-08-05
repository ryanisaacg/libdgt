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

## To-Do

- [ ] Documentation
	- [ ] Write documentation for each module
	- [ ] Generate and host the documentation on a github page
	- [ ] Link to the documentation from the README
- [ ] Featureset
    - [ ] TTF font rendering
    - [ ] Particle system
    - [ ] Sprites and animated sprites
    - [ ] Zero effort game loops
    - [ ] 2D tilemap for storing and pixel-perfect geometry collision
	- [ ] Loading and playing sound
	- [ ] Gamepad API
	- [ ] Screen-shake, inverted screen, etc.
	- [ ] User-created shaders
- [ ] Bugs
	- [ ] Viewports seem not to correctly apply when the window is resized
