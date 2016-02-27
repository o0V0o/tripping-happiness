precision highp float;

attribute vec4 position;
attribute vec3 normal;

uniform mat4 perspective;
uniform mat4 view;
uniform mat4 model;

varying vec3 fNormal;
varying vec3 fPosition;

void main()
{
	mat4 MV = view*model;
	mat4 MVP = perspective * MV;
	vec4 pos = vec4(position.xyz, 1.0);
	gl_Position = MVP * pos;
	fNormal = (MV * vec4(normal, 0.0)).xyz;
	fPosition = (MVP * pos).xyz;
}
