module dgt.sound;
import derelict.sdl2.mixer;
import dgt.io;
import dgt.util : nullTerminate;

/**
A loaded chunk of sound data
*/
struct SoundClip
{
	private Mix_Chunk* source;

	@disable this();
	@disable this(this);

    @nogc nothrow:
    ///Load the clip from the specified path
    this(in string path)
    {
		auto pathNullTerminated = nullTerminate(path);
        source = Mix_LoadWAV(pathNullTerminated.ptr);
		pathNullTerminated.destroy();
        if(source == null)
            println("Sound file at ", path, " not found.");
    }

	~this()
	{
		Mix_FreeChunk(source);
	}

    ///Get the volume for the sound clip
    @property int volume() { return Mix_VolumeChunk(source, -1); }
    ///Set the volume for the sound clip
    @property int volume(in int value) { return Mix_VolumeChunk(source, value); }
    ///Play a sound a certain number of times, returning an instance
    SoundInstance play(in int times = 1)
    {
        return SoundInstance(Mix_PlayChannel(-1, source, times - 1));
    }
}

/**
A specific instance of a playing sound

The sound instance is invalid once the sound has stopped
*/
struct SoundInstance
{
    private int id;

    @nogc nothrow:
    this(in int id) { this.id = id; }

    ///Pause the current clip
    void pause() { Mix_Pause(id); }
    ///Resume the clip
    void resume() { Mix_Resume(id); }
    ///Stop the clip
    void stop() { Mix_HaltChannel(id); }
    ///Fade the clip to silence over a certain number of milliseconds
    void fadeOut(in int ms) { Mix_FadeOutChannel(id, ms); }
    ///Checks if the sound is playing
    @property bool isPlaying() const { return Mix_Playing(id) != 0; }
    ///Checks if the sound is paused
    @property bool isPaused() const { return Mix_Paused(id) != 0; }
}
