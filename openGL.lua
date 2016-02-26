local ctypes = require('ctypes')

local context = {}
function getContext(canvas)

	canvas=canvas or js.global.glCanvas or "GLCanvas"
	if context[canvas] then return context[canvas] end

	if type(canvas) == "string" then
		canvas = js.global.document:getElementById(canvas)
	end

	local glObj = canvas:getContext("webgl") or canvas:getContext("experimental-webgl")
	assert(glObj, "could not get openGL context")

	glObj.viewportWidth = canvas.width
	glObj.viewportHeight = canvas.height

	local sizes = {
		[glObj.FLOAT] = 4,
		[glObj.FLOAT_VEC2] = 8,
		[glObj.FLOAT_VEC3] = 12,
		[glObj.FLOAT_VEC4] = 16,
		[glObj.UNSIGNED_SHORT] = 2;
		[glObj.UNSIGNED_INT] = 4;
		[glObj.INT] = 4,
		[glObj.INT_VEC2] = 8,
		[glObj.INT_VEC3] = 12,
		[glObj.INT_VEC4] = 16,
	}
	local compat = { --define opengl->webgl compatability functions
		glGetProgramiv=function(program, value)
			return glObj.getProgramParameter(program, value)
		end,
		glGenBuffers=function(n)
			n=n or 1
			local buffs = {}
			for i=1,n do table.insert(buffs,glObj:createBuffer(n)) end
			return table.unpack(buffs)
		end,
		glBufferData=function(target, n, data, hints)
			return glObj:bufferData(target, data, hints)
		end
	}
	-- make a thin proxy table for the gl object to abstract some things away,
	-- like using ":" for all the js calls. we will just wrap a function around
	-- them...
	-- also, having to access things as glFuncName, rather than webgl's funcName
	local mt = {}
	local function capitalize(str)
		if type(str)~="string" or #str<1 then return end
		local c,str = str:match('(.)(.*)')
		return c:lower() .. str
	end
	mt.__index = function(t,k)
		local obj = glObj[k] or glObj[k:match('^GL_(.*)')] or glObj[capitalize(k:match('^gl(.*)'))] 
		if type(obj)=="userdata" and getmetatable(obj) then
			t[k] = function(...)
				return obj(glObj, ...)
			end
			return t[k]
		end
		return obj
	end

	mt.__newindex = function(t,k,v)
		glObj[k] = v
	end
	local function sizeof(type)
		return sizes[type]
	end

	compat.canvas = canvas
	compat.context=glObj

	compat.sizeof=sizeof
	compat.NULL_BUFFER=nil
	context[canvas] = setmetatable(compat, mt), canvas
	return context[canvas]
end

return getContext(canvas)
