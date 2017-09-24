module dgt.texture;

import derelict.sdl2.sdl, derelict.sdl2.image;
import derelict.opengl;
import dgt.array : Array;
import dgt.io : println;
import dgt.geom : Vector, Rectangle;
import dgt.util;

import std.path : dirName;
import std.string : indexOf;

import core.stdc.string : strlen;

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
    public uint id;
    public:
    int width, height;
    Rectangle region;
    package bool rotated = false;

    @disable this();


    @nogc nothrow public:
    ///Create a Texture from data in memory
    this(ubyte* data, int w, int h, PixelFormat format)
    {
        println("Size: ", w, ":", h);
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
    
    //Mock or don't mock the constructor
    version(unittest)
    {
        this(string name)
        {
        }
    }
    else
    {
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

    pure:
    ///Get a texture that represents a region of a larger texture
    Texture getSlice(Rectangle region, bool rotated = false) const
    {
        Texture tex = this;
        tex.region = Rectangle(this.region.x + region.x,
                this.region.y + region.y, region.width, region.height);
        tex.rotated = rotated;
        return tex;
    }
    ///Get the width of the source image
    @property int sourceWidth() const { return width; }
    ///Get the height of the source image
    @property int sourceHeight() const { return height; }
    ///Get the size of the texture's region
    @property Rectangle size() const { return region; }
}

/**
A structure that loads and stores texture atlases

The loader assumes the input file is in the Spine format: http://esotericsoftware.com/spine-atlas-format
*/
struct Atlas
{
    private:
    Array!Texture pages, regions;
    Array!string regionNames;
    Array!char contents;

    @disable this();

    nothrow @nogc:
    ///Load the atlas and the textures from the given path
    this(in string atlasPath)
    {
        pages = Array!Texture(2);
        regions = Array!Texture(32);
        regionNames = Array!string(32);
        contents = readFileToBuffer(atlasPath);
        string text = contents.array;
        auto texturePath = Array!char(atlasPath.length * 2);
        scope(exit) texturePath.destroy();
        while(text.length > 0)
        {
            texturePath.clear();
            string relativeTexturePath = text.nextline(text);
            const atlasPathDir = dirName(atlasPath);
            foreach(character; atlasPathDir) texturePath.add(character);
            texturePath.add('/');
            foreach(character; relativeTexturePath) texturePath.add(character);
            const page = Texture(texturePath.array);
            pages.add(page);
            //ignore the size, format, filter, and repeat lines of the format
            for(int i = 0; i < 4; i++)
                text.nextline(text);
            auto regionName = text.nextline(text);
            while(regionName.length > 0)
            {
                auto propertyLine = text.nextline(text);
                bool rotate;
                Vector position, size;
                while(propertyLine.length > 0 && propertyLine[0] == ' ')
                {
                    propertyLine = propertyLine.trimLeft;
                    const colonIndex = propertyLine.indexOf(':');
                    const property = propertyLine[0..colonIndex];
                    const value = propertyLine[colonIndex + 1..propertyLine.length].trimLeft;
                    if(property == "rotate")
                    {
                        rotate = (value == "true");
                    } else if(property == "xy")
                    {
                        const x = parsePositiveInt(value[0..value.indexOf(',')]);
                        const y = parsePositiveInt(value[value.indexOf(',') + 1..value.length].trimLeft);
                        position = Vector(x, y);
                    } else if(property == "size")
                    {
                        const x = parsePositiveInt(value[0..value.indexOf(',')]);
                        const y = parsePositiveInt(value[value.indexOf(',') + 1..value.length].trimLeft);
                        size = Vector(x, y);
                    }
                    propertyLine = text.nextline(text);
                }
                regions.add(page.getSlice(Rectangle(position, size), rotate));
                regionNames.add(regionName);
                regionName = propertyLine;
            }
        }
    }

    @nogc:
    ///Get the texture by the name it has in the atlas
    pure Texture opIndex(in string regionName, 
            in Texture notFound = Texture(null, 0, 0, PixelFormat.RGB)) const
    {
        for(uint i = 0; i < regionNames.length; i++)
            if(regionNames[i] == regionName)
                return regions[i];
        return notFound;
    }

    ///Free the memory and textures associated with the atlas
    void destroy()
    {
        pages.destroy();
        regions.destroy();
        contents.destroy();
    }
}

unittest
{
    auto atlas = Atlas("test.atlas");
    scope(exit) atlas.destroy();
    assert(atlas.regionNames[0] == "bg-dialog");
    assert(atlas.regionNames[1] == "bg-dialog2");
    assert(atlas.regions[0].size.topLeft == Vector(519, 223));
    assert(atlas.regions[0].size.size == Vector(21, 42));
    assert(atlas.regions[1].rotated);
}
