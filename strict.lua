--this module forces all variables to be LOCAL, and will raise an error on any
--global access. 
local g = _G

_G = setmetatable(g, {
	__newindex=function(t,k,v)
		rawset(t,k,v)
		error("using global variable "..k)
	end})
