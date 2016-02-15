local gl = require("OpenGl") --load a file that abstracts away where/how/what opengl is
local class = require("object")
local VBO = require('vbo')

local EAB = class(VBO)
function EAB.__init(self)
	self:super(gl.GL_UNSIGNED_INT)
	self.target = gl.GL_ELEMENT_ARRAY_BUFFER
end
--function EAB:bind() bind this buffer as an Element Array Buffer.
function EAB:bind()
	gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.usrdata)
end
--function EAB:unbind() unbind this element array buffer
function EAB:unbind()
	gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)
end

return EAB
