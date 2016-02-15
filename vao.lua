local gl = require("OpenGl") --load a file that abstracts away where/how/what opengl is
local class = require('object')

local VAO = class()
--function VAO.new() return VAO a new VAO object
function VAO.__init(self)
	local vao = gl.glGenVertexArrays(1)
	self.usrdata = vao
end
--function VAO:destroy() free resources of this VAO object
function VAO:destroy()
	gl.glDeleteVertexArrays(1, self.usrdata)
	self.usrdata=nil
end
-- function VAO:bind() binds this VAO so it can be used
function VAO:bind()
	gl.glBindVertexArray(self.usrdata)
end
-- function VAO:unbind() unbinds this VAO so it can't be used.
function VAO:unbind()
	gl.glBindVertexArray(0) -- Disable VAO
end
-- function VAO:bindAttribute(Int location, VBO buffer, Int count, Int datatype, Bool normalize ) binds the VBO to this VAO at the location specified. after this call the VAO and VBO are unbound.
function VAO:bindAttribute(location, buffer, count, offset, normalize)
	assert(location, "invalid parameters to VAO.bindAttribute")
	assert(buffer, "invalid parameters to VAO.bindAttribute")
	count = count or buffer.dim or 1
	print(offset)
	offset = (offset or 0)*gl.sizeof(buffer.datatype)
	print(offset)
	normalize = normalize or false

	local stride = (buffer.dim) * gl.sizeof(buffer.datatype)
	local datatype = buffer.datatype

	print("binding attribute:", location, count, offset, stride)

	self:bind()
	buffer:bind()
	gl.glEnableVertexAttribArray(location)
	--bind active VBO to attribute location in this VAO.
	gl.glVertexAttribPointer(location, count, datatype, normalize, stride, offset)
	buffer:unbind()
	self:unbind()
end

return VAO
