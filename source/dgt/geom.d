module dgt.geom;
import std.math : sqrt, cos, sin, PI;
import dgt.io;


struct Vector(T)
{
    T x = 0, y = 0;

    @nogc nothrow void print() const
    {
        dgt.io.print("Vector(", x, ", ", y, ")");
    }

    @nogc nothrow pure:
    this(T x, T y)
    {
        this.x = x;
        this.y = y;
    }

    this(U)(Vector!U vec)
    {
        this.x = cast(T)vec.x;
        this.y = cast(T)vec.y;
    }

    Vector!T opUnary(string op)()
    {
        static if (op == "-")
        {
            return Vector!T(-x, -y);
        }
    }

    Vector!T opBinary(string op)(T scalar)
    {
        static if (op == "*")
        {
            return Vector!T(x * scalar, y * scalar);
        }
        static if (op == "/")
        {
            return Vector!T(x / scalar, y / scalar);
        }
    }

    Vector!T opBinary(string op)(Vector!T other)
    {
        static if (op == "+")
        {
            return Vector!T(x + other.x, y + other.y);
        }
        static if (op == "-")
        {
            return Vector!T(x - other.x, y - other.y);
        }
    }

    float len2()
    {
        return x * x + y * y;
    }

    float len()
    {
        return sqrt(len2());
    }
}

unittest
{
    Vector!int a, b;
    a = Vector!int(5, 10);
    b = Vector!int(1, -2);
    assert((a + b).x == 6);
    assert((a - b).y == 12);
}

struct Rectangle(T)
{
    public Vector!T topLeft = Vector!T(0, 0), size = Vector!T(0, 0);

    @nogc nothrow void print() const
    {
        dgt.io.print("Rectangle(", x, ", ", y, ", ", width, ", ", height, ")");
    }

    @nogc nothrow pure public:
    this(T x, T y, T width, T height)
    {
        topLeft = Vector!T(x, y);
        size = Vector!T(width, height);
    }

    @property T x() const { return topLeft.x; }
    @property T x(T val) { return topLeft.x = val; }
    @property T y() const { return topLeft.y; }
    @property T y(T val) { return topLeft.y = val; }
    @property T width() const { return size.x; }
    @property T width(T val) { return size.x = val; }
    @property T height() const { return size.y; }
    @property T height(T val) { return size.y = val; }

    bool contains(Vector!T v)
    {
        return v.x >= x && v.y >= y && v.x < x + width && v.y < y + height;
    }

    bool overlaps(Rectangle!T b)
    {
        return x < b.x + b.width && x + width > b.x && y < b.y + b.height && y + height > b.y;
    }

    bool overlaps(Circle!T c)
    {
        Vector!T closest;
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
    a = Rectangle!int(0, 0, 32, 32);
    b = Rectangle!int(16, 16, 32, 32);
    c = Rectangle!int(50, 50, 5, 5);
    assert(a.overlaps(b));
    assert(!a.overlaps(c));
}

struct Circle(T)
{
    public Vector!T center = Vector!T(0, 0);
    public T radius = 0;

    @nogc nothrow void print() const
    {
        dgt.io.print("Circle(", x, ", ", y, ", ", radius, ")");
    }

    @nogc nothrow pure public:
    this(T x, T y, T radius)
    {
        center = Vector!T(x, y);
        this.radius = radius;
    }
    @property T x() const { return center.x; }
    @property T x(T val) { return center.x = val; }
    @property T y() const { return center.y; }
    @property T y(T val) { return center.y = val; }

