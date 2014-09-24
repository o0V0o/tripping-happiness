local Matrix = require("matrix")
local O = require("object")


local Camera = O.class()
--constructor Camera(self, near, far, fov) return Camera a new camera object with the given near and far clipping planes, and Field of View, located at (0,0,0), facing (0,0,-1)
function Camera.__init(self, near, far, fov)
	near = near or .1
	far = far or 100
	fov = fov or 90
	self.near = near
	self.far = far
	self.fov = fov
	self.transform = Matrix.identity(4)
	self:recalculate()
end
--function Camera:perspective(near, far, fov) return Camera Sets the camera's near and far clipping planes, and Field of View
function Camera:perspective(near, far, fov)
	self.near = near
	self.far = far
	self.fov = fov
	self:recalculate()
	return self
end
--function Camera:recalculate() Recalculates the camera's perspective projection matrix, called after setting near,far or fov using associated setters
function Camera:recalculate()
	local x,y
	--if not context then x=1;y=1 else x,y = context:getSize() end
	--local aspect = x/y
	local aspect = 1
	self.perspective = Matrix.perspective(self.near, self.far, aspect, self.fov)
end
--function Camera:setNear(near) setter for the near clipping plane
function Camera:setNear(near)
	self.near = near
	self:recalculate()
end
--function Camera:setFar(far) setter for the far clipping plane
function Camera:setFar(far)
	self.far = far
	self:recalculate()
end
--function Camera:FOV(fov) setter for the field of view
function Camera:setFOV(fov)
	self.fov = fov
	self:recalculate()
end
--function Camera:reset() return Camera (self)
--resets the camera to position (0,0,0), facing (0,0,-1)
function Camera:reset()
	self.transform = Matrix.identity(4)
	return self
end
--function Camera:lookat(Vec3 pos, Vec3 point, Vec3 up) return Camera (self)
--Sets the camera to be at position *pos*, looking at the world-space point *point*, with the vector *up* facing upwards.
function Camera:lookat(eye, point, up)
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
	self.transform = t
	self.pos = eye
	return self
end
--function Camera:rotate(Vec3 axis, Number angle) Rotates the camera *angle* radians around the vector *axis*
function Camera:rotate(axis, angle)
	self.transform:rotate(axis, -angle)
end
--function Camera:translate(Vec3 v) Translates the camera by the given vector
function Camera:translate(v)
	self.transform:translate(-v)
	self.pos = self.pos + v
end
--function Camera:setPos(Vec3 pos) set the position of the camera to *pos*
function Camera:setPos(pos)
	for row = 0,2 do
		mdata[12+row] = pos[row]
	end
end

return Camera
