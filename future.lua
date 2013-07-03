local Future = Class{
  init = function(self, sprites, nav)
    self.sim = {}
    
    self.sprites = Class.clone(sprites) -- destroys class structure, leaves table, oh well
    self.sprites.time = 0
    table.insert(self.sim, Class.clone(self.sprites))
    
    self.nav = nav
    
    self.world = love.physics.newWorld(0, 0, false)
    
    local function beginContact(a, b, coll)
      if a:getUserData().type == 'ship' then
        local ship = a
      elseif b:getUserData().type == 'ship' then
        local ship = b
      end
      if ship then
        self.collisionCourse = true
      end
    end
    self.world:setCallbacks(beginContact)
    
    self.objects = {}
    for i,s in ipairs(self.sprites) do
      local object = {}
      
      if s.type == "ship" then
        object.body = love.physics.newBody(self.world, s.x, s.y, "dynamic")
        object.shape = love.physics.newCircleShape(s.size)
      elseif s.type == "planet" then
        object.body = love.physics.newBody(self.world, s.x, s.y, "kinematic")
        object.shape = love.physics.newCircleShape(s.radius)
      end
      
      object.fixture = love.physics.newFixture(object.body, object.shape, 1)
      object.fixture:setUserData({spritesI = i, type = s.type})
      
      object.spritesI = i
      object.type = s.type
      
      object.body:setMass(s.mass)
      object.body:setLinearVelocity(s.dx, s.dy)
      -- object.body:setAngle(s.r)
      object.body:setFixedRotation(true)
      
      table.insert(self.objects, object)
      
      if s.type == "ship" then
        self.shipFixtI = #self.objects
        self.shipSprI = i
      end
    end
  end,
  sim = {},
  granularity = 0.01
}

function Future:simulateTo(t)
  local sim = self.sim
  local ship = self.objects[self.shipFixtI].body

  while sim[#sim].time < t and not self.collisionCourse do

    local shipVec = Vector(ship:getPosition())
    for _,p in ipairs(self.objects) do
      if p.type == "planet" then
        local planet = p.body
        local planetVec = Vector(planet:getPosition())
        local distance = planetVec - shipVec
        
        -- F = GMm/R^2
        -- local G = 6.674*(10^7) -- m3 kg-1 s-2 -- -11 + 18
        -- local G = 0.8650 -- cm3 g-1 hr-2
        -- local R = distance:len() * 100000000 -- megameters to meters
        -- local M = planet:getMass() * 1000000000000 -- teragrams to grams
        -- local m = ship:getMass() * 1000000000000 -- teragrams to grams
        -- print(G, R, M, m)
        -- local force = (G*M*m) / (R^2)
        -- local normforce = force*distance
        -- ship:applyForce(normforce:unpack())
        local force = self.sprites[p.spritesI].mass / distance:len2()
        local normforce = force*distance
        ship:applyForce(normforce:unpack())
      end
    end
    
    if self.nav:at(self.sprites.time) then
      local vel = Vector(ship:getLinearVelocity())
      ship:applyForce((vel*self.sprites[self.shipSprI].power):unpack())
    end
    
    self.world:update(self.granularity)

    -- ship:setAngle(-math.atan2(ship:getLinearVelocity()))
    
    self.sprites.time = self.sprites.time + self.granularity
    for _,fxt in ipairs(self.objects) do
      local sprite = self.sprites[fxt.spritesI]
      sprite.x, sprite.y = fxt.body:getPosition()      
      sprite.dx, sprite.dy = fxt.body:getLinearVelocity()
      
      --sprite.r = fxt.body:getAngle()
      if (fxt.type == 'ship') then sprite.r = -math.atan2(ship:getLinearVelocity()) end
    end
    
    table.insert(sim, Class.clone(self.sprites))
  end
end

function Future:indexAtTime(t)  
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
      return high -- close enough (time is in between low and high sim points)
  end
  return binarySearch(self.sim, t)
end

function Future:at(t)
  self:simulateTo(t)
  
  if self.collisionCourse and t>self.sim[#self.sim].time then return self.sim[#self.sim] end
  return self.sim[self:indexAtTime(t)]
end

function Future:atI(i)
  self:simulateTo(i*self.granularity) -- TODO: clunky
  
  if self.collisionCourse and i>#self.sim then return self.sim[#self.sim] end
  return self.sim[i]
end

function Future:shipAt(t)
  return self:at(t)[self.shipSprI]
end

function Future:shipAtI(i)
  return self:atI(i)[self.shipSprI]
end

function Future:shipLine(fromT, toT)
  self:simulateTo(toT)
  
  local fromIndex = self:indexAtTime(fromT)
  local toIndex = self:indexAtTime(toT)
  local line = PointLine()
  
  for i=fromIndex,toIndex do
    local ship = self:shipAtI(i)
    local point = Point(ship.x, ship.y, "shipPath")
    point.time = self:atI(i).time
    -- point.index = i
    line:add(point)
  end
  
  return line
end

function Future:atInterpolate(t)
  self:simulateTo(t)
  
  if self.collisionCourse and t>self.sim[#self.sim].time then return self.sim[#self.sim] end
  
  local low = self.sim[self:indexAtTime(t)]
  local high = self.sim[self:indexAtTime(t)+1]
  local dTime = t-low.time
  local duration = high.time-low.time
  -- https://code.google.com/p/tweener/source/browse/trunk/as3/caurina/transitions/Equations.as
  local function interpolate(t, startV, endV, duration)
    return (endV-startV)*t/duration + startV;
  end
  
  local sprites = Class.clone(low)
  for i,s in ipairs(sprites) do
    s.x = interpolate(dTime, low[i].x, high[i].x, duration)
    s.y = interpolate(dTime, low[i].y, high[i].y, duration)
    s.r = interpolate(dTime, low[i].r, high[i].r, duration)
  end
  return sprites
end

function Future:destroy()
  self.world:destroy()
  self.nav = nil
end

return Future