    bool contains(Vector!T v)
    {
        Vector!T dist = v - center;
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

struct Transform(T)
{
    private T[9] data = [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ];

    @nogc nothrow void print() const
    {
        dgt.io.print("Transform[");
        for(size_t x = 0; x < 3; x++)
        {
            dgt.io.print("[");
            for(size_t y = 0; y < 3; y++)
            {
                dgt.io.print(this[x, y]);
                if(y != 2) dgt.io.print(", ");
            }
            dgt.io.print("]");
            if(x != 2) dgt.io.print(", ");
        }
        dgt.io.print("]");
    }

    @nogc nothrow pure:

    public T* ptr()
    {
        return data.ptr;
    }

    public Transform!T opBinary(string op)(Transform!T other)
    if (op == "*")
    {
        Transform!T ret;
        for (size_t i = 0; i < 3; i++) {
            for (size_t j = 0; j < 3; j++) {
                ret[i, j] = 0;
                for (size_t k = 0; k < 3; k++) {
                    ret[i, j] = ret[i, j] + this[k, j] * other[i, k];
                }
            }
        }
        return ret;
    }

    public Vector!T opBinary(string op)(Vector!T other)
    if (op == "*")
    {
        return Vector!T(other.x * this[0, 0] + other.y * this[0, 1] + this[0, 2],
            other.x * this[1, 0] + other.y * this[1, 1] + this[1, 2]);
    }

    public Vector!U opBinary(string op, U)(Vector!U other)
    if (op == "*")
    {
        auto converted = Vector!T(cast(T)other.x, cast(T)other.y);
        auto transformed = this * converted;
        return Vector!U(cast(U)transformed.x, cast(U)transformed.y);
    }

    public T opIndex(size_t i, size_t j) const
    {
        return data[i * 3 + j];
    }

    public T opIndexAssign(T val, size_t i, size_t j)
    {
        return data[i * 3 + j] = val;
    }

    public ref Transform!T opAssign(T[9] array)
    {
        data = array;
        return this;
    }
}


@nogc nothrow:

pure Transformf identity()
{
    return Transform!float();
}

pure Transformf rotate(float angle)
{
    float c = cos(angle * PI / 180);
    float s = sin(angle * PI / 180);
    Transform!float transform;
    transform = [
        c, -s, 0,
        s, c, 0,
        0, 0, 1
    ];
    return transform;
}

pure Transformf translate(float x, float y)
{
    Transform!float transform;
    transform = [
        1, 0, x,
        0, 1, y,
        0, 0, 1
    ];
    return transform;
}

pure Transformf scale(float x, float y)
{
    Transform!float transform;
    transform = [
        x, 0, 0,
        0, y, 0,
        0, 0, 1
    ];
    return transform;
}

alias Vectori = Vector!int;
alias Vectorf = Vector!float;
alias Rectanglei = Rectangle!int;
alias Rectanglef = Rectangle!float;
alias Circlei = Circle!int;
alias Circlef = Circle!float;
alias Transformf = Transform!float;

unittest
{
    Transform!int m, n;
    n[0, 0] = 5;
    assert(n.ptr[0] == 5);
    auto result = m * n;
    assert(result[0, 0] == 5);
    m[0, 0] = 2;
    result = m * n;
    assert(result[0, 0] = 10);
}
unittest
{
    auto trans = scale(2, 2);
    auto vec = Vectorf(2, 5);
    auto scaled = trans * vec;
    assert(scaled.x == 4 && scaled.y == 10);
}
unittest
{
    auto trans = translate(3, 4);
    auto vec = Vectorf(1, 1);
    vec = trans * vec;
    assert(vec.x == 4 && vec.y == 5);
}
unittest
{
    auto trans = identity() * translate(-0, -0) * rotate(0) * scale(1, 1);
    auto vec = trans * Vectorf(15, 12);
    assert(vec.x == 15);
}
unittest
{
    auto vec = Vectorf(1.5, 2.5);
    auto ivec = Vectori(vec);
    assert(ivec.x == 1 && ivec.y == 2);
}
unittest
{
    auto vec = Vectori(5, 0);
    assert(vec.len2 == 25);
    assert(vec.len == 5);
}
unittest
{
    auto vec = Vectorf(10, 10);
    vec = vec / 2;
    assert(vec.x == 5 && vec.y == 5);
}
unittest
{
    auto circ = Circlef(0, 0, 10);
    auto vec1 = Vectorf(0, 0);
    auto vec2 = Vectorf(11, 11);
    assert(circ.contains(vec1));
    assert(!circ.contains(vec2));
}
unittest
{
    auto rect = Rectanglei(0, 0, 32, 32);
    auto vec1 = Vectori(5, 5);
    auto vec2 = Vectori(33, 1);
    assert(rect.contains(vec1));
    assert(!rect.contains(vec2));
}
unittest
{
    auto circ = Circlei(0, 0, 5);
    auto rec1 = Rectanglei(0, 0, 2, 2);
    auto rec2 = Rectanglei(5, 5, 4, 4);
    assert(circ.overlaps(rec1) && rec1.overlaps(circ));
    assert(!circ.overlaps(rec2) && !rec2.overlaps(circ));
}
unittest
{
    println("Should print a vector at 0, 0: ", Vectori(0, 0));
    println("Should print a circle at 0, 0 with a radius of 10: ", Circlei(0, 0, 10));
    println("Should print a rectangle at 0, 0, with a side of 5", Rectanglei(0, 0, 5, 5));
    println("Should print an identity matrix: ", identity());
}
