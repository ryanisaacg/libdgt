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
		engine.draw(tex, 100, 0, 32, 32);
		engine.draw(tex, 100, 400, 32, 32);
		engine.draw(red, Rectanglef(30, 30, 40, 40));
		engine.draw(blue, Rectanglef(100, 100, 40, 40));
		engine.draw(blue, Circlef(100, 100, 32));
		engine.end();
	}
	engine.destroy();
}
