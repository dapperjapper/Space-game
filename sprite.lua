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
    if self.type == 'planet' then
      self.orbitX = x
      self.orbitY = y
      self.orbitRadius = 0
      self.radius = 0
    end
    self.dx = 0 -- TODO: no class defaults?
    self.dy = 0
    self.mass = 1
    self.r = 0
    -- self.id = nextID
    -- nextID = nextID+1
  end
}

function Sprite:isSprite()
  print("yeah!")
  return true
end

return Sprite