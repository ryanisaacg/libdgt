module dgt.color;

import dgt.io;

import derelict.sdl2.sdl : SDL_Color;

private pure @nogc nothrow int getHexChar(char c)
{
	if(c >= '0' && c <= '9')
		return cast(int)(c - '0');
	else if(c >= 'A' && c <= 'F')
		return cast(int)(c - 'A') + 10;
	else
		assert(0);
}

struct Color
{
	float r, g, b, a;

	@nogc nothrow:
	static Color fromHexCode(string hexcode)
	{
		for(size_t i = 0; i < hexcode.length; i += 2)
		{
			int value = 16 * getHexChar(hexcode[i]) + getHexChar(hexcode[i + 1]);
			println("Value: ", value);
		}
		return Color(1, 1, 1, 1);
	}

	void print() const
	{
        import core.stdc.stdio;
		printf("Color(%f, %f, %f, %f)", r, g, b, a);
	}

	pure:
	public SDL_Color opCast() const
	{
		SDL_Color c = SDL_Color(
			cast(ubyte)(255 * r), cast(ubyte)(255 * g), cast(ubyte)(255 * b), cast(ubyte)(255 * a)
		);
		return c;
	}
}


static immutable white = Color(1, 1, 1, 1);
static immutable black = Color(0, 0, 0, 0);
static immutable red = Color(1, 0, 0, 1);
static immutable orange = Color(1, 0.5, 0, 1);
static immutable yellow = Color(1, 1, 0, 1);
static immutable green = Color(0, 1, 0, 1);
static immutable cyan = Color(0, 1, 1, 1);
static immutable blue = Color(0, 0, 1, 1);
static immutable purple = Color(1, 0, 1, 1);
static immutable indigo = Color(0.5, 0, 1, 1);

unittest
{
    import dgt.io : println;
    println("Should print a color equivalent to white: ", white);
    SDL_Color orangeSDL = cast(SDL_Color)orange;
    assert(orangeSDL.r == 255 && orangeSDL.g == 127 && orangeSDL.b == 0 && orangeSDL.a == 255);
}
