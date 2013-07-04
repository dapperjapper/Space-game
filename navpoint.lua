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

return NavPoint