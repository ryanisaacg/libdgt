module au.ui;

import au.geom : Rectangle, Vector;
import au.texture : Texture;
import au.window : Window;

@nogc nothrow:
bool button(Window window, Rectangle!int area, Vector!int position,  Texture tex,  Texture hover,  Texture press)
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
