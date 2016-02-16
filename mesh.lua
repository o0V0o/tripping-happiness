local get = require('get')
local class = require("object")
local V = require("vector")
local Matrix = require("matrix")
local types = require("types")

if not table.unpack then table.unpack = unpack end


local M = {}

function map(list, func)
	for k,v in ipairs(list) do
		list[k] = func(v)
	end
end
function split(p, pattern)
	local t = {}
	for m in p:gmatch(pattern) do
		table.insert(t, m)
	end
	return t
end

function distancePtPt(p1,p2)
	return (p2-p1):len()
end
function distancePtLine(pt, ro, rd)
	-- taken from http://onlinemschool.com/math/library/analytic_geometry/p_line/
	print(pt, ro, rd)
	return math.abs(  (pt-ro):cross(rd):len() / rd:len()  )
end
function distancePtPlane(pa, pb, n)
	-- taken from http://paulbourke.net/geometry/pointlineplane/
	local D = -1 * (n.x*pb.x + n.y*pb.y + n.z+pb.z)
	local dist = math.abs((n.x*pa.x + n.y*pa.y + n.z*pa.z + D) / n:len())
	print("Pt-Plane:", pa,pb,n,dist)
	return dist
end
function distance(pt, pts)
	if pts.super == V.Vector then
		return distancePtPt(pt,pts)
	elseif #pts==2 then
		print("pt-Line:", pts[1], pts[2])
		return distancePtLine(pt,pts[1],pts[2]-pts[1])
	elseif #pts==3 then
		print("pt-Plane:", pts[1], pts[2], pts[3])
		return distancePtPlane(pt,pts[1], (pts[1]-pts[2]):cross(pts[3]-pts[2]))
	else
		error("Unable to find distance with "..#pts.." dimensional object")
	end
end

--function M.normalize(verts, VertInds) return [vec3], [Int] a list of normal values
--for each **face**, and an element index array for each vertex in vertInds
function M.normalize(verts, vertInds)
	local normals, normInds = {}, {}

	local i=1
	while i <= #vertInds-2 do
		print(i,"/", #vertInds)
		local p1 = verts[ vertInds[i]]
		local p2 = verts[ vertInds[i+1]]
		local p3 = verts[ vertInds[i+2]]
		local normal = (p2-p3):cross(p1-p3)
		table.insert(normals, normal)
		table.insert(normInds, #normals)
		table.insert(normInds, #normals)
		table.insert(normInds, #normals)
		print(p1,p2,p3,normal)
		i = i + 3
	end
	return normals, normInds
end
--function M.meshanize(verts, VertInds, ...) return Mesh
-- Create a mesh from vertices and attributes, where each attribute has its own element index array.
-- example call: meshanizer(vertexArray, vertexElementIndexArray, "normal", normalArray, normalElementArray, "texcoord", texcoordArray, texcoordElementArray)
--
function M.meshanize(verts, vertInds, ...)
	print("meshanizing:",verts, vertInds, ...)
	for k,v in ipairs(verts) do
		print("verts:", k, v)
	end
	for k,v in ipairs(vertInds) do
		print("inds:", k, v)
	end
	local args = {...}
	local attribNames = {}
	local attribBuffers = {}
	local attribInds = {}

	local meshVerts = {}
	local meshInds = {}
	local meshAttributes = {}
	local meshIndTransform = {}
	--local meshIndTransform = ListTable((#args/3)+1) --lookup table to go from vertex+attribute indices -> real mesh index

	local function addMeshVert(vertInd, ...)
			table.insert(meshVerts, verts[vertInd])
			for i,ind in ipairs({...}) do
				table.insert(meshAttributes[attribNames[i]], attribBuffers[i][ind])
			end
			print("new mesh vert:", #meshVerts)
			return #meshVerts-1
	end

	-- get the real index of the point matching all the specified index values.
	-- If a vertex does not already exist that matches these indeces, then make
	-- one.
	local function indexOf(vertInd, ...)
		assert(vertInd)
		local args = {...}
		if #args == 0 then meshIndTransform[vertInd] = addMeshVert( vertInd, ...) end
		if not meshIndTransform[vertInd] then meshIndTransform[vertInd]={} end
		local t = meshIndTransform[vertInd]
		for i, ind in ipairs(args) do
			if not t[ind] and i~=#args then t[ind]={} end
			if not t[ind] and i==#args then
				t[ind] = addMeshVert(vertInd, ...)
			end
			t = t[ind]
		end
		return t
	end



	for i=1,#args,3 do
		local name = args[i]
		local pts = args[i+1]
		local ind = args[i+2]
		table.insert(attribNames, name)
		attribBuffers[#attribNames]=pts
		attribInds[#attribNames]=ind
		meshAttributes[name] = {}
	end
	for i,vertInd in ipairs(vertInds) do
		local t = {}
		for _,inds in ipairs(attribInds) do
			table.insert(t, inds[i])
		end
		table.insert(meshInds, indexOf(vertInd, table.unpack(t)))
	end
	print("Making Mesh:", table.unpack(meshInds))
	return Mesh(meshVerts, meshInds, meshAttributes)
end

local loaders = {}
loaders["OBJ"] = function(content)
	local verts = {}; local vertInds = {}
	local texcoords = {}; local texInds = {}
	local normals = {}; local normInds = {}


	--get absolute index from relative (negative) indices
	local function absInd(i, list)
		i=i or 0
		if i<0 then return #list+i end
		return i
	end

	local instructions = {}
	instructions["v"] = function(params)
		local v = V.vec4(tonumber(params[1]) or 0,
						tonumber(params[2]) or 0,
						tonumber(params[3]) or 0,
						tonumber(params[4]) or 0)
		table.insert(verts, v)
		print("v -> ",#verts,v)
	end

	instructions["vn"] = function(params)
		assert(params[1]);assert(params[2]);assert(params[3])
		assert(params[1] and params[2] and params[3], "not enough parameters to make a normal")
		local v = V.vec3(tonumber(params[1]),
						 tonumber(params[2]),
						 tonumber(params[3]))
		table.insert(normals, v)
		print("normal:", v)
	end
	instructions["vt"] = function(params)
		assert(params[1]);assert(params[2])
		local v = V.Vector( tonumber(params[1]),
							tonumber(params[2]),
							tonumber(params[3]))
		table.insert(texcoords, v)
		print("texcoord:", v)
	end

	instructions["f"] = function(params)
		assert(params[1]);assert(params[2]);assert(params[3])
		local firstV,firstT,firstN
		local lastV,lastT,lastN
		for _,p in ipairs(params) do
			local vertInd, texInd, normInd = table.unpack( split(p,"([^/]*)/?") )
			vertInd = absInd(tonumber(vertInd), verts)
			texInd = absInd(tonumber(texInd), texcoords)
			normInd = absInd(tonumber(normInd), normals)

			if not firstV then
				firstV=vertInd; firstT=texInd; firstN=normInd
			elseif not lastV then
				lastV=vertInd; lastT=texInd; lastN=normInd
			else
				table.insert(vertInds, firstV); table.insert(vertInds, lastV); table.insert(vertInds, vertInd)
				table.insert(texInds, firstT); table.insert(texInds, lastT); table.insert(texInds, texInd)
				table.insert(normInds, firstN); table.insert(normInds, lastN); table.insert(normInds, normInd)
				print("face: ",firstV, lastV, vertInd)
				lastV=vertInd;lastT=texInd;lastN=normInd
			end
		end
	end

	for line in content:gmatch(".-\n") do
		params = split(line, "%S+")
		local cmd = table.remove(params, 1)
		if instructions[cmd] then
			instructions[cmd](params)
		end

	end
	print("normals#", #normals)
	print("texcoords#", #texcoords)
	local args = {}
	table.insert(args, verts)
	table.insert(args, vertInds)
	if #texcoords > 0 then
		table.insert(args, "texcoord")
		table.insert(args, texcoords)
		table.insert(args, texInds)
	end
	if #normals > 0 then
		table.insert(args, "normal")
		table.insert(args, normals)
		table.insert(args, normInds)
	end
	for k,v in ipairs(args) do
		print(k,v)
	end
	print( table.unpack(args))
	--local mesh = M.meshanize(table.unpack( args))
	local mesh = M.meshanize(verts, vertInds, "texcoord", texcoords, texInds, "normal", normals, normalInds)
	--local mesh = M.meshanize(verts, vertInds, "blah", {}, normInds)
	--local mesh = M.meshanize(verts, vertInds) 
	print("done loading obj")
	return mesh
end
function M.load(fname)
	--decide based on extension
	local name, ext = fname:match("(.-)[.]([^.]+)")
	ext = ext:upper()
	print(fname,name,ext)
	local content = get(fname)
	if loaders[ext] then return loaders[ext](content) end
	error("No loader present for " .. ext .. " filetype.")
end

Mesh = class()
--constructor Mesh([Vector] vertArray, [Int] elementIndexArray, Table attributes) 
--return Mesh a new Mesh object with the given vertices, that form faces as described in the *elementIndexArray*
--The constructed Mesh object has a set of attributes, such as normals, texure coordinates, etc, that can be passed 
--as a table in the following format:
--	{ "attributeName" = vectorArray, ... }
--	such that each vectorArray is the *same size*, indexed by ind per face
--example: Mesh( {vec3(1,0,0),vec3(1,1,1),vec3(0,1,1)}, {1,2,3}, {normal={vec3(1,0,0),vec3(0,0,1),vec3(0,1,0)},texcoord={vec2(0,0),vec2(1,1),vec2(.5,.5)}})
function Mesh:__init(verts, ind, attributes)
	self.transform = Matrix.identity(4)
	self.verts = verts
	self.indices = ind
	self.attributes = attributes or {}
	self.attributes["position"] = verts
	if self.verts[1].dim == 3 then
		for k,v in pairs(self.verts) do
			self.verts[k] = V.vec4( v, 1) -- add W component.
		end
	end
end
function Mesh:attributeDefault(name, default)
	local oldAttrib = self.attributes[name] or {}
	local newAttrib = types.DefaultTable( function()
		return default:copy()
	end)
	for k,v in pairs(oldAttrib) do
		newAttrib[k] = v
	end
	self.attributes[name] = newAttrib
end
function Mesh:linkTo( mesh )
	self.verts = mesh.verts
	self.ind = mesh.ind
	self.indices = mesh.indices
	self.attributes = mesh.attributes
	self.transform = mesh.transform
	return self
end
function Mesh:copyFrom( mesh )
	self.verts = {}
	for k,v in pairs(mesh.verts) do self.verts[k] = v:copy() end
	self.indices = {}
	for k,v in pairs(mesh.indices) do self.indices[k] = v:copy() end
	self.attributes = {}
	for k,v in pairs(mesh.attributes) do self.attributes[k] = v:copy() end
	self.transform = mesh.transform:copy()
	return self
end
function Mesh:reset()
	self.transform = Matrix.identity(4)
end
function Mesh:translate(v)
	return self.transform:translate(v)
end
function Mesh:scale(s)
	return self.transform:scale(s)
end
function Mesh:rotate(...)
	return self.transform:rotate(...)
end
function Mesh:__tostring()
	local str = {}

	table.insert(str, "index")
	table.insert(str, "\t")
	table.insert(str, "vertex")
	for name,_ in pairs(self.attributes) do
		table.insert(str, "\t")
		table.insert(str, name)
	end
	table.insert(str, "\n")
	for _,i in ipairs(self.indices) do
		i=i+1
		table.insert(str, tostring(i))
		table.insert(str, "\t")
		table.insert(str, tostring(self.verts[i]) )
		for _,pts in pairs(self.attributes) do
			table.insert(str, "\t")
			table.insert(str, tostring(pts[i]) )
		end
		table.insert(str, "\n")
	end
	return table.concat(str)
end




--[[
function Mesh:optimize()
	--TODO break into smaller functions
	-- search for duplicate vertices, and verts that arnt referenced by indices
	--find duplicate verts
	local dupes = {}
	for i,v in ipairs(self.verts) do
		for i2,v2 in ipairs(self.verts) do
			if v2==v and i2~=i then
				local dupe = true
				for _,atr in pairs(self.attributes) do
					if atr[i] ~= atr[ii] then
						--not a duplicate.
						dupe = false
					end
				end
				if dupe then
					dupes[i2]==i
				end
			end
		end
	end

	-- find unused verts, and mark them as dupes
	local usedVerts = {}
	for _,ind in pairs(self.ind) do
		usedVerts[ind] = true
	end
	for i,v in pairs(self.verts) do
		if not usedVerts[i] then
			dupes[i] = 0
		end
	end

	-- remove all duplicate verts
	for i,newi in pairs(dupes) do
		table.remove(self.verts, i)
		for _,atr in pairs(self.attributes) do
			table.remove(atr, i)
		end
		local newind = {}
		for ii,ind in ipairs(self.ind) do
			if ind == i then
				newind[ii] == newi
			elseif ind > i then
				if newind[ii] then
					newind[ii] = newind[ii] - 1
				else
					newind[ii] = ind - 1
				end
			else
				newind[ii] = ind
			end
		end
		self.ind = newind
	end
end
--]]
M.Mesh = Mesh
return M
