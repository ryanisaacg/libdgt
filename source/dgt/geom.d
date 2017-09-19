/**
Contains various generic geometry containers

floathe entire module is designed for 2D, because libdgt is for 2D development
*/
module dgt.geom;

import std.algorithm.comparison;
import std.math : approxEqual, sqrt, cos, sin, sgn, PI;
import dgt.io;

@safe:

//The famous fast inverse square root
@trusted pure nothrow @nogc private float Q_rsqrt(float number)
{
	long i;
	float x2, y;
	const float threehalfs = 1.5;
	x2 = number * 0.5;
	y  = number;
	i  = *cast(long*) &y;
	i  = 0x5f3759df - ( i >> 1 );
    y  = * cast(float*) &i;
	y  = y * ( threehalfs - ( x2 * y * y ) );
    return y;
}

/**
A 2D vector with an arbitrary numeric type
*/
struct Vector
{
    float x = 0, y = 0;

    @nogc nothrow void print() const
    {
        dgt.io.print("Vector(", x, ", ", y, ")");
    }

    @nogc nothrow pure:
    ///Create a vector with an x and a y
    this(float x, float y)
    {
        this.x = x;
        this.y = y;
    }

    Vector opUnary(string op)() const
    {
        static if (op == "-")
        {
            return Vector(-x, -y);
        }
    }

    Vector opBinary(string op)(in float scalar) const
    {
        static if (op == "*")
        {
            return Vector(x * scalar, y * scalar);
        }
        static if (op == "/")
        {
            return Vector(x / scalar, y / scalar);
        }
    }

    Vector opBinary(string op)(in Vector other) const
    {
        static if (op == "+")
        {
            return Vector(x + other.x, y + other.y);
        }
        static if (op == "-")
        {
            return Vector(x - other.x, y - other.y);
        }
    }

    bool opEquals(Vector other) const
    {
        return approxEqual(x, other.x, 0.000001) && approxEqual(y, other.y, 0.000001);
    }

    ///Get the squared length of the vector (faster than getting the length)
    @property float len2() const
    {
        return x * x + y * y;
    }

    ///Get the length of the vector
    @property float len() const
    {
        return sqrt(len2());
    }

    ///Clamp a vector somewhere between a minimum and a maximum
    Vector clamp(in Vector min, in Vector max) const
    {
        return Vector(std.algorithm.comparison.clamp(x, min.x, max.x), std.algorithm.comparison.clamp(y, min.y, max.y));
    }

	///Get the cross product of a vector
	float cross(in Vector other) const
    {
        return x * other.y - y * other.x;
    }

    ///Get the dot product of a vector
    float dot(in Vector other) const
    {
        return x * other.x + y * other.y;
    }

    ///Normalize the vector's length from [0, 1]
    Vector normalize() const
    {
        return this * Q_rsqrt(len2);
    }

    ///Get only the X component of the Vector, represented as a vector
    @property Vector xComp() const
    {
        return Vector(x, 0);
    }

    ///Get only the Y component of the Vector, represented as a vector
    @property Vector yComp() const
    {
        return Vector(0, y);
    }

    ///Get the vector equal to Vector(1 / x, 1 / y)
    @property Vector inverse() const
    {
        return Vector(1 / x, 1 / y);
    }
}

unittest
{
    Vector a, b;
    a = Vector(5, 10);
    b = Vector(1, -2);
    assert((a + b).x == 6);
    assert((a - b).y == 12);
}

///Represents a 2D line segment
struct Line
{
    Vector start, end;

    @nogc nothrow pure: 

	bool intersects(in Line other) const
	{
        //See https://stackoverflow.com/a/565282 for algorithm
		Vector p = start;
		Vector q = other.start;
		Vector r = end - start;
		Vector s = other.end - other.start;
		//t = (q - p) x s / (r x s)
		//u = (q - p) x r / (r x s)
		float u_numerator = (q - p).cross(r);
        float t_numerator = (q - p).cross(s);
        float denominator = r.cross(s);
        if (denominator == 0) {
			if(u_numerator != 0)
				return false;
			float t0 = (q - p).dot(r) / r.dot(r);
			float t1 = t0 + s.dot(r) / r.dot(r);
			return (t0 >= 0 && t0 <= 1) || (t1 >= 0 && t1 <= 1) || 
				(sgn(t0) != sgn(t1));
		} else {
			float u = u_numerator / denominator;
			float t = t_numerator / denominator;
			return t >= 0 && t <= 1 && u >= 0 && u <= 1;
		}
	}

