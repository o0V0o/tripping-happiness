
local class = require('object')

local O = class()
function O:__init(...)
	print("Simple Object created:", ...)
end
function O:draw()
	print(NYI)
end

return O
