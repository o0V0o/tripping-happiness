--platform for webgl

P={}

P.context = nil
assert(js)

function P.init()
end

function P.time()
	return js.global.Date:now()
end

function P.terminate()
end

return P
