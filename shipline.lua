local ShipLine = Class{
  init = function(self, sprites, cam)
    self.sprites = sprites
    self.nav = Nav()
    self.granularity = 0.32
    self.cam = cam
    self.future = nil
    self:recalculate()
  end
}

function ShipLine:recalculate()
  if self.future then self.future:destroy(); self.future=nil end
  self.future = Future(self.sprites, self.nav)
  self.future.granularity = self.granularity
  self.line = self.future:shipLine(0, 10)
  self.lineList = self.future:shipLineList(0, 10)
end

function ShipLine:keypressed(key, code)
  
end

function ShipLine:keyreleased(key, code)
  
end

function ShipLine:mousepressed(x, y, button)
  local navLengthPower = 0.05 --sec
  
  if button == "l" then
    if self.hoverPoint and #self.nav.points < 1 then
      local navPoint = NavPoint()
      navPoint.x, navPoint.y = self.hoverPoint:unpack()
      -- navPoint.index = hoverPoint.index
      navPoint.time = self.hoverPoint.time
      navPoint.length = 0.1
      self.activeNavPoint = nav:add(navPoint)
      self:recalculate()
    end
  elseif button == 'wu' then
    if self.activeNavPoint then
      self.nav.points[self.activeNavPoint].length = self.nav.points[self.activeNavPoint].length + navLengthPower
      self:recalculate()
    end
  elseif button == 'wd' then
    if self.activeNavPoint and self.nav.points[self.activeNavPoint].length > navLengthPower*2 then
      self.nav.points[self.activeNavPoint].length = self.nav.points[self.activeNavPoint].length - navLengthPower
      self:recalculate()
    end
  end
end

function ShipLine:mousereleased(x, y, button)
  
end

function ShipLine:update()
  -- look for closest point on line
  local mouse = Vector(self.cam:mousepos())
  local distMin = self.line[1]:dist(mouse)
  self.hoverPoint = self.line[1]
  for i=2,#self.line do
    local dist = self.line[i]:dist(mouse)
    if dist < distMin then
      distMin = dist
      self.hoverPoint = self.line[i]
    end
  end
  if distMin*cam.scale > 10 then self.hoverPoint=nil end -- No hover unless 10 pixels away
end

function ShipLine:draw()
  love.graphics.line(unpack(self.lineList))
  
  love.graphics.setPointSize(10)
  
  if self.hoverPoint then 
    love.graphics.point(self.hoverPoint.x,self.hoverPoint.y)
  end
  
  for _,p in ipairs(self.nav.points) do
    love.graphics.point(p:vector():unpack())
  end
  
  if self.activeNavPoint then
    love.graphics.setColor(255, 0, 0)
    love.graphics.point(self.nav.points[self.activeNavPoint]:vector():unpack())
    love.graphics.line(unpack(nav.points[self.activeNavPoint]:shipLineList(self.future)))
    
    -- for i=startI,endI,2 do
    --   love.graphics.line(line[i],line[i+1])
    -- end
  end
end

return ShipLine