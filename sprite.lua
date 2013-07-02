local Sprite = Class{
  x=0, y=0,
  dx=0, dy=0,
  r=0,
  mass = 1,
  init = function(self)
    self.x = 0
    self.y = 0
    self.dx = 0 -- TODO: no class defaults?
    self.dy = 0
    self.r = 0
  end
}

return Sprite