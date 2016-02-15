local gl = require("openGL")
local class = require("object")

local Attribute = class()
function Attribute:__init(info)
	self.name = info.name
	self.type = info.type
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
	gl.GL_FLOAT = {
		1=function(self,v) gl.glUniform1f(self.idx, v) end,
		2=function(self,v) gl.glUniform2fv(self.idx, table.unpack(v)) end,
		3=function(self,v) gl.glUniform3fv(self.idx, table.unpack(v)) end,
		4=function(self,v) gl.glUniform4fv(self.idx, table.unpack(v)) end,
		},
	gl.GL_INT = {
		1=function(self,v) gl.glUniform1i(self.idx, v) end,
		2=function(self,v) gl.glUniform2iv(self.idx, table.unpack(v)) end,
		3=function(self,v) gl.glUniform3iv(self.idx, table.unpack(v)) end,
		4=function(self,v) gl.glUniform4iv(self.idx, table.unpack(v)) end,
		}
}

local Uniform = class()
function Uniform:__init(info)
	self.name = info.name
	self.type = info.type
	self.size = info.size
end
function Uniform:set(v)
	local ok,err = pcall(setters[self.type][self.size], self, v)
	if not ok then print("err on set:", self) end
	assert(ok, err)
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

function inspect(program)
	local n = gl.glGetProgramiv(program, gl.GL_ACTIVE_ATTRIBUTES)
	--WebGLActiveInfo {name='...', size=n, type=?}
	local attributes = {}
	for i=1,n do
		local info = gl.glGetActiveAttrib(program, i)
		table.insert(attributes, info)
	end

	local attributeObjs = {}
	for k,v in attributes do
		attributeObjs[v.name] = Attribute(v)
	end

	local n = gl.glGetProgramiv(program, gl.GL_ACTIVE_ATTRIBUTES)
	local uniforms = {}
	for i=1,n do
		local info = gl.glGetActiveUniform(program, i)
		table.insert(uniforms, info)
	end

	local attributeObjs = {}
	for k,v in attributes do
		attributeObjs[v.name] = Attribute(v)
	end

	return attributeObjs, uniformObj
end
