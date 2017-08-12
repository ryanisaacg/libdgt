module au.texture;

import derelict.opengl3.gl;
import au.geom : Rectangle;

struct Texture
{
    uint id;
    int width, height;
    Rectangle!int region;

    @nogc nothrow:
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
}
