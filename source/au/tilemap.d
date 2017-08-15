module au.tilemap;
import au.array, au.geom;
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
	private int size = 0, width = 0, height = 0;

	@nogc nothrow public:
	this(int width, int height, int size)
	{
		this.width = width;
		this.height = height;
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

	Vector!int slideContact(int x, int y, int width, int height, Vector!int v) {
		if (empty(x + v.x, y + v.y, width, height)) {
			return v;
		} else {
			while (!empty(x + v.x, y, width, height)) {
				v.x /= 2;
			}
			while (!empty(x + v.x, y + v.y, width, height)) {
				v.y /= 2;
			}
			return v;
		}
	}
}
