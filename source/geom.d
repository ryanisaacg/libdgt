import std.math : sqrt, cos, sin, PI;

unittest
{
	import core.stdc.stdio;
    Matrix2i m, n;
    m.setToIdentity();
    n[0, 0] = 5;
    assert((m * n)[0, 0] == 5);
    m[0, 0] = 2;
    assert((m * n)[0, 0] = 10);

    Matrix3f scale;
    scale.setToIdentity();
    scale[0, 0] = 2;
    scale[1, 1] = 2;
    Vector3f vector;
    vector.x = 2;
    vector.y = 5;
    auto scaled = scale * vector;
	printf("%f:%f\n", scaled.x, scaled.y);
    assert(scaled.x == 4 && scaled.y == 10);

    auto trans = translate(3, 4);
    auto vec = Vector2f(1, 1);
    vec = trans * vec;
    assert(vec.x == 4 && vec.y == 5);
}

@nogc nothrow pure:

struct Vector(T, size_t N)
{
    static assert(N > 0);
    private T[N] data;

    @nogc nothrow pure public:
    static if(N == 1)
    {
        this(T a) { data[0] = a; }
    }
    static if(N == 2)
    {
        this(T a, T b) { data[0] = a; data[1] = b; }
    }
    static if(N == 3)
    {
        this(T a, T b, T c) { data[0] = a; data[1] = b; data[2] = c; }
    }

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

    Vector!(T, N + n) expand(size_t n)()
    {
        Vector!(T, N + n) result;
        for(size_t i = 0; i < N; i++)
            result.data[i] = this.data[i];
        return result;
    }

    Vector!(T, N - n) shrink(size_t n)()
    {
        Vector!(T, N - n) result;
        for(size_t i = 0; i < N - n; i++)
            result.data[i] = this.data[i];
        return result;
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
	public Vector!(T, 2) topLeft, size;

	@nogc nothrow pure public:
	this(T x, T y, T width, T height)
	{
		topLeft.set([x, y]);
		size.set([width, height]);
	}

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
	public Vector!(T, 2) center;
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
		static assert ( M == N );
        static assert (op == "*");
        Vector!(T, N) ret;
		for (size_t i = 0; i < N; i++) {
			for (size_t j = 0; j < M; j++) {
				ret.data[i] += this[j, i] * other.data[j];
			}
		}
        return ret;
    }

    public Vector!(T, N - 1) opBinary(string op)(Vector!(T, N - 1) other)
    {
        static assert (N > 1);
        static assert (op == "*");
        Vector!(T, N) ret = other.expand!1;
		for (size_t i = 0; i < N; i++) {
			for (size_t j = 0; j < M; j++) {
				ret.data[i] += this[j, i] * ret.data[j];
			}
		}
        return ret.shrink!1;
    }

    public T opIndex(size_t i, size_t j)
    {
        return data[i * N + j];
    }

    public T opIndexAssign(T val, size_t i, size_t j)
    {
        return data[i * N + j] = val;
    }

    public ref Matrix!(T, M, N) opAssign(T[M * N] array)
    {
        data = array;
        return this;
    }
}

Transform2D identity()
{
    Transform2D transform;
    transform = [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ];
    return transform;
}

Transform2D rotate(float angle)
{
    float c = cos(angle * PI / 180);
	float s = sin(angle * PI / 180);
    Transform2D transform;
    transform = [
        c, -s, 0,
        s, c, 0,
        0, 0, 1
    ];
    return transform;
}

Transform2D translate(float x, float y)
{
    Transform2D transform;
    transform = [
        1, 0, x,
        0, 1, y,
        0, 0, 1
    ];
    return transform;
}

Transform2D scale(float x, float y)
{
    Transform2D transform;
    transform = [
        x, 0, 0,
        0, y, 0,
        0, 0, 1
    ];
    return transform;
}

alias Vector2i = Vector!(int, 2);
alias Vector2f = Vector!(float, 2);
alias Vector3i = Vector!(int, 3);
alias Vector3f = Vector!(float, 3);
alias Rectanglei = Rectangle!int;
alias Rectanglef = Rectangle!float;
alias Circlei = Circle!int;
alias Circlef = Circle!float;
alias Matrix2i = Matrix!(int, 2, 2);
alias Matrix3i = Matrix!(int, 3, 3);
alias Matrix2f = Matrix!(float, 2, 2);
alias Matrix3f = Matrix!(float, 3, 3);
alias Transform2D = Matrix!(float, 3, 3);
alias Trnasform3D = Matrix!(float, 4, 4);

