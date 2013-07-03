local Nav = Class{
  init = function(self)
    self.points = {}
  end,
  __includes = {PointList}
}

-- returns NavPoint firing at t (including length) or false if none
function Nav:at(t)
  if #self.points < 1 then return false end
    
  local maxPoint = nil
  for _,p in ipairs(self.points) do
    if p.time < t then
      if not maxPoint or p.time > maxPoint.time then
        maxPoint = p
      end
    end
  end
  
  if maxPoint and maxPoint:endTime() >= t then
    return maxPoint
  else return false end
end

function Nav:last()
  local maxPoint = nil
  for _,p in ipairs(self.points) do
    if not maxPoint or p.time > maxPoint.time then
      maxPoint = p
    end
  end
  return maxPoint
end

return Nav