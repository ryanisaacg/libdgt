module au.font;
import derelict.sdl2.sdl, derelict.sdl2.ttf;
import au.array, au.color, au.geom, au.texture, au.window;

static immutable FONT_MAX_CHARS = 223;
static immutable FONT_CHAR_OFFSET = 32;

struct Font
{
	Array!Texture characterTextures;
	int height;

    @nogc nothrow:
    this(Window window, TTF_Font* font, Color col)
    {
        SDL_Color color = cast(SDL_Color)col;
        char[2] buffer = ['\0', '\0'];
        SDL_Surface*[FONT_MAX_CHARS] characters;
        int total_width = 0;
        height = 0;
        //Render each ASCII character to a surface
    	for (int i = 0; i < FONT_MAX_CHARS; i++) {
    		buffer[0] = getChar(i);
    		characters[i] = TTF_RenderText_Solid(font, buffer.ptr, color);
    		total_width += characters[i].w;
    		if (characters[i].h > height) {
    			height = characters[i].h;
    		}
    	}
        //Blit all of the characters to a large surface
    	SDL_Surface* full = SDL_CreateRGBSurface(0, total_width, height, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
    	int position = 0;
    	for (int i = 0; i < FONT_MAX_CHARS; i++) {
    		SDL_Rect dest = SDL_Rect(position, 0, 0, 0);
    		SDL_BlitSurface(characters[i], null, full, &dest);
    		position += characters[i].w;
    	}
        //Load the surface into a texture
        Texture texture = window.loadTexture(full);
        SDL_FreeSurface(full);
        //Add reference to the texture for each character
        position = 0;
        characterTextures.ensureCapacity(FONT_MAX_CHARS);
        for (int i = 0; i < FONT_MAX_CHARS; i++) {
            characterTextures[i] = texture.getSlice(Rectangle!int(position, 0, characters[i].w, characters[i].h));
            position += characterTextures[i].region.width;
            SDL_FreeSurface(characters[i]);
        }
    }

    void destroy()
    {
        characterTextures.destroy();
    }

    pure:
    Texture render(char c)
    {
        return characterTextures[getIndex(c)];
    }

    Rectangle!int getSizeOfString(string str)
    {
    	int position = 0;
    	int width = 0, height = this.height;
    	for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
    		if (position > width)
    			width = position;
    		if (c == '\t')
    			position += 4 * render(' ').region.width;
            else if (c == '\n')
            {
    			height += render('\n').region.height;
    			position = 0;
    		}
            else if (c != '\r')
    			position += render(c).region.width;
    	}
    	return Rectangle!int(0, 0, width, height);
    }

    private int getIndex(char c)
    {
        return c - FONT_CHAR_OFFSET;
    }

    private char getChar(int index)
    {
        return cast(char)(index + FONT_CHAR_OFFSET);
    }
}
