local libname = "drawlib."
local O = require(libname.."object")
local V = require(libname.."vector")
local Matrix = require(libname.."matrix")
local types = require(libname.."types")

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

--[[
--function convexMesh(verts) return Mesh
-- create a convex hull mesh from these vertices.
function convexMesh(pts)
	local verts, ind, normals = {},{},{}
	if #pts < 3 then assert("can't build hull out of 3 points!") end

	local ptsCH, indCH = initialSimplex(pts)

	while true do
	end
end

function nextPoint(...)
	for each face do
		for each pt in conflict do
		end
	end
end

function initialSimplex(pts)
	assert( #pts >=3, "Not enough points to create a 3Dimensional simplex!" )
	-- find AABB and intersecting points.
	local maxima = {{},{},{}}
	local minima = {{},{},{}}
	local boundries = {}
	local max = {}
	local min = {}
	local swizzletable = {"x", "y", "z"}
	-- find the min/max points in each dimension
	for p in pairs(pts) do
		for i=1,3 do
			local DIM = swizzletable[i]
			if not min[i] or p[DIM] < min[i][DIM] then min[i] = p end
			if not max[i] or p[DIM] > max[i][DIM] then max[i] = p end
		end
	end

	--now accumulate all points that lie on the min/max boundry for each dimension
	local function close(p1, p2)
		return distance(p1,p2) < EPSILON
	end
	for p in pairs(pts) do
		for i=1,3 do
			local DIM = swizzletable[i]
			if close(p[DIM], max[i][DIM]) then table.insert(maxima[i], p);table.insert(boundries, p) end
			if close(p[DIM], min[i][DIM]) then table.insert(minima[i], p);table.insert(boundries, p) end
		end
	end
	-- lets check for coincident/colinear/coplanar points.
	local dist = {}
	local dimension = 3
	local maxdim = nil
	for i=1,3 do
		dist[i] = max[i]-min[i]
		if not maxdim or dist[i]>maxdim then maxdim = dist[i] end
		if dist[i] < EPSILON then dimension = dimension - 1 end -- test if this dimension has any real dimension to it.
	end
	function coincidence(dim)
		if dim==0 then return "coincident" end
		if dim==1 then return "colinear" end
		if dim==2 then return "coplanar" end
		return "?"
	end
	assert( dimension == 3, "Invalid input for convex hull! points are " .. coincidence(dimension))
	
	-- take the min & max from the largest dimension
	function distance(pt, pts)
		if pts.type = V.Vector then
			return distancePtPt(pt,pts)
		elseif #pts==2 then
			return distancePtLine(pt,pts[0],pts[1])
		elseif #pts==3 then
			return distancePtPlane(pt,pts[0],pts[1],pts[2])
		else
			error("Unable to find distance with "..#pts.." dimensional object")
		end
	end
	function distancePtPt(p1,p2)
		return (p2-p1):magnitude()
	end
	function distancePtLine(pt, ro, rd)
		-- taken from http://onlinemschool.com/math/library/analytic_geometry/p_line/
		return math.abs(  (p-ro):cross(rd) / rd:magnitude()  )
	end
	function distancePtPlane(pa, pb, n)
		-- taken from http://paulbourke.net/geometry/pointlineplane/
		local D = -1 * (n.x*pb.x + n.y*pb.y + n.z+pb.z)
		return (n.x*pa.x + n.y*pa.y + n.z*pa.z + D) / n:magnitude()
	end
	local ptsCh maxdist maxP1 maxP2 = {},0
	error("Need to define point-line distance")
	--lets find the first 2 points...
	for _,p1 in pairs(boundries) do
		for _,p2 in pairs(boundries) do
			if distance(p1,p2) > maxDist then 
				maxDist = distance(p1,p2)
				maxP1 = p1
				maxP2 = p2
			end
		end
	end
	table.insert(ptsCH, maxP1)
	table.insert(ptsCH, maxP2)
	-- now find and add the remaining 2 points
	for _ = 3,4 do
		for p in pairs(boudries) do
			if not table.elememt(ptsCH, p) and (maxp == nil or distance(p, ptsCH) > maxdist) then --use the magic distance function to calculate pt-line and pt-plane distances
				maxp = p
				maxdist = distance(p, line)
			end
		end
		table.insert(ptsCH, maxp)
	end
	indCH = {1,2,3,1,2,4,2,3,4,1,3,4}
	return ptsCh, indCh
end
--]]

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
	assert(file, "Could not open file:" .. fname)
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
function Mesh:linkTo( mesh )
	self.verts = mesh.verts
	self.ind = mesh.ind
	self.attributes = mesh.attributes
	self.transform = mesh.transform
	return self
end
function Mesh:copyFrom( mesh )
	self.verts = {}
	for k,v in pairs(mesh.verts) do self.verts[k] = v:copy() end
	self.ind = {}
	for k,v in pairs(mesh.ind) do self.ind[k] = v:copy() end
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
