local gl = require("openGL") --load a file that abstracts away where/how/what opengl is
local class = require('object')


local VBO = class()
--function VBO.new() return VBO a new VBO object
function VBO.__init(self, datatype, hints)
	local vbo = gl.glGenBuffers(1)
	self.usrdata = vbo
	self.target = gl.GL_ARRAY_BUFFER
	self.datatype = datatype or gl.GL_FLOAT
	self.hints = hints or gl.GL_DYNAMIC_DRAW
end
--function VBO:destroy() free resources of this VBO object
function VBO:destroy()
	gl.glDeleteBuffers(1, self.usrdata)
	self.usrdata=nil
end
--function VBO:bufferData([GLFloat] data, GLint bufferType, GLint hints)
--move a float array into this VBO, using the given buffer type and buffer hints. If not provided, bufferType defaults to GL_ARRAY_BUFFER, hints defaults to GL_STATIC_DRAW
function VBO:bufferData(data, target, hints)
	target = target or self.target
	hints = hints or self.hints
	self:bind(target)
	gl.glBufferData( target, gl.sizeof(self.datatype)*#data, data, hints)
	self:unbind(target)
	self.data = data -- keep a reference to data to prevent GC (who cares?)
end
--function VBO:bind(GLint target) bind this buffer to the specified target, or to GL_ARRAY_BUFFER if not specified
function VBO:bind(target)
	target = target or self.target
	gl.glBindBuffer(target, self.usrdata)
end
--function VBO:unbind(GLint target) remove any binding for the specified target, or for GL_ARRAY_BUFFER if not specified
function VBO:unbind(target)
	target = target or self.target
	gl.glBindBuffer(target, gl.NULL_BUFFER)
end

function VBO:useForAttribute( attrib, normalize,stride,offset)
	normalize = normalize or false
	self:bind()
	gl.glVertexAttribPointer( attrib.idx, gl.sizeof(attrib.type)/gl.sizeof(gl.GL_FLOAT), self.datatype, normalize, stride or 0, offset or 0)
	self:unbind()
end

return VBO
