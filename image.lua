local gl = require("openGL")
local class = require('object')
local platform = require('platform')

local Image = class()

-- load an image (asyncronously)
function Image:__init(path, onload)
	self.loaded = false
	self.onload = onload
	platform.loadImage(path, function(img, width, height)
		print("image loaded!", img, width, height)
		self.width = width
		self.height = height
		self.data = img
		self.loaded = true
		self.datatype = gl.GL_UNSIGNED_BYTE
		if self.onload and type(self.onload=='function') then self:onload() end
	end)
end
-- this blocks until the image is loaded. 
function Image:glData()
	while not self.loaded do
		platform.sleep(100)
	end
	return self.data
end

return Image
