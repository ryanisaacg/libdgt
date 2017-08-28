module dgt.window;
import derelict.opengl;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import core.stdc.stdio, core.stdc.stdlib, core.stdc.time, core.thread;

import std.typecons : Nullable;

import dgt.array, dgt.color, dgt.font, dgt.gamepad, dgt.geom, dgt.gl_backend, dgt.io, dgt.sound, dgt.music, dgt.particle, dgt.sprite, dgt.texture, dgt.tilemap, dgt.util;

struct WindowConfig
{
    bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed;

    @property SDL_WindowFlags flags() const
    {
        return SDL_WINDOW_OPENGL |
        (resizable ? SDL_WINDOW_RESIZABLE : cast(SDL_WindowFlags)0) |
        (fullscreen ? SDL_WINDOW_FULLSCREEN : cast(SDL_WindowFlags)0) |
        (borderless ? SDL_WINDOW_BORDERLESS : cast(SDL_WindowFlags)0) |
        (minimized ? SDL_WINDOW_MINIMIZED : cast(SDL_WindowFlags)0) |
        (maximized ? SDL_WINDOW_MAXIMIZED : cast(SDL_WindowFlags)0) |
        (input_grabbed ? SDL_WINDOW_INPUT_GRABBED : cast(SDL_WindowFlags)0);
    }
}

static immutable SDL_NUM_KEYS = 284;

struct Window
{
    private:
    SDL_Window *window;
    GLBackend ctx;
    bool shouldContinue = true;
    bool[SDL_NUM_KEYS] current_keys; //The total number of SDL keys
    bool[SDL_NUM_KEYS] previous_keys;
    Vectori mousePos = Vectori(0, 0), previousMouse = Vectori(0, 0);
    bool mouseLeft = false, mouseRight = false, mouseMiddle = false,
         mouseLeftPrevious = true, mouseRightPrevious = true, mouseMiddlePrevious = true;
    //TODO: Add a function to wait on IO
    Array!Particle particles;
    uint previous_ticks;
    int offsetX, offsetY, windowWidth, windowHeight;
    Texture white;
    Rectangle!int camera;
    Array!Gamepad connectedGamepads;
    int scale;

    @disable this();
    @disable this(this);

    public:
    bool inUIMode = false;
    uint fps = 60;
    float aspectRatio;

    this(in string title, in int width, in int height, in WindowConfig config, in int scale = 1, in bool bindToGlobal = true)
    {
        version(Windows)
        {
            DerelictSDL2.load(SharedLibVersion(2, 0, 3));
        }
        //Initialize libraries
        SDL_Init(SDL_INIT_VIDEO);
        new Thread({
            SDL_Init(SDL_INIT_AUDIO | SDL_INIT_GAMECONTROLLER);
            version(Windows)
            {
                DerelictSDL2Image.load();
                DerelictSDL2ttf.load();
                DerelictSDL2Mixer.load();
            }
            IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
            TTF_Init();
            Mix_Init(MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG);
        }).start();
        window = SDL_CreateWindow(title.ptr,
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
            config.flags);
        ctx = GLBackend(window);
        particles = Array!Particle(128);
        camera.set(0, 0, width * scale, height * scale);
        windowWidth = width;
        windowHeight = height;

        ubyte[3] white_pixel = [ 255, 255, 255 ];
        white = Texture(white_pixel.ptr, 1, 1, false);
        glViewport(0, 0, width, height);
        aspectRatio = cast(float)width / height;
        this.scale = scale;

        srand(cast(uint)time(null));

        if(bindToGlobal)
            globalWindow = &this;

        thread_joinAll();
        Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
        Mix_AllocateChannels(512);

        connectedGamepads = Array!Gamepad(SDL_NumJoysticks());
        for(int i = 0; i < SDL_NumJoysticks(); i++)
            if(SDL_IsGameController(i))
                connectedGamepads.add(Gamepad(SDL_GameControllerOpen(i)));
    }

    @nogc nothrow @trusted:

