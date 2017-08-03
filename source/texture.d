import geom : Rectangle;

struct Texture
{
    uint id;
    int width, height;
    Rectangle!int region;
}
