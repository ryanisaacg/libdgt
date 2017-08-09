import geom : Rectangle;

struct Texture
{
    uint id;
    int width, height;
    Rectangle!int region;

    @nogc nothrow pure:
    Texture getSlice(Rectangle!int region)
    {
        Texture tex = this;
        tex.region = region;
        return tex;
    }
}
