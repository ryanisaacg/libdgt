module dgt.texture;
import derelict.sdl2.sdl, derelict.sdl2.image;
import derelict.opengl3.gl;
import dgt.io;
import dgt.geom : Rectangle;

struct Texture
{
    package uint id;
    private:
    int width, height;
    Rectangle!int region;

    @disable this();

    @nogc nothrow:
    void loadFrom(SDL_Surface* sur)
    {
        loadFrom(cast(ubyte*)sur.pixels, sur.w, sur.h, sur.format.BytesPerPixel == 4);
    }

    void loadFrom(ubyte* data, int w, int h, bool has_alpha)
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
        id = texture;
        width = w;
        height = h;
        region = Rectangle!int(0, 0, w, h);
    }

    public:
    this(ubyte* data, int w, int h, bool has_alpha)
    {
        loadFrom(data, w, h, has_alpha);
    }

    this(string name)
    {
        SDL_Surface* surface = IMG_Load(name.ptr);
        if (surface == null)
            println("Texture with filename ", name, " not found");
        else
        {
            loadFrom(surface);
            SDL_FreeSurface(surface);
        }
    }

    this(SDL_Surface* sur)
    {
        loadFrom(sur);
    }

    void destroy()
    {
        glDeleteTextures(1, &id);
    }

    pure:
    Texture getSlice(Rectangle!int region)
    {
        Texture tex = this;
        tex.region = region;
        return tex;
    }
    int getSourceWidth() { return width; }
    int getSourceHeight() { return height; }
    Rectangle!int getRegion() { return region; }
}

unittest
{
    import dgt;
    WindowConfig config;
	config.resizable = true;
	Window window = new Window("Test title", 640, 480, config);
    auto texture = Texture("test.png");
    auto region = Rectanglei(2, 2, 16, 16);
    auto slice = texture.getSlice(region);
    assert(slice.getRegion.x == 2 && slice.getRegion.y == 2
        && slice.getRegion.width == 16 && slice.getRegion.height == 16);
}

unittest
{
    import dgt;
    WindowConfig config;
	config.resizable = true;
	Window window = new Window("Test title", 640, 480, config);
    auto invalid = Texture("invalid filename");
}
