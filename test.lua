--local G = require('drawlib')
local Shader = require'shader'

local shader = Shader("simgle.vs", "solid.fs")
--local cube = G.SimpleObject( G.mesh("cube.obj") )

shader.color = {1,0,0,1} --set color to red.
--cube:draw(shader)
print("done")
