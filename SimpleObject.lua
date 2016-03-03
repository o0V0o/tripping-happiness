local gl = require('openGL')
local ctypes = require('ctypes')
local class = require('object')
local VBO = require('vbo')
local EAB = require('eab')

--maps mesh parameters to shader attribute names
local defaultMap = setmetatable({}, {__index=function(t,k) return k end})

local O = class()
function O:__init(mesh, attributeMap)
	--print("Simple Object created:", mesh)
	self.mesh = mesh
end
local function flatten(pts)
	local buffer = {}
	for _,v in ipairs(pts) do
		for i=1,v.dim do
			table.insert(buffer, v[i-1])
		end
	end
	return buffer
end
function O:recalculate(shader, attributeMap)
	attributeMap = attributeMap or defaultMap
	self.attributeMap = attributeMap
	print("calculating", self)
	self.vbos = {}
	self.eab = EAB()
	for name,attribute in pairs(shader.attributes) do
		local mesh_attrib = attributeMap[name]
		print("calculating attribute", name,"mesh=", mesh_attrib)
		assert(mesh_attrib, "no mapping for attribute")
		local data = self.mesh.attributes[mesh_attrib]
		assert(data and #data>0, "no such attribute in mesh")
		self.vbos[mesh_attrib] = VBO(gl.GL_FLOAT, gl.GL_STATIC_DRAW)
		print("attrib size", attribute.size, attribute.typename, "mesh size", data[1].dim, gl.sizeof(attribute.type))
		self.vbos[mesh_attrib]:bufferData( ctypes.floatArray( flatten(data)) )
	end
	print("eab buffering...")
	self.eab:bufferData( ctypes.shortArray( self.mesh.indices ) )
	print("calculated.")
end
function O:draw(shader)
	assert(self.eab, "need to recalculate SimpleObject before draw")
	self.eab:bind()
	for name,attribute in pairs(shader.attributes) do
		local mesh_attrib = self.attributeMap[name]
		if self.mesh.attributes[mesh_attrib] then
			self.vbos[mesh_attrib]:useForAttribute(attribute)
		end
	end
	gl.drawElements( gl.GL_TRIANGLES, #(self.mesh.indices) , self.eab.datatype, 0)
end

return O
