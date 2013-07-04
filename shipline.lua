local ShipLine = Class{
  init = function(self, sprites, cam)
    self.sprites = sprites
    self.nav = Nav()
    self.granularity = 0.1
    self.cam = cam
    self.future = nil
    self.points = nil -- interface points, like crash notifiers and end of sim
    self:recalculate()
    
    self.goForward = 0
    self.goneForward = 0
    self.hotPoint = nil
    self.activePoint = nil
  end
}

function ShipLine:recalculate(startChangedT) -- TODO: optimize for nav changes only recalculate after the nav
  -- TODO: Should all this be ShipLine's responsibilty? Poor shipline
  local lastNav = self.nav:last()
  if lastNav then lastNav=lastNav:endTime() else lastNav=0 end
  local endTime = math.max(10, lastNav)
  
  if self.future then self.future:destroy(); self.future=nil end
  self.future = Future(self.sprites, self.nav)
  self.future.granularity = self.granularity
  self.line = self.future:shipLine(0, endTime)
  self.nav:updatePositions(self.future)
  self:updatePoints()
end

function ShipLine:extend(t)
  self.line = self.future:shipLine(0, self.line:last().time+t)
  self:updatePoints()
end

function ShipLine:updatePoints()
  self.points = PointList()
  if self.future.collisionCourse then
    local endp = Point(self.line:last().x, self.line:last().y, "collision")
    endp.time = self.line:last().time
    self.points:add(endp)
  else
    local endp = Point(self.line:last().x, self.line:last().y, "end")
    endp.time = self.line:last().time
    self.points:add(endp)
  end
end

function ShipLine:keypressed(key, code)
  
end

function ShipLine:keyreleased(key, code)
  
end

function ShipLine:mousepressed(x, y, button)
  local navLengthPower = 0.05 --sec
  local interacted = false
  
  if love.keyboard.isDown(' ') then return false end
  if button == "l" then
    if self.hotPoint then
      if mode == "plan" then
        if self.hotPoint.type=="shipPath" then
          -- add nav
          if self.nav:at(self.hotPoint.time) then return false end -- point already occupied
          local navPoint = NavPoint()
          navPoint.x, navPoint.y = self.hotPoint:vector():unpack()
          -- navPoint.index = hoverPoint.index
          navPoint.time = self.hotPoint.time
          navPoint.length = 0
          self.activePoint = self.nav:add(navPoint) -- TODO: nav directionality
          self:recalculate()
        elseif self.hotPoint.type=="end" then
          -- extend
          self:extend(10)
        else
          -- select
          self.activePoint = self.hotPoint
        end
      elseif mode == "ff" then
        self:deselect()
        self:fastForward(self.hotPoint.time)
      end
      interacted = true
    end
  elseif button == 'wu' then
    if self.activePoint and self.activePoint.type=='nav' then
      if not self.nav:at(self.activePoint.time + self.activePoint.length + navLengthPower) then
        self.activePoint.length = self.activePoint.length + navLengthPower
        self:recalculate(self.activePoint.time)
      end
      interacted = true
    end
  elseif button == 'wd' then
    if self.activePoint and self.activePoint.type=='nav' then
      if self.activePoint.length > navLengthPower*2 then
        self.activePoint.length = self.activePoint.length - navLengthPower
        self:recalculate(self.activePoint.time)
      end
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

function ShipLine:fastForward(t)
  self:updateSprites(self.future:at(t))
  self.nav:moveAllBack(t)
  self.points:moveAllBack(t)
  self:recalculate()
  
  --self:recalculate()
  -- local transitionLength = 2 -- sec
  -- 
  -- self.goForwardIncrements = t/transitionLength
  -- self.goForward = t
  -- self.goneForward = 0
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

