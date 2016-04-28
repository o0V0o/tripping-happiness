local Matrix = require("matrix")
local vec3 = require('vector').vec3
local gl = require('openGL')
local class = require("object")


local Camera = class()
--constructor Camera(self, near, far, fov) return Camera a new camera object with the given near and far clipping planes, and Field of View, located at (0,0,0), facing (0,0,-1)
function Camera.__init(self,near, far, fov, aspect, position, direction, up)
	self.aspect = aspect
	self.near = near or .1
	self.far = far or 100
	self.fov = fov or 90

	if not self.aspect then
		local x = gl.context.viewportWidth
		local y = gl.context.viewportHeight
		print("aspect ratio", x, y, x/y)
		self.aspect = x/y
	end

	self.position = position or vec3(0,0,0)
	self.direction = direction or vec3(0,0,1)
	self.up = up or vec3(0,1,0)
	self.xDir = vec3(0,0,0) --just need to allocate space
	self.yDir = vec3(0,0,0) --just need to allocate space

	self:recalculate()
	self:setPerspective(self.near, self.far, self.fov, self.aspect)
end
--function Camera:setPerspective(near, far, fov) return Camera Sets the camera's near and far clipping planes, and Field of View
function Camera:setPerspective(near, far, fov, aspect)
	self.near = near
	self.far = far
	self.fov = fov
	self.aspect = aspect or self.aspect
	self.perspective = Matrix.perspective(self.near, self.far, self.aspect, self.fov)
	return self
end
function Camera:setOrtho()
	self.perspective = Matrix.identity(4)
end
--function Camera:recalculate() Recalculates the camera's perspective projection matrix, called after setting near,far or fov using associated setters
function Camera:recalculate()

	self.up:cross(self.direction, self.xDir ):normalize()
	self.direction:cross(self.xDir, self.yDir ):normalize()
	self.direction:normalize()

	self.view = self.view or Matrix.identity(4)
	local usrdata = self.view.usrdata
	local xdata, ydata, zdata = self.xDir.usrdata, self.yDir.usrdata, self.direction.usrdata

	for col = 0,2 do
		usrdata[(col*4)+0] = xdata[col]
		usrdata[(col*4)+1] = ydata[col]
		usrdata[(col*4)+2] = -zdata[col] --flip Z to make it more natural
		usrdata[(col*4)+3] = 0
	end

	usrdata[12] = -self.xDir:dot(self.position)
	usrdata[13] = -self.yDir:dot(self.position)
	usrdata[14] = -self.direction:dot(self.position)
	usrdata[15] = 1

	return self
end
--function Camera:lookat(Vec3 point) return Camera (self)
--Sets the camera to be at position *self.position*, looking at the world-space point *point*, with the vector *self.up* facing upwards.
function Camera:lookat(point)
	self.direction = self.position:sub(point, self.direction)
	self:recalculate() --recalculates the transformation matrix
	

	--[[
	point = -point
	local t = Matrix.identity(4)
	local f = point - eye
	f:normalize()
	up:normalize()

	local s = f:copy():cross(up)
	local u = s:copy():normalize():cross(f)

	local usrdata = t.usrdata
	local sdata,udata,fdata
	sdata = s.usrdata; udata = u.usrdata; fdata = f.usrdata
	for col = 0,2 do
		usrdata[(col*4)+0] = sdata[col]
		usrdata[(col*4)+1] = udata[col]
		usrdata[(col*4)+2] = -fdata[col]
	end
	t:translate( -eye )
	self.view = t
	return self
	--]]
end
--function Camera:rotate(Vec3 axis, Number angle) Rotates the camera *angle* radians around the vector *axis*
function Camera:rotate(axis, angle)
	error("not implemented")
end
--function Camera:translate(Vec3 v) Translates the camera by the given vector
function Camera:translate(v)
	self.position = self.position + v
	self:recalculate()
end

function Camera:rotate(x, y)
	local xStep = x*self.xDir
	local yStep = y*self.yDir
	self.direction = self.direction+xStep+yStep
	self.direction:normalize()
	self:recalculate()
end

return Camera
