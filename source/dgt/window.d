module dgt.window;
import derelict.opengl;
import derelict.sdl2.sdl, derelict.sdl2.image, derelict.sdl2.mixer, derelict.sdl2.ttf;
import core.stdc.stdio, core.stdc.stdlib, core.stdc.time, core.thread;

import std.ascii;
import std.typecons : Nullable;

import dgt.array, dgt.camera, dgt.color, dgt.font, dgt.gamepad, dgt.geom, dgt.gl_backend, dgt.io, dgt.sound, dgt.music, dgt.particle, dgt.sprite, dgt.texture, dgt.tilemap, dgt.util;

///The flags used to control a window's initial behavior
struct WindowConfig
{
    bool fullscreen, resizable, borderless, minimized, maximized, input_grabbed, vsync = true;

    @property package SDL_WindowFlags flags() const
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

private static immutable SDL_NUM_KEYS = 284;

/**
The main window

Handles drawing and input
*/
struct Window
{
    private:
    SDL_Window *window;
    GLBackend ctx;
    bool shouldContinue = true;
    bool[SDL_NUM_KEYS] current_keys; //The total number of SDL keys
    bool[SDL_NUM_KEYS] previous_keys;
    Vector mousePos = Vector(0, 0), previousMouse = Vector(0, 0);
    bool mouseLeft = false, mouseRight = false, mouseMiddle = false,
         mouseLeftPrevious = true, mouseRightPrevious = true, mouseMiddlePrevious = true;
    //TODO: Add a function to wait on IO
    Array!Particle particles;
    uint previous_ticks;
    int offsetX, offsetY, windowWidth, windowHeight;
    Texture white;
    Camera camera;
    Array!Gamepad connectedGamepads;

    @disable this();
    @disable this(this);

    public:
    ///If the window is drawing in UI Mode, where drawing ignores the camera
    bool inUIMode = false;
    ///The number of target frames per second
    uint fps = 60;
    ///The target aspect ratio of the window
    float aspectRatio;

    /**
    Create a window

    Params:
    title = The window's stitle
    width = The window width in units
    height = The window height in units
    config = The flags that control the behavior of the window
    scale = the number of 'units' per pixel
    bindToGlobal = set the global window reference to this window
    */
    this(in string title, in int width, in int height, in WindowConfig config, in bool bindToGlobal = true)
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
        windowWidth = width;
        windowHeight = height;
        window = SDL_CreateWindow(title.ptr,
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
            width, height,
            config.flags);
        ctx = GLBackend(window, config.vsync);
        particles = Array!Particle(128);
        const region = Rectangle(0, 0, width, height);
        setTransform(Camera(region, region));

        ubyte[3] white_pixel = [ 255, 255, 255 ];
        white = Texture(white_pixel.ptr, 1, 1, PixelFormat.RGB);
        glViewport(0, 0, width, height);
        aspectRatio = cast(float)width / height;

        srand(cast(uint)time(null));

        if(bindToGlobal)
            globalWindow = &this;

