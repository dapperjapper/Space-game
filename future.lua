local Future = Class{
  init = function(self, sprites, nav)
    self.sim = {}
    
    self.sprites = Class.clone(sprites)
    self.sprites.time = 0
    table.insert(self.sim, Class.clone(self.sprites))
    
    self.nav = nav
    
    self.world = love.physics.newWorld(0, 0, false)
    
    self.fixtures = {}
    for i,s in ipairs(self.sprites) do
      local fixture = {}
      
      if s.type == "ship" then
        fixture.body = love.physics.newBody(self.world, s.x, s.y, "dynamic")
        fixture.shape = love.physics.newCircleShape(s.size)
      elseif s.type == "planet" then
        fixture.body = love.physics.newBody(self.world, s.x, s.y, "kinematic")
        fixture.shape = love.physics.newCircleShape(s.radius)
      end
      
      fixture.fixture = love.physics.newFixture(fixture.body, fixture.shape, 1)
      fixture.spritesI = i
      
      fixture.body:setMass(s.mass)
      fixture.body:setLinearVelocity(s.dx, s.dy)
      fixture.body:setAngle(s.r)
      
      table.insert(self.fixtures, fixture)
      
      if s.type == "ship" then
        self.shipFixtI = #self.fixtures
        self.shipSprI = i
      end
    end
  end,
  sim = {},
  granularity = 0.01
}

function Future:simulateTo(t)
  local sim = self.sim
  local ship = self.fixtures[self.shipFixtI].body

  while sim[#sim].time < t do

    local shipVec = Vector(ship:getPosition())
    for _,p in ipairs(self.fixtures) do
      if self.sprites[p.spritesI].type == "planet" then
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
        -- print(force)
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

    ship:setAngle(-math.atan2(ship:getLinearVelocity()))
    
    self.sprites.time = self.sprites.time + self.granularity
    for _,fxt in ipairs(self.fixtures) do
      local sprite = self.sprites[fxt.spritesI]
      sprite.x, sprite.y = fxt.body:getPosition()
      sprite.r = fxt.body:getAngle()
      sprite.dx, sprite.dy = fxt.body:getLinearVelocity()
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
      return low -- close enough (time is in between low and high sim points)
  end
  return binarySearch(self.sim, t)
end

function Future:at(t)
  self:simulateTo(t)
  
  return self.sim[self:indexAtTime(t)]
end

function Future:shipAt(t)
  return self:at(t)[self.shipSprI]
end

function Future:shipLine(fromT, toT)
  self:simulateTo(toT)
  
  local fromIndex = self:indexAtTime(fromT)
  local toIndex = self:indexAtTime(toT)
  local line = {}
  
  for i=fromIndex,toIndex do
    point = Point(self.sim[i][self.shipSprI].x, self.sim[i][self.shipSprI].y)
    point.time = self.sim[i].time
    point.type = "shipPath"
    -- point.index = i
    table.insert(line, point)
  end
  
  return line
end

function Future:shipLineList(fromT, toT)
  self:simulateTo(toT)
  
  local fromIndex = self:indexAtTime(fromT)
  local toIndex = self:indexAtTime(toT)
  local line = {}
  for i=fromIndex,toIndex do
    table.insert(line, self.sim[i][self.shipSprI].x)
    table.insert(line, self.sim[i][self.shipSprI].y)
  end
  
  return line
end

function Future:destroy()
  self.world:destroy()
  self.nav = nil
end

return Future