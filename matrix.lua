
local class = require'object'
local ctypes = require'ctypes'

local M = {}

--local Matrix = {}
--Matrix.__index = Matrix
local Matrix = class()

function M.mat3()
	return Matrix(3,3)
end
function M.mat4()
	return Matrix(4,4)
end
function M.identity(dim)
	assert(dim, "Matrix.identity: no dimension given")
	local M = Matrix(dim,dim)
	local usrdata = M.usrdata
	for i = 0,dim-1 do
		usrdata[ (i*dim) +i ] = 1.0
	end
	return M
end
function M.lookat(eye, at, up)
	local v = (at-eye):normalize()
	local n = v:copy():cross(up):normalize()
	local u = n:copy():cross(v):normalize()
	v=-v

	if eye==at then return M.identity(4) end

	local M=Matrix(4,4)
	local mdata = M.usrdata
	mdata [ 0 ] = n.x
	mdata [ 4 ] = n.y
	mdata [ 8 ] = n.z
	mdata [12 ] = -n:dot(eye)
	mdata [ 1 ] = u.x
	mdata [ 5 ] = u.y
	mdata [ 9 ] = u.z
	mdata [ 13] = -u:dot(eye)
	mdata [ 2 ] = v.x
	mdata [ 6 ] = v.y
	mdata [ 10] = v.z
	mdata [ 14] = -v:dot(eye)
	mdata [ 3 ] = 0
	mdata [ 7 ] = 0
	mdata [ 11] = 0
	mdata [ 15] = 1
	return M
end
function M.perspective(near, far, aspect, fov)
	local self = Matrix(4,4)
	fov = math.rad(fov)
	local mdata = self.usrdata

	local t = math.tan(fov/2)
	local f = 1/t
	local d = far-near

	mdata[ 0 ] = f/aspect
	mdata[ 5 ] = f
	mdata[ 10 ] = -1*(near+far)/d
	mdata[ 11 ] = -1
	mdata[ 14 ] = (-2*far*near)/d
	return self
end

function Matrix:__init(dim1, dim2)
	assert(dim1 and dim2, "Matrix.new: not enough dimensions given")
	self.usrdata = ctypes.floatArray( dim1*dim2 )
	           --col, row
	self.dim = {dim1,dim2}
end
function Matrix:index(col,row)
	local nrows = self.dim[2]
	col = col - 1; row = row - 1
	return (col*nrows)+row
end

function Matrix:transform(transformation)
	local new = self * transformation
	self.usrdata = new.usrdata
	return self
end
function Matrix:translate(v)
	assert(self.dim[1]==4 and self.dim[2]==4 and v.dim==3, "incorrect dimensions for translation")
	local translate = M.identity(4)
	local mdata = translate.usrdata
	local vdata = v.usrdata
	for i = 0,2 do
		mdata[12+i] = vdata[i]
	end
	return self:transform(translate)
end
function Matrix:scale(v)
	assert(self.dim[1]==4 and self.dim[2]==4, "incorrect matrix dimensions for scaling")
	local scale = M.identity(4)
	local mdata = scale.usrdata
	local nrows = 4

	if type(v)=="number" then 
		for col = 0,2 do
			local row=col
			mdata[ (col*nrows) +row ] = v
		end
	else
		assert(v.dim >= 3, "incorrect vector dimension for scaling")
		local vdata = v.usrdata
		for col = 0,2 do
			local row=col
			mdata[ (col*nrows) +row ] = vdata[row]
		end
	end
	return self:transform(scale)
end
function Matrix:rotate(axis, angle, origin)
	local rot = M.rotate(axis, angle)
	if origin then
		return self:tranlate(-origin):transform(rot):translate(origin)
	else
		return self:transform(rot)
	end
end

function M.skew(v)
	assert(v.dim==3, "incorrect vector dimensions to calculate skew-symmetric matrix")
	local self = Matrix(3,3)
	local mdata = self.usrdata
	local vdata = v.usrdata
	local nrows = 3
	mdata[ (0*nrows) +1 ] = -vdata[2]
	mdata[ (0*nrows) +2 ] =  vdata[1]
	mdata[ (1*nrows) +2 ] = -vdata[0]

	mdata[ (1*nrows) +0 ] =  vdata[2]
	mdata[ (2*nrows) +0 ] = -vdata[1]
	mdata[ (2*nrows) +1 ] =  vdata[0]
	return self
end

--function M.rotate(quaternion) return Mat2 represents the quaternion rotation as a 4x4 transformation matrix
function M.rotateq(q)
	local M = Matrix(4,4)
	local mdata = M.usrdata
	local i = q.imaginary.x
	local j = q.imaginary.y
	local k = q.imaginary.z
	local r = q.real


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
	return M
end
--function M.rotate(axis, angle) return Mat4 represents the rotation as a 4x4 transformation matrix
function M.rotate(v,theta)
	assert(v.dim==3, "incorrect dimensions for rotating")
	v:normalize()
	local self = M.identity(3)
	local N = M.skew(v)
	local N2 = N * N

	local c = math.cos(theta)
	local s = math.sin(theta)
	local t = 1-c

	local t1 = s*N
	local t2 = N2*t

	self = self + s*N + N2*t
	self:resize(4,4)
	self.usrdata[15]=1  --fill in new cells like an identity matrix
	return self
