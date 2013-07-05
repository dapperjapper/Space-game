local Future = Class{
  init = function(self, sprites, nav)
    self.sim = {}
    
    self.sprites = sprites:clone()
    self.sprites.time = 0
    table.insert(self.sim, self.sprites:clone())
    
    self.nav = nav
    self.world = love.physics.newWorld(0, 0, true)
    
    local function beginContact(a, b)
      local isShip = false
      if a:getUserData().sprite.type == 'ship' then
        isShip = true
      elseif b:getUserData().sprite.type == 'ship' then
        isShip = true
      end
      self.collisionCourse = isShip
    end
    -- http://love2d.org/forums/viewtopic.php?f=4&t=9643
    self.world:setCallbacks(beginContact, function() collectgarbage() end)
    
    self.sprites:makeBox2D(self.world)
  end,
  sim = {},
  granularity = 0.01
}

function Future:simulateTo(t)
  local sim = self.sim
  local shipBody = self.sprites:ship().box2D.body

  while sim[#sim].time < t and not self.collisionCourse do
    
    local shipVec = Vector(shipBody:getPosition())
    for _,s in ipairs(self.sprites.sprites) do
      if s.type == "planet" then
        local planetBody = s.box2D.body
        local planetSpr = s
        
        -- rotate planets
        planetSpr.r = planetSpr.r+(planetSpr.orbitSpeed/(2*math.pi)*self.granularity)
        planetSpr:updatePos()
        planetBody:setPosition( planetSpr.x, planetSpr.y )
        
        -- apply radial gravity to ship
        local planetVec = Vector(planetBody:getPosition())
        local distance = planetVec - shipVec        
        -- F = GMm/R^2
        -- local G = 6.674*(10^-11) -- m3 kg-1 s-2
        local force = planetSpr.mass / distance:len2()
        local normforce = force*distance
        shipBody:applyForce(normforce:unpack())
      end
    end
    
    local navPoint = self.nav:at(self.sprites.time)
    if navPoint then
      local dir = Vector( math.cos(navPoint.direction), math.sin(navPoint.direction) )
      shipBody:applyForce( (dir*self.sprites:ship().power):unpack() )
    end
    
    self.world:update(self.granularity)
    self.sprites.time = self.sprites.time + self.granularity
    
    -- copy box2d to sprites
    self.sprites:updateFromBox2D()
    
    table.insert(sim, self.sprites:clone())
  end
end

function Future:indexAtTime(t)  
  -- http://rosettacode.org/wiki/Binary_search#Lua
  local function binarySearch (list, value)
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
      return high -- close enough (time is in between low and high sim points)
  end
  return binarySearch(self.sim, t)
end

function Future:timeAtIndex(i)
  return i*self.granularity
end  

-- Clone if you intend to change these values
function Future:at(t)
  self:simulateTo(t)
  
  if self.collisionCourse and t>self.sim[#self.sim].time then return self.sim[#self.sim] end
  return self.sim[self:indexAtTime(t)]
end

function Future:atI(i)
  self:simulateTo(self:timeAtIndex(i))
  
  if self.collisionCourse and i>#self.sim then return self.sim[#self.sim] end
  return self.sim[i]
end

function Future:shipAt(t)
  return self:at(t):ship()
end

function Future:shipAtI(i)
  return self:atI(i):ship()
end

function Future:shipLine(fromT, toT)
  self:simulateTo(toT)
  
  local fromIndex = self:indexAtTime(fromT)
  local toIndex = self:indexAtTime(toT)
  local line = PointList()
  
  for i=fromIndex,toIndex do
    local ship = self:shipAtI(i)
    local point = Point(ship.x, ship.y, "shipPath")
    point.time = self:atI(i).time
    -- point.index = i
    line:add(point)
  end
  
  return line
end

-- function Future:atInterpolate(t)
--   self:simulateTo(t)
--   
--   if self.collisionCourse and t>self.sim[#self.sim].time then return self.sim[#self.sim] end
--   
--   local low = self.sim[self:indexAtTime(t)]
--   local high = self.sim[self:indexAtTime(t)+1]
--   local dTime = t-low.time
--   local duration = high.time-low.time
--   -- https://code.google.com/p/tweener/source/browse/trunk/as3/caurina/transitions/Equations.as
--   local function interpolate(t, startV, endV, duration)
--     return (endV-startV)*t/duration + startV;
--   end
--   
--   local sprites = Class.clone(low)
--   for i,s in ipairs(sprites) do
--     s.x = interpolate(dTime, low[i].x, high[i].x, duration)
--     s.y = interpolate(dTime, low[i].y, high[i].y, duration)
--     s.r = interpolate(dTime, low[i].r, high[i].r, duration)
--   end
--   return sprites
-- end

function Future:destroy()
  self.world:destroy()
  self.nav = nil
end

return Future