module dgt.util;
import core.stdc.math, core.stdc.stdlib;

import dgt.array;
import dgt.geom;

@nogc nothrow:

///A normalized random function
float random()
{
    return cast(float) rand() / RAND_MAX;
}
///Generate a random float in a range
float randomRange(in float min, in float max)
{
    return (max - min) * random() + min;
}
///Generate a random int in a range
int randomRange(in int min, in int max)
{
    return cast(int)randomRange(cast(float)min, cast(float)max);
}
///Generate a vector in a range
Vector randomRange(in Vector a, in Vector b)
{
    return Vector(randomRange(a.x, b.x), randomRange(a.y, b.y));
}
///Create a null terminated buffer from a string
Array!char nullTerminate(in string str)
{
    Array!char nameNullTerminated = Array!char(str.length + 1);
    for(size_t i = 0; i < str.length; i++)
        nameNullTerminated.add(str[i]);
    nameNullTerminated.add('\0');
    return nameNullTerminated;
}
unittest
{
    for(size_t i = 0; i < 1000; i++)
    {
        Vector vector = randomRange(Vector(-1, -1), Vector(5, 5));
        assert(vector.x >= -1 && vector.y >= -1 && vector.x < 5 && vector.y < 5);
    }
}
unittest
{
    auto str = nullTerminate("Test string");
    auto expected = "Test string\0";
    for(size_t i = 0; i < expected.length; i++)
        assert(str[i] == expected[i]);
}
