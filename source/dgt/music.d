module dgt.music;
import derelict.sdl2.mixer;
import dgt.util : nullTerminate;

struct Music
{
	private Mix_Music* source;

	@disable this();
	@disable this(this);

    @nogc nothrow:
    this(string path)
    {
		auto pathNullTerminated = nullTerminate(path);
        source = Mix_LoadMUS(pathNullTerminated.ptr);
		pathNullTerminated.destroy();
    }

	~this()
	{
		Mix_FreeMusic(source);
	}

    @property int volume() const { return Mix_VolumeMusic(-1); }
    @property int volume(in int value) { return Mix_VolumeMusic(value); }
    void play(in int times = 1)
    {
        Mix_PlayMusic(source, times - 1);
    }
    void pause()
    {
        Mix_PauseMusic();
    }
    void resume()
    {
        Mix_ResumeMusic();
    }
    void stop()
    {
        Mix_HaltMusic();
    }
    void fadeOut(int ms)
    {
        Mix_FadeOutMusic(ms);
    }
}
