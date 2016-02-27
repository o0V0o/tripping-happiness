local class = require('object')
local gl = require("openGL")

local Texture = class()

function Texture:__init(format, wrapmode, minfilter, magfilter, mipmap)
	self.format = self.format or gl.GL_RGB
	self.wrapmode = wrapmode or gl.GL_REPEAT
	self.minfilter = minfilter or (mipmap and gl.GL_LINEAR_MIPMAP_LINEAR) or gl.GL_LINEAR
	self.magfilter = magfilter or gl.GL_LINEAR

	self.texture = gl.createTexture()
	self.texdim = gl.GL_TEXTURE_2D

	self:setMode(self.wrapmode, self.minfilter, self.magfilter, self.mipmap)
end
function Texture:setMode(wrapmode, minfilter, magfilter, mipmap)
	self:bind()
	print(".")
	gl.glTexParameteri(self.texdim, gl.GL_TEXTURE_WRAP_S, wrapmode)
	print(".")
	gl.glTexParameteri(self.texdim, gl.GL_TEXTURE_WRAP_T, wrapmode)
	print(".")
	gl.glTexParameteri(self.texdim, gl.GL_TEXTURE_MIN_FILTER, minfilter)
	print(".")
	gl.glTexParameteri(self.texdim, gl.GL_TEXTURE_MAG_FILTER, magfilter)
	print(".")
	if mipmap then
		gl.glGenerateMipmap(self.texdim)
	end
	self:unbind()
end

local activeTextureUnits = {}
local function findNextTextureUnit(texUnits)
	for i=0,#activeTextureUnits+1 do
		if not activeTextureUnits[i] then
			if not gl["GL_TEXTURE"..i] then return nil 
			else return i end
		end
	end
end
function Texture:activate()
	if self.texunitIdx then return self.texunitIdx end
	local idx = assert(findNextTextureUnit(activeTextureUnits), "can not active texture: no free texture unit")
	self.texunit = "GL_TEXTURE"..idx
	self.texunitIdx = idx
	activeTextureUnits[idx] = true
	print("activating texunit", idx, self.texunit, gl[self.texunit])

	gl.glActiveTexture(gl[self.texunit])
	self:bind()
	return self.texunitIdx
end
function Texture:unbind()
	self.texunitIdx = nil
	gl.glBindTexture( self.texdim, gl.NULL_BUFFER )
end
function Texture:bind()
	print('binding', self.texdim, self.texture, gl.GL_TEXTURE_2D)
	gl.glBindTexture( self.texdim, self.texture )
end
function Texture:buffer(img)
	-- the internal format can also be a compressed format, which is just variations on the actual pixel format. can implement that later
	print("!",img:glData())
	js.global.console:log("?",img:glData())
	print("format",self.format)
	self:bind()
	gl.glTexImage2D(self.texdim, 0, self.format, img.width, img.height, 0, self.format, img.datatype, img:glData() )
	self:unbind()
end

return Texture
