local context = {}
function getContext(canvas)
	canvas=canvas or js.global.glCanvas or "GLCanvas"

	if context[canvas] then return context[canvas] end

	if type(canvas) == "string" then
		canvas = js.global.document:getElementById(canvas)
	end

	local glObj = canvas:getContext("webgl") or canvas:getContext("experimental-webgl")

	glObj.viewportWidth = canvas.width
	glObj.viewportHeight = canvas.height
	-- make a thin proxy table for the gl object to abstract some things away,
	-- like using ":" for all the js calls. we will just wrap a function around
	-- them...
	-- also, having to access things as glFuncName, rather than webgl's funcName
	local mt = {}
	mt.__index = function(t,k)
		local obj = glObj[k] or glObj[k:match('^gl(./*)')] or glObj[k:match('^GL_(.*)')]
		if type(obj)=="userdata" and getmetatable(obj) then
			t[k] = function(...)
				return obj(glObj, ...)
			end
			return t[k]
		end
		return glObj[k]
	end

	mt.__newindex = function(t,k,v)
		glObj[k] = v
	end
	context[canvas] = setmetatable({context=glObj}, mt), canvas
	return context[canvas]
end

return getContext(canvas)
