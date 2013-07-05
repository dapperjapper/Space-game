-- Non continous array of Points (sorted) 
local PointList = Class{
  init = function(self)
    self.points = {}
  end
}

function PointList:add(point) -- keeps it sorted
  local i = self:pointBeforeOrOn(point.time)
  table.insert( self.points, i+1, point )
  return point
end

function PointList:remove(point)
  for i,p in ipairs(self.points) do
    if p == point then table.remove( self.points, i ) end
  end
  return point
end

function PointList:moveAllBack(t, future) 
  local pToRemove = {}
  for _,p in ipairs(self.points) do
    p.time = p.time-t
    if p.time <= 0 then
      table.insert(pToRemove, p) -- Since you can't modify a table while looping through it
    end
  end
  for _,p in ipairs(pToRemove) do
    self:remove(p)
    if p.type=='nav' and p:endTime() > 0 then
      local navPoint = p:clone()
      navPoint.time = 0  -- TODO: not totally consistent???
      navPoint.length = p:endTime()
      navPoint:updatePosition(future)
      self:add(navPoint)
    end
  end
end

function PointList:pointBeforeOrOn(t)
  -- http://rosettacode.org/wiki/Binary_search#Lua
  local function binarySearch (list,value)
      local low = 1
      local high = #list
      local mid = 0
      while low <= high do
          mid = math.floor((low+high)/2)
          if list[mid].time > value then high = mid - 1
          else if list[mid].time < value then low = mid + 1
               else return mid
               end
          end
      end
      return high -- close enough (time is in between low and high sim points, returns low)
  end
  
  return binarySearch(self.points,t)
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

function PointList:drawPoints(cam, future)
  for _,p in ipairs(self.points) do
    p:draw(cam, future)
  end
end

function PointList:last()
  return self.points[#self.points]
end

function PointList:asLineList()
  local lineList = {}
  for _,p in ipairs(self.points) do
    table.insert( lineList, p.x )
    table.insert( lineList, p.y )
  end
  if #lineList < 4 then -- If the line doesn't even cover two points than add an extra point
    table.insert(lineList, lineList[1])
    table.insert(lineList, lineList[2])
  end
  return lineList
end


return PointList