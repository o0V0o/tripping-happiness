local libname = "drawlib."
local O = require(libname.."object")
local V = require(libname.."vector")
local Matrix = require(libname.."matrix")
local types = require(libname.."types")


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
	print("split:", p, unpack(t))
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

--function convexMesh([vec3]) return Mesh
-- create a convex hull mesh from these vertices.
function M.convexHull(pts)
	local verts, ind, normals = {},{},{}

	local faces, ptsCH, indCH = initialSimplex(pts)

	
	local pt
	
	--local normals, normInds = M.normalize(ptsCH, indCH)


	--map( ptsCH, function(pt) return V.Vector(4, pt, 1) end) -- meshes need vec4 matrix math
	--return M.meshanize(ptsCH, indCH, "normal",normals, normInds)
end

local Hull = O.class()
function Hull:__init( pts )
	self:initialSimplex()
end
function Hull:calculate()
	while true do
		pt,face = self:nextPt()
		if not pt then break end
		self:addPt(face, pt)
	end
end
function Hull:addPt(face,pt)
	local horizon = {}
	self:horizonTest(face, pt, horizon)

	for _, face in pairs(horizon) do
		-- make a triangle from each edge of the horizon to the new pt
		
	end
	return faces
end
function Hull:nextPt()
	local maxPt, maxFace, maxDist = nil, nil, 0
	for _, face in pairs( self.faces) do
		for pt in pairs(face.conflict) do
			local dist = distancePtPlane(pt, face.pt, face.normal)
			if dist > maxDist then
				maxPt=pt
				maxDist = dist
				maxFace = face
			end
		end
	end
	return maxPt, maxFace
end
function Hull:horizonTest(face, pt, horizon)
	if not self:visible( pt ) then return --escape condition
	else table.insert(horizon, face) end

	for face in pairs(self.faceGraph[face]) do
		self:horizonTest(face, pt, horizon)
	end
end

local Triangle = O.class()
function Triangle:__init(pts)
	for i,pt in ipairs(pts) do
		self[i] = pt
	end
end

local Face = O.class()
--[[
function Face:__init(triangles)
	self.triangles = triangles
	local pt1 = triangles[1][1]
	local pt2 = triangles[1][2]
	local pt3 = triangles[1][3] 
	self.normal = (pt1-pt2):cross(pt3-pt2)
	self.pt = pt1
	self.edges = ...
	self.neighbors = ... 
	self.conflict = {}
	print("Face:", self.normal, self.pt )
end
--]]
function Face:__init(edges)
	self.edges = edges
end
function Face:visible(pt)
	return true
end


local EPSILON = .05

