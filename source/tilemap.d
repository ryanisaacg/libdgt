import array, geom;

struct Tile(T)
{
	T value;
	bool solid;
}

struct Tilemap(T)
{
	private Array!(Tile!T) buffer;
	private int size = 0, width = 0, height = 0;

	@nogc nothrow pure public:
	this(int width, int height, int size)
	{
		this.width = width;
		this.height = height;
		this.size = size;
		buffer.ensureCapacity((width / size) * (height / size));
	}

	ref Tile!T opIndex(int x, int y)
	{
		return buffer[(x / size) * height / size + (y / size)];
	}
	
	ref Tile!T opIndexAssign(Tile!T tile, int x, int y)
	{
		return buffer[(x / size) * height / size + (y / size)] = tile;
	}

	bool empty(int x, int y)
	{
		return !this[x, y].solid;
	}

	bool empty(int x, int y, int width, int height)
	{
		for(int i = x; i < x + width; x += size)
			for(int j = y; j < y + height; y += size)
				if(!empty(x, y))
					return false;
		return empty(x + width, y) && empty(x, y + height) && empty(x + width, y + height);
	}

	Vector!int moveContact(int x, int y, int width, int height, Vector!int speed)
	{
		//TODO: implement this
	}

	Vector!int slideContact(int x, int y, int width, int height, Vector!int speed)
	{
		auto x = moveContact(x, y, width, height, Vector!int(speed.x, 0));
		auto y = moveContact(x, y, width, height, Vector!int(0, speed.y));
		return Vector!int(x.x, y.y);
	}
}
