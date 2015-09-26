-- matrix/vector and quaternion implementations: https://github.com/Wiladams/TINN/tree/master/src/graphicsZ

--local LIBPATH = "drawlib."
LIBPATH = (select('1', ...):match("(.*[/])[^/]*")) or ""
--LIBPATH = "tripping-happiness/"
-- add ffi libs to package path
require(LIBPATH.."ffipath")
-- load opengl
local ffi = require("ffi")
local gl = require("ffi/OpenGL")
local glfw = require("ffi/glfw")
-- load my code :D
local O = require(LIBPATH.."object")
local S = require(LIBPATH.."shaders")

local V = require(LIBPATH.."vector")
local Matrix = require(LIBPATH.."matrix")
local Camera = require(LIBPATH.."camera")
local Mesh = require(LIBPATH.."mesh")
local Types = require(LIBPATH.."types")


local G = {}

--local print = function(...) end

-- class declarations
local VAO = O.class()
local VBO = O.class()
local EAB = O.class(VBO)
local Window = O.class()

-- export classes
G.Camera = Camera
G.Mesh = Mesh
G.Vector = V
G.Matrix = Matrix

-- globals
local shaderList = {}
local windowList = nil --list of all created windows
local basicColorProg = nil

local glTypes = {}
glTypes[gl.GL_FLOAT] = "GLfloat"
glTypes[gl.GL_INT] = "GLint"
glTypes[gl.GL_UNSIGNED_INT] = "GLuint"

context = nil
local camera = Camera()

-- table to collect and store drawing operations
local drawOps = {}
drawOps["POLY"] = {} -- arbitrary 2d polygons
drawOps["MESH"] = {} -- 3d meshes

local shader2D

function G.init()
	assert( glfw.glfwInit() )
	glfw.glfwWindowHint( glfw.GLFW_DEPTH_BITS, 16)
	glfw.glfwWindowHint( glfw.GLFW_CONTEXT_VERSION_MAJOR, 3)
	glfw.glfwWindowHint( glfw.GLFW_CONTEXT_VERSION_MINOR, 3)
	--glfw.glfwWindowHint( glfw.GLFW_SAMPLES, 4)
	--glfw.glfwWindowHint( glfw.GLFW_OPENGL_FORWARD_COMPAT, gl.GL_TRUE)
	--glfw.glfwWindowHint( glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE)
end

function G.time()
	return glfw.glfwGetTime()
end

function G.useCamera(cam)
	camera = cam
end

--initialize 2D rendering
function G.init2D()
	shader2D = G.Shader("simple2.vertex", "simple2.frag", {size=4, name="position"}, {size=4, name="color"})
	gl.glClearColor(0, 0.2, 0.4, 0)
	print("init 2D drawing")
end

function G.terminate()
	-- close all open windows
	if windowList then
		for window, _ in pairs(windowList) do
			print( window, _ )
			window:close()
		end
	end
	if shaderList then
		for _, shader in pairs(shaderList) do
			print("killing a shader.")
			shader:destroy()
		end
	end
	glfw.glfwTerminate()
end

function G.newWindow( title, width, height, fullscreen )
	return Window(title, width, height, fullscreen)
end

function G.loadShaders( vFile, fFile)
	return S.loadShaders(vFile, fFile)
end
function G.mesh( mesh )
	table.insert(drawOps["MESH"], mesh)
end

function G.clear()
	gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
end

