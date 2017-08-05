import derelict.opengl3.gl;
import derelict.sdl2.sdl, derelict.sdl2.image;

import color, geom, gl_backend, texture;

import core.stdc.stdio;


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
	Vectorf mouse;
	bool mouse_left, mouse_right, mouse_middle;
	//TODO: Add a function to wait on IO
//	AU_Particle* particles;
	size_t particle_count, particle_capacity;
//	AU_Tilemap map;
	uint previous_ticks;
	Rectangle!float camera;
	int window_width, window_height;
	Texture white;

	void init(string title, int width, int height, WindowConfig config)
	{
		DerelictSDL2.load();
		DerelictSDL2Image.load();
		SDL_Init(SDL_INIT_VIDEO/*| SDL_INIT_AUDIO*/);
		window = SDL_CreateWindow(title.ptr,
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
			SDL_WINDOW_OPENGL | (SDL_WINDOW_RESIZABLE && config.resizable) |
			(SDL_WINDOW_FULLSCREEN && config.fullscreen) |
			(SDL_WINDOW_BORDERLESS && config.borderless) |
			(SDL_WINDOW_MINIMIZED && config.minimized) |
			(SDL_WINDOW_MAXIMIZED && config.maximized) |
			(SDL_WINDOW_INPUT_GRABBED && config.input_grabbed) |
			(SDL_WINDOW_ALLOW_HIGHDPI && config.highdpi));
		ctx.init(window);
//		engine.particle_capacity = 128;
//		engine.particles = au_memory_alloc(sizeof(AU_Particle) * engine.particle_capacity);
//		engine.particle_count = 0;
//		engine.map = NULL;
		camera.set(0, 0, width, height);
		window_width = width;
		window_height = height;

		IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
//		TTF_Init(); //initialize the SDL font subsystem
//		Mix_Init(MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG); //Initialize the SDL mixer
//		Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
//		Mix_AllocateChannels(512);

		ubyte[3] white_pixel = [ 255, 255, 255 ];
		white = loadTexture(white_pixel.ptr, 1, 1, false);
		glViewport(0, 0, width, height);
	}

	@nogc nothrow:
	void destroy()
	{
		ctx.destroy();
		SDL_DestroyWindow(window);
		//TTF_Quit();
		//Mix_Quit();
		IMG_Quit();
		SDL_Quit();
	}

	@nogc nothrow:
	Texture loadTexture(ubyte* data, int w, int h, bool has_alpha)
	{
		GLuint texture;
		glGenTextures(1, &texture);
		glBindTexture(GL_TEXTURE_2D, texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, has_alpha ? GL_RGBA : GL_RGB, w, h, 0, has_alpha ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE,
					 data);
		glGenerateMipmap(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, 0);
		Texture tex = { id: texture, width: w, height: h, region: Rectangle!int(0, 0, w, h)};
		return tex;
	}

	Texture loadTexture(const char* name)
	{
		SDL_Surface* surface = IMG_Load(name);
		Texture tex = loadTexture(surface);
		SDL_FreeSurface(surface);
		return tex;
	}

	Texture loadTexture(SDL_Surface* sur) {
		return loadTexture(cast(ubyte*)sur.pixels, sur.w, sur.h, sur.format.BytesPerPixel == 4);
	}

	//TODO: Pass a rectangle and create a camera
	void begin(Color bg)
	{
		previous_ticks = SDL_GetTicks();
		previous_keys = current_keys;
		SDL_Event e;
		while (SDL_PollEvent(&e))
		{
			switch (e.type)
			{
				case SDL_QUIT:
					should_continue = false;
					break;
				case SDL_KEYDOWN:
					current_keys[e.key.keysym.scancode] = true;
					break;
				case SDL_KEYUP:
					current_keys[e.key.keysym.scancode] = false;
					break;
				case SDL_WINDOWEVENT_RESIZED:
					int w, h;
					SDL_GetWindowSize(window, &w, &h);
					glViewport(0, 0, w, h); //TODO: Letterbox
					break;
				default:
					break;
			}
		}
		int x, y;
		int button_mask = SDL_GetMouseState(&x, &y);
		mouse = Vectorf(x, y);
		mouse_left = (button_mask & SDL_BUTTON(SDL_BUTTON_LEFT)) != 0;
		mouse_right = (button_mask & SDL_BUTTON(SDL_BUTTON_RIGHT)) != 0;
		mouse_middle = (button_mask & SDL_BUTTON(SDL_BUTTON_MIDDLE)) != 0;
		float left = camera.x, right = camera.x + camera.width, top = camera.y, bottom = camera.y + camera.height;
		ctx.transform = [
			2 / (right - left), 0, 0,
			0, 2 / (top - bottom), 0,
			-(right + left) / (right - left), -(top + bottom) / (top - bottom), 1
		];
	}

	void end()
	{
		//Update particles
		/*if (eng.map != NULL) {
			for (size_t i = 0; i < eng.particle_count; i++) {
				AU_Particle* part = eng.particles + i;
				switch (part.behavior) {
					case AU_MAP_IGNORE:
						break;
					case AU_MAP_DIE:
						if (au_tmap_get(eng.map, part.position.x, part.position.y)) {
							eng.particles[i].lifetime = 0;
						}
						break;
					case AU_MAP_BOUNCE:
						if (au_tmap_get(eng.map, part.position.x + part.velocity.x, part.position.y)) {
							part.velocity.x *= -1;
						}
						if (au_tmap_get(eng.map, part.position.x, part.position.y + part.velocity.y)) {
							part.velocity.y *= -1;
						}
				}
			}
		}

		for (size_t i = 0; i < eng.particle_count; i++) {
			AU_Particle* part = eng.particles + i;
			au_particle_update(part);
			if (part.lifetime <= 0) {
				eng.particles[i] = eng.particles[eng.particle_count - 1];
				eng.particle_count--;
				i--;
			} else {
				AU_Sprite sprite = au_sprite_new(part.region);
				sprite.transform.x = part.position.x;
				sprite.transform.y = part.position.y;
				au_draw_sprite(eng, &sprite);
			}
		}*/

		ctx.flip();

		uint time = SDL_GetTicks();
		if (time - previous_ticks < 1000 / fps) {
			SDL_Delay(1000 / fps - (time - previous_ticks)); //account for the time elapsed during the frame
		}
		previous_ticks = time;
	}

	void draw(size_t Len)(Color color, Vectorf[Len] points)
	{
		static assert ( Len >= 3 );
		Vertex[Len] vertices;
		GLuint[Len * 3] indices;
		for (size_t i = 0; i < Len; i++)
		{
			vertices[i].pos = points[i];
			vertices[i].col = color;
		}
		for (size_t i = 0; i < Len; i++) {
			indices[i * 3] = 0;
			indices[i * 3 + 1] = cast(uint)i;
			indices[i * 3 + 2] = cast(uint)i + 1;
		}
		ctx.add(white.id, vertices, indices);
	}


	void draw(size_t NumPoints = 32)(Color color, Circlef circle) {
		Vectorf[NumPoints] points; //A large array of points to simulate a circle
		auto rotation = rotate(360 / NumPoints);
		auto pointer = Vectorf(0, -circle.radius);
		for (size_t i = 0; i < NumPoints; i++)
		{
			points[i] = circle.center + pointer;
			pointer  = rotation * pointer;
		}
		draw(color, points);
	}

	void draw(Color color, Rectanglef rect) {
		Vectorf[4] points = [ rect.topLeft, Vectorf(rect.x + rect.width, rect.y),
			rect.topLeft + rect.size, Vectorf(rect.x, rect.y + rect.height)];
		draw(color, points);
	}

	void draw(ref Texture tex, float x, float y, float w, float h,
						float rot = 0, float or_x = 0, float or_y = 0,
						float scale_x = 1, float scale_y = 1,
						bool flip_x = false, bool flip_y = false,
						Color color = color.white) {
		auto trans = identity() * translate(-or_x, -or_y) * rotate(rot)
			* scale(scale_x, scale_y);
		draw(tex, trans, x + or_x, y + or_y, w, h, flip_x, flip_y, color);
	}

	void draw(ref Texture tex, ref Transform!float trans, float x, float y,
					   float w, float h, bool flip_x = false, bool flip_y = false,
					   Color color = color.white) {
		//Calculate the destination points with the transformation
		auto tl = trans * Vectorf(0, 0);
		auto tr = trans * Vectorf(w, 0);
		auto bl = trans * Vectorf(0, h);
		auto br = trans * Vectorf(w, h);

		//Calculate the source points normalized to [0, 1]
		//The conversion factor for normalizing vectors
		float conv_factor_x = 1.0f / tex.width;
		float conv_factor_y = 1.0f / tex.height;
		float norm_x = tex.region.x * conv_factor_x;
		float norm_y = tex.region.y * conv_factor_y;
		float norm_w = tex.region.width * conv_factor_x;
		float norm_h = tex.region.height * conv_factor_y;
		auto src_tl = Vectorf(norm_x, norm_y);
		auto src_tr = Vectorf(norm_x + norm_w, norm_y);
		auto src_br = Vectorf(norm_x + norm_w, norm_y + norm_h);
		auto src_bl = Vectorf(norm_x, norm_y + norm_h);
		if (flip_x) {
			auto tmp = src_tr;
			src_tr = src_tl;
			src_tl = tmp;
			tmp = src_br;
			src_br = src_bl;
			src_bl = tmp;
		}
		if (flip_y) {
			auto tmp = src_tr;
			src_tr = src_br;
			src_br = tmp;
			tmp = src_tl;
			src_tl = src_bl;
			src_bl = tmp;
		}
		//Add all of the vertices to the context
		auto translate = Vectorf(x, y);
		ctx.add(tex.id, [ Vertex(tl + translate, src_tl, color),
			Vertex(tr + translate, src_tr, color),
			Vertex(br + translate, src_br, color),
			Vertex(bl + translate, src_bl, color)], [0, 1, 2, 2, 3, 0]);
	}

