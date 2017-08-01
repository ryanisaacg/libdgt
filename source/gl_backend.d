import derelict.opengl3.gl;
import derelict.sdl2.sdl;

import array : Array;
import color : Color;

const GLchar* vertex_shader = "#version 130 
in vec3 position; 
in vec2 tex_coord; 
in vec4 color; 
uniform mat4 transform; 
out vec4 Color; 
out vec2 Tex_coord; 
void main() { 
	Color = color; 
	Tex_coord = tex_coord; 
	gl_Position = transform * vec4(position, 1.0); 
}";
const GLchar* fragment_shader = "#version 130
in vec4 Color; 
in vec2 Tex_coord; 
out vec4 outColor; 
uniform sampler2D tex; 
void main() { 
	vec4 tex_color = texture(tex, Tex_coord);
	outColor = Color * tex_color;
}";

struct GLBackend 
{
	//The draw data
	private Array!GLuint textureIDs;
	private Array!float vertices;
	private Array!GLuint indices;

	private SDL_GLContext ctx;
	//OpenGL opbjects
	private GLuint shader, fragment, vertex, vbo, ebo, vao, texture_location;
	private SDL_Window* window;

	//The amount of floats per vertex
	private static immutable size_t vertex_size = 8;

	public void init(SDL_Window* window)
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
		//Create and compile shaders
		vertex = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vertex, 1, &vertex_shader, null);
		glCompileShader(vertex);
		GLint status;
		glGetShaderiv(vertex, GL_COMPILE_STATUS, &status);
		if (status != GL_TRUE) 
		{
			//TODO: Print vertex shader failure message
			/* printf("Vertex shader compilation failed\n");
			char[512] buffer;
			glGetShaderInfoLog(ctx.vertex, 512, NULL, buffer);
			printf("Error: %s\n", buffer);
			exit(-1); */
		}
		fragment = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fragment, 1, &fragment_shader, null);
		glCompileShader(fragment);
		glGetShaderiv(fragment, GL_COMPILE_STATUS, &status);
		if (status != GL_TRUE) 
		{
			//TODO: Print fragment shader failure message
			/* printf("Fragment shader compilation failed\n");
			char buffer[512];
			glGetShaderInfoLog(ctx.fragment, 512, null, buffer);
			printf("Error: %s\n", buffer);
			exit(-1); */
		}
		shader = glCreateProgram();
		glAttachShader(shader, vertex);
		glAttachShader(shader, fragment);
		glBindFragDataLocation(shader, 0, "outColor");
		glLinkProgram(shader);
		glUseProgram(shader);
	//	glEnable (GL_DEPTH_TEST);
		glEnable (GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  
	}

	@nogc nothrow:
	void destroy() 
	{
		textureIDs.destroy();
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
}
