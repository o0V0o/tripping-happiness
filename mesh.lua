local O = require("object")
local V = require("vector")
local Matrix = require("matrix")
local types = require("types")

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
	print("split:", p, unpack(t))
	return t
end

local M = {}

--function meshanize(verts, VertInds, ...) return Mesh
-- Create a mesh from vertices and attributes, where each attribute has its own element index array.
-- example call: meshanizer(vertexArray, vertexElementIndexArray, "normal", normalArray, normalElementArray, "texcoord", texcoordArray, texcoordElementArray)
--
local function meshanize(verts, vertInds, ...)
	print("meshanizing:",verts, vertInds, ...)
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
			return #meshVerts
	end

	local function indexOf(vertInd, ...)
		assert(vertInd)
		local args = {...}
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
		print("meshanizing:",i, name, #attribNames)
	end
	for i,vertInd in ipairs(vertInds) do
		local t = {}
		for _,inds in ipairs(attribInds) do
			table.insert(t, inds[i])
		end
		table.insert(meshInds, indexOf(vertInd, unpack(t)))
	end
	return Mesh(meshVerts, meshInds, meshAttributes)
end

local loaders = {}
loaders["OBJ"] = function(content)
	local verts = {}; local vertInds = {}
	local texcoords = {}; local texInds = {}
	local normals = {}; local normInds = {}

	local instructions = {}

	--get absolute index from relative (negative) indices
	local function absInd(i, list)
		i=i or 0
		if i<0 then return #list+i end
		return i
	end

	instructions["v"] = function(params)
		assert(params[1]);assert(params[2]);assert(params[3])
		params[4] = params[4] or 1
		table.insert(verts, V.vec4(tonumber(params[1]),
		                           tonumber(params[2]),
		                           tonumber(params[3]),
		                           tonumber(params[4])))
		print("v -> ",#verts,verts[#verts])
	end

	instructions["vn"] = function(params)
		assert(params[1]);assert(params[2]);assert(params[3])
		table.insert(normals, V.vec3(tonumber(params[1]),
		                             tonumber(params[2]),
		                             tonumber(params[3])))
	end
	instructions["vt"] = function(params)
		assert(params[1]);assert(params[2])
		if params[3] then
			table.insert(texcoords, V.vec3(tonumber(params[1]),
			                               tonumber(params[2]),
			                               tonumber(params[3])))
		else
			table.insert(texcoords, V.vec2(tonumber(params[1]),
			                               tonumber(params[2])))
		end
	end

	instructions["f"] = function(params)
		assert(params[1]);assert(params[2]);assert(params[3])
		local firstV,firstT,firstN
		local lastV,lastT,lastN
		for _,p in ipairs(params) do
			print("param:", p)
			local vertInd, texInd, normInd = unpack( split(p,"([^/]*)/?") )
			vertInd = absInd(tonumber(vertInd), verts)
			texInd = absInd(tonumber(texInd), texcoords)
			normInd = absInd(tonumber(normInd), normals)
			print("splitted:", vertInd, texInd, normInd)

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
		print("line:", line)
		params = split(line, "%S+")
		local cmd = table.remove(params, 1)
		print("cmd:",cmd)
		if instructions[cmd] then
			instructions[cmd](params)
		end

	end
	print("normals#", #normals)
	print("texcoords#", #texcoords)
	local mesh = meshanize(verts, vertInds, "texcoord", texcoords, texInds, "normal", normals, normInds)
	map( mesh.ind, function(i) return i-1 end) --map from 1-based to 0-based indexing.
	return mesh
end
function M.load(fname)
	--decide based on extension
	local name, ext = fname:match("(.-)[.]([^.]+)")
	ext = ext:upper()
	print(fname,name,ext)
	local file = io.open(fname)
	local content = file:read("*all")
	file:close()
	if loaders[ext] then return loaders[ext](content) end
	error("No loader present for " .. ext .. " filetype.")
end

Mesh = O.class()
--constructor Mesh([Vector] vertArray, [Int] elementIndexArray, Table attributes) return Mesh
--return Mesh a new Mesh object with the given vertices, that form faces as described in the *elementIndexArray*
--The constructed Mesh object has a set of attributes, such as normals, texure coordinates, etc, that can be passed 
--as a table in the following format:
--	{ "attributeName" = vectorArray, ... }
--example: Mesh( {vec3(1,0,0),vec3(1,1,1),vec3(0,1,1)}, {1,2,3}, {normal={vec3(1,0,0),vec3(0,0,1),vec3(0,1,0)},texcoord={vec2(0,0),vec2(1,1),vec2(.5,.5)}})
function Mesh:__init(verts, ind, attributes)
	self.transform = Matrix.identity(4)
	self.verts = verts
	self.ind = ind
	self.attributes = attributes or {}
	self.attributes["position"] = verts
	self.attributes["pos"] = verts
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
function Mesh:reset()
	self.transform = Matrix.identity(4)
end
function Mesh:translate(v)
	self.transform:translate(v)
end
function Mesh:scale(s)
	self.transform:scale(s)
end
function Mesh:rotate(...)
	self.transform:rotate(...)
end
function Mesh:__tostring()
	local str = {}

	table.insert(str, "index")
	table.insert(str, "\t")
	table.insert(str, "vertex")
	for name,_ in pairs(self.attributes) do
		print(name, _)
		table.insert(str, "\t")
		name = "..."
		table.insert(str, name)
	end
	table.insert(str, "\n")
	for _,i in ipairs(self.ind) do
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
