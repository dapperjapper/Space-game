local NavPoint = Class{
  init = function(self)
    self.x = 0
    self.y = 0
    self.time = 0
    -- self.index = 0
    self.length = 0 -- length is in seconds
  end
}

function NavPoint:vector()
  return Vector(self.x, self.y)
end

function NavPoint:shipLine(future)
  return future:shipLine(self.time, self.time+self.length)
end

function NavPoint:shipLineList(future)
  return future:shipLineList(self.time, self.time+self.length)
end

return NavPoint