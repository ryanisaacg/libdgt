module dgt.gl_backend;
import derelict.opengl;
import derelict.sdl2.sdl;

import dgt.array : Array;
import dgt.color : Color;
import dgt.geom;
import dgt.io;

///The default vertex shader
string DEFAULT_VERTEX_SHADER = "#version 150
in vec2 position;
in vec2 tex_coord;
in vec4 color;
uniform mat3 transform;
out vec4 Color;
out vec2 Tex_coord;
void main() {
	Color = color;
	Tex_coord = tex_coord;
	vec3 transformed = vec3(position, 1.0) * transform;
	transformed.z = 0;
	gl_Position = vec4(transformed, 1.0);
}";
///The default fragment shader
string DEFAULT_FRAGMENT_SHADER = "#version 150
in vec4 Color;
in vec2 Tex_coord;
out vec4 outColor;
uniform sampler2D tex;
void main() {
	vec4 tex_color = texture(tex, Tex_coord);
	outColor = Color * tex_color;
}";

///Represents a vertex to pass to OpenGL
struct Vertex
{
	Vector pos, texPos;
	Color col;

	@nogc nothrow:

	void print() const
	{
		dgt.io.print("Vertex(", pos, ", ", texPos, ", ", col, ")");
	}
}

/**
Handles opengl contexts and passing data to OpenGL such as shaders and vertices
*/
struct GLBackend
{
	//The draw data
	private GLuint texture = 0;
	public Array!float vertices;
	private Array!GLuint indices;

	private SDL_GLContext ctx;
	//OpenGL objects
	private GLuint shader, fragment, vertex, vbo, ebo, vao, texture_location;
	private string transformAttribute,
		positionAttribute,
		texPositionAttribute,
		colorAttribute, textureAttribute;
	private SDL_Window* window;
	public Transform transform;

	//The amount of floats per vertex
	private static immutable size_t vertex_size = 8;

    @disable this();
	@disable this(this);

	@trusted:
	package this(SDL_Window* window, bool vsync)
	{
		DerelictGL3.load();
		this.window = window;
		SDL_GL_SetSwapInterval(vsync ? 1 : 0);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		ctx = SDL_GL_CreateContext(window);
		DerelictGL3.reload();
        DerelictGL3.loadExtra();
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

	~this()
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

    /**
	Set the current shader and its attributes

	The GL backend passes a uniform 3x3 matrix to a uniform with a name
	given by 'transformAttributeName.' This matrix is a transformation
	applied to every vertex. Each vertex receives a vec2 of its position
	and texture coordinate, given by 'positionAttributeName' and
	'texPositionAttributeName.' Vertices also are blended with a color,
	given by 'colorAttributeName.' The texture is passed as a uniform
	sampler2D to 'textureAttributeName.' The output of the shader is a
	vec4 for a color, given by 'colorOutputName'
	*/
	public void setShader(in string vertexShader, 
		in string fragmentShader,
		in string transformAttributeName = "transform",
		in string positionAttributeName = "position",
		in string texPositionAttributeName = "tex_coord",
		in string colorAttributeName = "color",
		in string textureAttributeName = "tex",
		in string colorOutputName = "outColor")
	{
		transformAttribute = transformAttributeName;
		positionAttribute = positionAttributeName;
		texPositionAttribute = texPositionAttributeName,
		colorAttribute = colorAttributeName;
		textureAttribute = textureAttributeName;
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
		glBindFragDataLocation(shader, 0, colorOutputName.ptr);
		glLinkProgram(shader);
		glUseProgram(shader);
	}

    /**
    Clear the screen and the vertex and index buffers

    Any data that hasn't been drawn will be lost
    */
	public void clear(in Color col)
	{
		vertices.clear();
		indices.clear();
		glClearColor(col.r, col.g, col.b, col.a);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

    ///Draw the current vertices and indices and clear the buffers
	public void flush()
	{
		GLint transform_attrib = glGetUniformLocation(shader, transformAttribute.ptr);
		glUniformMatrix3fv(transform_attrib, 1, GL_FALSE, transform.ptr);
		//Bind the vertex data
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STREAM_DRAW);
		//Bind the index data
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STREAM_DRAW);
		//Set up the vertex attributes
		GLint posAttrib = glGetAttribLocation(shader, positionAttribute.ptr);
		glEnableVertexAttribArray(posAttrib);
		glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)0);
		GLint texAttrib = glGetAttribLocation(shader, texPositionAttribute.ptr);
		glEnableVertexAttribArray(texAttrib);
		glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)(2 * GLfloat.sizeof));
		GLint colAttrib = glGetAttribLocation(shader, colorAttribute.ptr);
		glEnableVertexAttribArray(colAttrib);
		glVertexAttribPointer(colAttrib, 4, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(void*)(4 * GLfloat.sizeof));
		//Upload the texture to the GPU
		texture_location = glGetUniformLocation(shader, textureAttribute.ptr);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture);
		glUniform1i(texture_location, 0);
		//Draw the triangles
		glDrawElements(GL_TRIANGLES, cast(int)indices.length, GL_UNSIGNED_INT, cast(void*)0);
		vertices.clear();
		indices.clear();
	}

    ///Flush the buffers and display the new screen
	public void flip()
	{
		flush();
		SDL_GL_SwapWindow(window);
	}


	private void switchTexture(in GLuint texture)
	{
		if (this.texture != 0)
			flush();
		this.texture = texture;
	}

    /**
    Add some vertices and indices to the backend

    The 0th index is the first vertex in this add, not since the last flush
    */
	public void add(in GLuint texture,
					in Vertex[] newVertices, in GLuint[] newIndices)
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
	auto vert = Vertex(Vector(0, 0), Vector(1, 1), Color(1, 1, 1, 1));
	println("Should print a white vertex at 0, 0 from 1, 1: ", vert);
}
