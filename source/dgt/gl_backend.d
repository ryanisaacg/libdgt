module dgt.gl_backend;
import derelict.opengl3.gl;
import derelict.sdl2.sdl;

import dgt.array : Array;
import dgt.color : Color;
import dgt.geom;
import dgt.io;

string DEFAULT_VERTEX_SHADER = "#version 130
in vec2 position;
in vec2 tex_coord;
in vec4 color;
uniform mat3 transform;
out vec4 Color;
out vec2 Tex_coord;
void main() {
	Color = color;
	Tex_coord = tex_coord;
	vec3 transformed = transform * vec3(position, 1.0);
	transformed.z = 0;
	gl_Position = vec4(transformed, 1.0);
}";
string DEFAULT_FRAGMENT_SHADER = "#version 130
in vec4 Color;
in vec2 Tex_coord;
out vec4 outColor;
uniform sampler2D tex;
void main() {
	vec4 tex_color = texture(tex, Tex_coord);
	outColor = Color * tex_color;
}";

struct Vertex
{
	Vectorf pos, texPos;
	Color col;

	@nogc nothrow:

	void print() const
	{
		dgt.io.print("Vertex(", pos, ", ", texPos, ", ", col, ")");
	}
}

struct GLBackend
{
	//The draw data
	private GLuint texture = 0;
	public Array!float vertices;
	private Array!GLuint indices;

	private SDL_GLContext ctx;
	//OpenGL objects
	private GLuint shader, fragment, vertex, vbo, ebo, vao, texture_location;
	private SDL_Window* window;
	public Transform!float transform;

	//The amount of floats per vertex
	private static immutable size_t vertex_size = 8;

    @disable this();

	public this(SDL_Window* window)
	{
		DerelictGL3.load();
		this.window = window;
		SDL_GL_SetSwapInterval(1);
		ctx = SDL_GL_CreateContext(window);
		DerelictGL3.reload();
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);
		glGenBuffers(1, &vbo);
		glGenBuffers(1, &ebo);
		setShader(DEFAULT_VERTEX_SHADER, DEFAULT_FRAGMENT_SHADER);
		glEnable (GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		vertices = Array!float(1024);
		indices = Array!GLuint(1024);
	}

	@nogc nothrow:
	public void setShader(string vertexShader, string fragmentShader)
	{
		if(shader != 0) glDeleteProgram(shader);
		if(vertex != 0) glDeleteShader(vertex);
		if(fragment != 0) glDeleteShader(fragment);
		vertex = glCreateShader(GL_VERTEX_SHADER);
		auto vertexShaderPtr = vertexShader.ptr;
		glShaderSource(vertex, 1, cast(GLchar**)(&vertexShaderPtr), null);
		glCompileShader(vertex);
		GLint status;
		glGetShaderiv(vertex, GL_COMPILE_STATUS, &status);
		if (status != GL_TRUE)
		{
			println("Vertex shader compilation failed");
			char[512] buffer;
			GLsizei length;
			glGetShaderInfoLog(vertex, 512, &length, buffer.ptr);
			println("Error: ", buffer[0..length]);
			setShader(DEFAULT_VERTEX_SHADER, fragmentShader);
		}
		fragment = glCreateShader(GL_FRAGMENT_SHADER);
		auto fragmentShaderPtr = fragmentShader.ptr;
		glShaderSource(fragment, 1, cast(GLchar**)(&fragmentShaderPtr), null);
		glCompileShader(fragment);
		glGetShaderiv(fragment, GL_COMPILE_STATUS, &status);
		if (status != GL_TRUE)
		{
			println("Fragment shader compilation failed\n");
			char[512] buffer;
			GLsizei length;
			glGetShaderInfoLog(vertex, 512, &length, buffer.ptr);
			println("Error: ", buffer[0..length]);
			setShader(vertexShader, DEFAULT_FRAGMENT_SHADER);
		}
		shader = glCreateProgram();
		glAttachShader(shader, vertex);
		glAttachShader(shader, fragment);
		glBindFragDataLocation(shader, 0, "outColor");
		glLinkProgram(shader);
		glUseProgram(shader);
	}

	public void destroy()
	{
		vertices.destroy();
		indices.destroy();
		glDeleteProgram(shader);
		glDeleteShader(fragment);
		glDeleteShader(vertex);

		glDeleteBuffers(1, &vbo);
		glDeleteBuffers(1, &ebo);

		glDeleteVertexArrays(1, &vao);
		SDL_GL_DeleteContext(ctx);
	}

	public void clear(Color col)
	{
		vertices.clear();
		indices.clear();
		glClearColor(col.r, col.g, col.b, col.a);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	public void flush()
	{
		GLint transform_attrib = glGetUniformLocation(shader, "transform");
		glUniformMatrix3fv(transform_attrib, 1, GL_FALSE, transform.ptr);
		//Bind the vertex data
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STREAM_DRAW);
		//Bind the index data
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STREAM_DRAW);
		//Set up the vertex attributes
		GLint posAttrib = glGetAttribLocation(shader, "position");
		glEnableVertexAttribArray(posAttrib);
		glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)0);
		GLint texAttrib = glGetAttribLocation(shader, "tex_coord");
		glEnableVertexAttribArray(texAttrib);
		glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)(2 * GLfloat.sizeof));
		GLint colAttrib = glGetAttribLocation(shader, "color");
		glEnableVertexAttribArray(colAttrib);
		glVertexAttribPointer(colAttrib, 4, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)(4 * GLfloat.sizeof));
		//Upload the texture to the GPU
		texture_location = glGetUniformLocation(shader, "tex");
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture);
		glUniform1i(texture_location, 0);
		//Draw the triangles
		glDrawElements(GL_TRIANGLES, cast(int)indices.length, GL_UNSIGNED_INT, cast(void*)0);
		vertices.clear();
		indices.clear();
	}

	public void flip()
	{
		flush();
		SDL_GL_SwapWindow(window);
	}

	private void switchTexture(GLuint texture)
	{
		if (this.texture != 0)
			flush();
		this.texture = texture;
	}

	public void add(size_t Vertices, size_t Indices)(GLuint texture,
					ref Vertex[Vertices] newVertices, ref GLuint[Indices] newIndices)
	{
		if(this.texture != texture)
			switchTexture(texture);
		auto offset = vertices.length / vertex_size;
		foreach(v; newVertices)
			vertices.addAll(v.pos.x, v.pos.y, v.texPos.x, v.texPos.y,
				v.col.r, v.col.g, v.col.b, v.col.a);
		foreach(i; newIndices)
			indices.add(cast(uint)(i + offset));
	}
}
unittest
{
	auto vert = Vertex(Vectorf(0, 0), Vectorf(1, 1), Color(1, 1, 1, 1));
	println("Should print a white vertex at 0, 0 from 1, 1: ", vert);
}
unittest
{
	import dgt;
    WindowConfig config;
	config.resizable = true;
	Window window = new Window("Test title", 640, 480, config);
    window.setShader("broken", "broken");
}
