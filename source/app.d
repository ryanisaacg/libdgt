import std.stdio, std.file;
import dgt;
import std.datetime;

void main()
{
	WindowConfig config = { resizable : true, highdpi : true };
	Window engine = Window("Test title", 640, 480, config);
	auto tex = Texture("test.png");
	scope(exit) tex.destroy();
	auto map = Tilemap!bool(640, 480, 32);
	scope(exit) map.destroy();
    float n = 0;
    auto buttonTex = Texture("button.png");
    auto camera = Rectanglei(0, 0, 640, 480);
    float value = 0;
	auto button = Button(Rectanglei(300, 300, 32, 32), Vectori(300, 300),
				buttonTex.getSlice(Rectanglei(0, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(32, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(64, 0, 32, 32)));
	auto slider = Slider(Rectanglei(0, 440, 640, 32), tex);
	auto carouselTex = Texture("carousel.png");
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

		engine.draw(red, Rectanglei(30, 30, 40, 40));
		engine.draw(blue, Rectanglei(100, 100, 40, 40));
		engine.draw(Color(0, 1, 0, 0.5), Circlei(100, 100, 32));

        if(engine.gamepads.length)
            if(engine.gamepads[0].faceDown)
                writeln("Face button down");

        engine.inUIMode = true;
        engine.draw(white, Rectanglei(50, 50, 100, 10));
        if (button.draw(engine))
            writeln("Button pressed");
		n = slider.draw(engine, n);
		carouselOption = carousel.draw(engine, carouselOption);
	}
}
