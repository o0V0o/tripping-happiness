--this module forces all variables to be LOCAL, and will raise an error on any
--global access. 
local g = _G

local exceptions = {}
--ensure we have a traceback function.
local traceback = (debug and debug.traceback) or function() return "..." end
_G = setmetatable(g, {
	__index=function(t,k)
		if not exceptions[k] then
			local stacktrace = "\n"..traceback()
			error("accessing global variable "..k..stacktrace)
		end
	end,
	__newindex=function(t,k,v)
		rawset(t,k,v)
		if not exceptions[k] then 
			local stacktrace = "\n"..traceback()
			error("using global variable "..k..stacktrace)
		end
	end
})

return function(e)
	for _,v in pairs(e) do
		exceptions[v] = true
	end
end
