/**
Allows the user to load and create bitmap fonts

To actually draw text on the screen use the Window draw functions
*/
module dgt.font;
import derelict.sdl2.sdl, derelict.sdl2.ttf;
import dgt.array, dgt.color, dgt.geom, dgt.io, dgt.texture, dgt.window;
import dgt.util : nullTerminate;

/**
An enum that determines character styling
*/
enum FontStyle : int
{
    normal = TTF_STYLE_NORMAL,
    bold = TTF_STYLE_BOLD,
    italic = TTF_STYLE_ITALIC,
    underline = TTF_STYLE_UNDERLINE,
    strikethrough = TTF_STYLE_STRIKETHROUGH
}

/**
A structure that stores rendered font glyps for drawing on the screen
*/
struct Font
{
    static immutable FONT_MAX_CHARS = 223;
    static immutable FONT_CHAR_OFFSET = 32;
	Array!Texture characterTextures;
	private int height;

    @disable this();
    @disable this(this);

    @nogc nothrow public:
    /**
    Load a font from a TTF file with a given size, color, and style
    */
	this(in string filename, in int size, in Color col, in FontStyle style)
    {
        //Pass the C function a null-terminated path to avoid string literal issues
        auto pathNullTerminated = nullTerminate(filename);
        TTF_Font* font = TTF_OpenFont(pathNullTerminated.ptr, size);
		pathNullTerminated.destroy();
        TTF_SetFontStyle(font, style);
        if (font == null)
            println("Font with filename ", filename, " not found");
		SDL_Color color = cast(SDL_Color)col;
        //Create a null-terminated buffer to send glyphs to the TTF library
        char[2] buffer = ['\0', '\0'];
        SDL_Surface*[FONT_MAX_CHARS] characters;
        int total_width = 0;
        height = 0;
        //Render each ASCII character to a surface
    	for (int i = 0; i < FONT_MAX_CHARS; i++)
		{
    		buffer[0] = getCharFromIndex(i);
            //Render the character and note how much space it takes up
    		characters[i] = TTF_RenderText_Solid(font, buffer.ptr, color);
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
            characterTextures.add(texture.getSlice(Rectanglei(position, 0, characters[i].w, characters[i].h)));
            position += characterTextures[i].size.width;
            SDL_FreeSurface(characters[i]);
        }
    }

    ~this()
    {
        characterTextures.destroy();
    }

    pure:
    /// Get the glyph for a given character
    Texture render(in char c) const
    {
        return characterTextures[getIndexFromChar(c)];
    }

    ///Find how much space a string would take when rendered
    Rectangle!int getSizeOfString(in string str, float lineHeight = 1) const
    {
    	int position = 0;
    	int width = 0, height = cast(int)(this.height * lineHeight);
    	for(size_t i = 0; i < str.length; i++)
        {
            char c = str[i];
    		if (position > width)
    			width = position;
            //a tab is equivalent to 4 space characters
    		if (c == '\t')
    			position += 4 * render(' ').size.width;
            //Move down a line
            else if (c == '\n')
            {
    			height += cast(int)(characterHeight * lineHeight);
    			position = 0;
    		}
            else if (c != '\r')
    			position += render(c).size.width;
    	}
    	return Rectanglei(0, 0, width, height);
    }

    //Get the pixel height of the characters in the font
    @property int characterHeight() const { return height; }

    private int getIndexFromChar(in char c) const
    {
        return c - FONT_CHAR_OFFSET;
    }

    private char getCharFromIndex(in int index) const
    {
        return cast(char)(index + FONT_CHAR_OFFSET);
    }
}
