import std.stdio, std.file;
import dgt;
import std.datetime;

void main()
{
	WindowConfig config = { resizable : true, vsync : true };
	Window engine = Window("Test title", 640, 480, config);
	engine.setShader(
"#version 150
in vec2 pos;
in vec2 texPos;
in vec4 col;
uniform mat3 trans;
out vec4 Color;
out vec2 Tex_coord;
void main() {
	Color = col;
	Tex_coord = texPos;
	vec3 transformed = trans * vec3(pos, 1.0);
	transformed.z = 0;
	gl_Position = vec4(transformed, 1.0);
}",
"#version 150
in vec4 Color;
in vec2 Tex_coord;
out vec4 outCol;
uniform sampler2D image;
void main() {
	vec4 tex_color = texture(image, Tex_coord);
	outCol = Color * tex_color;
}",
"trans",
"pos",
"texPos",
"col",
"image",
"outCol"
);
	auto level = Level("example/example.json");
    auto tex = Texture("example/test.png");
	scope(exit) tex.destroy();
	auto map = Tilemap!bool(640, 480, 32);
	scope(exit) map.destroy();
    float n = 0;
    auto buttonTex = Texture("example/button.png");
    auto camera = Rectanglei(0, 0, 640, 480);
    float value = 0;
	auto button = Button(Rectanglei(300, 300, 32, 32), Vectori(300, 300),
				buttonTex.getSlice(Rectanglei(0, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(32, 0, 32, 32)),
				buttonTex.getSlice(Rectanglei(64, 0, 32, 32)));
	auto slider = Slider(Rectanglei(0, 440, 640, 32), tex);
	auto carouselTex = Texture("example/carousel.png");
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
	auto font = Font("example/DejaVuSansMono.ttf", 14, Color.white, FontStyle.normal);
	while(engine.isOpen)
	{
		engine.begin(Color.black);
		scope(exit) engine.end();

		engine.draw(tex, 100, 0, 32, 32);
		engine.draw(tex, 200, 400, 32, 32);
		engine.draw(tex, 300, 400, 32, 32);

		engine.draw(Color.red, Rectanglei(30, 30, 40, 40));
		engine.draw(Color.blue, Rectanglei(100, 100, 40, 40));
		engine.draw(Color(0, 1, 0, 0.5), Circlei(100, 100, 32));

		engine.draw(font, "abcdef ghijkl\nmopqrstuvwxyz", 200, 200, 60, false, 2);

        if(engine.gamepads.length)
            if(engine.gamepads[0].faceDown)
                writeln("Face button down");

        engine.inUIMode = true;
        engine.draw(Color.white, Rectanglei(50, 50, 100, 10));
        if (button.draw(engine))
            writeln("Button pressed");
		n = slider.draw(engine, n);
		carouselOption = carousel.draw(engine, carouselOption);
	}
}
