local ShipLine = Class{
  init = function(self, sprites, cam)
    self.sprites = sprites
    self.nav = Nav()
    self.granularity = 0.1882
    self.cam = cam
    self.future = nil
    self.points = PointList()
    self:recalculate()
    
    self.hotPoint = nil
    self.activePoint = nil
  end
}

function ShipLine:recalculate()
  if self.future then self.future:destroy(); self.future=nil end
  self.future = Future(self.sprites, self.nav)
  self.future.granularity = self.granularity
  self.line = self.future:shipLine(0, 10)
  self.lineList = self.future:shipLineList(0, 10)
  self.nav:updatePositions(self.future)
end

function ShipLine:keypressed(key, code)
  
end

function ShipLine:keyreleased(key, code)
  
end

function ShipLine:mousepressed(x, y, button)
  local navLengthPower = 0.05 --sec
  local interacted = false
  
  if button == "l" then
    if self.hotPoint then
      if self.hotPoint.type=="shipPath" then
        if self.nav:at(self.hotPoint.time) then return false end
        local navPoint = NavPoint()
        navPoint.x, navPoint.y = self.hotPoint:vector():unpack()
        -- navPoint.index = hoverPoint.index
        navPoint.time = self.hotPoint.time
        navPoint.length = 0
        self.activePoint = self.nav:add(navPoint)
        self:recalculate()
        interacted = true
      else
        self.activePoint = self.hotPoint
        interacted = true
      end
    end
  elseif button == 'wu' then
    if self.activePoint and self.activePoint.type=='nav' then
      if not self.nav:at(self.activePoint.time + self.activePoint.length + navLengthPower) then
        self.activePoint.length = self.activePoint.length + navLengthPower
        self:recalculate()
        interacted = true
      end
    end
  elseif button == 'wd' then
    if self.activePoint and self.activePoint.type=='nav' and self.activePoint.length > navLengthPower*2 then
      self.activePoint.length = self.activePoint.length - navLengthPower
      self:recalculate()
      interacted = true
    end
  elseif button == 'r' then
    if self.hotPoint and self.hotPoint.type=='nav' then
      self.nav:remove(self.hotPoint)
      self:deselect()
      self:recalculate()
      interacted = true
    end
  end
  
  return interacted
end

function ShipLine:mousereleased(x, y, button)
  
end

function ShipLine:deselect()
  self.activePoint = nil
end

function ShipLine:pointAtI(index)
  local point = self.points:pointAtI(index, self.future)
  if point then
    return point
  else
    return self.nav:pointAtI(index, self.future)
  end
end

function ShipLine:update()
  -- look for closest point on line
  local mouse = Vector(self.cam:mousepos())
  local distMin = self.line[1]:vector():dist(mouse)
  self.hotPoint = self.line[1]
  for i=2,#self.line do
    local dist = self.line[i]:vector():dist(mouse)
    local pointAtI = self:pointAtI(i)
    if pointAtI then dist = dist - 10 end
    
    if dist < distMin then
      distMin = dist
      self.hotPoint = self.line[i]
      if pointAtI then self.hotPoint = pointAtI end
    end
  end
  if distMin*cam.scale > 10 then self.hotPoint=nil end -- No hover unless 10 pixels away
end

function ShipLine:draw()
  love.graphics.setLineWidth(1)
  love.graphics.line(unpack(self.lineList))
      
  for _,p in ipairs(self.nav.points) do
    love.graphics.setLineWidth(3)
    love.graphics.circle('fill', p.x,p.y, 4)    
    love.graphics.line(unpack(p:shipLineList(self.future)))
  end
  
  if self.activePoint and self.activePoint.type=='nav' then
    love.graphics.setColor(0, 255, 0)
    love.graphics.circle('fill', self.activePoint.x,self.activePoint.y, 4)    
    love.graphics.line(unpack(self.activePoint:shipLineList(self.future)))
    
    -- for i=startI,endI,2 do
    --   love.graphics.line(line[i],line[i+1])
    -- end
  end
  
  love.graphics.setLineWidth(1)
  love.graphics.setColor(255, 255, 255)
  if self.hotPoint then
    love.graphics.circle('line', self.hotPoint.x,self.hotPoint.y, 6)
  end
end

return ShipLine