    void close()
    {
        shouldContinue = false;
    }

    ~this()
    {
        foreach(gamepad; gamepads)
            gamepad.destroy();
        SDL_DestroyWindow(window);
        TTF_Quit();
        Mix_Quit();
        IMG_Quit();
        SDL_Quit();
    }

    void begin(in Color bg, in Rectangle!int cam)
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
                            SDL_GL_GetDrawableSize(window, &w, &h);
                            float windowRatio = cast(float)w / h;
                            offsetX = offsetY = 0;
                            if(windowRatio > aspectRatio)
                            {
                                auto oldW = w;
                                w = cast(int)(aspectRatio * h);
                            }
                            else if(windowRatio < aspectRatio)
                            {
                                auto oldH = h;
                                h = cast(int)(w / aspectRatio);
                                offsetY = (oldH - h) / 2;
                            }
                            glViewport(offsetX, offsetY, w, h);
                            windowWidth = w;
                            windowHeight = h;
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
        previousMouse = mousePos;
        mousePos = Vectori(x * scale, y * scale);
        mouseLeftPrevious = mouseLeft;
        mouseRightPrevious = mouseRight;
        mouseMiddlePrevious = mouseMiddlePrevious;
        mouseLeft = (button_mask & SDL_BUTTON(SDL_BUTTON_LEFT)) != 0;
        mouseRight = (button_mask & SDL_BUTTON(SDL_BUTTON_RIGHT)) != 0;
        mouseMiddle = (button_mask & SDL_BUTTON(SDL_BUTTON_MIDDLE)) != 0;
        float left = camera.x / scale, right = left + camera.width / scale,
                top = camera.y / scale, bottom = top + camera.height / scale;
        ctx.transform = [
            2 / (right - left), 0, 0,
            0, 2 / (top - bottom), 0,
            -(right + left) / (right - left), -(top + bottom) / (top - bottom), 1
        ];
    }

    void stepParticles(T)(in Tilemap!T map)
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

    void end(T)(in Tilemap!T map)
    {
        ctx.flip();

        stepParticles(map);

        uint time = SDL_GetTicks();
        if (time - previous_ticks < 1000 / fps) {
            SDL_Delay(1000 / fps - (time - previous_ticks)); //account for the time elapsed during the frame
        }
        previous_ticks = time;
    }

    void draw(size_t Len)(in Color color, in Vectori[Len] points)
    {
        static immutable Indices = (Len - 2) * 3;
        static assert ( Len >= 3 );
        Vertex[Len] vertices;
        GLuint[Indices] indices;
        Vectori offset = inUIMode ? camera.topLeft : Vectori(0, 0);
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


    void draw(size_t NumPoints = 32)(in Color color, in Circlei circle)
    {
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

    void draw(in Color color, in Rectanglei rect)
    {
        Vectori[4] points = [ rect.topLeft, Vectori(rect.x + rect.width, rect.y),
            rect.topLeft + rect.size, Vectori(rect.x, rect.y + rect.height)];
        draw(color, points);
    }

    void draw(in Texture tex, in float x, in float y)
    {
        draw(tex, x, y, tex.size.width * scale, tex.size.height * scale);
    }

    void draw(in Texture tex, in float x, in float y, in float w, in float h,
                        in float rot = 0, in float or_x = 0, in float or_y = 0,
                        in float scale_x = 1, in float scale_y = 1,
                        in bool flip_x = false, in bool flip_y = false,
                        in Color color = dgt.color.white)
    {
        auto trans = identity() * translate(-or_x, -or_y) * rotate(rot)
            * dgt.geom.scale(scale_x, scale_y);
        draw(tex, trans, x + or_x, y + or_y, w, h, flip_x, flip_y, color);
    }

    void draw(in Texture tex, in Transform!float trans, in float x, in float y,
                       in float w, in float h, in bool flip_x = false, in bool flip_y = false,
                       in Color color = dgt.color.white)
    {
        //Calculate the destination points with the transformation
        auto tl = (trans * Vectorf(0, 0)) / scale;
        auto tr = (trans * Vectorf(w, 0)) / scale;
        auto bl = (trans * Vectorf(0, h)) / scale;
        auto br = (trans * Vectorf(w, h)) / scale;

        //Calculate the source points normalized to [0, 1]
        //The conversion factor for normalizing vectors
        float conv_factor_x = 1.0f / tex.sourceWidth;
        float conv_factor_y = 1.0f / tex.sourceHeight;
        float norm_x = tex.size.x * conv_factor_x;
        float norm_y = tex.size.y * conv_factor_y;
        float norm_w = tex.size.width * conv_factor_x / scale;
        float norm_h = tex.size.height * conv_factor_y / scale;
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
        auto translate = Vectorf(x, y) + (inUIMode ? Vectorf(camera.topLeft) : Vector!float(0, 0));
        translate = translate / scale;
        Vertex[4] vertices = [ Vertex(tl + translate, src_tl, color),
            Vertex(tr + translate, src_tr, color),
            Vertex(br + translate, src_br, color),
            Vertex(bl + translate, src_bl, color)];
        GLuint[6] indices = [0, 1, 2, 2, 3, 0];
        ctx.add!(4, 6)(tex.id, vertices, indices);
    }

    void draw(ref scope Sprite sprite)
    {
        sprite.update();
        draw(sprite.texture, sprite.x, sprite.y, sprite.width, sprite.height,
                sprite.rotation, sprite.originX, sprite.originY,
                sprite.scaleX, sprite.scaleY, sprite.flipX, sprite.flipY, sprite.color);
    }

    int draw(ref in Font font, in char c, in float x, in float y)
    {
        Texture renderChar = font.render(c);
        draw(renderChar, x, y);
        return renderChar.size.width;
    }

    void draw(ref in Font font, in string str, in float x, in float y)
    {
        int position = 0;
        float cursor = y;
        //Loop from the beginning to end of the string
        for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
            if (c == '\t')
            {
                for (int j = 0; j < 4; i++)
                {
                    position += draw(font, ' ', position + x, cursor);
                }
            } else if (c == '\n')
                cursor += font.height;
            else if (c != '\r')
                position += draw(font, c, position + x, cursor);
        }
    }

    void addParticleBurst(in ParticleEmitter emitter)
    {
        int parts = randomRange(emitter.particle_min, emitter.particle_max);
        for (int i = 0; i < parts; i++)
            particles.add(emitter.emit());
    }

    bool isKeyDown(in string name) const
    {
        return current_keys[SDL_GetScancodeFromName(name.ptr)];
    }

    bool wasKeyDown(in string name) const
    {
        return previous_keys[SDL_GetScancodeFromName(name.ptr)];
    }

    void setShader(in string vertexShader, in string fragmentShader)
    {
        ctx.setShader(vertexShader, fragmentShader);
    }

    pure:
    @property Vector!int mouse() const
    {
        return mousePos * camera.width / windowWidth - Vectori(offsetX, offsetY)
            + (inUIMode ? Vectori(0, 0) : camera.topLeft);
    }
    @property bool mouseLeftPressed() const { return mouseLeft; }
    @property bool mouseRightPressed() const { return mouseRight; }
    @property bool mouseMiddlePressed() const { return mouseMiddle; }
    @property bool mouseLeftReleased() const { return !mouseLeft && mouseLeftPrevious; }
    @property bool mouseRightReleased() const { return !mouseRight && mouseRightPrevious; }
    @property bool mouseMiddleReleased() const { return !mouseMiddle && mouseMiddlePrevious; }
    @property bool isOpen() const { return shouldContinue; }
    @property Array!Gamepad gamepads() { return connectedGamepads; }
    @property int width() const { return windowWidth; }
    @property int height() const { return windowHeight; }
    @property int unitsPerPixel() const { return scale; }
}

private Window* globalWindow;

public @nogc nothrow ref Window getWindow()
{
    return *globalWindow;
}
