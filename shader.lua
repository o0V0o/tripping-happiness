local gl = require("openGL") --load a file that abstracts away where/how/what opengl is
local loadShader = require("loadshader")
local class = require("object")
local introspection = require("introspection")

local currentProgram
Shader = class()
function Shader:__init(vFile, fFile)
	self.prog = loadShader(vFile, fFile)
	local attributes, uniforms = introspection.inspect(self.prog)
	self.attributes = attributes
	self.uniforms = uniforms
	self.uniformValues = {}
	local offset = 0
	for _,attribute in ipairs(self.attributes) do
		attribute.stride = offset
		offset = offset + gl.sizeof(attribute.type)
	end
	for _,attribute in pairs(self.attributes) do
		gl.enableVertexAttribArray( attribute.idx )
	end
	self.loaded = true --indicates that further table acess will go to uniforms
end
function Shader:destroy()
	gl.glDeleteProgram(self.prog)
end
function Shader:__newindex(key, value)
	if self.uniforms and self.uniforms[key] then
		self.uniformValues[key] = value
		if self:active() then
			self.uniforms[key]:set(value)
		end
	elseif self.loaded then
		print("can't set uniform", key)
	else
		rawset(self, key, value)
	end
end
function Shader:use()
	if self:active() then return end
	gl.glUseProgram( self.prog)
	currentProgram = self.prog
	for key,value in pairs(self.uniformValues) do
			self.uniforms[key]:set(value)
	end
end
function Shader:active()
	return currentProgram==self.prog
end

return Shader