    ///Check if a line segment intersects a circle
    bool intersects(in Circle c) const
    {
        Vector center = c.center;
        Vector line = end - start; 
        Vector dist = center - start;
        Vector nor_line = line.normalize();
        float product = dist.dot(nor_line);
        // Find the closest point on the line to check
        Vector check_point;
        if(product <= 0) {
            check_point = start;
        } else if(product >= 1) {
            check_point = end;
        } else {
            check_point = start + nor_line * product;
        }
        // Check to see if the closest point is within the radius
        return (center - check_point).len2 < c.radius * c.radius;
    }

    ///Check if a line segment intersects a rectangle
    bool intersects(in Rectangle r) const
    {
        return r.contains(start) || r.contains(end) 
            || Line(r.topLeft, r.topLeft + r.size.xComp).intersects(this) 
            || Line(r.topLeft, r.topLeft + r.size.yComp).intersects(this) 
            || Line(r.topLeft + r.size.xComp, r.topLeft + r.size).intersects(this)
            || Line(r.topLeft + r.size.yComp, r.topLeft + r.size).intersects(this);
    }

}

/**
An axis-aligned rectangle made of some numeric type
*/
struct Rectangle
{
    ///floathe top left of the rectangle
    public Vector topLeft = Vector(0, 0);
    ///floathe width and height of the rectangle
    public Vector size = Vector(0, 0);

    @nogc nothrow void print() const
    {
        dgt.io.print("Rectangle(", x, ", ", y, ", ", width, ", ", height, ")");
    }

    @nogc nothrow pure public:
    ///Create a rectangle with the given dimension
    this(in float x, in float y, in float width, in float height)
    {
        topLeft = Vector(x, y);
        size = Vector(width, height);
    }
    ///Create a rectangle at 0, 0 with a given size
    this(in float width, in float height)
    {
        this(0, 0, width, height);
    }
    ///Create a rectangle with a given top left and a given size
    this(in Vector top, in Vector dimension)
    {
        topLeft = top;
        size = dimension;
    }

    @property float x() const { return topLeft.x; }
    @property float x(float val) { return topLeft.x = val; }
    @property float y() const { return topLeft.y; }
    @property float y(float val) { return topLeft.y = val; }
    @property float width() const { return size.x; }
    @property float width(float val) { return size.x = val; }
    @property float height() const { return size.y; }
    @property float height(float val) { return size.y = val; }

    ///Checks if a point falls within the rectangle
    bool contains(in Vector v) const
    {
        return v.x >= x && v.y >= y && v.x < x + width && v.y < y + height;
    }

    ///Check if any of the area bounded by this rectangle is bounded by another
    bool overlaps(in Rectangle b) const
    {
        return x < b.x + b.width && x + width > b.x && y < b.y + b.height && y + height > b.y;
    }

    ///Check if any of the area bounded by this rectangle is bounded by a circle
    bool overlaps(in Circle c) const
    {
        Vector closest;
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

    ///Set the rectangle's dimensions
    void set(float newX, float newY, float newWidth, float newHeight)
    {
        x = newX;
        y = newY;
        width = newWidth;
        height = newHeight;
    }

    /**
    Move the rectangle so it is entirely contained with another

    If the rectangle is moved it will always be flush with a border of the given area
    */
    Rectangle constrain(in Rectangle outer) const
    {
        return Rectangle(topLeft.clamp(outer.topLeft, outer.topLeft + outer.size - size), size);
    }

    ///Translate the rectangle by a vector
    Rectangle translate(in Vector vec) const
    {
        return Rectangle(x + vec.x, y + vec.y, width, height);
    }
}

unittest
{
    Rectangle a, b, c;
    a = Rectangle(0, 0, 32, 32);
    b = Rectangle(16, 16, 32, 32);
    c = Rectangle(50, 50, 5, 5);
    assert(a.overlaps(b));
    assert(!a.overlaps(c));
}

/**
A circle with a center and a radius
*/
struct Circle
{
    public Vector center = Vector(0, 0);
    public float radius = 0;

    @nogc nothrow void print() const
    {
        dgt.io.print("Circle(", x, ", ", y, ", ", radius, ")");
    }

    @nogc nothrow pure public:
    this(float x, float y, float radius)
    {
        center = Vector(x, y);
        this.radius = radius;
    }
    @property float x() const { return center.x; }
    @property float x(float val) { return center.x = val; }
    @property float y() const { return center.y; }
    @property float y(float val) { return center.y = val; }

    /**
    Checks if a vector falls within the area bounded by a circle
    */
    bool contains(in Vector v) const
    {
        Vector dist = v - center;
        return dist.len2 < radius * radius;
    }

    /**
    Checks to see if the circle and the rectangle share any area
    */
    bool overlaps(in Rectangle r) const
    {
        return r.overlaps(this);
    }

    /**
    Checks to see if the circles have any overlapping area
    */
    bool overlaps(in Circle c) const
    {
        float xDiff = x - c.x;
        float yDiff = y - c.y;
        float rad = radius + c.radius;
        return xDiff * xDiff + yDiff * yDiff < rad * rad;
    }

