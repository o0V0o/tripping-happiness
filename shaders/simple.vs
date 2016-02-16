precision highp float;

attribute vec4 position;
uniform mat4 mvpMatrix;

void main()
{
	vec4 pos = vec4(position.xyz, 1.0);
	gl_Position = mvpMatrix * pos;
}
