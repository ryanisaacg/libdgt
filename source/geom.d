import std.math : sqrt;

@nogc nothrow pure:

struct Vector(T, size_t N)
{
    static assert(N > 0);
    private T[N] data;

    @nogc nothrow pure public:
    @property T x() { return data[0]; }
    @property T x(T val) { return data[0] = val; }

    static if(N > 1)
    {
        @property T y() { return data[1]; }
        @property T y(T val) { return data[1] = val; }
    }

    static if(N > 2)
    {
        @property T z() { return data[2]; }
        @property T z(T val) { return data[2] = val; }
    }

	Vector!(T, N) opBinary(string op)(Vector!(T, N) other)
	{
		static if (op == "+")
		{
			Vector!(T, N) result;
			for(size_t i = 0; i < N; i++)
				result.data[i] = data[i] + other.data[i];
			return result;
		}
		static if (op == "-")
		{
			Vector!(T, N) result;
			for(size_t i = 0; i < N; i++)
				result.data[i] = data[i] - other.data[i];
			return result;
		}
	}

	float len2()
	{
		T total = 1;
		for(size_t i = 0; i < N; i++)
			total *= data[i];
		return total;
	}

	float len()
	{
		return sqrt(len2());
	}

	void set(size_t N)(T[N] a)
	{
		for(size_t i = 0; i < N; i++)
			data[i] = a[i];
	}
}

unittest
{
	Vector!(int, 2) a, b;
	a.set([5, 10]);
	b.set([1, -2]);
	assert((a + b).x = 6);
	assert((a - b).y = 12);
}

struct Rectangle(T)
{
	private Vector!(T, 2) topLeft, size;
    
	@nogc nothrow pure public:
	@property T x() { return topLeft.x; }
    @property T x(T val) { return topLeft.x = val; }
	@property T y() { return topLeft.y; }
	@property T y(T val) { return topLeft.y = val; }
	@property T width() { return size.x; }
    @property T width(T val) { return size.x = val; }
	@property T height() { return size.y; }
	@property T height(T val) { return size.y = val; }

	bool contains(Vector!(T, 2) v)
	{
		return v.x >= x && v.y >= y && v.x < x + width && v.y < y + height;
	}

	bool overlaps(Rectangle!T b)
	{
		return x < b.x + b.width && x + width > b.x && y < b.y + b.height && y + height > b.y;
	}

	bool overlaps(Circle!T c)
	{
		Vector!(T, 2) closest;
		if (c.x < x) {
			closest.x = x;
		} else if (c.x > x + width) {
			closest.x = x + width;
		} else {
			closest.x = c.x;
		}
		if (c.y < y) {
			closest.y = y;
		} else if (c.y > y + height) {
			closest.y = y + height;
		} else {
			closest.y = c.y;
		}
		closest.x = closest.x - c.x;
		closest.y = closest.y - c.y;
		return (closest.x * closest.x) + (closest.y * closest.y) < c.radius * c.radius;
	}

	void set(T newX, T newY, T newWidth, T newHeight)
	{
		x = newX;
		y = newY;
		width = newWidth;
		height = newHeight;
	}
}

unittest
{
	Rectangle!int a, b, c;
	a.set(0, 0, 32, 32);
	b.set(16, 16, 32, 32);
	c.set(50, 50, 5, 5);
	assert(a.overlaps(b));
	assert(!a.overlaps(c));
}

struct Circle(T)
{
	private Vector!(T, 2) center;
	public T radius;

	@nogc nothrow pure public:
	@property T x() { return center.x; }
    @property T x(T val) { return center.x = val; }
	@property T y() { return center.y; }
	@property T y(T val) { return center.y = val; }

	bool contains(Vector!(T, 2) v)
	{
		Vector!(T, 2) dist = v - center;
		return dist.len2 < radius * radius;
	}

	bool overlaps(Rectangle!T r)
	{
		return r.overlaps(this);
	}

	bool overlaps(Circle!T c)
	{
		float xDiff = x - c.x;
		float yDiff = y - c.y;
		float rad = radius + c.radius;
		return xDiff * xDiff + yDiff * yDiff < rad * rad;
	}

	void set(T newX, T newY, T newRadius)
	{
		x = newX;
		y = newY;
		radius = newRadius;
	}
}

unittest
{
	Circle!int a, b, c;
	Rectangle!int d;
	a.set(0, 0, 16);
	b.set(5, 5, 4);
	c.set(50, 50, 5);
	d.set(10, 10, 10, 10);
	assert(a.overlaps(b));
	assert(!a.overlaps(c));
	assert(a.overlaps(d));
	assert(!c.overlaps(d));
}

struct Matrix(T, size_t M, size_t N)
{
    static assert(M > 0 && N > 0);
    private T[M * N] data;

    @nogc nothrow pure:

	public T* dataPointer() 
	{
		return data.ptr;
	}

    public void setToIdentity() 
	{
        static assert(M == N);
        for(size_t i = 0; i < M; i++)
            for(size_t j = 0; j < N; j++)
                this[i, j] = 0;
        for(size_t i = 0; i < M; i++)
            this[i, i] = 1;
    }

    public Matrix!(T, m, N) opBinary(string op, size_t m)(Matrix!(T, m, N) other)
    {
        static assert(op == "*");
        Matrix!(T, m, N) ret;
        for (size_t i = 0; i < m; i++) {
    		for (size_t j = 0; j < N; j++) {
    			for (size_t k = 0; k < M; k++) {
    				ret[i, j] = ret[i, j] + this[k, j] * other[i, k];
    			}
    		}
    	}
        return ret;
    }

    public Vector!(T, N) opBinary(string op)(Vector!(T, N) other)
    {
        static assert(op == "*");
        Vector!(T, N) ret;
		for (size_t i = 0; i < N; i++) {
			for (size_t j = 0; j < M; j++) {
				ret.data[i] += this[j, i] * other.data[j];
			}
		}
        return ret;
    }

    public T opIndex(size_t i, size_t j)
    {
        return data[i * N + j];
    }

    public T opIndexAssign(T val, size_t i, size_t j)
    {
        return data[i * N + j] = val;
    }
}

unittest
{
    Matrix!(int, 2, 2) m, n;
    m.setToIdentity();
    n[0, 0] = 5;
    assert((m * n)[0, 0] == 5);
    m[0, 0] = 2;
    assert((m * n)[0, 0] = 10);

    Matrix!(int, 3, 3) scale;
    scale.setToIdentity();
    scale[0, 0] = 2;
    scale[1, 1] = 2;
    Vector!(int, 3) vector;
    vector.x = 2;
    vector.y = 5;
    auto scaled = scale * vector;
    assert(scaled.x == 4 && scaled.y == 10);
}
