local PointList = Class{
  init = function(self)
    self.points = {}
  end
}

function PointList:add(point)
  table.insert( self.points, point )
  return point
end

function PointList:remove(point)
  for i,p in ipairs(self.points) do
    print(inspect(p), inspect(point))
    if p == point then table.remove( self.points, i ) end
  end
  return point
end

function PointList:pointAtI(index, future)
  for _,p in ipairs(self.points) do
    if p:index(future) == index then return p end
  end
  
  return nil
end

function PointList:updatePositions(future)
  for _,p in ipairs(self.points) do p:updatePosition(future) end
end

function PointList:inCameraCoords(cam)
  local pointList = PointList()
  for _,p in ipairs(self.points) do
    table.insert( pointList.points, p:inCameraCoords(cam) )
  end
  return pointList
end

return PointList