module au.ui;

import au.array : Array;
import au.geom : Rectanglei, Vectori;
import au.texture : Texture;
import au.window : Window;

struct Button
{
    @disable this();

    public @nogc nothrow:

    Rectanglei area;
    Vectori position;
    Texture tex, hover, press;

    this(Rectanglei area, Vectori position, Texture tex, Texture hover, Texture press)
    {
        this.area = area;
        this.position = position;
        this.tex = tex;
        this.hover = hover;
        this.press = press;
    }

    bool draw(Window window)
    {
        bool mouseContained = area.contains(window.mousePos);
        window.draw(mouseContained ? (window.mouseLeftPressed ? press : hover) : tex,
                position.x, position.y);
        return mouseContained && window.mouseLeftReleased;
    }
}

struct Slider
{
    public @nogc nothrow:
    Rectanglei area;
    Texture slider;

    @disable this();

    this(Rectanglei area, Texture sliderHead)
    {
        this.area = area;
        this.slider = sliderHead;
    }

    float draw(Window window, float current)
    {
        window.draw(slider, -slider.getRegion.width / 2 + area.x + current * area.width,
                -slider.getRegion.height / 2 + area.y + area.height / 2);
        if (window.mouseLeftPressed && area.contains(window.mousePos))
            return (window.mouseX - area.x) / cast(float)(area.width);
        else
            return current;
    }

}

struct Carousel
{
    @disable this();
    public @nogc nothrow:
    Button left, right;
    Vectori position;
    Array!Texture textures;

    this(Button left, Button right, Vectori currentItemPosition, Array!Texture textures)
    {
        this.left = left;
        this.right = right;
        this.position = currentItemPosition;
        this.textures = textures;
    }

    int draw(Window window, int current)
    {
        if (left.draw(window))
            current --;
        if (right.draw(window))
            current ++;
        current = cast(int)((current + textures.length) % textures.length);
        window.draw(textures[current], position.x, position.y);
        return current;
    }
}
