local ShipLine = Class{
  init = function(self, sprites, cam)
    self.sprites = sprites
    self.nav = Nav()
    self.granularity = 0.1882
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

function ShipLine:recalculate(startChangedT)
  local lastNav = self.nav:last()
  if lastNav then lastNav=lastNav:endTime() else lastNav=0 end
  local endTime = math.max(20, lastNav)
  
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
          self.activePoint = self.nav:add(navPoint)
          self:recalculate()
        elseif self.hotPoint.type=="end" then
          -- extend
          self:extend(10)
        else
          -- select
          self.activePoint = self.hotPoint
        end
      elseif mode == "ff" then
        print ('fast forward to ', self.hotPoint.time)
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
  --self:recalculate()
  local transitionLength = 2 -- sec
  
  self.goForwardIncrements = t/transitionLength
  self.goForward = t
  self.goneForward = 0
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

function radiusRectangle(w, h, r)
  -- http://stackoverflow.com/a/3197924
  local vx = math.cos(r)
  local vy = math.sin(r)

  local x1 = -h/2
  local y1 = -w/2
  local x2 = h/2
  local y2 = w/2
  
  local times = {}
  if vx ~= 0 then
    times[1] = x1/vx
    times[2] = x2/vx
  end
  if vy ~= 0 then
    times[3] = y1/vy
    times[4] = y2/vy
  end
  
  local minT = w+h -- larger than all
  for _,v in ipairs(times) do
    if v<minT and v>0 then minT = v end
  end
  
  return minT
end

function ShipLine:update(dt)
  if self.goForward > 0 then
    self:updateSprites(self.future:atInterpolate(self.goneForward)) -- run by main, but updates self.sprites too because they are linked
    if self.line:first().time < self.goneForward then -- remove parts of line we've gone over
      table.remove(self.line.points, 1)
    end
    local navPoint = self.nav:pointAtI(self.future:indexAtTime(self.goneForward), self.future)
    if navPoint then
      self.nav:remove(navPoint)
    end
    local point = self.points:pointAtI(self.future:indexAtTime(self.goneForward), self.future)
    if point then
      self.points:remove(point)
    end
    
    self.goForward = self.goForward - (dt*self.goForwardIncrements)
    self.goneForward = self.goneForward + (dt*self.goForwardIncrements)
    if (self.goForward <= 0) then
      self:recalculate()
    end
  end
  
  -- look for closest point on line
  local mouse = Vector(self.cam:mousepos())
  local distMin = self.line.points[1]:vector():dist(mouse)
  self.hotPoint = self.line.points[1]
  for i=2,#self.line.points do
    local dist = self.line.points[i]:vector():dist(mouse)
    local pointAtI = self:pointAtI(i)
    if pointAtI then dist = dist - 10 end
    
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
    elseif p.type == "collision" then
      love.graphics.setColor(255, 0, 0)
    end
    love.graphics.circle('fill', pcam.x, pcam.y, 4)
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