G.Shader = O.class()
function G.Shader.__init(self, vFile, fFile, ...)
	local attributes = {...}
	self.attributes = {}

	self.prog = G.loadShaders(vFile, fFile)
	local ptSize = 0
	local dims = {}
	for _,attrib in ipairs(attributes) do
		ptSize = ptSize + attrib.size
		table.insert(dims, attrib.size)
		table.insert(self.attributes, attrib.name)
	end
	for k,v in pairs(dims) do
		print(k,v)
	end
	for k,v in pairs(self.attributes) do
		print(k,v)
	end
	self.vao = VAO()
	print("NEWSHADER!", #dims)
	self.vbo = VBO(gl.GL_FLOAT, unpack(dims))
	self.eab = EAB()

	local offset = 0
	for _,attrib in ipairs(attributes) do
		print("binding:", attrib.name, attrib.size, offset)
		self.vao:bindAttribute( gl.glGetAttribLocation(self.prog, attrib.name), self.vbo ,attrib.size, offset)
		offset = offset + attrib.size
	end
	table.insert(shaderList, self)
end
function G.Shader:destroy()
		gl.glDeleteProgram(self.prog)
		self.vbo:destroy()
		self.eab:destroy()
		self.vao:destroy()
end
function G.uniform(shader, name, value)
	local prog = shader.prog
	local location = gl.glGetUniformLocation(prog, name)
	gl.glUniform1f(location, value)
end
function G.draw3D(shader)
	-- draw all 3D meshes with the given shader program
	local prog = shader.prog
	local vao = shader.vao
	local vbo = shader.vbo
	local eab = shader.eab
	
	gl.glUseProgram( prog )
	local mvpLocation = gl.glGetUniformLocation(prog, "mvpMatrix")

	for i,mesh in ipairs( drawOps["MESH"] ) do
		local transform = mesh.transform * camera.transform * camera.perspective
		local ind = mesh.ind
		local pts = mesh.verts
		local attributes = {}
		for _,attribName in ipairs(shader.attributes) do
			local buffer = mesh.attributes[attribName] or Types.DefaultTable(function() return V.vec1(0) end)
			table.insert(attributes, buffer)
			--print("ATTRIBUTE:",attribName)
		end


		print2 = function(i) print(":", i) return i end

		--[[
		print("ind:"); map(ind, print2)
		print("pos:"); map(attributes[1], print2)
		print("norm:"); map(attributes[2], print2)
		--print("color:"); map(attributes[3], print2)
		--]]

		gl.glUniformMatrix4fv(mvpLocation, 1, gl.GL_FALSE, transform.usrdata)
		-- buffer and send points
		vbo:bufferPoints(unpack(attributes))
		eab:bufferPoints( ind )
		vao:bind()
		eab:bind()
		gl.glDrawElements(gl.GL_TRIANGLES, #ind, eab.datatype, ffi.cast("void*",0))
		eab:unbind()
		vao:unbind()
	end
end

function map(list, func)
	for k,v in ipairs(list) do
		list[k] = func(v)
	end
end

function G.draw2D(shader)
	-- draw all polygons with a simple color shader
	local r,g,b = 1,0,1
	local prog = shader2D.prog
	local vao2D = shader2D.vao
	local vbo2D = shader2D.vbo


	gl.glUseProgram( prog )
	local mvpLocation = gl.glGetUniformLocation(prog, "mvpMatrix")
	gl.glUniformMatrix4fv(mvpLocation, 1, gl.GL_FALSE, Matrix.identity(4).usrdata)
	gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	for i,op in ipairs( drawOps["POLY"] ) do
		local color = op.color
		local pts = op.pts
		local colors = {}
		for _=1,#pts do
			table.insert( colors, V.vec3(color.r, color.g, color.b, 1))
		end
		-- buffer and send points
		vbo2D:bufferPoints(pts, colors)
		--vbo2D:bufferPoints(pts)
		vao2D:bind()
		gl.glDrawArrays(gl.GL_TRIANGLE_FAN, 0, #pts)
		vao2D:unbind()
	end
end
function G.clear()
	gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
end
function G.clear2D()
	for i,_ in ipairs( drawOps["POLY"] ) do
		drawOps["POLY"][i] = nil
	end
end
function G.circle(center, radius, color)
	assert(center, "G.circle: no center")
	assert(radius, "G.circle: no radius")

	local n = 10
	local theta = 360 / n
	local tangential = tan(theta) * radius
	local radial = cos(theta)

	local v = V.vec2(radius,0)
	local points = {}
	local p = center + v
	for n = 1,n do
		table.insert(p)
		v:set( p.y, -p.x )
		v:scale( tangential )
		p = p + v
		p:scale( radial )
	end
	G.polygon(points, color)
end

function G.line(p1, p2a, width, color)
	width = width or 1
	G.circle(p1,width)
	G.circle(p2,width)

	local offset = V.vec2(y2-y1,x2-x1)
	offset:normalize()
	offset:scale(width)

	G.polygon({p1+vec,p1-vec, p2-vec,p2+vec},color)
end


function G.polygon(points, color)
	color = color or {r=1,g=1,b=1}
	table.insert(drawOps["POLY"], {pts=points, color=color})
end

function G.rect(p1, p2, color)
	--local p3 = V.vec2(p1.x, p2.y)
	--local p4 = V.vec2(p2.x, p1.y)
	local p3 = V.vec2(p1.usrdata[0], p2.usrdata[1])
	local p4 = V.vec2(p2.usrdata[0], p1.usrdata[1])
	G.polygon({p1, p3, p2, p4}, color)
end

function Window.__init(self, title, width, height, fullscreen)
	assert(title, "no title.")
	width = width or 640
	height = height or 480
	if not fullscreen then fullscreen = false end

	width, height = 100, 100
	local win = assert(
		--ffi.gc( glfw.glfwCreateWindow( width, height, glfw.GLFW_WINDOWED, title, nil), glfw.glfwDestroyWindow)) -- bad API..
		ffi.gc( glfw.glfwCreateWindow( width, height, title, nil,  nil), glfw.glfwDestroyWindow))
	local window = {}
	self.usrdata = win

	self.lastFPS = glfw.glfwGetTime()
	self.frameCount = 0
	self.open = true
	self:onClose( function(win)
		print("closing")
		self.open = false
		return 0
	end)
	self:onResize( function(win, x, y)
		print( "resize:", x, y)
		self.width = x
		self.height = y
		if camera then camera:recalculate() end
		gl.glViewport( 0,0, x,y)
	end)
	if not windowList then
		windowList = {}
		self:makeCurrent()
	end
	windowList[self] = true
end

function Window:getSize()
	local width = ffi.new("int[1]")
	local height = ffi.new("int[1]")
	glfw.glfwGetWindowSize(self.usrdata, width, height)
	return width[0],height[0]
end
function Window:makeCurrent()
	glfw.glfwMakeContextCurrent( self.usrdata )
	gl.glEnable(gl.GL_DEPTH_TEST)
	gl.glDepthMask(gl.GL_TRUE)
	gl.glDepthFunc(gl.GL_LEQUAL)
	gl.glDepthRange(0,1)
	gl.glClearDepth(1)
	context = self
end
--function Window:swapBuffers() swap graphics buffers for this window
function Window:swapBuffers()
	glfw.glfwSwapBuffers(self.usrdata)
	self.frameCount = self.frameCount + 1
end

--function Window:poll() polls the event loop for ALL windows.
function Window:poll()
	glfw.glfwPollEvents()
end
jit.off(Window.poll)

--function Window:close() Close this window
function Window:close()
	glfw.glfwDestroyWindow(self.usrdata)
	self.open = false
	windowList[self] = nil
end

--function Window:fps() return the average frames per second drawn to this window
function Window:fps()
	local now = glfw.glfwGetTime()
	local fps = self.frameCount / (now - self.lastFPS)
	self.frameCount = 0
	self.lastFPS = now
	return fps
end

function Window:onClose( func )
	assert(func, "no function given for Window:onClose")
	glfw.glfwSetWindowCloseCallback( self.usrdata, func )
end

function Window:onResize( func )
	assert(func, "No function given for Window:onResize")
	glfw.glfwSetWindowSizeCallback( self.usrdata, func )
end




--function VAO.new() return VAO a new VAO object
function VAO.__init(self)
	local vao = ffi.new("GLint[1]")
	gl.glGenVertexArrays(1, vao)
	gl.glBindVertexArray(vao[0])
	self.usrdata = vao
end
--function VAO:destroy() free resources of this VAO object
function VAO:destroy()
	gl.glDeleteVertexArrays(1, self.usrdata)
	self.usrdata=nil
end
-- function VAO:bind() binds this VAO so it can be used
function VAO:bind()
	gl.glBindVertexArray(self.usrdata[0])
end
-- function VAO:unbind() unbinds this VAO so it can't be used.
function VAO:unbind()
	gl.glBindVertexArray(0) -- Disable VAO
end
-- function VAO:bindAttribute(Int location, VBO buffer, Int count, Int datatype, Bool normalize ) binds the VBO to this VAO at the location specified. after this call the VAO and VBO are unbound.
function VAO:bindAttribute(location, buffer, count, offset, normalize)
	assert(location, "invalid parameters to VAO.bindAttribute")
	assert(buffer, "invalid parameters to VAO.bindAttribute")
	count = count or buffer.dim or 1
	print(offset)
	offset = offset*ffi.sizeof(glTypes[buffer.datatype]) or 0
	print(offset)
	offset = ffi.cast("void*", offset)
	normalize = normalize or false
	--if not normalize then normalize = false end
	

	local stride = (buffer.dim) * ffi.sizeof( glTypes[ buffer.datatype ] )
	local datatype = buffer.datatype

	print("binding attribute:", location, count, offset, stride)

	self:bind()
	buffer:bind()
	gl.glEnableVertexAttribArray(location)
	--bind active VBO to attribute location in this VAO.
	gl.glVertexAttribPointer(location, count, datatype, normalize, stride, offset)

	buffer:unbind()
	self:unbind()
end


--function VBO.new() return VBO a new VBO object
function VBO.__init(self, datatype, ...)
	local vbo = ffi.new("GLint[1]")
	gl.glGenBuffers(1, vbo)
	self.usrdata = vbo
	self.target = gl.GL_ARRAY_BUFFER
	self.dims = {...}
	self.dim = 0
	print("NEWVBO!")
	for _,i in ipairs(self.dims) do
		print("dim:", _, i)
		self.dim = self.dim + i
	end
	self.datatype = datatype
	self.hints = hints or gl.GL_DYNAMIC_DRAW
end
--function VBO:destroy() free resources of this VBO object
function VBO:destroy()
	gl.glDeleteBuffers(1, self.usrdata)
	self.usrdata=nil
end
--function VBO:bufferData([GLFloat] data, GLint bufferType, GLint hints)
--move a float array into this VBO, using the given buffer type and buffer hints. If not provided, bufferType defaults to GL_ARRAY_BUFFER, hints defaults to GL_STATIC_DRAW
function VBO:bufferData(data, datatype, target, hints)
	target = target or self.target or gl.GL_ARRAY_BUFFER
	hints = hints or self.hints or gl.GL_DYNAMIC_DRAW
	self:bind(target)
	gl.glBufferData( target, ffi.sizeof(data), data, hints)
	self:unbind(target)
	self.data = data -- keep a reference to data to prevent GC
end

--function VBO:bufferPoints([Vector], ...)
--Add the vectors to this VBO, as a GL_ARRAY_BUFFER of GLFloat's. 
function VBO:bufferPoints( ... )
	local ptBuffers = {...}
	local pad = self.dim
	local nPts = #ptBuffers[1]
	--[[
	for _,pts in ipairs(ptBuffers) do
		local dim
		if type(pts[1]) == "number" then
			dim = 1
		else
			dim = pts[1].dim
		end
		pad = pad - dim
	end
	--]]
	
	--print("data size:", nPts, self.dim, nPts*self.dim)
	local data = ffi.new(glTypes[self.datatype].."[?]", nPts*self.dim) -- allocate data
	local n = 0
	for j = 1,nPts do
		for bufferIdx,pts in ipairs(ptBuffers) do
			--buffer this data
			local p = pts[j]
			local dim

			if type(p) == "number" then
				dim = 1
				data[n] = p
			else --assume Vector class
				dim = p.dim
				local usrdata = p.usrdata
				for i = 0,dim-1 do
					data[n + i] = usrdata[i]
				end
			end

			n = n + dim
			local pad = self.dims[bufferIdx] - dim
			if pad>0 then
				for i = 0,pad-1 do
					data[n + i] = 0
					--print(n+i)
				end
				n = n + pad
			end
		end
	end

	--for i=0,nPts*self.dim-1 do
		--print(data[i])
	--end
	self:bufferData(data, self.datatype, self.target, gl.GL_DYNAMIC_DRAW)
end
--function VBO:bufferPoints([Vector], ...)
--Add the vectors to this VBO, as a GL_ARRAY_BUFFER of GLFloat's. 
--[[
function VBO:bufferPoints2(points)
	local dim = points[1].dim -- how many dimensions per points?
	local pad = self.dim - dim
	local data = ffi.new(glTypes[self.datatype].."[?]", #points*self.dim) -- allocate data
	local n = 0
	for _,p in ipairs(points) do
		-- add this point to the array
		local usrdata = p.usrdata
		for i = 0,dim-1 do
			data[n + i] = usrdata[i]
		end
		n = n + dim
		if pad>0 then
			for i = 0,pad-1 do
				data[n + i] = 0
			end
			n = n + pad
		end
	end
	self:bufferData(data, self.datatype, gl.GL_ARRAY_BUFFER)
end
--]]

--function VBO:bind(GLint target) bind this buffer to the specified target, or to GL_ARRAY_BUFFER if not specified
function VBO:bind(target)
	target = target or self.target or gl.GL_ARRAY_BUFFER
	gl.glBindBuffer(target, self.usrdata[0])
end

--function VBO:unbind(GLint target) remove any binding for the specified target, or for GL_ARRAY_BUFFER if not specified
function VBO:unbind(target)
	target = target or self.target or gl.GL_ARRAY_BUFFER
	gl.glBindBuffer(target, 0)
end

function EAB.__init(self)
	VBO.__init(self, gl.GL_UNSIGNED_INT, 1)
	self.target = gl.GL_ELEMENT_ARRAY_BUFFER
end
--function EAB:bind() bind this buffer as an Element Array Buffer.
function EAB:bind()
	gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.usrdata[0])
end
--function EAB:unbind() unbind this element array buffer
function EAB:unbind()
	gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)
end

G.init()

return G
