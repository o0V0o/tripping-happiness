-- matrix/vector and quaternion implementations: https://github.com/Wiladams/TINN/tree/master/src/graphicsZ

local gl = require("openGL") --load a file that abstracts away where/how/what opengl is
local platform = require("Platform") --load a file that abstacts away the window/context creation

local class = require("object")
local V = require("vector")
--local Matrix = require("matrix")
--local Camera = require("camera")
--local Mesh = require("mesh")


local G = {}

-- table to collect and store drawing operations
local scene = {}
local resources = {} -- all non GC'd resources should go in here with a destroy method

G.init = platform.init
G.time = platform.time

function G.useCamera(cam)
	camera = cam
end
-- clean up any allocated resources that we can.
function G.terminate()
	for _, obj in pairs(G.resources) do
		print("killing a resource", resource)
		resource:destroy()
	end
	platform.terminate()
end

function G.addObject( mesh )
	table.insert(scene, mesh)
end
function G.clear()
	gl.glClear( bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
end
function G.draw(shader)
	-- draw all 3D meshes with the given shader program
	shader:use()
	for i,mesh in pairs( scene ) do
		mesh:draw(shader, camera)
	end
end

G.init()

return G