function ShipLine:update(dt)
  -- if self.goForward > 0 then
  --   -- updateSprites run through callback by main, but updates self.sprites too because they are linked *magic*
  --   self:updateSprites(self.future:atInterpolate(self.goneForward))
  --   
  --   if self.goneForward > 0 then
  --     repeat -- remove parts of line we've gone over
  --       table.remove(self.line.points, 1)
  --     until self.line.points[1].time > self.goneForward
  --   
  --     if self.nav.points[1] then
  --       repeat -- remove navpoints we've gone over
  --         table.remove(self.nav.points, 1)
  --       until self.nav.points[1].time > self.goneForward
  --     end
  --   
  --     if self.points.points[1] then
  --       repeat -- remove points we've gone over
  --         table.remove(self.points.points, 1)
  --       until self.points.points[1].time > self.goneForward
  --     end
  --   end
  --       
  --   self.goForward = self.goForward - (dt*self.goForwardIncrements)
  --   self.goneForward = self.goneForward + (dt*self.goForwardIncrements)
  --   if self.goForward <= 0 then
  --     self.goForward = 0
  --     self.goneForward = 0
  --     self:recalculate()
  --   end
  -- end
  
  -- look for closest point on line
  local mouse = Vector(self.cam:mousepos())
  local distMin = self.line.points[1]:vector():dist(mouse)
  self.hotPoint = self.line.points[1]
  for i=2,#self.line.points do
    local dist = self.line.points[i]:vector():dist(mouse)
    local pointAtI = self:pointAtI(i)
    -- TODO: if two lines overlap, prioritize earlier point
    if pointAtI then dist = dist - 10 end -- Prioritize special points
    
    if dist < distMin then
      distMin = dist
      self.hotPoint = self.line.points[i]
      if pointAtI then self.hotPoint = pointAtI end
    end
  end
  if distMin*cam.scale > 20 then self.hotPoint=nil end -- No hover unless 10 pixels away
  
  if self.hotPoint then
    if self.hotPoint.type == "end" then
      local pcam = self.hotPoint:inCameraCoords(self.cam)
      gui.Tooltip{text="Click to extend", pos={pcam.x, pcam.y}}
    elseif self.hotPoint.type == "collision" then
      local pcam = self.hotPoint:inCameraCoords(self.cam)
      gui.Tooltip{text="WARNING: Collision course", pos={pcam.x, pcam.y}}
    elseif mode == 'ff' then
      local pcam = self.hotPoint:inCameraCoords(self.cam)
      gui.Tooltip{text="Click to jump to here", pos={pcam.x, pcam.y}}
    end
  end
end

function ShipLine:draw()
  
  -- Draw ship line
  love.graphics.setLineWidth(1)
  love.graphics.setColor(255, 255, 255)
  love.graphics.line(unpack( self.line:inCameraCoords(self.cam):asLineList() ))
  
  -- Draw interface points in their colors
  for _,p in ipairs(self.points.points) do
    local pcam = p:inCameraCoords(self.cam)
    if p.type == "end" then
      love.graphics.setColor(255, 255, 255)
      love.graphics.push()
      love.graphics.translate(pcam.x, pcam.y)
      love.graphics.rotate(self.future:shipAt(p.time).r)

      love.graphics.rectangle('fill', -2, -5, 4, 5)
      love.graphics.polygon('fill', -6, 0, 6, 0, 0, 8)
      love.graphics.pop()
    elseif p.type == "collision" then
      love.graphics.setColor(255, 0, 0)
      love.graphics.circle('fill', pcam.x, pcam.y, 4)
    end
  end
  
  -- Draw unselected navs in bold white
  love.graphics.setLineWidth(3)
  love.graphics.setColor(255, 255, 255)
  for _,p in ipairs(self.nav.points) do
    local pcam = p:inCameraCoords(self.cam)
    love.graphics.circle('fill', pcam.x, pcam.y, 4)    
    love.graphics.line(unpack( p:shipLine(self.future):inCameraCoords(self.cam):asLineList() ))
  end
  
  -- Draw over selected nav in green
  love.graphics.setColor(0, 255, 0)
  if self.activePoint and self.activePoint.type=='nav' then
    local pcam = self.activePoint:inCameraCoords(self.cam)
    love.graphics.circle('fill', pcam.x, pcam.y, 4)    
    love.graphics.line(unpack( self.activePoint:shipLine(self.future):inCameraCoords(self.cam):asLineList() ))
  end
  
  -- Draw hovering circle on "hotPoint"
  love.graphics.setLineWidth(1)
  love.graphics.setColor(255, 255, 255)
  if self.hotPoint then
    local pcam = self.hotPoint:inCameraCoords(self.cam)
    love.graphics.circle('line', pcam.x, pcam.y, 6)
  end
end

return ShipLine