function Hull:initialSimplex()
	local pts = self.pts
	assert( #pts >=3, "Not enough points to create a 3Dimensional simplex!" )
	-- find AABB and intersecting points.
	local min, max, boundries, ptsCH = {}, {}, {}, {}
	local swizzletable = {"x", "y", "z"}

	-- find the min/max points in each dimension
	for _,p in pairs(pts) do
		for i=1,3 do
			local DIM = swizzletable[i]
			print(DIM, p[DIM], min[i], i)
			if not min[i] or p[DIM] < min[i][DIM] then min[i] = p;table.insert(boundries, p) end
			if not max[i] or p[DIM] > max[i][DIM] then max[i] = p;table.insert(boundries, p) end
		end
	end

	-- lets check for coincident/colinear/coplanar point sets.
	--  NYI
	
	-- take the min & max from the largest dimension
	local ptsCh, maxDist, maxP1, maxP2 = {},0
	--lets find the first 2 points... (may be on the same boundry plane)
	for _,p1 in pairs(boundries) do
		for _,p2 in pairs(boundries) do
			if distance(p1,p2) > maxDist then 
				maxDist = distance(p1,p2); maxP1 = p1; maxP2 = p2
			end
		end
	end
	table.insert(ptsCH, maxP1); table.insert(ptsCH, maxP2)

	-- now find and add the remaining 2 points
	for _ = 3,4 do
		maxDist = 0
		for _,p in pairs(boundries) do
			if (maxp == nil or distance(p, ptsCH) > maxDist) then --use the magic distance function to calculate pt-line and pt-plane distances
				maxp = p
				maxDist = distance(p, ptsCH)
			end
		end
		table.insert(ptsCH, maxp)
	end
	indCH = {1,2,3,4,2,1,4,3,2,1,3,4}
	local faces = asHalfEdges( ptsCH, indCH )


	-- make a Face object for each triangle
	faces = {}
	table.insert(self.faces, Face( {Triangle{ptsCH[1],ptsCH[2],ptsCH[3]}} ))
	table.insert(self.faces, Face( {Triangle{ptsCH[4],ptsCH[2],ptsCH[1]}} ))
	table.insert(self.faces, Face( {Triangle{ptsCH[4],ptsCH[3],ptsCH[2]}} ))
	table.insert(self.faces, Face( {Triangle{ptsCH[1],ptsCH[3],ptsCH[4]}} ))

	assignConflict(self)

	return self
end

local function Edge(edges, pt1, pt2)
	local self, twin
	-- test if this edge or its twin already exist
	if edges[pt1][pt2] then
		self = edges[pt1][pt2]
		twin = edges[pt2][pt1]
	else
		self, twin = {}, {}
		self.tail = pt1
		twin.tail = pt2
		self.twin = twin
		twin.twin = self
		if not edges[pt1] then edges[pt1]={} end
		if not edges[pt2] then edges[pt2]={} end
		edges[pt1][pt2] = self
		edges[pt2][pt1] = twin
	end
	return self
end
local function asHalfEdges( pts, ind )
	local edges, faces = {}, {} 
	for i = 1, #ind, 3 do
		local p1,p2,p3 = pts[ind[i]], pts[ind[i+1]], pts[ind[i+2]]
		local e1 = Edge(edges,p1, p2)
		local e2 = Edge(edges,p2, p3)
		local e3 = Edge(edges,p3, p1)
		e1.next = e2; e1.prev = e3
		e2.next = e3; e2.prev = e1
		e3.next = e1; e3.prev = e2
		table.insert(faces, Face( {e1,e2,e3} ))
	end
	return faces
end
local function asMesh( faces )
	local face = faces[1] -- start somewhere...

end
local function asMeshRecursion(edge)
	local nextEdge
	while nextEdge~=edge do
		asMeshRecursion( edge.twin )
		nextEdge = edge.next
	end
end

local function assignConflict(self)
	local faces, pts = self.faces, self.pts
	assert(#faces>0, "can't assign conflict points without any faces")
	for pt in pairs( pts ) do
		-- find the closest face
		local minDist, closestFace = nil, nil
		for face in pairs( faces ) do
			if testSidedness(face, pt) then -- if point on the outside of this face
				local dist = distancePtPlane(pt, face.pt, face.normal )
				if not minDist or dist<minDist then minDist = dist; closestFace = face end
				--table.insert( self.ptVisibility[pt], face )
				--self.ptVisibility:add(pt, face) -- doubly linked hash table
			end
		end
		if closestFace then
			table.insert( closestFace.conflict, pt )
		else
			-- this face is not on the hull. forget about it.
		end
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
		table.insert(meshInds, indexOf(vertInd, unpack(t)))
	end
	print("Making Mesh:", table.unpack(meshInds))
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
	local mesh = M.meshanize(table.unpack( args))
	local mesh = M.meshanize(verts, vertInds, "texcoord", texcoords, texInds, "normal", normals, normalInds)
	local mesh = M.meshanize(verts, vertInds, "blah", {}, normInds)
	local mesh = M.meshanize(verts, vertInds) 
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
--constructor Mesh([Vector] vertArray, [Int] elementIndexArray, Table attributes) 
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
		table.insert(str, "\t")
		table.insert(str, name)
	end
	table.insert(str, "\n")
	for _,i in ipairs(self.ind) do
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
