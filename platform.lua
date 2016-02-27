--platform for webgl
--

local gl = require("openGL")

local P={}

P.context = nil
assert(js)

function P.loadImage(path, callback)
	local img = js.new(js.global.Image)
	img.src = path
	img.onload = js.global:jsCallback(function()
		if type(callback)=="function" then callback(img, img.width, img.height) end
	end)
end

function P.init()
	gl.canvas.width = gl.canvas.clientWidth
	gl.canvas.height = gl.canvas.clientHeight
	gl.viewport(0,0,gl.canvas.width, gl.canvas.height)
end

function P.time()
	return js.global.Date:now()
end

function P.sleep()
	error("sleep not yet implemented. how the fuck do I suspend the VM and return to JS???")
end

function P.terminate()
end

return P
