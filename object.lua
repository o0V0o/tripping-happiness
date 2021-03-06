local Object = {}
--function Object.class( parent )
function Object.class( parent ,getter, setter)
	local class = {}
	local objMt = class
	local classMt = {}
	if parent then
		for k,v in pairs(parent) do
			print("Copy:", k, v)
			objMt[k] = v
		end
		class.super = parent
		classMt.__index = parent
	else
		classMt.__index = nil
	end

	if setter then
		local private = {} -- private table that will be closed over in the __newindex function, and not available elsewhere
		objMt.__newindex = function(self, key)
			setter(self, private, key)
		end
	end

	if getter then
		objMt.__index = function(self, key)
			local val = class[key]
			if not val then
				val = getter( self, key )
			end
			return val
		end
	else
		objMt.__index = class
	end


	function classMt.__call(class,...)
		local self = {}
		setmetatable(self, objMt)
		self.super = class
		if self.__init then self.__init(self,...) end
		return self
	end
	return setmetatable(class,classMt), objMt
end

--function Object.clone(Object) return Connector a copy of this connector
function Object.clone(self)
	local clone = {}
	for k,v in pairs(self) do
		clone[k] = v
	end
	return setmetatable(clone, getmetatable(self))
end

return Object
