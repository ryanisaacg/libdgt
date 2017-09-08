///Adds integration with the Tiled map editor
module dgt.level;

import std.file : readText;
import std.json;
import std.path : dirName;

import dgt.array, dgt.color, dgt.geom, dgt.texture, dgt.tilemap;

import dgt.io;

///A layer of tiles represented by integer constants
struct TileLayer
{
    string name;
    Array!int tiles;
    int offsetX, offsetY, widthInTiles, heightInTiles;
    float opacity;
    bool visible;

    @nogc nothrow:
    pure int opIndex(in int x, in int y) const
    {
        return tiles[x + y * widthInTiles];
    }

    void destroy()
    {
        tiles.destroy();
    }
}

///A layer of free-floating objects
struct EntityLayer
{
    string name;
    Array!Entity entities;
    int offsetX, offsetY;
    float opacity;
    bool visible;

    @nogc nothrow void destroy()
    {
        entities.destroy();
    }
}

////A free-floating entity 
struct Entity
{
    string name, type;
    int x, y, width, height, rotation;
    bool flipX, flipY;
    Texture tex;
    bool visible;
}

///A structure to load the Tiled map into
struct Level
{
    static immutable FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
    static immutable FLIPPED_VERTICALLY_FLAG = 0x40000000;
    static immutable FLIPPED_DIAGONALLY_FLAG = 0x20000000;


    Array!Texture sourceImages;
    Array!Texture tileImages;
    Array!TileLayer tileLayers;
    Array!EntityLayer entityLayers;

    int tileWidth, tileHeight, widthInTiles, heightInTiles;

    private uint stripGID(uint gid, ref bool outFlipX, ref bool outFlipY) const
    {
        outFlipX = outFlipY = (gid & FLIPPED_DIAGONALLY_FLAG) != 0;
        outFlipX = outFlipX != ((gid & FLIPPED_HORIZONTALLY_FLAG) != 0);
        outFlipY = outFlipY != ((gid & FLIPPED_VERTICALLY_FLAG) != 0);
        return gid & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG);
    }

    ///Load a Tiled map from a path in the filesystem
    this(in string path, in int scale = 1)
    {
        sourceImages = Array!Texture(4);
        tileImages = Array!Texture(16);
        tileLayers = Array!TileLayer(4);
        entityLayers = Array!EntityLayer(4);

        auto pathToMap = dirName(path);

        auto contents = parseJSON(readText(path));
        widthInTiles = cast(int)contents["width"].integer;
        heightInTiles = cast(int)contents["height"].integer;
        tileWidth = cast(int)contents["tilewidth"].integer;
        tileHeight = cast(int)contents["tileheight"].integer;
        foreach(tileset; contents["tilesets"].array)
        {
            auto image = Texture(pathToMap ~ "/" ~ tileset["image"].str);
            sourceImages.add(image);
            int margin = cast(int)tileset["margin"].integer;
            int spacing = cast(int)tileset["spacing"].integer;
            int width = cast(int)tileset["tilewidth"].integer;
            int height = cast(int)tileset["tileheight"].integer;
            for(int y = margin; y < image.sourceHeight - margin; y += height + spacing)
                for(int x = margin; x < image.sourceWidth - margin; x += width + spacing)
                    tileImages.add(image.getSlice(Rectanglei(x, y, width, height)));
        }

        foreach(layer; contents["layers"].array)
        {
            string name = layer["name"].str;
            int offsetX = "offsetx" in layer ? cast(int)layer["offsetx"].integer : 0;
            int offsetY = "offsety" in layer ? cast(int)layer["offsety"].integer : 0;
            float opacity = layer["opacity"].type == JSON_TYPE.FLOAT ? layer["opacity"].floating : layer["opacity"].integer;
            bool visible = layer["visible"].type == JSON_TYPE.TRUE;
            if(layer["type"].str == "tilelayer")
            {
                TileLayer tlayer = TileLayer(name, Array!int(layer["data"].array.length),
                    offsetX, offsetY,
                    cast(int)layer["width"].integer,
                    cast(int)layer["height"].integer,
                    opacity, visible);
                foreach(tile; layer["data"].array)
                    tlayer.tiles.add(cast(int)tile.integer - 1);
                tileLayers.add(tlayer);
            }
            else if(layer["type"].str == "objectgroup")
            {
                EntityLayer elayer = EntityLayer(name, Array!Entity(layer["objects"].array.length),
                    offsetX, offsetY, opacity, visible);
                foreach(object; layer["objects"].array)
                {
                    bool flipX, flipY;
                    uint gid = stripGID(cast(uint)object["gid"].integer, flipX, flipY);
                    elayer.entities.add(Entity(
                        object["name"].str,
                        object["type"].str,
                        scale * cast(int)object["x"].floating,
                        scale * cast(int)object["y"].floating,
                        scale * cast(int)object["width"].integer,
                        scale * cast(int)object["height"].integer,
                        cast(int)object["rotation"].integer,
                        flipX, flipY,
                        tileImages[gid - 1], object["visible"].type == JSON_TYPE.TRUE
                    ));
                }
                entityLayers.add(elayer);
            }
        }
    }

    /**
    Free all of the data in the map

    Also destroys the textures the map loads, so be careful
    */
    @nogc nothrow void destroy()
    {
        foreach(tex; sourceImages)
            tex.destroy();
        foreach(layer; tileLayers)
            layer.destroy();
        foreach(layer; entityLayers)
            layer.destroy();
        sourceImages.destroy();
        tileImages.destroy();
        tileLayers.destroy();
        entityLayers.destroy();
    }
}
