require('strict')
local oldprint = print
local ctypes = require('ctypes')
print(".")
local Shader = require'shader'
print(".")
local M = require('mesh')
print(".")
local G = require('drawlib')
print(".")
local Matrix = require('matrix')
print(".")
local vec3 = require("vector").vec3
print(".")
local SimpleObject = require('SimpleObject')
print(".")
local Image = require("image")
print(".")
local Texture = require('texture')
print(".")
local platform = require('platform')


local gl = require("openGL")


local shader = Shader("shaders/textured.vs", "shaders/textured.fs")


local cubemesh = M.load("cube.obj")
local spheremesh, monkeymesh = cubemesh, cubemesh
--local spheremesh = M.load("sphere.obj")
local monkeymesh = M.load("suzanne-cubemap.obj")
--local monkeymesh = M.load("suzanne-cylindermap.obj")

local attributeMap = {
	position = 'position',
	normal = 'normal',
	vTex = "texcoord"
}

local cube = SimpleObject( cubemesh )
local sphere = SimpleObject( spheremesh )
local monkey = SimpleObject( monkeymesh )

local update
local t = Texture()
local img = Image('cactuar.gif', function(img)
	t:buffer(img)
	t:activate()
end)



shader:use()
gl.glClearColor(1,1,1,1)
G:clear()
for k,v in pairs(cube.mesh.attributes) do print(k,v,#v) end
cube:recalculate(shader, attributeMap)
sphere:recalculate(shader, attributeMap)
monkey:recalculate(shader, attributeMap)

shader.color = {1,0,0} --set color to red.
shader.specColor = {1,1,1}
shader.shininess = 1500
shader.kDiffuse = 1
shader.kSpecular = 1.5
shader.kAmbient = 0.3

print("done")

local mvp = Matrix.identity(4)
local theta = 0

local z = -10
local p = Matrix.perspective(0.1,100,1,45)
local v = Matrix.lookat( vec3(3,3,3), vec3(0,0,0), vec3(0,1,0) )
local m = Matrix.rotate( vec3(0,1,0), theta )
local up = vec3(0,1,0)
shader.perspective = p
shader.view = v

local last, frames = 0,0
function update()
	 frames = frames + 1
	local now = platform.time()
	if now-last >= 1000 then
		print(frames, "fps")
		frames=0
		last = now
	end
	gl.viewport(0,0, gl.canvas.width, gl.canvas.height)
	--G.resize(100,100)
	G.clear()
	theta = theta + .05
	m:rotate( up, 0.05 )
	shader.model = m
	shader.diffuseTexture = t:activate()

	--shader.mvpMatrix = m*v --reset uniform
	shader.model = m

	--cube:draw(shader)
	--sphere:draw(shader)
	monkey:draw(shader)
	js.global:requestAnimationFrame(update)
end
update()
