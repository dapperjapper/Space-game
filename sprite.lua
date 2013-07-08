-- local nextID = 1
local Sprite = Class{
  init = function(self, x, y, type)
    self.type = type
    self.x = x
    self.y = y
    self.dx = 0
    self.dy = 0
    self.mass = 1
    self.r = 0
    
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
  return sprite
end

function Sprite:draw(cam)
  return
end

function Sprite:update(dt)
  return
end

function Sprite:drawGhost(cam)
  return
end

function Sprite:makeBox2D(world)
  return
end

function Sprite:updateFromBox2D()
  return
end

return Sprite