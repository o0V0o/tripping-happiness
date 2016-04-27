local class = require('object')
local gl = require('openGL')

local Framebuffer = class()

--define some easy to remember enums...
local framebufferTargets = {
	color = gl.GL_COLOR_ATTACHMENT0,
	depth = gl.GL_DEPTH_ATTACHMENT,
}
local renderbufferTypes = {
	depth = gl.GL_DEPTH_COMPONENT16
}

function Framebuffer:__init()
	self.usrdata = gl.glCreateFramebuffer()
	self.target = gl.GL_FRAMEBUFFER --the bind target for framebuffers
	self.attachments = {}
end
--cleanup!
function Framebuffer:__gc()
	gl.glDeleteFramebuffer(self.usrdata)
end

--creates and attaches a renderbuffer to the specified target, with the
--specified buffer type. (optional width and height, if the framebuffer is not
--setup yet)
function Framebuffer:renderbuffer(width, height, target, buffertype)
	--Get the proper GL enums for the target and buffertype values
	buffertype = buffertype or target --if not specified, the two are the same.
	target = framebufferTargets[target] --get the GL enum for this target
	buffertype = renderbufferTypes[buffertype] --get the GL enum for this type

	--create and setup the Renderbuffer
	local buffer = gl.glCreateRenderbuffer()
	--gl.bindRenderbuffer(gl.RENDERBUFFER, depthBuffer);
	gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, buffer)
	gl.glRenderbufferStorage(gl.GL_RENDERBUFFER, buffertype, width, height)
	--attach the renderbuffer
	self:bind()
	gl.glFramebufferRenderbuffer( self.target, target, gl.GL_RENDERBUFFER, buffer)
	self:unbind()
	--unbind the renderbuffer
	gl.glBindRenderbuffer(gl.GL_RENDERBUFFER, gl.NULL_BUFFER)
	self.attachments[target] = {width=width, height=height}
end

function Framebuffer:attach(target, texture)
	target = framebufferTargets[target]

	self:bind()
	gl.glFramebufferTexture2D(self.target, target, texture.target, texture.texture, 0)
	self:unbind()
	self.attachments[target] = texture
end

-- finds the actual size of the FBO based on the size of all of its attachments
function Framebuffer:calculateSize()
	self.width = math.huge
	self.height = math.huge
	for target,object in pairs(self.attachments) do
		print("FBO", object.width, object)
		for k,v in pairs(object) do
			print(k,v)
		end
		self.width = math.min(self.width, object.width)
		self.height = math.min(self.height, object.height)
	end
end

--use the framebuffer as a render target.
--checks for a  width/height
--sets the viewport to said width/height
--Whatever has to be done to make things *easy*
function Framebuffer:use()
	Framebuffer.inUse = self --not using the default framebuffer! (note that this is a *static* variable,
	--make sure we have a size.
	if not self.width or not self.height then self:calculateSize() end
	self:bind()
	gl.glViewport(0,0,self.width, self.height)
end

function Framebuffer:bind()
	gl.glBindFramebuffer(self.target, self.usrdata)
end

function Framebuffer:unbind(setViewport)
	gl.glBindFramebuffer(self.target, gl.NULL_BUFFER)
	Framebuffer.inUse = nil
	if setViewport then gl.viewport(0,0,gl.canvas.width, gl.canvas.height) end
end

return Framebuffer
