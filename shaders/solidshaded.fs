precision highp float;

varying vec3 fNormal;	//fragment normal direction
varying vec3 fPosition; //fragment position in *world* space.

vec3 light = vec3(10,10,10);
vec3 eye = vec3(0,0,0);

uniform vec3 color;

void main(){
	vec3 l = normalize(light-fPosition);// vector to light source
	vec3 n = normalize( fNormal );
	float diffuse = max( dot(l,n), 0.0 );

	gl_FragColor = vec4( diffuse*color, 1.0);
}
