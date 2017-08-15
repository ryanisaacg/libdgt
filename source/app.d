import std.stdio, std.file;
import au;

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
    float n = 0;
    auto buttonTex = engine.loadTexture("button.png");
    auto camera = Rectanglef(0, 0, 640, 480);
    float value = 0;
	auto button = Button(Rectanglei(300, 300, 32, 32), Vectori(300, 300),
				buttonTex.getSlice(Rectanglei(0, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(32, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(64, 0, 32, 32)));
	auto slider = Slider(Rectanglei(0, 440, 640, 32), tex);
	auto carouselTex = engine.loadTexture("carousel.png");
	auto leftButtonTex = carouselTex.getSlice(Rectanglei(0, 0, 32, 32));
	auto rightButtonTex = carouselTex.getSlice(Rectanglei(128, 0, 32, 32));
	Array!Texture carouselOptions = Array!Texture([
        carouselTex.getSlice(Rectanglei(32, 0, 32, 32)),
        carouselTex.getSlice(Rectanglei(64, 0, 32, 32)),
        carouselTex.getSlice(Rectanglei(96, 0, 32, 32))
	]);
	auto carousel = Carousel(
		Button(Rectanglei(400, 0, 32, 32), Vectori(400, 0), leftButtonTex, leftButtonTex, leftButtonTex),
		Button(Rectanglei(464, 0, 32, 32), Vectori(464, 0), rightButtonTex, rightButtonTex, rightButtonTex),
		Vectori(432, 0), carouselOptions);
    int carouselOption = 0;
	while(engine.isOpen)
	{
		engine.begin(black, camera);
		scope(exit) engine.end(map);

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

        engine.inUIMode = true;
        engine.draw(white, Rectanglef(50, 50, 100, 10));
        if (button.draw(engine))
        {
            writeln("Button pressed");
        }
        camera.x = camera.x + 50;
        writeln(value = slider.draw(engine, value));
		carouselOption = carousel.draw(engine, carouselOption);
	}
}
