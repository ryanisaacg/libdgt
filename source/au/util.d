module au.util;
import core.stdc.math, core.stdc.stdlib;

import au.geom;

@nogc nothrow:

//A normalized random function
float random()
{
    return cast(float) rand() / RAND_MAX;
}
float randf_range(float min, float max)
{
    return (max - min) * random() + min;
}
int randi_range(int min, int max)
{
    return cast(int)randf_range(min, max);
}
Vector!float randvectorf_range(Vector!float a, Vector!float b)
{
    return Vector!float(randf_range(a.x, b.x), randf_range(a.y, b.y));
}
Vector!int randvectori_range(Vector!int a, Vector!int b)
{
    return Vector!int(randi_range(a.x, b.x), randi_range(a.y, b.y));
}
unittest
{
    for(size_t i = 0; i < 1000; i++)
    {
        Vectori vector = randvectori_range(Vectori(-1, -1), Vectori(5, 5));
        assert(vector.x >= -1 && vector.y >= -1 && vector.x < 5 && vector.y < 5);
    }
    for(size_t i = 0; i < 1000; i++)
    {
        Vectorf vector = randvectorf_range(Vectorf(-1, -1), Vectorf(5, 5));
        assert(vector.x >= -1 && vector.y >= -1 && vector.x < 5 && vector.y < 5);
    }
}
