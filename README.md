# libdgt

## A D Game Toolkit library

The project is written in D to take advantage of its ability for both low and high level programming. There's no need for a separate scripting language like Lua; both the engine and high-level code can be written in the same language.

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
- Tiled JSON format support

## Roadmap

- Documentation
	- Write documentation for each module
        - [ ] Animation
        - [ ] Array
        - [ ] Color
        - [ ] Font
        - [ ] Gamepad
        - [ ] Geometry
        - [ ] OpenGL Backend
        - [ ] IO
		- [ ] Level
        - [ ] Music
        - [ ] Particles
        - [ ] Sound
        - [ ] Sprite
        - [ ] Texture
        - [ ] Tilemap
        - [ ] UI
        - [ ] Util
        - [ ] Window
	- Document power-of-two textures
	- Document SDL libraries
	- Generate and host the documentation on a github page
	- Link to the documentation from the README
- Testing
	- [ ] Animation
	- [x] Array
	- [x] Color
	- [ ] Font
	- [ ] Gamepad
	- [x] Geometry
	- [x] OpenGL Backend
	- [x] IO
	- [ ] Level
	- [ ] Music
	- [ ] Particles
	- [ ] Sound
	- [ ] Sprite
	- [ ] Texture
	- [x] Tilemap
	- [ ] UI
	- [x] Util
	- [ ] Window
