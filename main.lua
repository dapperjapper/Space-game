Class = require 'hump.class'
Vector = require "hump.vector"
Future = require "future"
Sprite = require "sprite"
Point = require "point"
PointList = require "pointlist"
PointLine = require "pointline"
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
  function cam:zoomPos(zoom, x, y)
    -- http://stackoverflow.com/a/13317413
    local viewRect = Vector(love.graphics.getWidth(), love.graphics.getHeight())*self.scale
    local diff = viewRect * (1 - 1 / zoom)
    local percentMouse = Vector()
    percentMouse.x = (Vector(self:mousepos()).x - Vector(self:pos()).x) / viewRect.x
    percentMouse.y = (Vector(self:mousepos()).y - Vector(self:pos()).y) / viewRect.y
    local delta = percentMouse:permul(diff)
    cam:move( delta:unpack() )
    cam:zoom(zoom)
  end
  function cam:lineToLineListInCameraCoords(line)
    local lineList = {}
    for _,p in ipairs(line) do
      local x, y = self:cameraCoords(p:vector():unpack())
      table.insert( lineList, x)
      table.insert( lineList, y)
    end
    return lineList
  end
  
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
    cam:zoomPos(zoomPower, x, y)
  elseif button == 'wd' then
    cam:zoomPos(1/zoomPower, x, y)
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
  gui.Label{text = "Granularity", pos={20, 0}}
  if gui.Slider{info = granSlider} then shipLine.granularity = granSlider.value; shipLine:recalculate() end
  gui.group.pop{}
end

function love.draw()
  cam:attach()
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.setLineWidth(1)
  
  love.graphics.circle('fill', sprites[2].x, sprites[2].y, sprites[2].radius, sprites[2].radius*cam.scale)
  
  cam:detach()
  shipLine:draw()
  
  
  gui.core.draw()
end