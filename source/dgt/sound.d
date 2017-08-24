module dgt.sound;
import derelict.sdl2.mixer;

struct SoundClip
{
	private Mix_Chunk* source;

    @nogc nothrow:
    this(in string path)
    {
        source = Mix_LoadWAV(path.ptr);
    }

    @property int volume() { return Mix_VolumeChunk(source, -1); }
    @property int volume(in int value) { return Mix_VolumeChunk(source, value); }

    SoundInstance play(in int times = 1)
    {
        return SoundInstance(Mix_PlayChannel(-1, source, times - 1));
    }

    void destroy()
    {
        Mix_FreeChunk(source);
    }
}

struct SoundInstance
{
    private int id;

    @nogc nothrow:
    this(in int id) { this.id = id; }

    void pause() { Mix_Pause(id); }
    void resume() { Mix_Resume(id); }
    void stop() { Mix_HaltChannel(id); }
    void fadeOut(in int ms) { Mix_FadeOutChannel(id, ms); }
    bool isPlaying() const { return Mix_Playing(id) != 0; }
    bool isPaused() const { return Mix_Paused(id) != 0; }
}
