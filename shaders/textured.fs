precision highp float;

varying vec3 fNormal;	//fragment normal direction
varying vec3 fPosition; //fragment position in *world* space.
varying vec2 fTexCoord;	//fragment UV coordinates in texture space

vec3 light = vec3(10,30,10);

uniform vec3 color;
uniform vec3 specColor;
uniform sampler2D diffuseTexture;
uniform float shininess;
uniform float kDiffuse;
uniform float kSpecular;
uniform float kAmbient;


void main(){
	vec3 v = -normalize(fPosition);
	vec3 n = normalize( fNormal );
	vec3 l = normalize(light-fPosition);// vector to light source
	//vec3 r = normalize(2.0*(dot(l,n))*n-l);
	vec3 r = normalize(reflect(l,n));

	float edge = dot(n, v);
	float diffuse = 0.0;
	diffuse = max( dot(l,n), 0.0 );

	float specular = max(dot(r,v), 0.0);
	specular = pow( specular, shininess);

	vec4 diffuseColor = texture2D(diffuseTexture, fTexCoord);
	diffuseColor = vec4( diffuseColor.xyz*diffuseColor.w + color*(1.0-diffuseColor.w), kDiffuse*(diffuse+kAmbient));
	//diffuseColor = vec4(color,kDiffuse*(diffuse+kAmbient));
	vec4 specularColor = vec4(specColor, kSpecular*specular);
	gl_FragColor = vec4( diffuseColor.xyz*diffuseColor.w + specularColor.xyz*specularColor.w, 1.0 );
}
