local class = require('object')
local vec3 = require('vector').vec3
local Quaternion = require('quaternion')
local Matrix = require('matrix')

local Transformation = class()
function Transformation:__init()
	self.scaleValue = 1
	self.rotation = Quaternion()
	self.position = vec3(0,0,0)
	self.dirty = true
end
function Transformation:matrix()
	if self.dirty then
		self.transform = Matrix.identity(4):scale(self.scaleValue):mult(self.rotation:matrix()):translate(self.position)
		self.transform = Matrix.identity(4):scale(self.scaleValue):transform(self.rotation:matrix()):translate(self.position)
		self.dirty = false
	end
	return self.transform
end
function Transformation:scale(s)
	self.scaleValue = self.scaleValue * s
	self.dirty = true
	return self
end
function Transformation:translate(offset)
	self.position:add(offset)
	self.dirty = true
	return self
end
function Transformation:rotate(axis, angle)
	self.rotation = self.rotation * Quaternion.axisAngle(axis, angle)
	self.dirty = true
	return self
end

return Transformation
