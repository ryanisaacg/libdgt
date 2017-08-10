import derelict.sdl2.mixer;

struct Music
{
	private Mix_Music* source;

    @nogc nothrow:
    this(string path)
    {
        source = Mix_LoadMUS(path.ptr);
    }

    @property int volume() { return Mix_VolumeMusic(-1); }
    @property int volume(int value) { return Mix_VolumeMusic(value); }
    void play(int times = 1)
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
    void destroy()
    {
        Mix_FreeMusic(source);
    }
}
