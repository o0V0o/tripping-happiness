local c={}

function c.floatArray(tbl)
	return js.global:jsFlaot32Array(tbl)
end

function c.copy(v2)
	return v2:slice()
end
