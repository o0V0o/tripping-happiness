local class = require('object')
local gl = require('openGL')

local Framebuffer = class()

function Framebuffer:__init()
	self.usrdata = gl.glCreateFramebuffer()
end

function Framebuffer:renderbuffer(target, buffertype, width, height)
	local buffer = gl.glCreateRenderbuffer()
	gl.glBindRenderBuffer(gl.GL_RENDERBUFFER, buffer)
	gl.glRenderBufferStorage(gl.GL_RENDERBUFFER, buffertype, width, height)
	gl.glFramebufferRenderbuffer( gl.GL_FRAMEBUFFER, target, gl.GL_RENDERBUFFER, buffer)
	gl.glBindRenderBuffer(gl.GL_RENDERBUFFER, gl.NULL_BUFFER)
end

function Framebuffer:attach(texture, target)
	self:bind()
	gl.glFramebufferTexture2D(gl.FRAMEBUFFER, target, gl.TEXTURE_2D, texture, 0)
	self:unbind()
end

function Framebuffer:bind()
	gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.usrdata)
end
function Framebuffer:unbind()
	gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, gl.NULL_BUFFER)
end


return Framebuffer
