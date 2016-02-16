#version 330 core

attribute vec4 position;
attribute vec4 normal;
attribute vec4 color;

varying vec4 vNormal;
varying vec4 vColor;
varying vec4 vPos;

uniform mat4 mvpMatrix;

void main()
{
	gl_Position = mvpMatrix * position;
	vPos = mvpMatrix * position;

	vColor = color;
	vNormal = normal;
}
