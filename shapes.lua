--this module provides helper functions to draw 2D shapes out of triangles.
--
local gl = require("OpenGl")
local vec2 = require("vector").vec2
local sin, cos, tan = math.sin, math.cos, math.tan

local Shapes = {}

function Shapes.circle(center, radius, color)
	assert(center, "G.circle: no center")
	assert(radius, "G.circle: no radius")

	local n = 10
	local theta = 360 / n
	local tangential = tan(theta) * radius
	local radial = cos(theta)

	local v = vec2(radius,0)
	local points = {}
	local p = center + v
	for n = 1,n do
		table.insert(p)
		v:set( p.y, -p.x )
		v:scale( tangential )
		p = p + v
		p:scale( radial )
	end
	return Shapes.polygon(points, color)
end
function Shapes.line(p1, p2a, width, color)
	width = width or 1
	Shapes.circle(p1,width)
	Shapes.circle(p2,width)

	local offset = vec2(y2-y1,x2-x1)
	offset:normalize()
	offset:scale(width)

	local vec=offset
	return Shapes.polygon({p1+vec,p1-vec, p2-vec,p2+vec},color)
end


function Shapes.polygon(points, color)
	color = color or {r=1,g=1,b=1}
	return {pts=points, color=color}
end

function Shapes.rectangle(p1, p2, color)
	local p3 = vec2(p1.x, p2.y)
	local p4 = vec2(p2.x, p1.y)
	return Shapes.polygon({p1, p3, p2, p4}, color)
end

return Shapes
