import std.stdio;
import au;

void main()
{
	Window engine;
	WindowConfig config;
	engine.init("Test title", 640, 480, config);
	while(engine.should_continue)
	{
		engine.begin(black);
		engine.end();
	}
	engine.destroy();
}
