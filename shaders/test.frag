#version 330 core

varying vec4 vNormal;
varying vec4 vColor;
varying vec4 vPos;

uniform float _scale = 5;
uniform vec2 _origin = vec2(0.5 ,0.5 );
uniform int _iter = 10;

void main(){
	vec4 view = vec4(-1,-1,1,1);
	vec2 c = (vPos.xy + vec2(1,1))/2.0;
	c = vPos.xy;

	float i;
	//for(i=0;i<_iter;i++){
		vec2 p = (c - view.xy) * ( view.xy - view.zw);
		int idx = int(floor(mod(c.x*3.0,3.0)));
		//idx = int(c.x * 3) ;
		// test which block c is in
		vec4 center = view/3.0;
		
	//}
	gl_FragColor = vec4(idx*.5,0,0,1);
}

/*
void main(){

	vec2 c = vPos.xy  * _scale + _origin;
	vec2 z = c;

	float i;
	for(i=0;i<_iter;i++){
		z = vec2( z.x*z.x - z.y*z.y, z.y*z.x + z.y*z.x ) + c;
		if( length(z) >= 2 ){
			break;
		}
	}
	i = i/_iter;


	// color it!
	gl_FragColor = vec4(i,i,i,1);
}
*/
