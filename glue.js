// add a shim for browsers that don't support slicing Typed Arrays
function sliceShim(begin, end){
	//use sane defaults
	begin = begin || 0
	console.log("shim!", end, this.length)
	end = Math.min(end, this.length) || this.length
	// handle negative values
	begin = (begin >= 0) ? begin : Math.max(0, this.length+begin)
	end = (end >= 0) ? end : Math.max(0, this.length+end)
	//calculate needed buffer size, and allocate it
	var size = Math.max(end-begin, 0)
	var clone = new Array(size)
	//finally, copy each and every element.
	for(i=0;i<size;i++){
		clone[i] = this[begin+i]
	}
	return  clone
}
if(!Float32Array.prototype.slice){
	Float32Array.prototype.slice = sliceShim
}
if(!Int32Array.prototype.slice){
	Int32Array.prototype.slice = sliceShim
}
if(!Uint16Array.prototype.slice){
	Uint16Array.prototype.slice = sliceShim
}

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
nullValue = null