        thread_joinAll();
        Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);
        Mix_AllocateChannels(512);
        connectedGamepads = Array!Gamepad(16);
        recalculateGamepads();
    }

    @nogc nothrow @trusted:

    private void recalculateGamepads()
    {
        foreach(gamepad; connectedGamepads)
            gamepad.destroy();
        connectedGamepads.clear();
        int joystick_length = SDL_NumJoysticks();
        for(int i = 0; i < joystick_length; i++)
            if(SDL_IsGameController(i))
                connectedGamepads.add(Gamepad(SDL_GameControllerOpen(i)));
    }

    ///Stop keeping the window alive
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


    ///Set the camera transform
    void setTransform(in Camera cam)
    {
        ctx.setTransform(cam.opengl);
    }

    /**
    Start a frame
    Params:
    bg = The color to clear with
    */
    void begin(in Color bg)
    {
        const region = Rectangle(0, 0, width, height);
        begin(bg, Camera(region, region));
    }

    /**
    Start a frame
    Params:
    bg = The color to clear with
    cam = the region to draw
    */
    void begin(in Color bg, in Camera cam)
    {
        inUIMode = false;
        ctx.clear(bg);
        previous_ticks = SDL_GetTicks();
        previous_keys = current_keys;
        SDL_Event e;
        while (shouldContinue && SDL_PollEvent(&e))
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
                case SDL_CONTROLLERDEVICEADDED:
                case SDL_CONTROLLERDEVICEREMOVED:
                case SDL_CONTROLLERDEVICEREMAPPED:
                    recalculateGamepads();
                    break;
                default:
                    break;
            }
        }
        int x, y;
        int button_mask = SDL_GetMouseState(&x, &y);
        previousMouse = mousePos;
        mousePos = Vector(x, y);
        mouseLeftPrevious = mouseLeft;
        mouseRightPrevious = mouseRight;
        mouseMiddlePrevious = mouseMiddlePrevious;
        mouseLeft = (button_mask & SDL_BUTTON(SDL_BUTTON_LEFT)) != 0;
        mouseRight = (button_mask & SDL_BUTTON(SDL_BUTTON_RIGHT)) != 0;
        mouseMiddle = (button_mask & SDL_BUTTON(SDL_BUTTON_MIDDLE)) != 0;
        setTransform(cam);
    }

    private void filterParticles(T)(in Tilemap!T map)
    {
        for(size_t i = 0; i < particles.length; i++)
        {
            switch (particles[i].behavior)
            {
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
    }

    ///Update particles and display the drawn objects
    void end()
    {
        for (size_t i = 0; i < particles.length; i++)
        {
            particles[i].update();
            if (particles[i].lifetime <= 0)
            {
                particles.remove(i);
                i--;
            }
            else
                draw(particles[i].region, particles[i].position.x, particles[i].position.y);
        }
        ctx.flip();
        uint time = SDL_GetTicks();
        if (time - previous_ticks < 1000 / fps) {
            SDL_Delay(1000 / fps - (time - previous_ticks)); //account for the time elapsed during the frame
        }
        previous_ticks = time;
    }

    ///Update particles, check particles against the tilemap, and display the drawn objects
    void end(T)(in Tilemap!T map)
    {
        filterParticles(map);
        end();
    }

    ///Draw a polygon with each point following the next in a circle around the edge
    void draw(size_t Len)(in Color color, in Vector[Len] points)
    {
        static immutable Indices = (Len - 2) * 3;
        static assert ( Len >= 3 );
        Vertex[Len] vertices;
        GLuint[Indices] indices;
        for (size_t i = 0; i < Len; i++)
        {
            auto point = points[i];
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


    /**
    Draw a circle with a given color

    The circle is actually draawn as a polygon, with NumPoints points. Increase or decrease it to increase or decrease the points on the circle
    */
    void draw(size_t NumPoints = 32)(in Color color, in Circle circle)
    {
        Vector[NumPoints] points; //A large array of points to simulate a circle
        auto rotation = Transform.rotate(360 / NumPoints);
        auto pointer = Vector(0, -circle.radius);
        for (size_t i = 0; i < NumPoints; i++)
        {
            points[i] = circle.center + pointer;
            pointer = rotation * pointer;
        }
        draw(color, points);
    }

    ///Draw a rectangle with a color
    void draw(in Color color, in Rectangle rect)
    {
        Vector[4] points = [ rect.topLeft, Vector(rect.x + rect.width, rect.y),
            rect.topLeft + rect.size, Vector(rect.x, rect.y + rect.height)];
        draw(color, points);
    }

    ///Draw a texture at the given units
    void draw(in Texture tex, in float x, in float y, in Color col = Color.white)
    {
        draw(tex, x, y, tex.size.width, tex.size.height, 0, 0, 0, 1, 1, false, false, col);
    }

    /**
    Draw a transformed texture 

    Params:
    tex = the texture
    x = the x in units
    y = the y in units
    w = the width in units
    h = the height in units
    rot = the rotation angle from 0 to 360
    scale_x = the x scale of the draw
    scale_y = the y scale of the draw
    flip_x = if the texture should be flipped horizontally
    flip_y = if the texture should be flipped vertically
    color = the color to blend with
    */
    void draw(in Texture tex, in float x, in float y, in float w, in float h,
                        in float rot = 0, in float or_x = 0, in float or_y = 0,
                        in float scale_x = 1, in float scale_y = 1,
                        in bool flip_x = false, in bool flip_y = false,
                        in Color color = Color.white)
    {
        auto trans = Transform.identity() 
            * Transform.translate(Vector(-or_x, -or_y))
            * Transform.rotate(rot)
            * Transform.translate(Vector(or_x, or_y))
            * Transform.scale(Vector(scale_x, scale_y));
        draw(tex, trans, x + or_x, y + or_y, w, h, flip_x, flip_y, color);
    }


    /**
    Draw a texture with a precalculated transform

    Params:
    tex = the texture
    x = the x in units
    y = the y in units
    w = the width in units
    h = the height in units
    flip_x = if the texture should be flipped horizontally
    flip_y = if the texture should be flipped vertically
    color = the color to blend with
    */
    void draw(in Texture tex, in Transform trans, in float x, in float y,
                       in float w, in float h, in bool flip_x = false, in bool flip_y = false,
                       in Color color = Color.white)
    {
        //Calculate the destination points with the transformation
        auto tl = trans * Vector(0, 0);
        auto tr = trans * Vector(w, 0);
        auto bl = trans * Vector(0, h);
        auto br = trans * Vector(w, h);

        //Calculate the source points normalized to [0, 1]
        //The conversion factor for normalizing vectors
        float conv_factor_x = 1.0f / tex.sourceWidth;
        float conv_factor_y = 1.0f / tex.sourceHeight;
        float norm_x = tex.size.x * conv_factor_x;
        float norm_y = tex.size.y * conv_factor_y;
        float norm_w = tex.size.width * conv_factor_x;
        float norm_h = tex.size.height * conv_factor_y;
        auto src_tl = Vector(norm_x, norm_y);
        auto src_tr = Vector(norm_x + norm_w, norm_y);
        auto src_br = Vector(norm_x + norm_w, norm_y + norm_h);
        auto src_bl = Vector(norm_x, norm_y + norm_h);
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
        auto translate = Vector(x, y);
        Vertex[4] vertices = [ Vertex(tl + translate, src_tl, color),
            Vertex(tr + translate, src_tr, color),
            Vertex(br + translate, src_br, color),
            Vertex(bl + translate, src_bl, color)];
        GLuint[6] indices = [0, 1, 2, 2, 3, 0];
        ctx.add(tex.id, vertices, indices);
    }

    ///Draw a sprite to the screen
    void draw(ref scope Sprite sprite)
    {
        sprite.update();
        draw(sprite.texture, sprite.x, sprite.y, sprite.width, sprite.height,
                sprite.rotation, sprite.originX, sprite.originY,
                sprite.scaleX, sprite.scaleY, sprite.flipX, sprite.flipY, sprite.color);
    }

    ///Draw a character using a font and find the width it took
    float draw(ref in Font font, in char c, in float x, in float y, in Color col = Color.white)
    {
        Texture renderChar = font.render(c);
        draw(renderChar, x, y, col);
        return renderChar.size.width;
    }

    ///Draw a string using a font
    void draw(ref in Font font, in string str, in float x, in float y, in float lineHeight = 1, in Color col = Color.white)
    {
        float position = 0;
        float cursor = y;
        //Loop from the beginning to end of the string
        for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
            if (c == '\t')
                for (int j = 0; j < 4; j++)
                    position += draw(font, ' ', position + x, cursor, col);
            else if (c == '\n')
            {
                position = 0;
                cursor += font.characterHeight * lineHeight;
            }
            else if (c != '\r')
                position += draw(font, c, position + x, cursor, col);
        }
    }

    ///Draw a wrapped string that can wrap on word or by character
    void draw(ref in Font font, in string str, in float x, in float y,
        in float maxWidth, in Color col = Color.white, in bool wrapOnWord = true, float lineHeight = 1)
    {
        size_t left = 0;
        float cursor = y;
        while(left < str.length)
        {
            size_t right = str.length;
            while(right > left && font.getSizeOfString(str[left..right]).width > maxWidth)
            {
                do
                {
                    right--;
                } while(wrapOnWord && right > left && str[right - 1].isAlphaNum);
            }
            if(right == left)
                right = str.length;
            draw(font, str[left..right], x, cursor, lineHeight, col);
            cursor += font.getSizeOfString(str[left..right], lineHeight).height;
            left = right;
        }
    }

    ///Create a burst of particles using the emitter
    void addParticleBurst(in ParticleEmitter emitter)
    {
        int parts = randomRange(emitter.particle_min, emitter.particle_max);
        for (int i = 0; i < parts; i++)
            particles.add(emitter.emit());
    }
    
    ///Sets the GLSL shader, see the GL backend docs
    void setShader(in string vertexShader, 
		in string fragmentShader,
		in string transformAttributeName = "transform",
		in string positionAttributeName = "position",
		in string texPositionAttributeName = "tex_coord",
		in string colorAttributeName = "color",
		in string textureAttributeName = "tex",
		in string colorOutputName = "outColor")
    {
        ctx.setShader(vertexShader, fragmentShader, 
            transformAttributeName, positionAttributeName,
            texPositionAttributeName, colorAttributeName,
            textureAttributeName, colorOutputName);
    }

    ///Checks if a key is being held down by a key name
    bool isKeyDown(in string name) const
    {
        return current_keys[SDL_GetScancodeFromName(name.ptr)];
    }

    ///Checks if key was down previously by a key name
    bool wasKeyDown(in string name) const
    {
        return previous_keys[SDL_GetScancodeFromName(name.ptr)];
    }

    private static Window* globalWindow;
    ///Get a global instance of the window
    public static @nogc Window* getInstance()
    {
        return globalWindow;
    }

    pure:
    ///Get the position of the mouse
    @property Vector mouse() const
    {
        return camera.unproject * mousePos;
    }
    @property bool mouseLeftPressed() const { return mouseLeft; }
    @property bool mouseRightPressed() const { return mouseRight; }
    @property bool mouseMiddlePressed() const { return mouseMiddle; }
    @property bool mouseLeftReleased() const { return !mouseLeft && mouseLeftPrevious; }
    @property bool mouseRightReleased() const { return !mouseRight && mouseRightPrevious; }
    @property bool mouseMiddleReleased() const { return !mouseMiddle && mouseMiddlePrevious; }
    @property bool isOpen() const { return shouldContinue; }
    @property Gamepad[] gamepads() { return connectedGamepads.array; }
    @property int width() const { return windowWidth; }
    @property int height() const { return windowHeight; }

}
