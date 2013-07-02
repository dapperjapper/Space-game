Class = require 'hump.class'
Vector = require "hump.vector"
Future = require "future"
Sprite = require "sprite"
Point = require "point"
PointList = require "pointlist"
NavPoint = require "navpoint"
Nav = require "nav"
ShipLine = require "shipline"
Camera = require "hump.camera"
inspect = require 'inspect'

require 'lovedebug'
_lovedebugpresskey = "tab"

gui = require "quickie"

granSlider = {value = 0.1882, min = 1, max = 0.01}

function love.load()
  love.physics.setMeter(10)
  
  sprites = {}
  
  -- ship = Sprite()
  -- ship.type = "ship"
  -- ship.x = 650/2-20.35 -- megameters
  -- ship.y = 650/2
  -- ship.dy = 200000000000000 -- megameters/second
  -- ship.power = 1
  -- ship.mass = 1 -- TODO: what should this be??
  -- table.insert( sprites, ship )
  -- 
  -- planet = Sprite()
  -- planet.type = "planet"
  -- planet.x = 650/2
  -- planet.y = 650/2
  -- planet.radius = 6.3781 -- megameters
  -- planet.mass = 5.97219*(10^15) -- teragrams
  -- table.insert( sprites, planet )
  
  ship = Sprite()
  ship.type = "ship"
  ship.x = 650/2-75
  ship.y = 650/2
  ship.dy = 20
  ship.power = 0.5
  ship.mass = 1 -- TODO: what should this be??
  ship.size = 1 -- circle collision radius
  table.insert( sprites, ship )
  
  planet = Sprite()
  planet.type = "planet"
  planet.x = 650/2
  planet.y = 650/2
  planet.radius = 10
  planet.mass = 1000
  table.insert( sprites, planet )
    
  -- nav = Nav()
  cam = Camera(planet.x, planet.y)
  shipLine = ShipLine(sprites, cam)
  --hotPoint = nil
  
  --recalculate()
  
  love.graphics.setMode(650, 650, false, true, 0)
    
  --mode = "plan"
  
  -- for n in pairs(_G) do print(n) end -- TODO: clean global variables
end

-- function recalculate()
--   if future then future:destroy() end
--   future = Future(sprites, nav)
--   print(granSlider.value)
--   future.granularity = granSlider.value
--   line = future:shipLine(0, 10)
--   lineList = future:shipLineList(0, 10)
--   
--   -- TODO: update navpoint positions
-- end

function love.keypressed(key, code)
  -- if key==' ' then
  --   oldmode = mode
  --   mode = 'nav'
  -- end
  gui.keyboard.pressed(key, code)
end

function love.keyreleased(key, code)
  -- if key==' ' then
  --   mode = oldmode
  -- end
end

function mouseinzone()
  return love.mouse.getY() > 30 -- TODO: clunky
end

function love.mousepressed(x, y, button)
  local zoomPower = 1.1
  
  if not mouseinzone() then return end
  
  if shipLine:mousepressed(x, y, button) then return true end -- shipLine captured event
  
  if button == "l" then
    love.mouse.startCam = Vector(cam:pos())
    love.mouse.start = Vector(x, y)
    shipLine:deselect()
  elseif button == 'wu' then
    cam:zoom(zoomPower)
  elseif button == 'wd' then
    cam:zoom(1/zoomPower)
  end
end

function love.mousereleased(x, y, button)
  if not mouseinzone() then return end
  
   if button == "l" then
     love.mouse.start = nil
     love.mouse.startCam = Vector(cam:pos())
   end
end

function love.update(dt)
  if love.mouse.isDown('l') and love.mouse.start then
    cam:lookAt( ( (love.mouse.start-Vector(love.mouse.getPosition()))/cam.scale+love.mouse.startCam ):unpack() )
  end
  
  shipLine:update()
  
  -- if mode == "plan" then
  --   -- look for closest point on line
  --   local mouse = Vector(cam:mousepos())
  --   local distMin = line[1]:dist(mouse)
  --   hoverPoint = line[1]
  --   for i=2,#line do
  --     local dist = line[i]:dist(mouse)
  --     if dist < distMin then
  --       distMin = dist
  --       hoverPoint = line[i]
  --     end
  --   end
  --   if distMin > 50 then hoverPoint=nil end
  -- end
  
  --if type(gui.mouse.getHot())=='table' then print("hey"); print(gui.mouse.getHot()) end
  
  gui.group.push{grow = "right", pos={10, 0}}
  gui.Label{text = 'Mode'}
  if gui.Checkbox{text = "Nav", checked=(mode=="nav")} then
    mode="nav"
  end
  if gui.Checkbox{text = "Plan Course", id="plan", checked=(mode=="plan")} then
    mode="plan"
  end
  if gui.Slider{info = granSlider} then shipLine.granularity = granSlider.value; shipLine:recalculate() end
  gui.group.pop{}
end

function love.draw()
  cam:attach()
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.setLineWidth(1)
  
  love.graphics.circle('fill', sprites[2].x, sprites[2].y, 10)
  
  shipLine:draw()
  
  cam:detach()
  
  gui.core.draw()
end