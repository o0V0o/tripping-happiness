-- this module provides helper functions to create native types for things like
-- buffers, vectors, and matrices. 
--
local c={}

--checks if a table is given, of if a number is given
--if a number is given, it makes a table of zeros, with a length equal to the
--number specified
local function fillarray(tbl)
	if type(tbl) == 'number' then
		local tmp = {}
		for i=1,tbl do 
			tmp[i]=0
		end
		return tmp
	end
	return tbl
end
function c.array(tbl)
	tbl = fillarray(tbl)
	assert(type(tbl)=="table", "array: type must be Table or Number")
	return js.global:jsArray(tbl)
end
function c.intArray(tbl)
	tbl = fillarray(tbl)
	assert(type(tbl)=="table", "intArray: type must be Table or Number")
	return js.global:jsInt32Array(tbl)
end
function c.shortArray(tbl)
	tbl = fillarray(tbl)
	assert(type(tbl)=="table", "shortArray: type must be Table or Number")
	return js.global:jsInt16Array(tbl)
end
function c.floatArray(tbl)
	tbl = fillarray(tbl) 
	assert(type(tbl)=="table", "floatArray: type must be Table or Number")
	return js.global:jsFloat32Array(tbl)
end

function c.copy(v2)
	return v2:slice()
end

return c
