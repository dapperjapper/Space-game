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

function PointList:moveAllBack(t)
  local pToRemove = {}
  for _,p in ipairs(self.points) do
    p.time = p.time-t
    if p.time <= 0 then
      table.insert(pToRemove, p) -- Since you can't modify a table while looping through it
    end
  end
  for _,p in ipairs(pToRemove) do
    self:remove(p)
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

function PointList:pointAtI(index, future) -- TODO: index is clunky
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