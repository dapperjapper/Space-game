-- local nextID = 1
local Sprite = Class{
  init = function(self, x, y, type)
    self.type = type
    self.x = x
    self.y = y
    self.dx = 0
    self.dy = 0
    self.mass = 1
    self.r = 0 -- for planet 0 = to the right
    
    if self.type == 'planet' then -- TODO: split into different classes (so many files!)
      self.orbitX = x
      self.orbitY = y
      self.orbitRadius = 0
      self.orbitSpeed = 0.1 -- rev/s positive for clockwise
      self.radius = 0
      self:updatePos()
    elseif self.type == 'ship' then
      self.power = 1
      self.size = 1
    end
    
    -- self.id = nextID
    -- nextID = nextID+1
  end
}

function Sprite:clone()
  local sprite = Sprite(self.x, self.y, self.type)
  
  sprite.dx = self.dx
  sprite.dy = self.dy
  sprite.mass = self.mass
  sprite.r = self.r
  sprite.orbitX = self.orbitX
  sprite.orbitY = self.orbitY
  sprite.orbitRadius = self.orbitRadius
  sprite.orbitSpeed = self.orbitSpeed
  sprite.radius = self.radius
  sprite.power = self.power
  sprite.size = self.size
    
  return sprite
end

function Sprite:draw(cam)
  if self.type == 'planet' then
    love.graphics.setColor(255, 255, 255)
    local pos = Vector(cam:cameraCoords(self.x, self.y))
    love.graphics.push()
    love.graphics.translate(pos.x, pos.y)
    local tempradius = math.max(5, self.radius*cam.scale)
    love.graphics.circle('fill', 0, 0, tempradius, tempradius+1)
    love.graphics.pop()
  elseif self.type == 'ship' then
    love.graphics.setColor(255, 255, 255)
    local pos = Vector(cam:cameraCoords(self.x, self.y))
    love.graphics.push()
    love.graphics.translate(pos.x, pos.y)
    love.graphics.rotate(self.r)
    love.graphics.polygon('fill',0, 10, 5, -10, -5, -10)
    love.graphics.pop()
  end
end

function Sprite:drawGhost(cam)
  if self.type == 'planet' then
    love.graphics.setColor(255, 255, 255, 100)
    local pos = Vector(cam:cameraCoords(self.x, self.y))
    love.graphics.push()
    love.graphics.translate(pos.x, pos.y)
    local tempradius = math.max(5, self.radius*cam.scale)
    love.graphics.circle('fill', 0, 0, tempradius, tempradius+1)
    love.graphics.pop()
  end
end

function Sprite:updatePos()
  self.x = (math.cos(self.r)*self.orbitRadius)+self.orbitX
  self.y = (math.sin(self.r)*self.orbitRadius)+self.orbitY
end

function Sprite:makeBox2D(world)
  local box2D = {}
  if self.type == "ship" then
    box2D.body = love.physics.newBody(world, self.x, self.y, "dynamic")
    box2D.shape = love.physics.newCircleShape(self.size)
  elseif self.type == "planet" then
    box2D.body = love.physics.newBody(world, self.x, self.y, "kinematic")
    box2D.shape = love.physics.newCircleShape(self.radius)
  end
  
  box2D.fixture = love.physics.newFixture(box2D.body, box2D.shape, 1)
  
  box2D.fixture:setUserData({sprite = self})
  
  box2D.body:setMass(self.mass)
  box2D.body:setLinearVelocity(self.dx, self.dy)
  box2D.body:setFixedRotation(true)
  
  self.box2D = box2D
end

function Sprite:updateFromBox2D()
  self.x, self.y = self.box2D.body:getPosition()      
  self.dx, self.dy = self.box2D.body:getLinearVelocity()
  
  if self.type == 'ship' then
    self.r = -math.atan2(self.box2D.body:getLinearVelocity())
  end -- self.r for planet modified in Future:simulateTo loop
end

return Sprite