local G = require('drawlib')
local M = require('mesh')
local Shader = require'shader'

local shader = Shader("simgle.vs", "solid.fs")
local cube = G.SimpleObject( M.load("cube.obj") )

shader.color = {1,0,0,1} --set color to red.
cube:draw(shader)
print("done")
