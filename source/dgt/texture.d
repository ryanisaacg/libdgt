module dgt.texture;
import derelict.sdl2.sdl, derelict.sdl2.image;
import derelict.opengl;
import dgt.array : Array;
import dgt.io;
import dgt.geom : Rectangle;
import dgt.util : nullTerminate;

import core.stdc.string;

///The format of each pixel in byte order
enum PixelFormat : GLenum
{
    RGB = GL_RGB,
    RGBA = GL_RGBA,
    BGR = GL_BGR,
    BGRA = GL_BGRA
}

/**
A drawable texture which can also be a region of a larger texture
*/
struct Texture
{
    package uint id;
    private:
    int width, height;
    Rectangle region;

    @disable this();

    @nogc nothrow public:
    ///Create a Texture from data in memory
    this(ubyte* data, int w, int h, PixelFormat format)
    {
        GLuint texture;
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, format, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
        id = texture;
        width = w;
        height = h;
        region = Rectangle(0, 0, w, h);
    }

    ///Load a texture from a file with a given path
    this(string name)
    {
        auto nameNullTerminated = nullTerminate(name);
        SDL_Surface* surface = IMG_Load(nameNullTerminated.ptr);
        nameNullTerminated.destroy();
        if (surface == null)
        {
            auto buffer = IMG_GetError();
            println("Image loading error: ", buffer[0..strlen(buffer)]);
            this(null, 0, 0, PixelFormat.RGB);
        }
        else
        {
            this(surface);
            SDL_FreeSurface(surface);
        }
    }

    ///Load a texture from an SDL_Surface in memory
    this(SDL_Surface* sur)
    {
        PixelFormat format;
        if(sur.format.BytesPerPixel == 4)
            if(sur.format.Rmask == 0x000000ff)
                format = PixelFormat.RGBA;
            else
                format = PixelFormat.BGRA;
        else
            if(sur.format.Rmask == 0x000000ff)
                format = PixelFormat.RGB;
            else
                format = PixelFormat.BGR;
        this(cast(ubyte*)sur.pixels, sur.w, sur.h, format);
    }

    ///Remove the texture from GPU memory
    void destroy()
    {
        glDeleteTextures(1, &id);
    }

    pure:
    ///Get a texture that represents a region of a larger texture
    Texture getSlice(Rectangle region)
    {
        Texture tex = this;
        tex.region = Rectangle(this.region.x + region.x,
                this.region.y + region.y, region.width, region.height);
        return tex;
    }
    ///Get the width of the source image
    @property int sourceWidth() const { return width; }
    ///Get the height of the source image
    @property int sourceHeight() const { return height; }
    ///Get the size of the texture's region
    @property Rectangle size() const { return region; }
}
