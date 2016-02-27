local gl = require("openGL")
local ctypes = require("ctypes")
local class = require("object")

local I = {}

local Attribute = class()
function Attribute:__init(info)
	self.name = info.name
	self.type = info.type
	self.typename = gl.constant(info.type)
	self.size = info.size
end
function Attribute:__tostring()
	local s = {}
	table.insert(s, "Attribute: ")
	table.insert(s, self.name)
	table.insert(s, "\n\ttype: ")
	table.insert(s, self.type)
	table.insert(s, "\n\tsize: ")
	table.insert(s, self.size)
	return table.concat(s)
end


local setters = {
	[gl.GL_FLOAT]=function(self,v) gl.glUniform1f(self.idx, v) end,
	[gl.GL_FLOAT_VEC2]=function(self,v) gl.glUniform2fv(self.idx, ctypes.floatArray(v)) end,
	[gl.GL_FLOAT_VEC3]=function(self,v) gl.glUniform3fv(self.idx, ctypes.floatArray(v)) end,
	[gl.GL_FLOAT_VEC4]=function(self,v) gl.glUniform4fv(self.idx, ctypes.floatArray(v)) end,

	[gl.GL_INT]=function(self,v) gl.glUniform1i(self.idx, v) end,
	[gl.GL_INT_VEC2]=function(self,v) gl.glUniform2iv(self.idx, ctypes.intArray(v)) end,
	[gl.GL_INT_VEC3]=function(self,v) gl.glUniform3iv(self.idx, ctypes.intArray(v)) end,
	[gl.GL_INT_VEC4]=function(self,v) gl.glUniform4iv(self.idx, ctypes.intArray(v)) end,
	[gl.GL_FLOAT_MAT4]=function(self,v) gl.glUniformMatrix4fv(self.idx, false, v.usrdata) end,

	[gl.GL_SAMPLER_2D]=function(self,v) gl.glUniform1i(self.idx, v) end
}
setters = setmetatable(setters, {__index=function(t,k)
	return function(self,v) print("no such uniform handler", gl.constant(k)) end
end})

local Uniform = class()
function Uniform:__init(info)
	self.name = info.name
	self.type = info.type
	self.size = info.size
end
function Uniform:set(v)
	setters[self.type](self, v)
end
function Uniform:__tostring()
	local s = {}
	table.insert(s, "Uniform: ")
	table.insert(s, self.name)
	table.insert(s, "\n\ttype: ")
	table.insert(s, self.type)
	table.insert(s, "\n\tsize: ")
	table.insert(s, self.size)
	return table.concat(s)
end

function I.inspect(program)
	local n = gl.glGetProgramiv(program, gl.GL_ACTIVE_ATTRIBUTES)
	--WebGLActiveInfo {name='...', size=n, type=?}
	local attributes = {}
	for i=0,n-1 do
		local info = gl.glGetActiveAttrib(program, i)
		table.insert(attributes, info)
	end

	local attributeObjs = {}
	for k,v in pairs(attributes) do
		attributeObjs[v.name] = Attribute(v)
		attributeObjs[v.name].idx = gl.glGetAttribLocation(program, v.name)
	end

	local n = gl.glGetProgramiv(program, gl.GL_ACTIVE_UNIFORMS)
	local uniforms = {}
	for i=0,n-1 do
		local info = gl.glGetActiveUniform(program, i)
		table.insert(uniforms, info)
	end

	local uniformObjs = {}
	for k,v in pairs(uniforms) do
		uniformObjs[v.name] = Uniform(v)
		uniformObjs[v.name].idx = gl.getUniformLocation(program, v.name)
	end

	return attributeObjs, uniformObjs
end

return I
