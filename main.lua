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
  
  shipLine = ShipLine(sprites, cam)
  
  love.graphics.setMode(650, 650, false, true, 0)
  
  -- for n in pairs(_G) do print(n) end -- TODO: clean global variables
end

function love.keypressed(key, code)
  gui.keyboard.pressed(key, code)
end

function love.keyreleased(key, code)
end

function mouseinzone()
  return love.mouse.getY() > 30 -- TODO: clunky
end

function love.mousepressed(x, y, button)
  local zoomPower = 1.1
  
  if not mouseinzone() then return end
  
  if shipLine:mousepressed(x, y, button) then return true end -- shipLine captured event
  
  -- basic zoom and drag if shipLine isn't using mouse movements
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
  -- drag
  if love.mouse.isDown('l') and love.mouse.start then
    cam:lookAt( ( (love.mouse.start-Vector(love.mouse.getPosition()))/cam.scale+love.mouse.startCam ):unpack() )
  end
  
  shipLine:update()
    
  gui.group.push{grow = "right", pos={10, 0}}
  gui.Label{text = "Granularity", pos={20, 0}}
  if gui.Slider{info = granSlider} then shipLine.granularity = granSlider.value; shipLine:recalculate() end
  gui.group.pop{}
end

function love.draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.setLineWidth(1)
  
  cam:attach()
  love.graphics.circle('fill', sprites[2].x, sprites[2].y, sprites[2].radius, sprites[2].radius*cam.scale)
  cam:detach()
  
  shipLine:draw()  
  gui.core.draw()
  
  love.graphics.setColor(24, 167, 181)
  local shippos = Vector(cam:cameraCoords(sprites[1].x, sprites[1].y))
  love.graphics.polygon('fill',shippos.x, shippos.y+5, shippos.x+3, shippos.y-5, shippos.x-3, shippos.y-5)
end