local NavPoint = Class{
  init = function(self, x, y)
    self.x = x or 0
    self.y = y or 0
    self.time = 0
    self.type = "nav"
    -- self.index = 0
    self.length = 0 -- length is in seconds
  end,
  __includes = {Point}
}

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

-- function NavPoint:shipLineList(future)
--   local lineList = future:shipLineList(self.time, self:endTime())
--   if #lineList < 4 then -- If the line doesn't even cover to points than add an extra point
--     table.insert(lineList, lineList[1])
--     table.insert(lineList, lineList[2])
--   end
--   return lineList
-- end

return NavPoint