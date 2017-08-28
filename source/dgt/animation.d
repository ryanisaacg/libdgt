/**
Allows storing instances of a looping, linear animation
*/
module dgt.animation;

import dgt.array, dgt.texture;

/**
A frame in an animation
*/
struct Frame
{
    public:
    /**
    The actual thing to draw when this frame is active
    */
    Texture image;
    /**
    The number of animation ticks this frame remains active

    An animation tick occurs once a frame, to a default of 60 times a second
    */
    int delay;
}

/**
An animated instance

It progresses linearly from frame to frame and loops when it finishes.
*/
struct Animation
{
    private:
    Array!Frame frames;
    int currentFrame, currentTime;

    @nogc nothrow public:
    /**
    Create an animation from a fixed-size array of frames.

    The frame array is copied into a local buffer.
    The Animation must be destroyed with `destroy`.
    */
    pure this(size_t N)(in Frame[N] frames)
    {
        this(Array!Frame(frames));
    }

    /**
    Create an animation from a variable-sized buffer of frames

    The animation now owns the frame buffer and destroys it when it is destroyed.
    The Animation must be destroyed with `destroy`.
    */
    pure this(Array!Frame frames)
    {
        this.frames = frames;
        currentFrame = 0;
        currentTime = 0;
        assert(frames.length > 0);
    }

    /**
    Destroy an animation and free its internal memory
    */
    void destroy()
    {
        frames.destroy();
    }

    /**
    Tick the animation forward one frame

    Returns: The current frame of the animation
    */
    pure ref const(Texture) update()
    {
        currentTime++;
        if (currentTime >= frames[currentFrame].delay)
        {
            currentTime = 0;
            currentFrame = cast(int)((currentFrame + 1) % frames.length);
        }
        return frames[currentFrame].image;
    }

    /**
    Returns: The current frame of the animation
    */
    pure @property ref const(Texture) texture() const
    {
        return frames[currentFrame].image;
    }
}
