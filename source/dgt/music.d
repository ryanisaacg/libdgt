/**
Allows the player to stream music from disk without loading it entirely into memory
*/
module dgt.music;
import derelict.sdl2.mixer;
import dgt.util : nullTerminate;

/**
Represents a piece of music that can be played by streaming

Only one piece of music can be played at once
*/
struct Music
{
	private Mix_Music* source;

	@disable this();
	@disable this(this);

    @nogc nothrow:
    ///Load the music clip from a path
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

    ///Get the volume of the music channel
    @property int volume() const { return Mix_VolumeMusic(-1); }
    ///Set the volume of the music channel
    @property int volume(in int value) { return Mix_VolumeMusic(value); }
    ///Play a song a given number of times
    void play(in int times = 1)
    {
        Mix_PlayMusic(source, times - 1);
    }
    ///Pause the music
    void pause()
    {
        Mix_PauseMusic();
    }
    ///Resume the music from pause
    void resume()
    {
        Mix_ResumeMusic();
    }
    ///Stop the music
    void stop()
    {
        Mix_HaltMusic();
    }
    ///Fade the music out over a given number of milliseconds
    void fadeOut(int ms)
    {
        Mix_FadeOutMusic(ms);
    }
}
