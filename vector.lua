local O = require("object")
local ffi = require("ffi")

local V = {}


--local Vector = {}
--Vector.__index = Vector
local Vector = O.class()

function V.vec1(x) if type(x)=="number" then return Vector(1,x or 0) else return V.Vector(1,x) end end
function V.vec2(x,y) if type(x)=="number" and type(y)=="number" then return Vector(2,x,y) else return V.Vector(2,x,y) end end
function V.vec3(x,y,z) if type(x)=="number" and type(y)=="number" and type(z)=="number" then return Vector(3,x,y,z) else return V.Vector(3,x,y,z) end end
function V.vec4(x,y,z,w) if type(x)=="number" and type(y)=="number" and type(z)=="number" and type(w)=="number" then return Vector(4,x,y,z,w) else return V.Vector(4,x,y,z,w) end end

function V.Vector(dim,...)
	local args = {...}
	local params = {}
	local i=1
	while i<=dim do
		local n = args[i]
		if type(n) == "nil" then
			table.insert(params, 0)
			i = i + 1
		elseif type(n) == number then
			table.insert(params, n)
			i = i + 1
		elseif n.dim==1 then
			table.insert(params, n.usrdata[0])
			i = i + 1
		elseif n.dim==2 then
			table.insert(params, n.usrdata[0])
			table.insert(params, n.usrdata[1])
			i = i + 2
		elseif n.dim==3 then
			table.insert(params, n.usrdata[0])
			table.insert(params, n.usrdata[1])
			table.insert(params, n.usrdata[2])
			i = i + 3
		elseif n.dim==4 then
			table.insert(params, n.usrdata[0])
			table.insert(params, n.usrdata[1])
			table.insert(params, n.usrdata[2])
			table.insert(params, n.usrdata[3])
			i = i + 4
		else
			error("unknown types in Vector constructor")
		end
	end
	assert(#params==dim, "incompatible types in Vector constructor")
	return Vector(dim, unpack(params) )
end

function Vector.__init(self,dim, ...)
	local usrdata = ffi.new("float[?]", dim, ...)
	self.usrdata = usrdata
	self.dim = dim
	--return setmetatable({usrdata=usrdata, dim=dim}, Vector)
end

function Vector:add(v)
	local usrdata = self.usrdata
	local usrdata2 = v.usrdata
	for i = 0,self.dim-1 do
		usrdata[i] = usrdata[i] + usrdata2[i]
	end
	return self
end

function Vector:sub(v)
	local usrdata = self.usrdata
	local usrdata2 = v.usrdata
	for i = 0,self.dim-1 do
		usrdata[i] = usrdata[i] - usrdata2[i]
	end
	return self
end

function Vector:scale(s)
	local usrdata = self.usrdata
	for i = 0,self.dim-1 do
		usrdata[i] = usrdata[i] * s
	end
	return self
end

function Vector:dot(v)
	local usrdata = self.usrdata
	local usrdata2 = v.usrdata
	local product = 0
	for i = 0,self.dim-1 do
		product = product + usrdata[i] * usrdata2[i]
	end
	return product
end

function Vector:cross(v)
	assert(v.dim == 3 and self.dim == 3, "cross product only works in 3 dimensions!")
	local v1 = self.usrdata
	local v2 = v.usrdata
	local cross1 = v1[1]*v2[2] - v1[2]*v2[1]
	local cross2 = v1[2]*v2[0] - v1[0]*v2[2]
	local cross3 = v1[0]*v2[1] - v1[1]*v2[0]
	v1[0] = cross1
	v1[1] = cross2
	v1[2] = cross3
	return self
end

function Vector:negate()
	local usrdata = self.usrdata
	for i = 0,self.dim-1 do
		usrdata[i] = -usrdata[i]
	end
	return self
end

function Vector:len()
	local usrdata = self.usrdata
	local sum = 0 
	for i = 0,self.dim-1 do
		sum = sum + math.pow(usrdata[i],2)
	end
	return math.sqrt(sum)
end
Vector.length = Vector.len

function Vector:normalize()
	local usrdata = self.usrdata
	local len = self:len()
	for i = 0,self.dim-1 do
		usrdata[i] = usrdata[i]/len
	end
	return self
end

function Vector:copy()
	local v2 = Vector( self.dim )
	ffi.copy(v2.usrdata, self.usrdata, ffi.sizeof(self.usrdata))
	return v2
end


function Vector.__unm(v)
	return (v:copy()):negate()
end
function Vector.__add(v1,v2)
	return (v1:copy()):add(v2)
end
function Vector.__sub(v1,v2)
	return (v1:copy()):sub(v2)
end
function Vector.__mul(v1,v2)
	if type(v1) == "number" then
		return (v2:copy()):scale(v1)
	elseif type(v2) == "number" then
		return (v1:copy()):scale(v2)
	else
		return (v1:copy()):cross(v2)
	end
end
function Vector.__tostring(v)
	local t = {}
	local usrdata = v.usrdata
	table.insert(t, "(")
	for i = 0,v.dim-1 do
		if i>0 then table.insert(t, ",") end
		table.insert(t, usrdata[i])
	end
	table.insert(t, ")")
	return table.concat(t)
end

return V
