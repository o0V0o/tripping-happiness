precision highp float;

uniform vec3 color;

void main(){
	// color it
	gl_FragColor = vec4(color, 1.0);
}
