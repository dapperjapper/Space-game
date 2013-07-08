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

function SpriteList:draw(cam)
  for _,s in ipairs(self.sprites) do
    s:draw(cam)
  end
end

function SpriteList:update(dt)
  for _,s in ipairs(self.sprites) do
    s:update(dt)
  end
end

function SpriteList:drawGhosts(cam)
  for _,s in ipairs(self.sprites) do
    s:drawGhost(cam)
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