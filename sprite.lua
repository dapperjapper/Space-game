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
    
    if self.type == 'planet' then
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

function Sprite:updatePos()
  self.x = (math.cos(self.r)*self.orbitRadius)+self.orbitX
  self.y = (math.sin(self.r)*self.orbitRadius)+self.orbitY
end

return Sprite