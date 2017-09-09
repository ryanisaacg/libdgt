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
    const(Frame[]) frames;
    int currentFrame = 0, currentTime = 0;

    @nogc nothrow public:
    /**
    Create an animation from an array of frames
    */
    pure this(in Frame[] frames)
    {
        this.frames = frames;
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
