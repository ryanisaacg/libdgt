import derelict.sdl2.sdl : SDL_Color;

struct Color
{
	float r, g, b, a;

	@nogc pure nothrow:
	SDL_Color toSDL() 
	{
		SDL_Color c = {
			cast(ubyte)(255 * r), cast(ubyte)(255 * g), cast(ubyte)(255 * b), cast(ubyte)(255 * a)
		};
		return c;
	}
}


