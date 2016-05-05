--this module forces all variables to be LOCAL, and will raise an error on any
--global access. 
local g = _G

--ensure we have a traceback function.
local traceback = (debug and debug.traceback) or function() return "..." end
_G = setmetatable(g, {
	__index=function(t,k)
		local stacktrace = "\n"..traceback()
		error("accessing global variable "..k..stacktrace)
	end,
	__newindex=function(t,k,v)
		rawset(t,k,v)
		local stacktrace = "\n"..traceback()
		error("using global variable "..k..stacktrace)
	end
})
