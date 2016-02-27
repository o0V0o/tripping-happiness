jsInstanceOf = function(obj, type){
	return obj instanceof type
}
jsCallback = function(proxy){
	return function(){ proxy()}
}
jsMatUniform = function(gl, program){
	var loc = gl.getUniformLocation(program, "mvpMatrix")
}
jsArray = function(table){
	var array = [];
	var i=1;
	while(typeof (table.get(i)) !== 'undefined'){
		array[i-1] = table.get(i);
		i=i+1;
	}
	return array;
}
jsInt16Array = function(table){
	var array = jsArray(table);
	var intArray = new Uint16Array(array);
	return intArray
}
jsInt32Array = function(table){
	var array = jsArray(table);
	var intArray = new Int32Array(array);
	return intArary
}
jsFloat32Array = function(table){
	var array = jsArray(table);
	var floatArray = new Float32Array(array);
	return floatArray
}
