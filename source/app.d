import std.stdio, std.file;
import au;

void main()
{
	Window engine;
	WindowConfig config;
	engine.init("Test title", 640, 480, config);
	auto tex = engine.loadTexture("test.png");
	while(engine.should_continue)
	{
		engine.begin(black);
		engine.drawTexture(tex, 0, 0, 32, 32);
		engine.end();
	}
	engine.destroy();
}
