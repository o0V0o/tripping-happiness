local oldprint = print
local ctypes = require('ctypes')
local Shader = require'shader'
local M = require('mesh')
local G = require('drawlib')
local Matrix = require('matrix')
local vec3 = require("vector").vec3
local SimpleObject = require('SimpleObject')

local gl = require("openGL")


local shader = Shader("shaders/simple.vs", "shaders/toonshading.fs")
local cubemesh = M.load("cube.obj")
local spheremesh = M.load("sphere.obj")
local monkeymesh = M.load("suzanne.obj")

local cube = SimpleObject( cubemesh )
local sphere = SimpleObject( spheremesh )
local monkey = SimpleObject( monkeymesh )


shader:use()
gl.glClearColor(1,1,1,1)
G:clear()

cube:recalculate(shader)
sphere:recalculate(shader)
monkey:recalculate(shader)

shader.color = {1,0,0} --set color to red.
shader.shininess = 150
shader.kDiffuse = 1
shader.kSpecular = 0.5

print("done")

local mvp = Matrix.identity(4)
local theta = 0

local z = -10
local p = Matrix.perspective(0.1,100,1,45)
local v = Matrix.lookat( vec3(3,3,3), vec3(0,0,0), vec3(0,1,0) )
local m = Matrix.rotate( vec3(0,1,0), theta )
local up = vec3(0,1,0)
shader.perspective = p

function update()
	gl.viewport(0,0, gl.canvas.width, gl.canvas.height)
	--G.resize(100,100)
	G.clear()
	theta = theta + .05
	m:rotate( up, 0.05 )

	shader.mvpMatrix = m*v --reset uniform

	--cube:draw(shader)
	--sphere:draw(shader)
	monkey:draw(shader)
	js.global:requestAnimationFrame(update)
	collectgarbage()
end

update()

