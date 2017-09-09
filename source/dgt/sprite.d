module dgt.sprite;

import dgt.animation;
import dgt.color;
import dgt.texture;

/**
A drawable object attached to a transformation

Can be either static (Texture) or dynamic (Animation)
*/
struct Sprite
{
    private:
    union SpriteData
    {
        Animation anim;
        Texture tex;

        @nogc nothrow pure:
        this(Animation a) { anim = a; }
        this(Texture t) { tex = t; }
    }

    enum SpriteType
    {
        Static, Animated
    }

    SpriteData data;
    SpriteType type;

    public @nogc nothrow pure:

    float x = 0, y = 0, width = 0, height = 0,
          originX = 0, originY = 0, scaleX = 1, scaleY = 1, rotation = 0;
    bool flipX = false, flipY = false;
    Color color = Color.white;

    ///Create a static sprite
    this(in Texture tex)
    {
        data.tex = tex;
        source = tex;
    }

    ///Create a dynamic sprite
    this(scope Animation anim)
    {
        data.anim = anim;
        source = anim;
    }

    ///Update the sprite (only affects dynamic sprites)
    void update()
    {
        if(type == SpriteType.Animated)
            data.anim.update();
    }

    ///Get the current texture of the sprite
    @property ref const(Texture) texture() const
    {
        if(type == SpriteType.Animated)
            return data.anim.texture;
        else
            return data.tex;
    }

    ///Set the source of the sprite to a static texture
    @property Texture source(in Texture tex)
    {
        data.tex = tex;
        type = SpriteType.Static;
        width = tex.size.width;
        height = tex.size.height;
        return tex;
    }

    ///Set the source of the sprite to a dynamic animation
    @property Animation source(scope Animation anim)
    {
        data = SpriteData(anim);
        type = SpriteType.Animated;
        width = anim.texture.size.width;
        height = anim.texture.size.height;
        return anim;
    }
}
