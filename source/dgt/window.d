module dgt.window;
import derelict.opengl3.gl;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import core.stdc.stdio, core.stdc.stdlib, core.stdc.time, core.thread;

import std.typecons : Nullable;

import dgt.array, dgt.color, dgt.font, dgt.gamepad, dgt.geom, dgt.gl_backend, dgt.io, dgt.sound, dgt.music, dgt.particle, dgt.sprite, dgt.texture, dgt.tilemap, dgt.util;

struct WindowConfig
{
    bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed, highdpi;

    int getFlags()
    {
        return SDL_WINDOW_OPENGL |
        (resizable ? SDL_WINDOW_RESIZABLE : 0) |
        (fullscreen ? SDL_WINDOW_FULLSCREEN : 0) |
        (borderless ? SDL_WINDOW_BORDERLESS : 0) |
        (minimized ? SDL_WINDOW_MINIMIZED : 0) |
        (maximized ? SDL_WINDOW_MAXIMIZED : 0) |
        (input_grabbed ? SDL_WINDOW_INPUT_GRABBED : 0) |
        (highdpi ? SDL_WINDOW_ALLOW_HIGHDPI : 0);
    }
}

static immutable SDL_NUM_KEYS = 284;

class Window
{
    private:
    SDL_Window *window;
    GLBackend ctx;
    bool shouldContinue = true;
    bool[SDL_NUM_KEYS] current_keys; //The total number of SDL keys
    bool[SDL_NUM_KEYS] previous_keys;
    Vectori mouse = Vectori(0, 0), previousMouse = Vectori(0, 0);
    bool mouseLeft = false, mouseRight = false, mouseMiddle = false,
         mouseLeftPrevious = true, mouseRightPrevious = true, mouseMiddlePrevious = true;
    //TODO: Add a function to wait on IO
    Array!Particle particles;
    uint previous_ticks;
    int window_width, window_height;
    Texture white;
    Rectangle!float camera;
    Array!Gamepad gamepads;

    public:
    bool inUIMode = false;
    uint fps = 60;
    float aspectRatio;
    int scale;

    this(string title, int width, int height, WindowConfig config, int scale = 1, bool bindToGlobal = true)
    {
        DerelictSDL2.load(SharedLibVersion(2, 0, 3));
        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
        SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
        new Thread(&DerelictSDL2Image.load).start();
        new Thread(&DerelictSDL2ttf.load).start();
        new Thread(&DerelictSDL2Mixer.load).start();
        window = SDL_CreateWindow(title.ptr,
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
            config.getFlags());
        ctx = GLBackend(window);
        particles = Array!Particle(128);
        camera.set(0, 0, width * scale, height * scale);
        window_width = width;
        window_height = height;
        thread_joinAll();
        new Thread({
            IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
        }).start();
        new Thread({
            TTF_Init();
        }).start();
        new Thread({
            Mix_Init(MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG);
        }).start();
        thread_joinAll();
        Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
        Mix_AllocateChannels(512);

        srand(cast(uint)time(null));

        ubyte[3] white_pixel = [ 255, 255, 255 ];
        white = Texture(white_pixel.ptr, 1, 1, false);
        glViewport(0, 0, width, height);
        aspectRatio = cast(float)width / height;
        this.scale = scale;
        gamepads = Array!Gamepad(SDL_NumJoysticks());
        for(int i = 0; i < SDL_NumJoysticks(); i++)
            if(SDL_IsGameController(i))
                gamepads.add(Gamepad(SDL_GameControllerOpen(i)));
        if(bindToGlobal)
            globalWindow = this;
    }

    @nogc nothrow:

    void close()
    {
        shouldContinue = false;
    }

    ~this()
    {
        ctx.destroy();
        SDL_DestroyWindow(window);
        TTF_Quit();
        Mix_Quit();
        IMG_Quit();
        SDL_Quit();
    }

    @nogc nothrow:

