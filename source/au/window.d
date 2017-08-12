module au.window;
import derelict.opengl3.gl;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import core.stdc.stdio, core.stdc.stdlib, core.stdc.time;

import std.typecons : Nullable;

import au.array, au.color, au.font, au.geom, au.gl_backend, au.io, au.sound, au.music, au.particle, au.texture, au.tilemap, au.util;

struct WindowConfig
{
    bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed, highdpi;
}

static immutable SDL_NUM_KEYS = 284;

class Window
{
    private:
    SDL_Window *window;
    GLBackend ctx;
    bool should_continue = true;
    bool[SDL_NUM_KEYS] current_keys; //The total number of SDL keys
    bool[SDL_NUM_KEYS] previous_keys;
    Vectori mouse;
    bool mouse_left, mouse_right, mouse_middle;
    //TODO: Add a function to wait on IO
    Array!Particle particles;
    uint previous_ticks;
    int window_width, window_height;
    Texture white;
    public:
    uint fps = 60;
    Rectangle!float camera;
    float aspectRatio;

    this(string title, int width, int height, WindowConfig config)
    {
        DerelictSDL2.load(SharedLibVersion(2, 0, 3));
        DerelictSDL2Image.load();
        DerelictSDL2ttf.load();
        DerelictSDL2Mixer.load();
        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
        window = SDL_CreateWindow(title.ptr,
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
            SDL_WINDOW_OPENGL |
            (config.resizable ? SDL_WINDOW_RESIZABLE : 0) |
            (config.fullscreen ? SDL_WINDOW_FULLSCREEN : 0) |
            (config.borderless ? SDL_WINDOW_BORDERLESS : 0) |
            (config.minimized ? SDL_WINDOW_MINIMIZED : 0) |
            (config.maximized ? SDL_WINDOW_MAXIMIZED : 0) |
            (config.input_grabbed ? SDL_WINDOW_INPUT_GRABBED : 0) |
            (config.highdpi ? SDL_WINDOW_ALLOW_HIGHDPI : 0));
        ctx.init(window);
        particles.ensureCapacity(128);
        camera.set(0, 0, width, height);
        window_width = width;
        window_height = height;
        IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
        TTF_Init(); //initialize the SDL font subsystem
        Mix_Init(MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG); //Initialize the SDL mixer
        Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
        Mix_AllocateChannels(512);

        srand(cast(uint)time(null));

        ubyte[3] white_pixel = [ 255, 255, 255 ];
        white = loadTexture(white_pixel.ptr, 1, 1, false);
        glViewport(0, 0, width, height);
        aspectRatio = cast(float)width / height;
    }

    @nogc nothrow:
    void destroy()
    {
        ctx.destroy();
        SDL_DestroyWindow(window);
        TTF_Quit();
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

    Texture loadTexture(string name)
    {
        SDL_Surface* surface = IMG_Load(name.ptr);
        Texture tex = loadTexture(surface);
        SDL_FreeSurface(surface);
        return tex;
    }

    Texture loadTexture(SDL_Surface* sur)
    {
        return loadTexture(cast(ubyte*)sur.pixels, sur.w, sur.h, sur.format.BytesPerPixel == 4);
    }

    Font loadFont(int size, Color col, string filename)
    {
        TTF_Font* font = TTF_OpenFont(filename.ptr, size);
        if (font == null) {
            fprintf(stderr, "Font with filename %s not found\n", filename.ptr);
        }
        Font bitmap_font = Font(this, font, col);
        TTF_CloseFont(font);
        return bitmap_font;
    }

    SoundClip loadSound(string filename)
    {
        return SoundClip(filename);
    }

    Music loadMusic(string filename)
    {
        return Music(filename);
    }

    void begin(Color bg)
    {
        ctx.clear(bg);
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
                case SDL_WINDOWEVENT:
                    switch(e.window.event) {
                        case SDL_WINDOWEVENT_RESIZED:
                        case SDL_WINDOWEVENT_SIZE_CHANGED:
                            int w, h;
                            SDL_GetWindowSize(window, &w, &h);
                            glViewport(0, 0, w, h); //TODO: Letterbox
                            break;
                        default:
                            break;
                    }
                    break;
                default:
                    break;
            }
        }
        int x, y;
        int button_mask = SDL_GetMouseState(&x, &y);
        mouse = Vectori(x, y);
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

