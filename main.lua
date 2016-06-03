DEBUG = true

require "graphics"
Class = require 'hump.class'
Vector = require "hump.vector"
Future = require "future"
Sprite = require "sprite"
Ship = require "ship"
Planet = require "planet"
SpriteList = require "spritelist"
Point = require "point"
PointList = require "pointlist"
NavPoint = require "navpoint"
Nav = require "nav"
ShipLine = require "shipline"
Camera = require "hump.camera"

inspect = require 'inspect'
if DEBUG then
  ProFi = require 'ProFi'
  -- require 'lovedebug'
  -- _lovedebugpresskey = "tab"
end

gui = require "suit"
game = {}
game.granSlider = {value = 0.1, min = 1, max = 0.01}
-- game.qualitySlider = {value = 10, min = 1, max = 10}

-- http://lua-users.org/wiki/MathLibraryTutorial
math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6))/1000000 )

function love.load()
  -- love.graphics.setCaption("Planetary")
  love.physics.setMeter(10)

  game.cursors = {}
  for _,f in ipairs(love.filesystem.getDirectoryItems('cursors/')) do
    local name = string.match(f, '(.+).png$')
    if name then game.cursors[name] = love.graphics.newImage( 'cursors/' .. f ) end
  end
  love.mouse.setVisible(false)

  -- http://designfestival.com/the-cicada-principle-and-why-it-matters-to-web-designers/
  game.starfield = {starfieldCanvas(500, {number = 10}), starfieldCanvas(700, {number = 10})}

  game.sprites = SpriteList()

  -- ship = Sprite()
  -- ship.type = "ship"
  -- ship.x = 650/2-20.35 -- megameters
  -- ship.y = 650/2
  -- ship.dy = 200000000000000 -- megameters/second
  -- ship.power = 1
  -- ship.mass = 1
  -- table.insert( game.sprites, ship )
  --
  -- planet = Sprite()
  -- planet.type = "planet"
  -- planet.x = 650/2
  -- planet.y = 650/2
  -- planet.radius = 6.3781 -- megameters
  -- planet.mass = 5.97219*(10^15) -- teragrams
  -- table.insert( game.sprites, planet )

   -- for angles: in radians and 0 = to the right

  local planet = Planet({ sun={650/2, 650/2}, radius=50, mass=500, appearance={type='sun'} })
  game.sprites:add(planet)

  for i=5,30,2 do
    local planet2 = Planet({ sun=planet, radius=i, orbitRadius=math.random(200,1000), r=math.pi*2/25*i, mass=500, orbitSpeed=0.1 })
    game.sprites:add(planet2)
  end

  local ship = Ship(650/2-200, 650/2-200, 'ship')
  ship.dx = 200
  ship.power = 1
  ship.mass = 1
  ship.radius = 1 -- circle collision radius
  game.sprites:add(ship)

  game.cam = Camera(ship.x, ship.y)
  function game.cam:zoomPos(zoom, x, y)
    -- http://stackoverflow.com/a/13317413
    local viewRect = Vector(love.graphics.getWidth(), love.graphics.getHeight())*self.scale
    local diff = viewRect * (1 - 1 / zoom)
    local percentMouse = Vector()
    percentMouse.x = (Vector(self:mousepos()).x - Vector(self:pos()).x) / viewRect.x
    percentMouse.y = (Vector(self:mousepos()).y - Vector(self:pos()).y) / viewRect.y
    local delta = percentMouse:permul(diff)
    self:move( delta:unpack() )
    self:zoom(zoom)
  end

  game.shipLine = ShipLine(game)
  game.shipLine.granularity = game.granSlider.value
  function game.shipLine:updateSprites(newSprites)
    game.sprites:importSimple(newSprites)
  end

  game.toolMode = 'plan'

  -- for n in pairs(_G) do print(n) end -- TODO: clean global variables
end

function love.keypressed(key, code)
  if key=="o" and DEBUG then
    ProFi:start()
  end
  if key=="p" and DEBUG then
    ProFi:stop()
    ProFi:writeReport( '/Users/jasper/Documents/Projects/Offline/planetary/love/profile.txt' )
  end

  if key == ' ' then
    game.oldMode = game.toolMode
    game.toolMode = 'pan'
  end
  gui.keyboard.pressed(key, code)
end

function love.keyreleased(key, code)
  if key == ' ' then
    game.toolMode = game.oldMode
  end
end

function game.mouseinzone()
  return love.mouse.getY() > 30 -- TODO: clunky
end

