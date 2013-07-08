local ShipLine = Class{
  init = function(self, game)
    self.game = game
    self.sprites = game.sprites
    self.nav = Nav()
    self.granularity = 0.1
    self.cam = game.cam
    self.future = nil
    self.interestPoints = nil -- like crash notifiers and end of the shipline
    self:recalculate()
    
    self.goForward = 0
    self.goneForward = 0
    self.hotPoint = nil
    self.activePoint = nil
  end
}

function ShipLine:recalculate(startChangedT) -- TODO: optimize for nav changes only recalculate after the nav
  local lastNav = self.nav:last()
  if lastNav then lastNav=lastNav:endTime() else lastNav=0 end
  local endTime = math.max(5, lastNav)
  
  if self.future then self.future:destroy(); self.future=nil end
  self.future = Future(self.sprites, self.nav)
  self.future.granularity = self.granularity
  self.line = self.future:shipLine(0, endTime)
  self.nav:updatePositions(self.future)
  self:updateInterestPoints()
end

function ShipLine:extend(t)
  self.line = self.future:shipLine(0, self.line:last().time+t)
  self:updateInterestPoints()
end

function ShipLine:updateInterestPoints()
  self.interestPoints = PointList()
  if self.future.collisionCourse then
    local endp = Point(self.line:last().x, self.line:last().y, "collision")
    endp.time = self.line:last().time
    self.interestPoints:add(endp)
  else
    local endp = Point(self.line:last().x, self.line:last().y, "end")
    endp.time = self.line:last().time
    self.interestPoints:add(endp)
  end
end

function ShipLine:keypressed(key, code)
  
end

function ShipLine:keyreleased(key, code)
  
end

function ShipLine:mousepressed(x, y, button)
  local navLengthPower = 0.05 --sec

  if button == "l" then
    if self.game.clickMode == 'addNav' then
      -- add nav
      local navPoint = NavPoint()
      navPoint.x, navPoint.y = self.hotPoint:vector():unpack()
      navPoint.time = self.hotPoint.time
      navPoint.length = 0
      self.activePoint = self.nav:add(navPoint)
      self.game.toolMode = 'navDir'
    elseif self.game.clickMode == 'extend' then
      self:extend(10)
    elseif self.game.clickMode == 'selectNav' then
      self.activePoint = self.hotPoint
    elseif self.game.clickMode == 'ff' then
      self:deselect()
      self:fastForward(self.hotPoint.time)
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
end

function ShipLine:fastForward(t)
  self:updateSprites(self.future:at(t))
  self.nav:moveAllBack(t, self.future)
  self.interestPoints:moveAllBack(t, self.future)
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
  local point = self.interestPoints:pointAtI(index, self.future)
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
  --     if self.interestPoints.points[1] then
  --       repeat -- remove points we've gone over
  --         table.remove(self.interestPoints.points, 1)
  --       until self.interestPoints.points[1].time > self.goneForward
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
  for i=1,#self.line.points do
    local dist = self.line.points[i]:vector():dist(mouse)
    local pointAtI = self:pointAtI(i)
    if pointAtI then dist = dist - 10 end -- Prioritize special points
    
    if dist < distMin then
      distMin = dist
      self.hotPoint = self.line.points[i]
      if pointAtI then self.hotPoint = pointAtI end
    end
  end
  if distMin*self.cam.scale > 20 then self.hotPoint=nil end -- No hover unless 10 pixels away
    
  self.clickMode = false
  if self.hotPoint then
    if self.game.toolMode == "plan" then
      if self.hotPoint.type=="shipPath" then
        -- add nav
        if not self.nav:at(self.hotPoint.time) then -- point already occupied
          self.clickMode = "addNav"
        end
      elseif self.hotPoint.type=="end" then
        -- extend
        self.clickMode = "extend"
      else
        -- select
        self.clickMode = "selectNav"
      end
    elseif self.game.toolMode == "ff" then
      self.clickMode = "ff"
    end
  end
  if self.game.toolMode == 'navDir' then
    self.clickMode = 'navDir'
    local mouse = Vector(self.cam:mousepos())
    local r = -math.atan2( (mouse-self.activePoint:vector()):unpack() )+(math.pi/2)
    self.activePoint.direction = r
  end
  
  self.scrollMode = false
  if self.activePoint and self.activePoint.type == 'nav' then
    self.scrollMode = 'navLength'
  end
  
  if self.hotPoint then
    if self.clickMode == "extend" then
      local pcam = self.hotPoint:inCameraCoords(self.cam)
      gui.Tooltip{text="Click to extend", pos={pcam.x, pcam.y}}
    elseif self.hotPoint.type == "collision" then
      local pcam = self.hotPoint:inCameraCoords(self.cam)
      gui.Tooltip{text="WARNING: Collision course", pos={pcam.x, pcam.y}}
    elseif self.clickMode == 'ff' then
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
  self.interestPoints:drawPoints(self.cam, self.future)
  
  -- Draw unselected navs in bold white
  love.graphics.setLineWidth(3)
  love.graphics.setColor(255, 255, 255)
  self.nav:drawPoints(self.cam, self.future)
  
  -- Draw over selected nav in green
  love.graphics.setColor(0, 255, 0)
  if self.activePoint and self.activePoint.type=='nav' then
    self.activePoint:draw(self.cam, self.future)
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