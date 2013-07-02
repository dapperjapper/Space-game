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

printed = false

function Point:inCameraCoords(cam)
  -- if printed then return end
  -- print(inspect(self))
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  local point = self:clone()
  if self.type == 'nav' then
    point.__includes={NavPoint} -- TODO: so clunky
  else
    point.__includes={Point}
  end
  -- print(inspect(point))
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  -- print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)print(nil)
  -- printed = true
  point.x, point.y = cam:cameraCoords(point.x, point.y)
  return point
end

return Point