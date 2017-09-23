import std.stdio, std.file;
import dgt;
import std.datetime;

void main()
{
	WindowConfig config = { resizable : true, vsync : false };
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
	vec3 transformed = vec3(pos, 1.0) * trans;
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
    auto atlas = Atlas("example/atlas.txt");
    scope(exit) atlas.destroy();
    auto tex = atlas["test"];
	auto map = Tilemap!bool(640, 480, 32);
	scope(exit) map.destroy();
    float n = 0;
    auto buttonTex = atlas["button"];
    auto camera = Rectangle(0, 0, 640, 480);
    float value = 0;
	auto button = Button(Rectangle(300, 300, 32, 32), Vector(300, 300),
				buttonTex.getSlice(Rectangle(0, 0, 32, 32)),
				buttonTex.getSlice(Rectangle(32, 0, 32, 32)),
				buttonTex.getSlice(Rectangle(64, 0, 32, 32)));
	auto slider = Slider(Rectangle(0, 440, 640, 32), tex);
	auto carouselTex = atlas["carousel"];
	auto leftButtonTex = carouselTex.getSlice(Rectangle(0, 0, 32, 32));
	auto rightButtonTex = carouselTex.getSlice(Rectangle(128, 0, 32, 32));
	auto carouselOptions = [
        carouselTex.getSlice(Rectangle(32, 0, 32, 32)),
        carouselTex.getSlice(Rectangle(64, 0, 32, 32)),
        carouselTex.getSlice(Rectangle(96, 0, 32, 32))
	];
	auto carousel = Carousel(
		Button(Rectangle(400, 0, 32, 32), Vector(400, 0), leftButtonTex, leftButtonTex, leftButtonTex),
		Button(Rectangle(464, 0, 32, 32), Vector(464, 0), rightButtonTex, rightButtonTex, rightButtonTex),
		Vector(432, 0), carouselOptions);
    int carouselOption = 0;
	auto font = Font("example/DejaVuSansMono.ttf", 14, FontStyle.normal);
    auto rect = Rectangle(0, 0, 20, 20);
    engine.loop((ref Window window) {
        window.begin(Color.black);
		engine.draw(tex, 100, 0, 32, 32);
		engine.draw(tex, 200, 400, 32, 32);
		engine.draw(tex, 300, 400, 32, 32);

		engine.draw(Color.red, Rectangle(30, 30, 40, 40));
		engine.draw(Color.blue, Rectangle(100, 100, 40, 40));
		engine.draw(Color(0, 1, 0, 0.5), Circle(100, 100, 32));

		engine.draw(font, "abcdef ghijkl\nmopqrstuvwxyz", 200, 200, 60, Color.green, false, 2);

        if(engine.gamepads.length)
            if(engine.gamepads[0].faceDown)
                writeln("Face button down");

        engine.inUIMode = true;
        engine.draw(Color.white, Rectangle(50, 50, 100, 10));
        if (button.draw(engine))
            writeln("Button pressed");
		n = slider.draw(engine, n);
		carouselOption = carousel.draw(engine, carouselOption);

        window.draw(Color.blue, rect);

        window.end();
    }, (ref Window window) {
        rect.y = rect.y + 1;
    });
}
