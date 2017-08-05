import std.stdio, std.file;
import au;
import gl_backend;

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
		engine.ctx.add(tex.id,
			[Vertex(Vectorf(0, 0), Vectorf(0, 0), white),
			Vertex(Vectorf(32, 0), Vectorf(0, 0), white),
			Vertex(Vectorf(32, 32), Vectorf(0, 0), white),
			Vertex(Vectorf(0, 32), Vectorf(0, 0), white)

			],
			[0, 1, 2, 2, 3, 0]);
		engine.ctx.add(tex.id, [
			Vertex(Vectorf(100, 400), Vectorf(0, 0), white),
			Vertex(Vectorf(132, 400), Vectorf(0, 0), white),
			Vertex(Vectorf(132, 432), Vectorf(0, 0), white),
			Vertex(Vectorf(100, 432), Vectorf(0, 0), white)
			],
			[0, 1, 2, 2, 3, 0]
			);
		engine.ctx.add(tex.id, [
			Vertex(Vectorf(300, 400), Vectorf(0, 0), white),
			Vertex(Vectorf(332, 400), Vectorf(0, 0), white),
			Vertex(Vectorf(332, 432), Vectorf(0, 0), white),
			Vertex(Vectorf(300, 432), Vectorf(0, 0), white)
			],
			[0, 1, 2, 2, 3, 0]
			);

		engine.draw(tex, 200, 500, 32, 32);
		engine.draw(tex, 300, 500, 32, 32);

		engine.draw(red, Rectanglef(30, 30, 40, 40));
		engine.draw(blue, Rectanglef(100, 100, 40, 40));
		engine.draw(blue, Circlef(100, 100, 32));
		engine.end();
	}
	engine.destroy();
}
