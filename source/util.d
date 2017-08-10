import core.stdc.math, core.stdc.stdlib;

import geom;

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
    return Vector!float(a.x + b.x, a.y + b.y);
}
Vector!int randvectori_range(Vector!int a, Vector!int b)
{
    return Vector!int(a.x + b.x, a.y + b.y);
}
