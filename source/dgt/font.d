module dgt.font;
import derelict.sdl2.sdl, derelict.sdl2.ttf;
import dgt.array, dgt.color, dgt.geom, dgt.io, dgt.texture, dgt.window;

enum FontStyle : int
{
    normal = TTF_STYLE_NORMAL,
    bold = TTF_STYLE_BOLD,
    italic = TTF_STYLE_ITALIC,
    underline = TTF_STYLE_UNDERLINE,
    strikethrough = TTF_STYLE_STRIKETHROUGH
}

struct Font
{
    static immutable FONT_MAX_CHARS = 223;
    static immutable FONT_CHAR_OFFSET = 32;
	Array!Texture characterTextures;
	int height;

    @disable this();
    @disable this(this);

    @nogc nothrow public:
	this(in string filename, in int size, in Color col, in FontStyle style)
    {
        TTF_Font* font = TTF_OpenFont(filename.ptr, size);
        TTF_SetFontStyle(font, style);
        if (font == null)
            println("Font with filename ", filename, " not found");
		SDL_Color color = cast(SDL_Color)col;
        char[2] buffer = ['\0', '\0'];
        SDL_Surface*[FONT_MAX_CHARS] characters;
        int total_width = 0;
        height = 0;
        //Render each ASCII character to a surface
    	for (int i = 0; i < FONT_MAX_CHARS; i++)
		{
    		buffer[0] = getCharFromIndex(i);
    		characters[i] = TTF_RenderText_Blended(font, buffer.ptr, color);
    		total_width += characters[i].w;
    		if (characters[i].h > height)
    			height = characters[i].h;
    	}
		TTF_CloseFont(font);
        //Blit all of the characters to a large surface
    	SDL_Surface* full = SDL_CreateRGBSurface(0, total_width, height, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
    	int position = 0;
    	for (int i = 0; i < FONT_MAX_CHARS; i++)
		{
    		SDL_Rect dest = SDL_Rect(position, 0, 0, 0);
    		SDL_BlitSurface(characters[i], null, full, &dest);
    		position += characters[i].w;
    	}
        //Load the surface into a texture
        Texture texture = Texture(full);
        SDL_FreeSurface(full);
        //Add reference to the texture for each character
        position = 0;
        characterTextures = Array!Texture(FONT_MAX_CHARS);
        for (int i = 0; i < FONT_MAX_CHARS; i++)
		{
            characterTextures[i] = texture.getSlice(Rectanglei(position, 0, characters[i].w, characters[i].h));
            position += characterTextures[i].size.width;
            SDL_FreeSurface(characters[i]);
        }
    }

    ~this()
    {
        characterTextures.destroy();
    }

    pure:
    Texture render(in char c) const
    {
        return characterTextures[getIndexFromChar(c)];
    }

    Rectangle!int getSizeOfString(in string str) const
    {
    	int position = 0;
    	int width = 0, height = this.height;
    	for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
    		if (position > width)
    			width = position;
    		if (c == '\t')
    			position += 4 * render(' ').size.width;
            else if (c == '\n')
            {
    			height += render('\n').size.height;
    			position = 0;
    		}
            else if (c != '\r')
    			position += render(c).size.width;
    	}
    	return Rectanglei(0, 0, width, height);
    }

    private int getIndexFromChar(in char c) const
    {
        return c - FONT_CHAR_OFFSET;
    }

    private char getCharFromIndex(in int index) const
    {
        return cast(char)(index + FONT_CHAR_OFFSET);
    }
}
