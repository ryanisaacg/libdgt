module dgt.sprite;

import dgt.animation;
import dgt.color;
import dgt.texture;

struct Sprite
{
    private:
    union SpriteData
    {
        Animation anim;
        Texture tex;
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

    this(Texture tex)
    {
        data.tex = tex;
        type = SpriteType.Static;
        width = tex.size.width;
        height = tex.size.height;
    }

    this(Animation anim)
    {
        data.anim = anim;
        type = SpriteType.Animated;
        width = anim.texture.size.width;
        height = anim.texture.size.height;
    }

    void setDrawable(Texture tex)
    {
        data.tex = tex;
        type = SpriteType.Static;
        width = tex.size.width;
        height = tex.size.height;
    }

    void setDrawable(Animation anim)
    {
        data.anim = anim;
        type = SpriteType.Animated;
        width = anim.texture.size.width;
        height = anim.texture.size.height;
    }

    void update()
    {
        if(type == SpriteType.Animated)
            data.anim.update();
    }

    @property ref const(Texture) texture() const
    {
        if(type == SpriteType.Animated)
            return data.anim.texture;
        else
            return data.tex;
    }
}
