precision highp float;

attribute vec4 position;
attribute vec3 normal;
attribute vec2 vTex;

uniform mat4 mvpMatrix;
uniform mat4 perspective;
uniform mat4 model;
uniform mat4 view;

varying vec3 fNormal;
varying vec3 fPosition;
varying vec2 fTexCoord;

void main()
{
	mat4 MV = view * model;
	mat4 MVP = perspective * MV;
	vec4 pos = vec4(position.xyz, 1.0);
	gl_Position = MVP * pos;
	fNormal = ((MV * vec4(normal, 1.0)) - (MV * vec4(0.0,0.0,0.0,1.0))).xyz;
	fPosition = (MVP * pos).xyz;
	fTexCoord = vTex;
}
