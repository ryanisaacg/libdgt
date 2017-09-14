module dgt.tilemap;
import dgt.array, dgt.geom;
import std.math;

/**
A single tile with an arbitrary value and if the tile is solid or not

A solid tile will indicate its square is not empty
*/
struct Tile(T)
{
	T value;
	bool solid;
}

/**
A fixed-size grid of tiles that can be queried
*/
struct Tilemap(T)
{
	static immutable INVALID_TILE = Tile!T(T(), true);

	private Array!(Tile!T) buffer;
	private int size, _width, _height;

	@nogc nothrow public:
    ///Create a tilemap with a given unit width and height and the units for the size of each tile square
	this(in int mapWidth, in int mapHeight, in int size)
	{
		this._width = mapWidth;
		this._height = mapHeight;
		this.size = size;
        buffer = Array!(Tile!T)((width / size) * (height / size));
		for(size_t i = 0; i < width; i += size)
			for(size_t j = 0; j < height; j += size)
				buffer.add(Tile!T(T(), false));
	}

    ///Free the underlying tilemap memory
	void destroy()
	{
		buffer.destroy();
	}

	pure:
    ///Get a tile from a location
	Tile!T opIndex(in float x, in float y) const
	{
		return valid(x, y) ? buffer[cast(int)((x / size) * height / size + (y / size))] : INVALID_TILE;
	}
    ///Get a tile from a location
    Tile!T opIndex(in Vector vec) const { return this[vec.x, vec.y]; }

    ///Set a tile from a location
	ref Tile!T opIndexAssign(in Tile!T tile, in float x, in float y)
	{
		return buffer[cast(int)((x / size) * height / size + (y / size))] = tile;
	}
    ///Set a tile from a location
    ref Tile!T opIndexAssign(in Tile!T tile, in Vector vec) { return this[vec.x, vec.y] = tile; }

	///Checks if a point falls within a tilemap
    bool valid(in float x, in float y) const
	{
		return x >= 0 && y >= 0 && x < width && y < height;
	}
	///Checks if a point falls within a tilemap
    bool valid(in Vector vec) const { return valid(vec.x, vec.y); }

    ///Checks if a point is both valid and empty
	bool empty(in float x, in float y) const
	{
		return !this[x, y].solid;
	}
    ///Checks if a point is both valid and empty
    bool empty(in Vector vec) const { return empty(vec.x, vec.y); }

    ///Checks if a region is both valid and empty
	bool empty(in float x, in float y, in float width, in float height) const
	{
		for(float i = x; i < x + width; i += size)
			for(float j = y; j < y + height; j += size)
				if(!empty(i, j))
					return false;
		return empty(x + width, y) && empty(x, y + height) && empty(x + width, y + height);
	}
    ///Checks if a region is both valid and empty
    bool empty(in Rectangle rect) const { return empty(rect.x, rect.y, rect.width, rect.height); }

    ///Determine the furthest a region can move without hitting a wall
	Vector slideContact(in float x, in float y, in float width, in float height, in Vector v) const
	{
		//Objects embedded in walls cannot move
		if(!empty(x, y, width, height))
			return Vector(0, 0);
		float tryX = x + v.x;
		float tryY = y + v.y;
		//The object can move unobstructed
		if(empty(tryX, tryY, width, height))
			return v;
		//The left side is embedded in a wall
		if(!empty(tryX, tryY) && !empty(tryX, tryY + height))
			tryX = (cast(int)tryX / size) * size;
		//The right side is embedded in a wall
		if(!empty(tryX + width, tryY) && !empty(tryX + width, tryY + height))
			tryX = (cast(int)(tryX + width) / size) * size - width;
		//The tpp side is embedded in a wall
		if(!empty(tryX, tryY) && !empty(tryX + width, tryY))
			tryY = (cast(int)tryY / size) * size;
		//The bottom side is embedded in a wall
		if(!empty(tryX, tryY + height) && !empty(tryX + width, tryY + height))
			tryY = (cast(int)(tryY + height) / size) * size - height;
		return Vector(tryX - x, tryY - y);
	}
    ///Determine the furthest a region can move without hitting a wall
    Vector slideContact(in Rectangle rect, in Vector vec) const 
	{
		return slideContact(rect.x, rect.y, rect.width, rect.height, vec); 
	}

    ///The width of the map in units
	@property int width() const { return _width; }
    ///The height of the map in units
	@property int height() const { return _height; }
    ///The size of a tile in units (both width and height)
	@property int tileSize() const { return size; }
}

unittest
{
    Tilemap!int map = Tilemap!int(640, 480, 32);
    map[35, 35] = Tile!int(5, true);
    assert(map[-1, 0].solid);
    assert(!map[35, 0].solid);
    assert(map[35, 35].value == 5);
    auto moved = map.slideContact(300, 5, 32, 32, Vector(0, -10));
    assert(moved.x == 0 && moved.y == -5);
    moved = map.slideContact(80, 10, 16, 16, Vector(1, -20));
    assert(moved.x == 1 && moved.y == -10);
    moved = map.slideContact(50, 50, 10, 10, Vector(20, 30));
    assert(moved.x == 20 && moved.y == 30);
    moved = map.slideContact(600, 10, 30, 10, Vector(15, 10));
    assert(moved.x == 10 && moved.y == 10);
	auto movedf = map.slideContact(10.0, 5, 5, 5, Vector(2, 2));
	assert(movedf.x == 2 && movedf.y == 2);
	movedf = map.slideContact(5.0, 5, 10, 10, Vector(-7.2, 0));
	assert(movedf.x == -5 && movedf.y == 0);
	movedf = map.slideContact(600, 0, 25, 10, Vector(20, 0));
	import dgt.io;
	println(movedf);
	assert(movedf.x == 15 && movedf.y == 0);
}
