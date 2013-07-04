-- local nextID = 1
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

return SpriteList