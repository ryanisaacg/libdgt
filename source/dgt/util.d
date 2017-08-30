module dgt.util;
import core.stdc.math, core.stdc.stdlib;

import dgt.array;
import dgt.geom;

@nogc nothrow:

//A normalized random function
float random()
{
    return cast(float) rand() / RAND_MAX;
}
float randomRange(in float min, in float max)
{
    return (max - min) * random() + min;
}
int randomRange(in int min, in int max)
{
    return cast(int)randomRange(cast(float)min, cast(float)max);
}
Vector!float randomRange(in Vector!float a, in Vector!float b)
{
    return Vector!float(randomRange(a.x, b.x), randomRange(a.y, b.y));
}
Vector!int randomRange(in Vector!int a, in Vector!int b)
{
    return Vector!int(randomRange(a.x, b.x), randomRange(a.y, b.y));
}
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
        Vectori vector = randomRange(Vectori(-1, -1), Vectori(5, 5));
        assert(vector.x >= -1 && vector.y >= -1 && vector.x < 5 && vector.y < 5);
    }
    for(size_t i = 0; i < 1000; i++)
    {
        Vectorf vector = randomRange(Vectorf(-1, -1), Vectorf(5, 5));
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
