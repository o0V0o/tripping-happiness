#version 330 core

varying vec4 vNormal;
varying vec4 vColor;
varying vec4 vPos;

uniform float _scale = .1;
uniform vec2 _origin = vec2(.17 , .58 );
uniform int _iter = 256;


vec3 color( float i ){
	float r = 1/(_scale*3);
	float g = (i*i*i / 1000)*tan(i);
	float b = cos(i/10);
	return vec3(r,g*.1,b);
	//return vec3(r,0,0);
}

void main(){

	vec2 c = vPos.xy  * _scale + _origin;
	vec2 z = c;

	float i;
	for(i=0;i<_iter;i++){
		z = vec2( z.x*z.x - z.y*z.y, z.y*z.x + z.y*z.x ) + c;
		//z= dot(z,z) + c;
		//if( length(z) >= 2 ){
		if( dot(z,z) >= 4 ){
			break;
		}
	}
	//i = i/_iter;


	// color it!
	gl_FragColor = vec4( color(i), 1);
}
