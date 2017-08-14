module au.ui;

import au.array : Array;
import au.geom : Rectangle, Vector;
import au.texture : Texture;
import au.window : Window;

struct Button
{
    public @nogc nothrow:

    Rectangle!int area;
    Vector!int position;
    Texture tex, hover, press;

    bool draw(Window window)
    {
        if (area.contains(window.mousePos))
        {
            if (window.mouseLeftPressed)
                window.draw(press, position.x, position.y);
            else
                window.draw(hover, position.x, position.y);
            return window.mouseLeftReleased;
        }
        else
            window.draw(tex, position.x, position.y);
        return false;
    }
}

struct Slider
{
    public @nogc nothrow:
    Rectangle!int area;
    float current;
    Texture slider;

    float draw(Window window)
    {
        window.draw(slider, -slider.region.width / 2 + area.x + current * area.width,
                -slider.region.height / 2 + area.y + area.height / 2);
        if (window.mouseLeftPressed && area.contains(window.mousePos))
            return (window.mouseX - area.x) / cast(float)(area.width);
        else
            return current;
    }

}

struct Carousel
{
    public @nogc nothrow:
    Button left, right;
    Vector!int position;
    Array!Texture textures;
    int current;

    int draw(Window window)
    {
        if (left.draw(window))
            current --;
        if (right.draw(window))
            current ++;
        current = (current + textures.length) % textures.length;
        window.draw(textures[current], position.x, position.y);
        return current;
    }
}
