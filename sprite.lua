-- local nextID = 1
local Sprite = Class{
  x=0, y=0,
  dx=0, dy=0,
  r=0,
  mass=1,
  init = function(self, x, y, type)
    self.type = type
    self.x = x
    self.y = y
    self.dx = 0 -- TODO: no class defaults?
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
    end
    
    -- self.id = nextID
    -- nextID = nextID+1
  end
}

function Sprite:updatePos()
  self.x = (math.cos(self.r)*self.orbitRadius)+self.orbitX
  self.y = (math.sin(self.r)*self.orbitRadius)+self.orbitY
end

return Sprite