    void stepParticles(T)(Nullable!(Tilemap!T) map = Nullable!(Tilemap!T)())
    {
        if(!map.isNull)
            for(size_t i = 0; i < particles.length; i++) {
                switch (particles[i].behavior) {
                case ParticleBehavior.Die:
                    if (!map.empty(particles[i].position.x, particles[i].position.y))
                        particles[i].lifetime = 0;
                    break;
                case ParticleBehavior.Bounce:
                    if (!map.empty(particles[i].position.x + particles[i].velocity.x, particles[i].position.y))
                        particles[i].velocity.x *= -1;
                    if (!map.empty(particles[i].position.x, particles[i].position.y + particles[i].velocity.y))
                        particles[i].velocity.y *= -1;
                    break;
                default: break;
                }
            }

        for (size_t i = 0; i < particles.length; i++) {
            particles[i].update();
            if (particles[i].lifetime <= 0) {
                particles.remove(i);
                i--;
            } else {
                draw(particles[i].region, particles[i].position.x, particles[i].position.y);
            }
        }
    }

    void end()
    {
        end!bool(Nullable!(Tilemap!bool)());
    }

    void end(T)(Nullable!(Tilemap!T) map)
    {
        ctx.flip();

        stepParticles(map);

        uint time = SDL_GetTicks();
        if (time - previous_ticks < 1000 / fps) {
            SDL_Delay(1000 / fps - (time - previous_ticks)); //account for the time elapsed during the frame
        }
        previous_ticks = time;
    }

    void draw(size_t Len)(Color color, Vectorf[Len] points)
    {
        static immutable Indices = (Len - 2) * 3;
        static assert ( Len >= 3 );
        Vertex[Len] vertices;
        GLuint[Indices] indices;
        for (size_t i = 0; i < Len; i++)
        {
            vertices[i].pos = points[i];
            vertices[i].col = color;
        }
        uint current = 1;
        for (size_t i = 0; i < Indices; i += 3, current += 1) {
            indices[i] = 0;
            indices[i + 1] = current;
            indices[i + 2] = current + 1;
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

    void draw(ref Texture tex, float x, float y)
    {
        draw(tex, x, y, tex.region.width, tex.region.height);
    }

    void draw(ref Texture tex, float x, float y, float w, float h,
                        float rot = 0, float or_x = 0, float or_y = 0,
                        float scale_x = 1, float scale_y = 1,
                        bool flip_x = false, bool flip_y = false,
                        Color color = au.color.white) {
        auto trans = identity() * translate(-or_x, -or_y) * rotate(rot)
            * scale(scale_x, scale_y);
        draw(tex, trans, x + or_x, y + or_y, w, h, flip_x, flip_y, color);
    }

    void draw(ref Texture tex, ref Transform!float trans, float x, float y,
                       float w, float h, bool flip_x = false, bool flip_y = false,
                       Color color = au.color.white) {
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
        Vertex[4] vertices = [ Vertex(tl + translate, src_tl, color),
            Vertex(tr + translate, src_tr, color),
            Vertex(br + translate, src_br, color),
            Vertex(bl + translate, src_bl, color)];
        GLuint[6] indices = [0, 1, 2, 2, 3, 0];
        ctx.add!(4, 6)(tex.id, vertices, indices);
    }


    int draw(ref Font font, char c, float x, float y) {
        Texture renderChar = font.render(c);
        draw(renderChar, x, y);
        return renderChar.region.width;
    }

    void draw(ref Font font, string str, float x, float y) {
        int position = 0;
        //Loop from the beginning to end of the string
        for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
            if (c == '\t')
            {
                for (int j = 0; j < 4; i++)
                {
                    position += draw(font, ' ', position + x, y);
                }
            } else if (c == '\n')
                y += font.height;
            else if (c != '\r')
                position += draw(font, c, position + x, y);
        }
    }

    void addParticleBurst(ref ParticleEmitter emitter)
    {
        int parts = randi_range(emitter.particle_min, emitter.particle_max);
        for (int i = 0; i < parts; i++)
            particles.add(emitter.emit());
    }

    bool isKeyDown(string name) { return current_keys[SDL_GetScancodeFromName(name.ptr)]; }
    bool wasKeyDown(string name) { return previous_keys[SDL_GetScancodeFromName(name.ptr)]; }

    pure:
    int mouseX() { return mouse.x; }
    int mouseY() { return mouse.y; }
    bool mouseLeft() { return mouse_left; }
    bool mouseRight() { return mouse_right; }
    bool mouseMiddle() { return mouse_middle; }
    bool isOpen() { return should_continue; }

/*  static void au_draw_sprite_transformed(AU_Engine* eng, AU_TextureRegion region, AU_SpriteTransform* trans) {
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
*/
}
