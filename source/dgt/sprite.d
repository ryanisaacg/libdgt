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
    Color color = white;

    this(Texture tex)
    {
        data.tex = tex;
        type = SpriteType.Static;
        width = tex.getRegion.width;
        height = tex.getRegion.height;
    }

    this(ref Animation anim)
    {
        data.anim = anim;
        type = SpriteType.Animated;
        width = anim.currentTexture.getRegion.width;
        height = anim.currentTexture.getRegion.height;
    }

    void setDrawable(Texture tex)
    {
        data.tex = tex;
        type = SpriteType.Static;
        width = tex.getRegion.width;
        height = tex.getRegion.height;
    }

    void setDrawable(Animation anim)
    {
        data.anim = anim;
        type = SpriteType.Animated;
        width = anim.currentTexture.getRegion.width;
        height = anim.currentTexture.getRegion.height;
    }

    void update()
    {
        if(type == SpriteType.Animated)
            data.anim.update();
    }

    ref Texture getTexture()
    {
        if(type == SpriteType.Animated)
            return data.anim.currentTexture();
        else
            return data.tex;
    }
}