function love.mousepressed(x, y, button)
  local zoomPower = 1.1

  if not game.mouseinzone() then return end

  game.mouseStartCam = Vector(game.cam:pos())
  game.mouseStart = Vector(x, y)

  -- basic zoom and drag if shipLine isn't using mouse movements
  if button == "l" then
    if game.clickMode ~= 'pan' then game.shipLine:mousepressed(x, y, button); return end -- shipLine captured event
  elseif button == 'r' then
    if game.clickMode ~= 'pan' then game.shipLine:mousepressed(x, y, button); return end -- shipLine captured event
  elseif button == 'wu' then
    if game.scrollMode ~= 'zoom' then game.shipLine:mousepressed(x, y, button); return end -- shipLine captured event
    game.cam:zoomPos(zoomPower, x, y)
  elseif button == 'wd' then
    if game.scrollMode ~= 'zoom' then game.shipLine:mousepressed(x, y, button); return end -- shipLine captured event
    game.cam:zoomPos(1/zoomPower, x, y)
  end
end

function love.mousereleased(x, y, button)
    if game.mouseStart then
    local moved = game.mouseStart-Vector(x, y)

    if button == "l" then
        if game.clickMode == 'pan' and game.mouseStart then
          if (moved.x == 0 and moved.y == 0) then -- didn't move at all, we have a click on our hands
            game.shipLine:deselect()
          end
        end

        if not game.mouseinzone() then return end

        if game.clickMode == 'navDir' then
          if (moved.x == 0 and moved.y == 0) then
            -- if clicked to create - navDir aligns to ship direction at that point
            game.shipLine.activePoint.direction = game.shipLine.future:shipAt(game.shipLine.activePoint.time).r
          end
          game.toolMode = 'plan'
        end
    end
  end

  if button == "l" then
    game.mouseStart = nil
    game.mouseStartCam = nil
  end
end

function love.update(dt)
  -- drag
  if love.mouse.isDown(1) and game.clickMode == 'pan' and game.mouseStart then
    game.cam:lookAt( ( (game.mouseStart-Vector(love.mouse.getPosition()))/game.cam.scale+game.mouseStartCam ):unpack() )
  end

  game.shipLine:update(dt)
  game.sprites:update(dt)
  game.clickMode = game.shipLine.clickMode or 'pan'
  game.scrollMode = game.shipLine.scrollMode or 'zoom'

  if game.clickMode == 'pan' and game.scrollMode == 'zoom' then
    game.cursor = 'pan'
  elseif game.clickMode == 'addNav' then
    game.cursor = game.clickMode
  --elseif game.clickMode == 'extend' then
  --elseif game.clickMode == 'selectNav' then
  elseif game.clickMode == 'ff' then
    game.cursor = game.clickMode
  else
    game.cursor = 'normal'
  end

  gui.layout:reset(10,0)
  -- gui.group.push{grow = "right", pos={10, 0}}
  gui.Label('Mode', 10, 0, 50, 30) --, size={50,30}}
  if gui.Checkbox({text = "Plan", checked=(game.toolMode=="plan")}, 10, 40) then
    game.toolMode="plan"
  end
  if gui.Checkbox({text = "Fast Forward", checked=(game.toolMode=="ff")}, 10, 70) then
    game.toolMode="ff"
  end
  -- gui.Label("Granularity", 10, 100) -- {text = "Granularity", pos={20, 0}}
  -- if gui.Slider(game.granSlider, 10, 130) then
  --   game.shipLine.granularity = game.granSlider.value
  --   game.shipLine:recalculate()
  -- end
  -- gui.group.pop{}
end

function love.draw()
  if DEBUG then
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS()), 10, 40)
    love.graphics.print("ToolMode: "..tostring(game.toolMode), 10, 50)
    love.graphics.print("ClickMode: "..tostring(game.clickMode), 10, 60)
    love.graphics.print("ScrollMode: "..tostring(game.scrollMode), 10, 70)
    love.graphics.print("Memory: "..tostring(math.floor(collectgarbage("count")/1000)), 10, 80)
  end

  -- draw starfield
  --love.graphics.setBlendMode('premultiplied')
    for i,starfield in ipairs(game.starfield) do
      local diam = starfield:getWidth()
      local x = game.cam.x*(0.25/i)%diam-diam
      while x < love.graphics.getWidth() do
        local y = game.cam.y*(0.25/i)%diam-diam
        while y < love.graphics.getHeight() do
          if x+diam>0 and y+diam>0 then
            love.graphics.draw(starfield, x,y)
          end
          y = y+diam
        end
        x = x+diam
      end
    end
  --love.graphics.setBlendMode('alpha')

  -- draw ghosts from the future oooooOOOOoo
  if game.shipLine.hotPoint then
    game.sprites:drawGhosts(game.cam, game.shipLine.future:at(game.shipLine.hotPoint.time))
  end
  game.sprites:draw(game.cam)
  game.shipLine:draw()
  gui.draw()

  love.graphics.setColor(255, 255, 255)
  love.graphics.push()
  love.graphics.translate(love.mouse.getPosition())
  love.graphics.draw(game.cursors[game.cursor])
  love.graphics.pop()
end
