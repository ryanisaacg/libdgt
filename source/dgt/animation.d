module dgt.animation;

import dgt.array, dgt.texture;

struct Frame
{
    public:
    Texture image;
    int delay;
}

struct Animation
{
    private:
    Array!Frame frames;
    int currentFrame, currentTime;

    @nogc nothrow public pure:
    this(size_t N)(in Frame[N] frames)
    {
        this(Array!Frame(frames));
    }

    this(Array!Frame frames)
    {
        this.frames = frames;
        currentFrame = 0;
        currentTime = 0;
        assert(frames.length > 0);
    }

    ref const(Texture) update()
    {
        currentTime++;
        if (currentTime >= frames[currentFrame].delay)
        {
            currentTime = 0;
            currentFrame = cast(int)((currentFrame + 1) % frames.length);
        }
        return frames[currentFrame].image;
    }

    @property ref const(Texture) texture() const
    {
        return frames[currentFrame].image;
    }
}
