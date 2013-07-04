-- Continous array of Points intended to form a line (sorted) 
local PointLine = Class{
  init = function(self)
    self.points = {}
  end
}

function PointLine:add(point)
  table.insert( self.points, point )
  return point
end

function PointLine:inCameraCoords(cam)
  local pointLine = PointLine()
  for _,p in ipairs(self.points) do
    table.insert( pointLine.points, p:inCameraCoords(cam) )
  end
  return pointLine
end

function PointLine:last()
  return self.points[#self.points]
end

function PointLine:asLineList()
  local lineList = {}
  for _,p in ipairs(self.points) do
    table.insert( lineList, p.x )
    table.insert( lineList, p.y )
  end
  if #lineList < 4 then -- If the line doesn't even cover to points than add an extra point
    table.insert(lineList, lineList[1])
    table.insert(lineList, lineList[2])
  end
  return lineList
end

return PointLine