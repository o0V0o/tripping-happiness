local gl = require("openGL") --load a file that abstracts away where/how/what opengl is
local class = require("object")
local VBO = require('vbo')

local EAB = class(VBO)
function EAB.__init(self, hints)
	VBO.__init(self, gl.GL_UNSIGNED_SHORT, hints)
	--self:super(gl.GL_UNSIGNED_INT, hints)
	self.target = gl.GL_ELEMENT_ARRAY_BUFFER
end

return EAB
