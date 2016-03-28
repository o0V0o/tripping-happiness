local class = require('object')
local gl = require("openGL")

local Texture = class()

local activeTextureUnits = {}
local function findNextTextureUnit(texUnits)
	for i=0,#activeTextureUnits+1 do
		if not activeTextureUnits[i] then
			if not gl["GL_TEXTURE"..i] then return nil 
			else return i end
		end
	end
end

function Texture:__init(format, wrapmode, minfilter, magfilter, mipmap)
	self.format = self.format or gl.GL_RGBA
	self.wrapmode = wrapmode or gl.GL_REPEAT
	self.mipmap = mipmap
	self.minfilter = minfilter or (mipmap and gl.GL_LINEAR_MIPMAP_LINEAR) or gl.GL_LINEAR
	self.magfilter = magfilter or gl.GL_LINEAR

	self.texture = gl.createTexture()
	self.target = gl.GL_TEXTURE_2D --indicates the openGL bind target for this texture. 
end

function Texture:attachTextureUnit()
	if not self.texunitIdx then 
		--find the next available texture unit and use it for this texture.
		local idx = assert(findNextTextureUnit(activeTextureUnits), "can not active texture: no free texture unit")
		self.texunit = "GL_TEXTURE"..idx
		self.texunitIdx = idx
		activeTextureUnits[idx] = true

		self:setMode(self.wrapmode, self.minfilter, self.magfilter, self.mipmap)
	end

	return self.texunitIdx
end

function Texture:releaseTextureUnit()
	activeTextureUnits[self.texunitIdx] = nil
	self.texunitIdx = nil
	self.texunit = nil
end

--set the correct mode values in opengl
function Texture:setMode(wrapmode, minfilter, magfilter, mipmap)
	self:bind()
	print(".")
	gl.glTexParameteri(self.target, gl.GL_TEXTURE_WRAP_S, wrapmode)
	print(".")
	gl.glTexParameteri(self.target, gl.GL_TEXTURE_WRAP_T, wrapmode)
	print(".")
	gl.glTexParameteri(self.target, gl.GL_TEXTURE_MIN_FILTER, minfilter)
	print(".")
	gl.glTexParameteri(self.target, gl.GL_TEXTURE_MAG_FILTER, magfilter)
	self:unbind()
end



function Texture:unbind()
	if self.texunit then
		gl.glActiveTexture(gl[self.texunit]) --make sure we affect the right texture unit...
		gl.glBindTexture( self.target, gl.NULL_BUFFER )
	end
end
function Texture:bind()
	self:attachTextureUnit()
	gl.glActiveTexture(gl[self.texunit]) --make sure we affect the right texture unit...
	gl.glBindTexture( self.target, self.texture )
end

function Texture:buffer(img)
	-- the internal format can also be a compressed format, which is just variations on the actual pixel format. can implement that later
	self:bind()
	gl.glTexImage2D(self.target, 0, self.format, img.width, img.height, 0, self.format, img.datatype, img:glData() )
	self:unbind()
	self.width = img.width
	self.height = img.height
end

return Texture
