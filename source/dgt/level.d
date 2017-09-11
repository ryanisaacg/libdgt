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

private int number(in JSONValue json)
{
    if(json.type == JSON_TYPE.INTEGER)
        return cast(int)json.integer;
    else
        return cast(int)json.floating;
}

///A structure to load the Tiled map into
struct Level
{
    static immutable FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
    static immutable FLIPPED_VERTICALLY_FLAG = 0x40000000;
    static immutable FLIPPED_DIAGONALLY_FLAG = 0x20000000;


    private
    {
        Array!Texture sourceImages;
        Array!Texture tileImages;
        Array!TileLayer tileLayers;
        Array!EntityLayer entityLayers;
    }

    ///Get the images used by the tiles and entities
    @property const(Texture[]) images() const { return tileImages.array; }
    ///Get the layers with tiles fixed to the grid
    @property const(TileLayer[]) fixedTileLayers() const { return tileLayers.array; }
    ///Get the layers with entities that can be freely moved
    @property const(EntityLayer[]) freeEntityLayers() const { return entityLayers.array; }

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
        widthInTiles = contents["width"].number;
        heightInTiles = contents["height"].number;
        tileWidth = contents["tilewidth"].number;
        tileHeight = contents["tileheight"].number;
        foreach(tileset; contents["tilesets"].array)
        {
            auto image = Texture(pathToMap ~ "/" ~ tileset["image"].str);
            sourceImages.add(image);
            int margin = tileset["margin"].number;
            int spacing = tileset["spacing"].number;
            int width = tileset["tilewidth"].number;
            int height = tileset["tileheight"].number;
            for(int y = margin; y < image.sourceHeight - margin; y += height + spacing)
                for(int x = margin; x < image.sourceWidth - margin; x += width + spacing)
                    tileImages.add(image.getSlice(Rectanglei(x, y, width, height)));
        }

        foreach(layer; contents["layers"].array)
        {
            string name = layer["name"].str;
            int offsetX = "offsetx" in layer ? layer["offsetx"].number : 0;
            int offsetY = "offsety" in layer ? layer["offsety"].number : 0;
            float opacity = layer["opacity"].type == JSON_TYPE.FLOAT ? layer["opacity"].floating : layer["opacity"].number;
            bool visible = layer["visible"].type == JSON_TYPE.TRUE;
            if(layer["type"].str == "tilelayer")
            {
                TileLayer tlayer = TileLayer(name, Array!int(layer["data"].array.length),
                    offsetX, offsetY,
                    layer["width"].number,
                    layer["height"].number,
                    opacity, visible);
                foreach(tile; layer["data"].array)
                    tlayer.tiles.add(tile.number - 1);
                tileLayers.add(tlayer);
            }
            else if(layer["type"].str == "objectgroup")
            {
                EntityLayer elayer = EntityLayer(name, Array!Entity(layer["objects"].array.length),
                    offsetX, offsetY, opacity, visible);
                foreach(object; layer["objects"].array)
                {
                    bool flipX, flipY;
                    uint gid = stripGID(cast(uint)object["gid"].number, flipX, flipY);
                    elayer.entities.add(Entity(
                        object["name"].str,
                        object["type"].str,
                        scale * object["x"].number,
                        scale * object["y"].number,
                        scale * object["width"].number,
                        scale * object["height"].number,
                        object["rotation"].number,
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
