import std.stdio, std.file;
import au;
import gl_backend;

void main()
{
	WindowConfig config;
	config.resizable = true;
	Window engine = new Window("Test title", 640, 480, config);
	scope(exit) engine.destroy();
	auto tex = engine.loadTexture("test.png");
	scope(exit) tex.destroy();
	int x = 100, y = 10;
	auto map = Tilemap!bool(640, 480, 32);
	scope(exit) map.destroy();
	map[96, 100] = Tile!bool(true, true);
	map[128, 100] = Tile!bool(true, true);
	while(engine.should_continue)
	{
		engine.begin(black);
		scope(exit) engine.end();

		engine.draw(tex, 100, 0, 32, 32);
		engine.draw(tex, 200, 400, 32, 32);
		engine.draw(tex, 300, 400, 32, 32);

		engine.draw(red, Rectanglef(30, 30, 40, 40));
		engine.draw(blue, Rectanglef(100, 100, 40, 40));
		engine.draw(Color(0, 1, 0, 0.5), Circlef(100, 100, 32));

		engine.draw(green, Rectanglef(x, y, 32, 32));
		auto move = map.slideContact(x, y, 32, 32, Vector!int(1, 3));
		x += move.x;
		y += move.y;
	}
}
