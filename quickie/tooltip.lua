local BASE = (...):match("(.-)[^%.]+$")
local core     = require(BASE .. 'core')
local group    = require(BASE .. 'group')
local mouse    = require(BASE .. 'mouse')
local keyboard = require(BASE .. 'keyboard')

-- {text = text, pos = {x, y}, widgetHit=widgetHit, draw=draw}
return function(w)
	assert(type(w) == "table" and w.text, "Invalid argument")

	local id = w.id or core.generateID()

	if keyboard.hasFocus(id) then
		keyboard.clearFocus()
	end
  
	core.registerDraw(id, w.draw or core.style.Tooltip,
		w.text, w.pos[1], w.pos[2])

	return mouse.releasedOn(id)
end

