///A collection of immediate-mode UI widgets
module dgt.ui;

import dgt.geom : Rectanglei, Vectori;
import dgt.texture : Texture;
import dgt.window : Window;

///A clickable button
struct Button
{
    @disable this();

    public @nogc nothrow:

    Rectanglei area;
    Vectori position;
    Texture tex, hover, press;

    /**
    Defines a button

    Params:
    area = The clickable region of the button
    position = The spot to draw the button
    tex = The default texture of the button
    hover = The texture when the button is hovered over
    press = The texture when the button is pressed down
    */
    this(in Rectanglei area, in Vectori position, in Texture tex, in Texture hover, in Texture press)
    {
        this.area = area;
        this.position = position;
        this.tex = tex;
        this.hover = hover;
        this.press = press;
    }

    ///Draw a button and return if it is pressed
    bool draw(ref scope Window window) const
    {
        bool mouseContained = area.contains(window.mouse);
        window.draw(mouseContained ? (window.mouseLeftPressed ? press : hover) : tex,
                position.x, position.y);
        return mouseContained && window.mouseLeftReleased;
    }
}

///A slider that can be moved along a horizontal axis
struct Slider
{
    public @nogc nothrow:
    Rectanglei area;
    Texture slider;

    @disable this();

    /**
    Create a slider

    Params:
    area = The region the slider can move around in
    sliderHead = The image to draw where the slider is currently pointing
    */
    this(in Rectanglei area, in Texture sliderHead)
    {
        this.area = area;
        this.slider = sliderHead;
    }

    ///Draw a slider with a given normalized value and return its new value
    float draw(ref scope Window window, in float current) const
    {
        window.draw(slider, -slider.size.width / 2 + area.x + current * area.width,
                -slider.size.height / 2 + area.y + area.height / 2);
        if (window.mouseLeftPressed && area.contains(window.mouse))
            return (window.mouse.x - area.x) / cast(float)(area.width);
        else
            return current;
    }

}

///A rotating selection of options
struct Carousel
{
    @disable this();
    public @nogc nothrow:
    Button left, right;
    Vectori position;
    const(Texture[]) textures;

    ///Create a carousel with a given set of options 
    this(in Button left, in Button right, in Vectori currentItemPosition, in Texture[] textures)
    {
        this.left = left;
        this.right = right;
        this.position = currentItemPosition;
        this.textures = textures;
    }

    ///Draw a carousel with a given current index and return the new index
    int draw(ref scope Window window, in int current) const
    {
        int next = current;
        if (left.draw(window))
            next --;
        if (right.draw(window))
            next ++;
        next = cast(int)((next + textures.length) % textures.length);
        window.draw(textures[next], position.x, position.y);
        return next;
    }
}
