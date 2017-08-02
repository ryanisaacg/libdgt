import derelict.sdl2.sdl;

import geom;
import gl_backend;

struct WindowConfig
{
	bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed, highdpi;
}

static immutable SDL_NUM_KEYS = 284;

struct Window
{
	SDL_Window *window;
	GLBackend ctx;
	uint fps = 60;
	bool should_continue = true;
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

	void init(char* title, int width, int height, char* icon, WindowConfig config)
	{
		SDL_Init(SDL_INIT_VIDEO/*| SDL_INIT_AUDIO*/);
		window = SDL_CreateWindow(title,
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
			SDL_WINDOW_OPENGL | (SDL_WINDOW_RESIZABLE && config.resizable) |
			(SDL_WINDOW_FULLSCREEN && config.fullscreen) |
			(SDL_WINDOW_BORDERLESS && config.borderless) |
			(SDL_WINDOW_MINIMIZED && config.minimized) |
			(SDL_WINDOW_MAXIMIZED && config.maximized) |
			(SDL_WINDOW_INPUT_GRABBED && config.input_grabbed) |
			(SDL_WINDOW_ALLOW_HIGHDPI && config.highdpi));
		ctx.init(window);
//		engine->particle_capacity = 128;
//		engine->particles = au_memory_alloc(sizeof(AU_Particle) * engine->particle_capacity);
//		engine->particle_count = 0;
//		engine->map = NULL;
		camera.set(0, 0, width, height);
		window_width = width;
		window_height = height;

//		TTF_Init(); //initialize the SDL font subsystem
//		Mix_Init(MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG); //Initialize the SDL mixer
//		Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
//		Mix_AllocateChannels(512);

//		unsigned char white_pixel[] = { 255, 255, 255 };

//		engine->white = au_load_texture_from_memory(engine, white_pixel, 1, 1, false);
	}

	@nogc nothrow:
	void destroy()
	{
		//TTF_Quit();
		//Mix_Quit();
		ctx.destroy();
		SDL_DestroyWindow(window);
		SDL_Quit();
	}
}
