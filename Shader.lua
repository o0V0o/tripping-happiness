local gl = require("OpenGl") --load a file that abstracts away where/how/what opengl is
local loadShader = require("loadshader")
local class = require("object")

Shader = class()
function Shader.__init(self, vFile, fFile)

	self.prog = loadShader(vFile, fFile)
	local attributes, uniforms = introspection.inspect(self.prog)
	self.attributes = attributes
	self.uniforms = uniforms

	table.insert(G.resources, self) --we are a GC collectable resources.
end
function Shader:destroy()
	gl.glDeleteProgram(self.prog)
end
function Shader:__newindex(key, value)
	self.uniforms[key]:set(value)
end
function Shader:use()
	gl.glUseProgram( prog)
end

return Shader
