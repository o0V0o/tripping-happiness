--local ffi = require("ffi") --can we abstract away the ffi interface for generating low-level data?
local ctypes = require("ctypes")
--local gl = require("ffi/OpenGL")
local gl = require("OpenGL") -- load a file to abstract away where/how/what opengl is
local S =  {}

function S.validateProgram( program )
	local int = ffi.new( "GLint[1]" )
	gl.glGetProgramiv(program, gl.GL_INFO_LOG_LENGTH, int)
	local length = int[0]
	if length <= 0 then
		return true
	end
	gl.glGetProgramiv(program, gl.GL_LINK_STATUS, int)
	local sucess = int[0]
	if sucess == gl.GL_TRUE then
		return true
	end
	local buffer = ffi.new( "char[?]", length)
	gl.glGetProgramInfoLog(program, length, nil, buffer)
	print( ffi.string(buffer) )
	return false
end
function S.validateShader( shader )
	local int = ffi.new( "GLint[1]" )

	gl.glGetShaderiv( shader, gl.GL_INFO_LOG_LENGTH, int )
	local length = int[0]
	if length <= 0 then
		return true
	end

	gl.glGetShaderiv( shader, gl.GL_COMPILE_STATUS, int )
	local success = int[0]
	if success == gl.GL_TRUE then
		return true
	end
	local buffer = ffi.new( "char[?]", length )
	gl.glGetShaderInfoLog( shader, length, int, buffer )
	print( ffi.string(buffer) )
	return false
end

function S.compileShader( src, type )
	local shader = gl.glCreateShader( type )
	if shader == 0 then
		print("shader type:", type)
		error( "glGetError: " .. gl.glGetError())
	end
	local src = ffi.new( "char[?]", #src, src )
	local srcs = ffi.new( "const char*[1]", src )
	gl.glShaderSource( shader, 1, srcs, nil )
	gl.glCompileShader ( shader )
	if type == gl.GL_VERTEX_SHADER then
		assert(S.validateShader( shader ), "vertex shader compilation failed")
	elseif type == gl.GL_FRAGMENT_SHADER then
		assert(S.validateShader( shader ), "fragment shader compilation failed")
	end
	return shader
end

local function readFile(fName)
	print("opening:", fName)
	local f = io.open(fName, "rb")
	local content = f:read("*all")
	f:close()
	return content.."\0"
end

function S.loadShaders(vFile, fFile) 
	-- Create the shaders
	local vShader = S.compileShader(readFile(vFile), gl.GL_VERTEX_SHADER)
	local fShader = S.compileShader(readFile(fFile), gl.GL_FRAGMENT_SHADER)

	local program = gl.glCreateProgram()
	gl.glAttachShader(program, vShader)
	gl.glAttachShader(program, fShader)
	gl.glLinkProgram(program)
	assert(S.validateProgram(program), "linking program failed")

	gl.glDeleteShader(vShader)
	gl.glDeleteShader(fShader)

	return program
end

return S
