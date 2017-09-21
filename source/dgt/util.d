module dgt.util;
import core.stdc.math, core.stdc.stdlib;

import std.algorithm : canFind;
import std.algorithm.comparison : equal;
import std.math;
import std.string : indexOf;

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
pure string nextline(in string str, out string rest)
{
    auto index = str.indexOf('\n');
    if(index == -1)
    {
        index = str.length;
        rest = "";
    }
    else
    {
        rest = str[index + 1..str.length];
    }
    return str[0..index];
}
pure string trimLeft(in string str)
{
    int i = 0;
    for(; i < str.length; i++)
        if(str[i] != ' ' && str[i] != '\t' && str[i] != '\n' && str[i] != '\r')
            break;
    return str[i..str.length];
}
pure int parsePositiveInt(string str)
{
	int value = 0;
	for(int digit = 0; digit < str.length; digit++)
	{
		import core.stdc.stdio;
		value += cast(int)std.math.pow(10, digit) * (str[str.length - 1 - digit] - '0');
	}
	return value;
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
unittest
{
    auto manyLines = "First line
Second line

Fourth line";
    const firstLine = manyLines.nextline(manyLines);
    assert(firstLine == "First line");
    const secondLine = manyLines.nextline(manyLines);
    assert(secondLine == "Second line");
    const thirdLine = manyLines.nextline(manyLines);
    assert(thirdLine == "");
    const fourthLine = manyLines.nextline(manyLines);
    assert(fourthLine == "Fourth line");
}
unittest
{
    const noTrim = "Text";
    const trimSpace = " Text";
    const trimVariety = "

    Text";
    assert(noTrim == noTrim.trimLeft);
    assert(noTrim == trimSpace.trimLeft);
    assert(noTrim == trimVariety.trimLeft);
}
unittest
{
    assert(parsePositiveInt("0") == 0);
    assert(parsePositiveInt("234") == 234);
}
