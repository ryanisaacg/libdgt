import derelict.sdl2.sdl;

import geom;
import gl_backend;

struct WindowConfig 
{
	bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed, highdpi;
}

static immutable SDL_NUM_KEYS = 284;

struct Window {
	GLBackend ctx;
	uint fps;
	bool should_continue;
	bool[SDL_NUM_KEYS] current_keys; //The total number of SDL keys
	bool[SDL_NUM_KEYS] previous_keys;
	Vector!(int, 2) mouse;
	bool mouse_left, mouse_right, mouse_middle;
//	AU_Particle* particles;
	size_t particle_count, particle_capacity;
//	AU_Tilemap map;
	uint previous_ticks;
	Rectangle!int camera;
	int window_width, window_height;
//	AU_Texture white;
}
