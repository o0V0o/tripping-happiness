local ctypes = require('ctypes')
local Shader = require'shader'
local M = require('mesh')
local G = require('drawlib')
local Matrix = require('matrix')
local vec3 = require("vector").vec3
local SimpleObject = require('SimpleObject')

local gl = require("openGL")

local shader = Shader("shaders/simple.vs", "shaders/solid.fs")
local cubemesh = M.load("cube.obj")
local cube = SimpleObject( cubemesh )


shader:use()
gl.glClearColor(0.6,1,.2,1)
G:clear()
cube:recalculate(shader)
shader.color = {1,0,0} --set color to red.
print("done")

local mvp = Matrix.identity(4)
local theta = 0

local z = -0.5
function update()
	G.clear()
	theta = theta + .05
	mvp = Matrix.identity(4)
	local p = Matrix.perspective(0.1,100,1,90)
	mvp:rotate( vec3(0,1,0), theta )
	mvp:translate( vec3(0,0,z) )
	mvp = mvp
	--mvp:scale(z)

	shader.mvpMatrix = mvp --reset uniform
	cube:draw(shader)
	js.global:requestAnimationFrame(update)
end

update()

