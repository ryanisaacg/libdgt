module au.color;
import derelict.sdl2.sdl : SDL_Color;
import core.stdc.stdio;

struct Color
{
	float r, g, b, a;

	@nogc nothrow:
	void print()
	{
		printf("Color(%f, %f, %f, %f)", r, g, b, a);
	}

	pure:
	public SDL_Color opCast()
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
