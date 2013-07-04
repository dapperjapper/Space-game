local Point = Class{
  init = function(self, x, y, type)
    self.x = x or 0
    self.y = y or 0
    self.type = type or ""
    self.time = 0
  end
}

function Point:vector()
  return Vector(self.x, self.y)
end

function Point:index(future)
  return future:indexAtTime(self.time)
end

function Point:clone()
  local point = Point(self.x, self.y, self.type)
  point.time = self.time
  return point
end

function Point:inCameraCoords(cam)
  local point = self:clone()

  point.x, point.y = cam:cameraCoords(point.x, point.y)
  return point
end

return Point