/*	static void au_draw_sprite_transformed(AU_Engine* eng, AU_TextureRegion region, AU_SpriteTransform* trans) {
		au_draw_texture_ex(eng, region, trans.color, trans.x, trans.y, trans.width, trans.height, trans.rotation,
						   trans.origin_x, trans.origin_y, trans.scale_x, trans.scale_y, trans.flip_x, trans.flip_y, trans.depth);
	}

	void au_draw_sprite(AU_Engine* eng, AU_Sprite* sprite) {
		au_draw_sprite_transformed(eng, sprite.region, &(sprite.transform));
	}

	void au_draw_sprite_animated(AU_Engine* eng, AU_AnimatedSprite* sprite) {
		au_anim_manager_update(&(sprite.animations));
		AU_TextureRegion region = au_anim_manager_get_frame(&(sprite.animations));
		au_draw_sprite_transformed(eng, region, &(sprite.transform));
	}

	AU_Font* au_load_font(AU_Engine* eng, int size, AU_Color col, const char* filename) {
		TTF_Font* font = TTF_OpenFont(filename, size);
		if (font == NULL) {
			fprintf(stderr, "Font with filename %s not found\n", filename);
			exit(1);
		}
		AU_Font* bitmap_font = au_font_init(eng, font, col);
		TTF_CloseFont(font);
		return bitmap_font;
	}

	int au_draw_char(AU_Engine* eng, AU_Font* font, char c, float x, float y) {
		AU_TextureRegion renderChar = au_font_get_char(font, c);
		au_draw_texture(eng, renderChar, x, y);
		return renderChar.rect.width;
	}

	void au_draw_string(AU_Engine* eng, AU_Font* font, const char* str, float x, float y) {
		char c;
		int position = 0;
		//Loop from the beginning to end of the string
		while ((c = *str) != '\0') {
			if (c == '\t') {
				for (int i = 0; i < 4; i++) {
					position += au_draw_char(eng, font, ' ', position + x, y);
				}
			} else if (c == '\n') {
				y += font.height;
			} else if (c == '\r') {
				//just ignore CR characters
			} else {
				position += au_draw_char(eng, font, c, position + x, y);
			}
			str++;
		}
	}

	void au_add_particles(AU_Engine* eng, AU_ParticleEmitter* emitter) {
		int parts = au_util_randi_range(emitter.particle_min, emitter.particle_max);
		if (eng.particle_count + parts >= eng.particle_capacity) {
			eng.particle_capacity *= 2;
			eng.particles = au_memory_realloc(eng.particles, sizeof(AU_Particle) * eng.particle_capacity);
		}
		for (int i = 0; i < parts; i++) {
			eng.particles[eng.particle_count] = au_particle_emitter_emit(emitter);
			eng.particle_count++;
		}
	}*/
}
