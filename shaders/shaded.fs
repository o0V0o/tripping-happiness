#version 330 core

varying vec4 vNormal;
varying vec4 vColor;

void main(){
	// color it!
	gl_FragColor = vec4(vNormal.rgb + vec3(.1,.1,.1), 1.0);
}
