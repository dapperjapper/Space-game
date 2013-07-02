local Point = Class{
  init = function(self, x, y)
    self.x = x or 0
    self.y = y or 0
    self.time = 0
  end
}

function Point:vector()
  return Vector(self.x, self.y)
end

function Point:index(future)
  return future:indexAtTime(self.time)
end

return Point