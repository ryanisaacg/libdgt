module dgt.sound;
import derelict.sdl2.mixer;
import dgt.util : nullTerminate;

struct SoundClip
{
	private Mix_Chunk* source;

	@disable this();
	@disable this(this);

    @nogc nothrow:
    this(in string path)
    {
		auto pathNullTerminated = nullTerminate(path);
        source = Mix_LoadWAV(pathNullTerminated.ptr);
		pathNullTerminated.destroy();
    }
	~this()
	{
		Mix_FreeChunk(source);
	}

    @property int volume() { return Mix_VolumeChunk(source, -1); }
    @property int volume(in int value) { return Mix_VolumeChunk(source, value); }

    SoundInstance play(in int times = 1)
    {
        return SoundInstance(Mix_PlayChannel(-1, source, times - 1));
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
    @property bool isPlaying() const { return Mix_Playing(id) != 0; }
    @property bool isPaused() const { return Mix_Paused(id) != 0; }
}