    /**
    Sets the dimensions of a circle
    */
    void set(float newX, float newY, float newRadius)
    {
        x = newX;
        y = newY;
        radius = newRadius;
    }

    ///floatranslate the circle by a given vector
    Circle translate(Vector vec)
    {
        return Circle(x + vec.x, y + vec.y, radius);
    }
}

unittest
{
    Circle a, b, c;
    Rectangle d;
    a.set(0, 0, 16);
    b.set(5, 5, 4);
    c.set(50, 50, 5);
    d.set(10, 10, 10, 10);
    assert(a.overlaps(b));
    assert(!a.overlaps(c));
    assert(a.overlaps(d));
    assert(!c.overlaps(d));
}

/**
A Transform 3x3 matrix to make transformations more efficient
*/
struct Transform
{
    private float[9] data = [
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

    this(in float[9] data)
    {
        this.data = data;
    }

    ///A pointer to the internal buffer to pass the matrix to C
    float* ptr()
    {
        return &data[0];
    }

    Transform opBinary(string op)(Transform other) const
    if (op == "*")
    {
        Transform ret;
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

    Vector opBinary(string op)(Vector other) const
    if (op == "*")
    {
        return Vector(other.x * this[0, 0] + other.y * this[0, 1] + this[0, 2],
            other.x * this[1, 0] + other.y * this[1, 1] + this[1, 2]);
    }

    Transform opBinary(string op)(float scalar) const
    if(op == "*")
    {
        Transform ret;
        for(int i = 0; i < 3; i++)
            for(int j = 0; j < 3; j++)
                ret[i, j] = this[i, j] * scalar;
        return ret;
    }

    float opIndex(size_t i, size_t j) const
    {
        return data[i * 3 + j];
    }

    float opIndexAssign(float val, size_t i, size_t j)
    {
        return data[i * 3 + j] = val;
    }

    ref Transform opAssign(float[9] array)
    {
        data = array;
        return this;
    }

    ///Flip the underlying matrix over the xy axis
    @property Transform transpose() const
    {
        return Transform([
            this[0, 0], this[0, 1], this[0, 2],
            this[1, 0], this[1, 1], this[1, 2],
            this[2, 0], this[2, 1], this[2, 2]
        ]);
    }

    /**
    Find a 2x2 submatrix

    The row and column that (x, y) sits in will be eliminated
    */
    float[4] submatrix(int x, int y) const
    {
        float[4] matrix;
        int index = 0;
        for(int i = 0; i < 3; i++)
        {
            for(int j = 0; j < 3; j++)
            {
                if(i == x || j == y)
                    continue;
                else
                {
                    matrix[index] = this[i, j];
                    index++;
                }
            }
        }
        return matrix;
    }

    /**
    Find a determinant of a 2x2 submatrix

    The row and column that (x, y) sits in will be ignored
    */
    float determinant(int x, int y) const
    {
        const sub = submatrix(x, y);
        return sub[0] * sub[3] - (sub[1] * sub[2]);
    }

    ///Find the determinant of the underlying matrix
    float determinant() const
    {
        float sum = 0;
        for(int i = 0; i < 3; i++)
            sum += this[i, 0] * determinant(i, 0);
        return sum;
    }

    ///Find the inverse of the transform
    @property Transform inverse() const
    {
        Transform other = this;
        //Find the matrix of minors
        for(int i = 0; i < 3; i++)
            for(int j = 0; j < 3; j++)
                other[i, j] = this.determinant(i, j);
        //Find the matrix of cofactors
        for(int i = 0; i < 3; i++)
            for(int j = 0; j < 3; j++)
                if(i != j && !(i == 0 && j == 2) && !(i == 2 && j == 0))
                    other[i, j] = -other[i, j];
        //Find the adjutant
        other = other.transpose;
        return other * (1 / this.determinant);
    }

    ///Create an identity matrix
    static pure Transform identity()
    {
        return Transform();
    }

    ///Create a rotation matrix
    static pure Transform rotate(in float angle)
    {
        float c = cos(angle * PI / 180);
        float s = sin(angle * PI / 180);
        return Transform([
            c, -s, 0,
            s, c, 0,
            0, 0, 1
        ]);
    }

    ///Create a translation matrix
    static pure Transform translate(in Vector vec)
    {
        return Transform([
            1, 0, vec.x,
            0, 1, vec.y,
            0, 0, 1
        ]);
    }

    ///Create a scale matrix
    static pure Transform scale(in Vector vec)
    {
        return Transform([
            vec.x, 0, 0,
            0, vec.y, 0,
            0, 0, 1
        ]);
    }
}


@nogc nothrow:
unittest
{
    auto vec = Vector(3, 5);
    auto inverse = vec.inverse;
    assert(approxEqual(inverse.x, 1.0 / 3, 0.00001) && 
        approxEqual(inverse.y, 1.0 / 5, 0.00001));
}
unittest
{
    auto vec = Vector(2, 4);
    auto translate = Transform.scale(Vector(0.5, 0.5));
    auto inverseTranslate = translate.inverse;
    auto transformed = inverseTranslate * vec;
    assert(transformed.x == 4 && transformed.y == 8);
}
unittest
{
    Transform m, n;
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
    auto trans = Transform.scale(Vector(2, 2));
    auto vec = Vector(2, 5);
    auto scaled = trans * vec;
    assert(scaled.x == 4 && scaled.y == 10);
}
unittest
{
    auto trans = Transform.translate(Vector(3, 4));
    auto vec = Vector(1, 1);
    vec = trans * vec;
    assert(vec.x == 4 && vec.y == 5);
}
unittest
{
    auto trans = Transform.identity() * Transform.translate(Vector()) 
        * Transform.rotate(0) * Transform.scale(Vector(1, 1));
    auto vec = trans * Vector(15, 12);
    assert(vec.x == 15);
}
unittest
{
    auto vec = Vector(5, 0);
    assert(vec.len2 == 25);
    assert(vec.len == 5);
}
unittest
{
    auto vec = Vector(10, 10);
    vec = vec / 2;
    assert(vec.x == 5 && vec.y == 5);
}
unittest
{
    auto circ = Circle(0, 0, 10);
    auto vec1 = Vector(0, 0);
    auto vec2 = Vector(11, 11);
    assert(circ.contains(vec1));
    assert(!circ.contains(vec2));
}
unittest
{
    auto rect = Rectangle(0, 0, 32, 32);
    auto vec1 = Vector(5, 5);
    auto vec2 = Vector(33, 1);
    assert(rect.contains(vec1));
    assert(!rect.contains(vec2));
}
unittest
{
    auto circ = Circle(0, 0, 5);
    auto rec1 = Rectangle(0, 0, 2, 2);
    auto rec2 = Rectangle(5, 5, 4, 4);
    assert(circ.overlaps(rec1) && rec1.overlaps(circ));
    assert(!circ.overlaps(rec2) && !rec2.overlaps(circ));
}
unittest
{
    auto min = Vector(-10, -2);
    auto max = Vector(5, 6);
    auto a = Vector(-11, 3);
    auto clamped = a.clamp(min, max);
    assert(clamped.x == -10 && clamped.y == 3);
    auto b = Vector(2, 8);
    clamped = b.clamp(min, max);
    assert(clamped.x == 2 && clamped.y == 6);
}
unittest
{
    auto constraint = Rectangle(0, 0, 10, 10);
    auto a = Rectangle(-1, 3, 5, 5);
    auto b = Rectangle(4, 4, 8, 3);
    a = a.constrain(constraint);
    assert(a.x == 0 && a.y == 3);
    b = b.constrain(constraint);
    assert(b.x == 2 && b.y == 4);
}

unittest
{
    println("Should print a vector at 0, 0: ", Vector(0, 0));
    println("Should print a circle at 0, 0 with a radius of 10: ", Circle(0, 0, 10));
    println("Should print a rectangle at 0, 0, with a side of 5", Rectangle(0, 0, 5, 5));
    println("Should print an identity matrix: ", Transform.identity());
}
unittest
{
    auto a = Rectangle(10, 10, 5, 5);
    auto b = Circle(10, 10, 5);
    auto c = Vector(1, -1);
    auto aTranslate = a.translate(c);
    auto bTranslate = b.translate(c);
    assert(aTranslate.y == a.y + c.y && aTranslate.y == a.y + c.y);
    assert(bTranslate.x == b.x + c.x && bTranslate.y == b.y + c.y);
}
unittest
{
    assert(Vector(6, 5).dot(Vector(2, -8)) == -28);
}
unittest
{
    const line1 = Line(Vector(0, 0), Vector(32, 32));
    const line2 = Line(Vector(0, 32), Vector(32, 0));
    const line3 = Line(Vector(32, 32), Vector(64, 64));
    const line4 = Line(Vector(100, 100), Vector(1000, 1000));
    assert(line1.intersects(line2));
    assert(line1.intersects(line3));
    assert(!line2.intersects(line3));
    assert(!line1.intersects(line4));
    assert(!line2.intersects(line4));
    assert(!line3.intersects(line4));
    const rect = Rectangle(32, 32);
    assert(line1.intersects(rect));
    assert(line2.intersects(rect));
    assert(line3.intersects(rect));
    assert(!line4.intersects(rect));
    const circ = Circle(0, 0, 33);
    assert(line1.intersects(circ));
    assert(line2.intersects(circ));
    assert(!line3.intersects(circ));
    assert(!line4.intersects(circ));
}
