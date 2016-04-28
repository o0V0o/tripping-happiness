local get = require('get')
local class = require("object")
local V = require("vector")
local Matrix = require("matrix")
local types = require("types")

if not table.unpack then table.unpack = unpack end

local print = function() end


local M = {}
local Mesh = class()

local function map(list, func)
	for k,v in ipairs(list) do
		list[k] = func(v)
	end
end
local function split(p, pattern)
	local t = {}
	for m in p:gmatch(pattern) do
		table.insert(t, m)
	end
	return t
end

local function distancePtPt(p1,p2)
	return (p2-p1):len()
end
local function distancePtLine(pt, ro, rd)
	-- taken from http://onlinemschool.com/math/library/analytic_geometry/p_line/
	print(pt, ro, rd)
	return math.abs(  (pt-ro):cross(rd):len() / rd:len()  )
end
local function distancePtPlane(pa, pb, n)
	-- taken from http://paulbourke.net/geometry/pointlineplane/
	local D = -1 * (n.x*pb.x + n.y*pb.y + n.z+pb.z)
	local dist = math.abs((n.x*pa.x + n.y*pa.y + n.z*pa.z + D) / n:len())
	print("Pt-Plane:", pa,pb,n,dist)
	return dist
end
local function distance(pt, pts)
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
--function M.meshanize(Table attributes) return Mesh
-- Create a mesh from vertices and attributes, where each attribute has its own element index array (all of the same size).
-- each attribute in the table is of the form attributes[name]={inds=[Int], pts=[Vector]}
--
function M.meshanize(attributes)
	local meshAttributes={}

	local nIdx = 0
	for name,attrib in pairs(attributes) do
		print("attribute", name, #attrib.pts, #attrib.inds)
		nIdx = #attrib.inds
		meshAttributes[name]={}
	end

	local nextidx = 0
	local meshInds = {}
	local lut = {} --simple lookup table for already created verts
	print(next(attributes))
	for idx=1,nIdx do
		local lutstr = {}
		for name,attrib in pairs(attributes) do
			table.insert(lutstr,attrib.inds[idx])
		end
		lutstr = table.concat(lutstr)
		local realidx = lut[lutstr]
		if not realidx then
			for name,attrib in pairs(attributes) do
				meshAttributes[name][nextidx+1]=attrib.pts[attrib.inds[idx]]
				print(nextidx, name, meshAttributes[name][nextidx+1])
				if name=='texcoord' then
					print(#attrib.inds, attrib.inds[idx])
					print(attrib.pts, #attrib.pts, attrib.pts[1])
				end
			end
			realidx = nextidx
			lut[lutstr] = realidx
			nextidx = nextidx+1
		end
		table.insert(meshInds, realidx)
	end

	return Mesh(meshInds, meshAttributes)
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
		local v = V.vec4(tonumber(params[1] or 0),
						tonumber(params[2] or 0),
						tonumber(params[3] or 0),
						tonumber(params[4] or 1))
		table.insert(verts, v)
		print("vertex:",v)
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
		local v = V.Vector( nil,
							tonumber(params[1]),
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
			--local vertInd, texInd, normInd = table.unpack( split(p,"([^/]*)/?") )
			local vertInd, texInd, normInd = p:match("(%d*)/(%d*)/(%d*)")
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
		local params = split(line, "%S+")
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
		if type(v)=='table' then
			print(k,v,#v)
		else
			print(k,v)
		end
	end
	print("Attributes Loaded From Obj", #verts, #vertInds, #texcoords, #texInds, #normals, #normInds)
	local attributes = {
		position={inds=vertInds, pts=verts},
		texcoord={inds=texInds, pts=texcoords},
		normal={inds=normInds, pts=normals}
	}
	local mesh = M.meshanize(attributes)

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

--constructor Mesh([Int] elementIndexArray, Table attributes) 
--return Mesh a new Mesh object with the given vertices, that form faces as described in the *elementIndexArray*
--The constructed Mesh object has a set of attributes, such as normals, texure coordinates, etc, that can be passed 
--as a table in the following format:
--	{ "attributeName" = vectorArray, ... }
--	such that each vectorArray is the *same size*, indexed by ind per face
--example: Mesh( {vec3(1,0,0),vec3(1,1,1),vec3(0,1,1)}, {1,2,3}, {normal={vec3(1,0,0),vec3(0,0,1),vec3(0,1,0)},texcoord={vec2(0,0),vec2(1,1),vec2(.5,.5)}})
function Mesh:__init(ind, attributes)
	self.transform = Matrix.identity(4)
	self.verts = attributes.position
	self.indices = ind
	self.attributes = attributes or {}
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