    void begin(Color bg, Rectangle!float cam)
    {
        camera = cam;
        inUIMode = false;
        ctx.clear(bg);
        previous_ticks = SDL_GetTicks();
        previous_keys = current_keys;
        SDL_Event e;
        while (SDL_PollEvent(&e))
        {
            switch (e.type)
            {
                case SDL_QUIT:
                    shouldContinue = false;
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
                            float windowRatio = cast(float)w / h;
                            if(windowRatio > aspectRatio)
                            {
                                auto oldW = w;
                                w = cast(int)(aspectRatio * h);
                                glViewport((oldW - w) / 2, 0, w, h);
                            }
                            else if(windowRatio < aspectRatio)
                            {
                                auto oldH = h;
                                h = cast(int)(w / aspectRatio);
                                glViewport(0, (oldH - h) / 2, w, h);
                            }
                            else
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
        previousMouse = mouse;
        mouse = Vectori(x * scale, y * scale);
        mouseLeftPrevious = mouseLeft;
        mouseRightPrevious = mouseRight;
        mouseMiddlePrevious = mouseMiddlePrevious;
        mouseLeft = (button_mask & SDL_BUTTON(SDL_BUTTON_LEFT)) != 0;
        mouseRight = (button_mask & SDL_BUTTON(SDL_BUTTON_RIGHT)) != 0;
        mouseMiddle = (button_mask & SDL_BUTTON(SDL_BUTTON_MIDDLE)) != 0;
        float left = camera.x, right = left + camera.width,
                top = camera.y, bottom = top + camera.height;
        ctx.transform = [
            2 / (right - left), 0, 0,
            0, 2 / (top - bottom), 0,
            -(right + left) / (right - left), -(top + bottom) / (top - bottom), 1
        ];
    }

    void stepParticles(T)(Tilemap!T map)
    {
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

    void end(T)(Tilemap!T map)
    {
        ctx.flip();

        stepParticles(map);

        uint time = SDL_GetTicks();
        if (time - previous_ticks < 1000 / fps) {
            SDL_Delay(1000 / fps - (time - previous_ticks)); //account for the time elapsed during the frame
        }
        previous_ticks = time;
    }

    void draw(size_t Len)(Color color, Vectori[Len] points)
    {
        static immutable Indices = (Len - 2) * 3;
        static assert ( Len >= 3 );
        Vertex[Len] vertices;
        GLuint[Indices] indices;
        Vectori offset = inUIMode ? Vectori(camera.topLeft) : Vectori(0, 0);
        for (size_t i = 0; i < Len; i++)
        {
            auto point = (points[i] + offset) / scale;
            vertices[i].pos.x = point.x;
            vertices[i].pos.y = point.y;
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


    void draw(size_t NumPoints = 32)(Color color, Circlei circle) {
        Vectori[NumPoints] points; //A large array of points to simulate a circle
        auto rotation = rotate(360 / NumPoints);
        auto pointer = Vectorf(0, -circle.radius);
        for (size_t i = 0; i < NumPoints; i++)
        {
            points[i] = circle.center + Vectori(pointer);
            pointer = rotation * pointer;
        }
        draw(color, points);
    }

    void draw(Color color, Rectanglei rect) {
        Vectori[4] points = [ rect.topLeft, Vectori(rect.x + rect.width, rect.y),
            rect.topLeft + rect.size, Vectori(rect.x, rect.y + rect.height)];
        draw(color, points);
    }

    void draw(ref Texture tex, float x, float y)
    {
        draw(tex, x, y, tex.getRegion.width, tex.getRegion.height);
    }

    void draw(ref Texture tex, float x, float y, float w, float h,
                        float rot = 0, float or_x = 0, float or_y = 0,
                        float scale_x = 1, float scale_y = 1,
                        bool flip_x = false, bool flip_y = false,
                        Color color = dgt.color.white) {
        auto trans = identity() * translate(-or_x, -or_y) * rotate(rot)
            * dgt.geom.scale(scale_x, scale_y);
        draw(tex, trans, x + or_x, y + or_y, w, h, flip_x, flip_y, color);
    }

    void draw(ref Texture tex, ref Transform!float trans, float x, float y,
                       float w, float h, bool flip_x = false, bool flip_y = false,
                       Color color = dgt.color.white) {
        //Calculate the destination points with the transformation
        auto tl = (trans * Vectorf(0, 0)) / scale;
        auto tr = (trans * Vectorf(w, 0)) / scale;
        auto bl = (trans * Vectorf(0, h)) / scale;
        auto br = (trans * Vectorf(w, h)) / scale;

        //Calculate the source points normalized to [0, 1]
        //The conversion factor for normalizing vectors
        float conv_factor_x = 1.0f / tex.getSourceWidth;
        float conv_factor_y = 1.0f / tex.getSourceHeight;
        float norm_x = tex.getRegion.x * conv_factor_x;
        float norm_y = tex.getRegion.y * conv_factor_y;
        float norm_w = tex.getRegion.width * conv_factor_x / scale;
        float norm_h = tex.getRegion.height * conv_factor_y / scale;
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
        auto translate = Vectorf(x, y) + (inUIMode ? camera.topLeft : Vector!float(0, 0));
        translate = translate / scale;
        Vertex[4] vertices = [ Vertex(tl + translate, src_tl, color),
            Vertex(tr + translate, src_tr, color),
            Vertex(br + translate, src_br, color),
            Vertex(bl + translate, src_bl, color)];
        GLuint[6] indices = [0, 1, 2, 2, 3, 0];
        ctx.add!(4, 6)(tex.id, vertices, indices);
    }

    void draw(ref Sprite sprite)
    {
        sprite.update();
        draw(sprite.getTexture, sprite.x, sprite.y, sprite.width, sprite.height,
                sprite.rotation, sprite.originX, sprite.originY,
                sprite.scaleX, sprite.scaleY, sprite.flipX, sprite.flipY, sprite.color);
    }

    int draw(ref Font font, char c, float x, float y) {
        Texture renderChar = font.render(c);
        draw(renderChar, x, y);
        return renderChar.getRegion.width;
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
        int parts = randomRange(emitter.particle_min, emitter.particle_max);
        for (int i = 0; i < parts; i++)
            particles.add(emitter.emit());
    }

    bool isKeyDown(string name) { return current_keys[SDL_GetScancodeFromName(name.ptr)]; }
    bool wasKeyDown(string name) { return previous_keys[SDL_GetScancodeFromName(name.ptr)]; }

    void setShader(string vertexShader, string fragmentShader)
    {
        ctx.setShader(vertexShader, fragmentShader);
    }

    pure:
    Vector!int mousePos() { return mouse; }
    int mouseX() { return mouse.x; }
    int mouseY() { return mouse.y; }
    bool mouseLeftPressed() { return mouseLeft; }
    bool mouseRightPressed() { return mouseRight; }
    bool mouseMiddlePressed() { return mouseMiddle; }
    bool mouseLeftReleased() { return !mouseLeft && mouseLeftPrevious; }
    bool mouseRightReleased() { return !mouseRight && mouseRightPrevious; }
    bool mouseMiddleReleased() { return !mouseMiddle && mouseMiddlePrevious; }
    bool isOpen() { return shouldContinue; }
    int getScale() { return scale; }
    Array!Gamepad getGamepads() { return gamepads; }
}

private Window globalWindow;

public @nogc nothrow Window getWindow()
{
    return globalWindow;
}

unittest
{
    import dgt;
    WindowConfig config;
	config.resizable = true;
	Window window = new Window("Test title", 640, 480, config);
    auto tex = Texture("test.png");
    scope(exit) tex.destroy();
    auto camera = Rectanglef(0, 0, 640, 480);
    auto map = Tilemap!bool(640, 480, 32);
    while(window.isOpen)
    {
        window.begin(black, camera);
        scope(exit)
        {
            window.end(map);
            window.close();
        }
        window.draw(tex, 100, 0, 32, 32);
        window.draw(red, Rectanglei(30, 30, 40, 40));
        window.draw(Color(0, 1, 0, 0.5), Circlei(100, 100, 32));
    }
}
