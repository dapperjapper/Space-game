local NavPoint = Class{
  init = function(self, x, y)
    self.x = x or 0
    self.y = y or 0
    self.time = 0
    self.type = "nav"
    self.length = 0 -- length is in seconds
    self.direction = 0
  end,
  __includes = {Point}
}

function NavPoint:clone()
  local point = NavPoint(self.x, self.y)
  point.time = self.time
  point.type = self.type
  point.length = self.length
  point.direction = self.direction
  return point
end

function NavPoint:updatePosition(future)
  local ship = future:shipAt(self.time)
  self.x = ship.x
  self.y = ship.y
end

function NavPoint:endTime()
  return self.time+self.length
end

function NavPoint:shipLine(future)
  return future:shipLine(self.time, self:endTime())
end

function NavPoint:draw(cam, future)
  local pcam = self:inCameraCoords(cam)
  love.graphics.circle('fill', pcam.x, pcam.y, 4)    
  love.graphics.line(unpack( self:shipLine(future):inCameraCoords(cam):asLineList() ))
  
  love.graphics.push()
  love.graphics.translate(pcam.x, pcam.y)
  love.graphics.rotate(self.direction)
  love.graphics.translate(10, 0)
  love.graphics.line(-10, 0, 0, 0)
  love.graphics.polygon('fill', 0, -6, 0, 6, 8, 0)
  love.graphics.pop()
end

return NavPoint