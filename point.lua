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

function Point:draw(cam, future)
  local pcam = self:inCameraCoords(cam)
  if self.type == "end" then
    love.graphics.setColor(255, 255, 255)
    love.graphics.push()
    love.graphics.translate(pcam.x, pcam.y)
    love.graphics.rotate(future:shipAt(self.time).r)

    love.graphics.rectangle('fill', -5, -2, 5, 4)
    love.graphics.polygon('fill', 0, -6, 0, 6, 8, 0)
    love.graphics.pop()
  elseif self.type == "collision" then
    love.graphics.setColor(255, 0, 0)
    love.graphics.circle('fill', pcam.x, pcam.y, 4)
  end
end

return Point