end
function M.rotate(v,theta)
	v:normalize()
	theta = -theta
	local self = M.identity(4)
	local mdata = self.usrdata
	local vdata = v.usrdata
	local c = math.cos(theta)
	local s = math.sin(theta)
	local t = 1-c

	local x = vdata[0]
	local y = vdata[1]
	local z = vdata[2]
	mdata[self:index(1,1)] = t*x*x + c
	mdata[self:index(1,2)] = t*x*y + z*s
	mdata[self:index(1,3)] = t*x*z - y*s

	mdata[self:index(2,1)] = t*x*y - z*s
	mdata[self:index(2,2)] = t*y*y + c
	mdata[self:index(2,3)] = t*y*z + x*s

	mdata[self:index(3,1)] = t*x*z + y*s
	mdata[self:index(3,2)] = t*y*z - x*s
	mdata[self:index(3,3)] = t*z*z + c
	return self
end

function Matrix:scalarMult(s)
	local usrdata = self.usrdata
	local nrows = self.dim[2]
	for col = 0,self.dim[1]-1 do
		for row = 0,self.dim[2]-1 do
			usrdata[ (col*nrows) + row ] = usrdata[ (col*nrows) + row ] * s
		end
	end
	return self
end

function Matrix:add(m2)
	assert(self.dim[1] == m2.dim[1] and self.dim[2] == m2.dim[2], "Addition of matrices of different size")
	local usrdata = self.usrdata
	local usrdata2 = m2.usrdata
	local cols = self.dim[2]
	for i = 0,self.dim[1]-1 do
		for j = 0,self.dim[2]-1 do
			usrdata[ (i*cols) + j ] = usrdata[ (i*cols) + j ] + usrdata2[ (i*cols) +j ]
		end
	end
	return self
end

function Matrix:sub(m2)
	assert(self.dim[1] == m2.dim[1] and self.dim[2] == m2.dim[2], "Addition of matrices of different size")
	local usrdata = self.usrdata
	local usrdata2 = m2.usrdata
	local cols = self.dim[2]
	for i = 0,self.dim[1]-1 do
		for j = 0,self.dim[2]-1 do
			usrdata[ (i*cols) + j ] = usrdata[ (i*cols) + j ] - usrdata2[ (i*cols) +j ]
		end
	end
	return self
end

function Matrix.mult(m1,m2)
	assert(m1.dim[2] == m2.dim[1], "Multiplication with invalid matrix sizes")
	local d1 = m1.usrdata
	local d2= m2.usrdata
	local m = Matrix(m1.dim[1], m2.dim[2])
	local mdata = m.usrdata
	local d1cols = m1.dim[2]
	local d2cols = m2.dim[2]
	local cols = m.dim[2]
	for i = 0,m.dim[1]-1 do
		for j = 0,m.dim[2]-1 do
			local v = 0
			for n = 0,m1.dim[2]-1 do
				v = v + d1[(i*d1cols)+n] * d2[(n*d2cols)+j]
			end
			mdata[(i*cols)+j] = v
		end
	end
	return m
end

function Matrix:resize(cols, rows)
	local new = Matrix(cols, rows)

	local olddata = self.usrdata
	local newdata = new.usrdata

	local oldcols = self.dim[1]
	local oldrows = self.dim[2]

	for i = 0,cols-1 do
		for j = 0,rows-1 do
			if i<oldcols and j<oldrows then
				newdata[(i*rows)+j] = olddata[(i*oldrows)+j]
			end
		end
	end
	self.dim = new.dim
	self.usrdata = newdata
	return self
end

function Matrix:copy()
	local m2 = Matrix( self.dim[1], self.dim[2] )
	m2.usrdata = ctypes.copy(self.usrdata)
	return m2
end

function Matrix.__tostring(self)
	local t = {}
	local usrdata = self.usrdata
	local nrows = self.dim[2]
	table.insert(t, "!Matrix ")
	table.insert(t, tostring(self.dim[1]))
	table.insert(t, "x")
	table.insert(t, tostring(self.dim[2]))
	table.insert(t, ":")
	for row = 0,self.dim[2]-1 do
		table.insert(t,"\n")
		table.insert(t, "|")
		for col = 0,self.dim[1]-1 do
			if col>0 then table.insert(t, ",\t") end
			table.insert(t, string.format("%.3f", usrdata[(col*nrows)+row]))
		end
		table.insert(t, "|")
	end
	table.insert(t, "\n")
	for i=0,(self.dim[1]*self.dim[2])-1 do
		table.insert(t, tostring(usrdata[i]))
		table.insert(t, ",")
	end
	table.remove(t)
	return table.concat(t)
end
function Matrix.__add(m1, m2)
	return (m1:copy()):add(m2)
end
function Matrix.__sub(m1,m2)
	return (m1:copy()):sub(m2)
end
function Matrix.__mul(m1, m2)
	if type(m1) == "number" then return m2:copy():scalarMult(m1) 
	elseif type(m2) == "number" then return m1:copy():scalarMult(m2) 
	else return Matrix.mult(m1, m2) end
end


return M
