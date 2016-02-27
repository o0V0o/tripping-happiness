precision highp float;

varying vec3 fNormal;	//fragment normal direction
varying vec3 fPosition; //fragment position in *world* space.

vec3 light = vec3(10,30,10);

uniform vec3 color;
uniform float shininess;
uniform float kDiffuse;
uniform float kSpecular;

vec3 toonmap( float i ){
	i = clamp(i, 0.0, 1.0);
	i = i * 2.0;
	return (color * floor(i))/2.0;
}

void main(){
	vec3 v = -normalize(fPosition);
	vec3 n = normalize( fNormal );
	vec3 l = normalize(light-fPosition);// vector to light source
	vec3 r = normalize(2.0*(dot(l,n))*n-l);

	float edge = dot(n, v);
	float diffuse = 0.0;
	if( abs(edge) > 0.3 ){
		diffuse = max( dot(l,n), 0.0 );
	}

	float specular = max(dot(r,v), 0.0);
	specular = pow( specular, shininess);
	float intensity = kDiffuse*diffuse + kSpecular*specular;

	//gl_FragColor = vec4( color*(intensity), 1.0);
	gl_FragColor = vec4( toonmap(intensity), 1.0);
}
