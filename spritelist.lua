local SpriteList = Class{
  init = function(self)
    self.time = 0
    self.sprites = {}
    self.shipId = nil
  end
}

function SpriteList:add(sprite)
  table.insert( self.sprites, sprite )
  if sprite.type == 'ship' then
    self.shipId = #self.sprites
  end
  sprite.id = #self.sprites
  return sprite
end

function SpriteList:ship()
  if self.shipId then
    return self.sprites[self.shipId]
  end
end

function SpriteList:clone()
  local spriteList = SpriteList()
  
  for _,s in ipairs(self.sprites) do
    spriteList:add(s:clone())
  end
  
  spriteList.time = self.time
  return spriteList
end

-- The simple clones are tables that contain only the core properties of the sprite that change over time
-- This reduces the storage costs for the Future class
function SpriteList:simpleClone()
  local spriteList = SpriteList()
  
  for _,s in ipairs(self.sprites) do
    spriteList:add(s:simpleClone())
  end
  
  spriteList.time = self.time
  return spriteList
end

function SpriteList:importSimple(simple)
  for i,s in ipairs(self.sprites) do
    self.sprites[i] = s:withSimple(simple.sprites[i])
  end
end

function SpriteList:draw(cam)
  for _,s in ipairs(self.sprites) do
    s:draw(cam)
  end
end

function SpriteList:update(dt)
  for _,s in ipairs(self.sprites) do
    if s.update then s:update(dt) end
  end
end

function SpriteList:drawGhosts(cam, simpleClones)
  for _,s in ipairs(self.sprites) do
    if s.drawGhost then
      s:drawGhost(cam, simpleClones.sprites[s.id])
    end
  end
end

function SpriteList:makeBox2D(world)
  for _,s in ipairs(self.sprites) do      
    s:makeBox2D(world)   
  end
end

function SpriteList:updateFromBox2D()
  for _,s in ipairs(self.sprites) do
    s:updateFromBox2D()
  end
end

return SpriteList