local class = require('object')
local v = require("vector")
local vec3, dot, cross = v.vec3, v.dot, v.cross
local mat4 = require('matrix').mat4

local Q = class()

function Q:__init(x,y,z,w)
	if type(x)=='table' then
		self.imaginary = x
		self.real = y
	elseif type(x)=='number' then
		self.imaginary = vec3(x,y,z)
		self.real = w
	elseif type(x)=='nil' then
		self.imaginary = vec3(0,0,0)
		self.real = 1
	end
	assert(self.real, "incorrect types for quaternion constructor")
	self:normalize()
end
function Q:matrix()
	if not self.mat then self.mat = mat4() end
	local mdata = self.mat.usrdata
	local r = self.real
	local i,j,k = self.imaginary.x, self.imaginary.y, self.imaginary.z

	mdata[0] = 1 - 2*j*j - 2*k*k
	mdata[1] = 2*(i*j + k*r)
	mdata[2] = 2*(i*k - j*r)
	mdata[3] = 0

	mdata[4] = 2*(i*j - k*r)
	mdata[5] = 1 - 2*i*i - 2*k*k
	mdata[6] = 2*(j*k + i*r)
	mdata[7] = 0

	mdata[8] = 2*(i*k + j*r)
	mdata[9] = 2*(j*k - i*r)
	mdata[10]= 1 - 2*i*i - 2*j*j
	mdata[11] = 0
	
	mdata[12] = 0
	mdata[13] = 0
	mdata[14] = 0
	mdata[15] = 1
	return self.mat
end
function Q:normalize()
	local sum = self.real^2
	sum = sum + self.imaginary.x^2
	sum = sum + self.imaginary.y^2
	sum = sum + self.imaginary.z^2
	sum = math.sqrt(sum)
	self.imaginary:scale( 1/sum )
	self.real = self.real/sum
	return self
end

function Q:__tostring()
	local t = {}
	local axis, angle = self:rotation()
	table.insert(t,"Quaternion: real=")
	table.insert(t,tostring(self.real))
	table.insert(t," imaginary=")
	table.insert(t,tostring(self.imaginary))
	table.insert(t, " axis")
	table.insert(t, tostring(axis))
	table.insert(t, " angle")
	table.insert(t, tostring(angle))
	return table.concat(t)
end

function Q.axisAngle(axis, angle)
	return Q(axis:copy():normalize()*math.sin(angle/2), math.cos(angle/2))
end

function Q.mult(a,b,c)
	if not c then c=Q() end
	local real = (a.real*b.real - dot(a.imaginary,b.imaginary))
	local imaginary = a.real*b.imaginary + b.real*a.imaginary + cross(a.imaginary,b.imaginary)
	c.real = real
	c.imaginary = imaginary
	return c
end

function Q:rotation()
	local real = ((self.real+1) % 2) - 1
	local angle = math.acos(real)*2
	if angle ~= angle then
		print("NAN!", self.real, real, math.acos(real))
	end
	return self.imaginary, math.acos(real)*2
end

function Q.__mul(a,b)
	return a:mult(b)
end

function Q:copy()
	local new = Q(0,0,0,0)
	new.real = self.real
	new.imaginary = self.imaginary:copy()
	return new
end

return Q
