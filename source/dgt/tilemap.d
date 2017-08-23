module dgt.tilemap;
import dgt.array, dgt.geom;
import std.math;

struct Tile(T)
{
	T value;
	bool solid;
}

struct Tilemap(T)
{
	static immutable INVALID_TILE = Tile!T(T(), true);

	private Array!(Tile!T) buffer;
	private int size, _width, _height;

	@nogc nothrow public:
	this(int mapWidth, int mapHeight, int size)
	{
		this._width = mapWidth;
		this._height = mapHeight;
		this.size = size;
        buffer = Array!(Tile!T)((width / size) * (height / size));
		for(size_t i = 0; i < width; i++)
			for(size_t j = 0; j < height; j++)
				buffer.add(Tile!T(T(), false));
	}

	pure:
	Tile!T opIndex(int x, int y)
	{
		return valid(x, y) ? buffer[(x / size) * height / size + (y / size)] : INVALID_TILE;
	}

	ref Tile!T opIndexAssign(Tile!T tile, int x, int y)
	{
		return buffer[(x / size) * height / size + (y / size)] = tile;
	}

	bool valid(int x, int y)
	{
		return x >= 0 && y >= 0 && x < width && y < height;
	}

	bool empty(int x, int y)
	{
		return !this[x, y].solid;
	}

	bool empty(int x, int y, int width, int height)
	{
		for(int i = x; i < x + width; i += size)
			for(int j = y; j < y + height; j += size)
				if(!empty(i, j))
					return false;
		return empty(x + width, y) && empty(x, y + height) && empty(x + width, y + height);
	}

    //TODO: Increase resolution of slideContact
	Vector!int slideContact(int x, int y, int width, int height, Vector!int v)
	{
		if (empty(x + v.x, y + v.y, width, height))
			return v;
		else
		{
			while (!empty(x + v.x, y, width, height))
				v.x /= 2;
			while (!empty(x + v.x, y + v.y, width, height))
				v.y /= 2;
			return v;
		}
	}

	@property int width() { return _width; }
	@property int height() { return _height; }
	@property int tileSize() { return size; }
}

unittest
{
    Tilemap!int map = Tilemap!int(640, 480, 32);
    map[35, 35] = Tile!int(5, true);
    assert(map[-1, 0].solid);
    assert(!map[35, 0].solid);
    assert(map[35, 35].value == 5);
    auto moved = map.slideContact(300, 5, 32, 32, Vectori(0, -10));
    assert(moved.x == 0 && moved.y == -5);
    moved = map.slideContact(80, 10, 16, 16, Vectori(1, -20));
    assert(moved.x == 1 && moved.y == -10);
    moved = map.slideContact(50, 50, 10, 10, Vectori(20, 30));
    assert(moved.x == 20 && moved.y == 30);
    moved = map.slideContact(600, 10, 30, 10, Vectori(15, 10));
    assert(moved.x == 7 && moved.y == 10);
}
