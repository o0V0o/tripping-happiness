local gl = require('openGL')
local ctypes = require('ctypes')
local class = require('object')
local VBO = require('vbo')
local EAB = require('eab')

--maps mesh parameters to shader attribute names
local defaultMap = {
	position = 'position',
	normal = 'normal',
	texcoord = 'texcoord'
}

local O = class()
function O:__init(mesh, attributeMap)
	print("Simple Object created:", mesh)
	self.attributeMap = attributeMap or defaultMap
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
function O:recalculate(shader) 
	print("calculating")
	self.vbos = {}
	self.eab = EAB()
	for mesh_attrib,shader_attrib in pairs(self.attributeMap) do
		print(mesh_attrib, shader_attrib)
		print(self.mesh.attributes[mesh_attrib], shader.attributes[shader_attrib])
		if shader.attributes[shader_attrib] then
			assert(self.mesh.attributes[mesh_attrib], "no such attribute in mesh")
			self.vbos[mesh_attrib] = VBO(gl.GL_FLOAT, gl.GL_STATIC_DRAW)
			self.vbos[mesh_attrib]:bufferData( ctypes.floatArray( flatten(self.mesh.attributes[mesh_attrib] )) )
			self.vbos[mesh_attrib]:useForAttribute(shader.attributes[shader_attrib])
		end
	end
	print("eab buffering...")
	self.eab:bufferData( ctypes.shortArray( self.mesh.indices ) )
	print("calculated.")
end
function O:draw(shader)
	for mesh_attrib, shader_attrib in pairs(self.attributeMap) do
		if shader[shader_attrib] then
			assert(self.mesh.attributes[mesh_attrib], "no such attribute in mesh")
			self.vbos[mesh_attrib]:useForAttribute(shader[shader_attrib])
		end
	end
	self.eab:bind()
	gl.drawElements( gl.GL_TRIANGLES, #(self.mesh.indices) , self.eab.datatype, 0)
end

return O
