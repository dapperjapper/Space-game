local ShipLine = Class{
  init = function(self, sprites, cam)
    self.sprites = sprites
    self.nav = Nav()
    self.granularity = 0.1882
    self.cam = cam
    self.future = nil
    self.points = nil -- interface points, like crash notifiers and end of sim
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
  self.nav:updatePositions(self.future)
  self:updatePoints()
end

function ShipLine:extend(t)
  self.line = self.future:shipLine(0, self.line:last().time+t)
  self:updatePoints()
end

function ShipLine:updatePoints()
  self.points = PointList()
  local endp = Point(self.line:last().x, self.line:last().y, "end")
  endp.time = self.line:last().time
  self.points:add(endp)
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
      elseif self.hotPoint.type=="end" then
        print("extend this bitch")
        self:extend(10)
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
      end
      interacted = true
    end
  elseif button == 'wd' then
    if self.activePoint and self.activePoint.type=='nav' then
      if self.activePoint.length > navLengthPower*2 then
        self.activePoint.length = self.activePoint.length - navLengthPower
        self:recalculate()
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

function ShipLine:update()
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
  
  if self.hotPoint and self.hotPoint.type == "end" then
    local pcam = self.hotPoint:inCameraCoords(self.cam)
    gui.Label{text="Click to extend", pos={pcam.x, pcam.y}, align = "center", draw = function(state, text, align, x,y,w,h)
    	local f = assert(love.graphics.getFont())
    	w = f:getWidth(text)+8
    	h = f:getHeight(text)+4
    	local point = Vector(x, y)
    	local middle = Vector(x - w/2, y - h/2)
    	local direction = Vector(love.mouse.getPosition()) - point
    	direction:normalize_inplace()
    	local angle = -math.atan2(direction:unpack())
    	local distance = radiusRectangle(w, h, angle) * 1.1 + 10
    	direction = direction * distance
    	local pos = middle - direction
    	
    	love.graphics.setColor(0, 0, 0)
    	love.graphics.rectangle( "fill", pos.x, pos.y, w, h )
    	love.graphics.setColor(255, 255, 255)
    	love.graphics.rectangle( "line", pos.x, pos.y, w, h )
    	love.graphics.print(text, pos.x+4, pos.y+2)
    end}
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
    if p.type == "end" then love.graphics.setColor(255, 255, 255) end
    love.graphics.circle('fill', pcam.x, pcam.y, 4)
  end
  
  -- Draw unselected navs in bold white
  love.graphics.setLineWidth(3)
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