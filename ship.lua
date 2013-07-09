local Ship = Class{
  init = function(self, x, y, type)
    self.type = type
    self.x = x
    self.y = y
    self.dx = 0
    self.dy = 0
    self.mass = 1
    self.r = 0 -- 0 = to the right
    self.power = 1
    self.radius = 1
  end,
  __includes = {Sprite}
}

function Ship:clone()
  local sprite = Ship(self.x, self.y, self.type)
  
  sprite.dx = self.dx
  sprite.dy = self.dy
  sprite.mass = self.mass
  sprite.r = self.r
  sprite.radius = self.radius
  sprite.power = self.power
  sprite.radius = self.radius
    
  return sprite
end

-- function Ship:simpleClone()
--   --local ship = {x=self.x, y=self.y, dx=self.dx, dy=self.dy, r=self.r}
--   return self:clone()
-- end

Ship.simpleClone = Ship.clone

function Ship:withSimple(simple)
  return simple:clone()
end

function Ship:draw(cam)
  love.graphics.setColor(255, 255, 255)
  local pos = Vector(cam:cameraCoords(self.x, self.y))
  love.graphics.push()
  love.graphics.translate(pos.x, pos.y)
  love.graphics.rotate(self.r)
  love.graphics.polygon('fill',10, 0, -10, 5, -10, -5)
  love.graphics.pop()
end

function Ship:makeBox2D(world)
  local box2D = {}
  box2D.body = love.physics.newBody(world, self.x, self.y, "dynamic")
  box2D.shape = love.physics.newCircleShape(self.radius)
  
  box2D.fixture = love.physics.newFixture(box2D.body, box2D.shape, 1)
  
  box2D.fixture:setUserData({sprite = self})
  
  box2D.body:setMass(self.mass)
  box2D.body:setLinearVelocity(self.dx, self.dy)
  box2D.body:setFixedRotation(true)
  
  self.box2D = box2D
end

function Ship:updateFromBox2D()
  self.x, self.y = self.box2D.body:getPosition()      
  self.dx, self.dy = self.box2D.body:getLinearVelocity()
  self.r = -math.atan2(self.box2D.body:getLinearVelocity())+(math.pi/2)
end

return Ship