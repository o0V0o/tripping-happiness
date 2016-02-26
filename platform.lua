--platform for webgl
--

local gl = require("openGL")

P={}

P.context = nil
assert(js)

function P.loadImage(path, callback)
	local img = js.new(js.global.Image)
	img.src = path
	img.onload = js.global:jsCallback(function(self)
		print("callback!", self)
		callback(img, self.width, self.height)
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

function P.terminate()
end

return P
