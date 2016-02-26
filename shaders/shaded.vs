precision highp float;

attribute vec4 position;
attribute vec3 normal;

uniform mat4 mvpMatrix;
uniform mat4 perspective;

varying vec3 fNormal;
varying vec3 fPosition;

void main()
{
	vec4 pos = vec4(position.xyz, 1.0);
	gl_Position = perspective * mvpMatrix * pos;
	fNormal = (mvpMatrix * vec4(normal, 0.0)).xyz;
	fPosition = ((mvpMatrix * pos).xyz)/pos.w;
}
