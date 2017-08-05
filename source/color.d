import derelict.sdl2.sdl : SDL_Color;

struct Color
{
	float r, g, b, a;

	@nogc pure nothrow:
	public T opCast(T)()
	if(T == SDL_Color)
	{
		SDL_Color c = {
			cast(ubyte)(255 * r), cast(ubyte)(255 * g), cast(ubyte)(255 * b), cast(ubyte)(255 * a)
		};
		return c;
	}
}

static immutable white = Color(1, 1, 1, 1);
static immutable black = Color(0, 0, 0, 0);
static immutable red = Color(1, 0, 0, 1);
static immutable orange = Color(1, 0.5, 0, 1);
static immutable yellow = Color(1, 1, 0, 1);
static immutable green = Color(1, 1, 0, 1);
static immutable cyan = Color(0, 1, 1, 1);
static immutable blue = Color(0, 0, 1, 1);
static immutable purple = Color(1, 0, 1, 1);
static immutable indigo = Color(0.5, 0, 1, 1);
