local Planet = Class{
  -- props = radius, mass, r, sun, orbitRadius, orbitSpeed
  init = function(self, props)
    self.type = "planet"
    
    self.dx = props.dx or 0
    self.dy = props.dy or 0
    self.mass = props.mass or 1
    self.r = props.r or 0
    self.sun = props.sun
    self.orbitX = props.sun.x or props.sun[1] or 0
    self.orbitY = props.sun.y or props.sun[2] or 0
    self.orbitRadius = props.orbitRadius or 0
    self.orbitSpeed = props.orbitSpeed or 0 -- rev/sec positive for clockwise
    self.radius = props.radius or 10
    self.appearance = Class.clone(props.appearance) or {}
    
    if props.tex then
      self.tex = props.tex
      self.texR = props.texR
      self.rings = props.rings
    else
      self:generateImages()
    end
    
    self:updatePosition(0)
  end,
  __includes = {Sprite}
}

function Planet:clone()
  local planet = Planet(self)
  return planet
end

require "planetgraphics"
local shadow = shadowGradient(50, 200, 2, {0, 0, 0})
local softShadow = shadowGradient(50, 30, 1.5, {0, 0, 0})

function Planet:generateImages()
  print('making images for planet #', self.id, 'size', self.radius)
  a = self.appearance
  
  if not a.type then a.type = 'gasgiant' end
  
  if a.type == 'gasgiant' then
    local redOrBlue = math.random(0,1)
    local hue
    if redOrBlue < 1 then hue=math.random(0,50) else hue=math.random(128,170) end
  
    a.color = {HSL(hue, math.random(0,255), math.random(50,200), 255)}
    a.shadowColor = blendColor({0, 0, 0, 200}, a.color)
    a.stripesA = math.random(0,100)
  
    local ringsOrNo = math.random(0,100)
    -- 70% have rings
    if ringsOrNo < 70 then
      a.rings = {}
      a.rings.color = a.color
      a.rings.number = math.floor(math.random(0,20)*self.radius/50)
    else
      a.rings = false
    end
  
    -- Image sizes are self.radius*8 so they are sharp up to a 4x zoom
    self.tex = gasGiantTexture(self.radius*2, {color=a.color, stripesA=a.stripesA, visualDiam=self.radius*2})
    self.texR = math.random(0, math.pi*2)
  
    if a.rings then
      self.rings = ringsCanvas(self.radius*32, {color=a.rings.color, thickness=1, rings=a.rings.number, visualDiam=self.radius*2})
    end
  elseif a.type == 'sun' then
    a.rings = false
    self.tex = sunTexture(self.radius*2, {visualDiam=self.radius*2})
    self.texR = 0
  end
end

function Planet:update(dt)
  -- Rotate planet visually
  -- self.texR = self.texR+math.pi/50*dt
end

function Planet:draw(cam) -- Clean up cray cray
  local tempradius = math.max(5, self.radius*cam.scale)
  local pos = Vector(cam:cameraCoords(self.x, self.y))
  local sun = Vector(cam:cameraCoords(self.orbitX, self.orbitY))
  local r = -math.atan2( (sun-pos):unpack() )+(math.pi/2)
  local dir = Vector(math.cos(r), math.sin(r))
  love.graphics.push()
  love.graphics.setColor(255,255,255)
  love.graphics.translate(pos.x, pos.y)
  
  if self.appearance.rings then
    self:drawRings(tempradius, dir, true)
  end
  
  love.graphics.setStencil(function()
     love.graphics.circle('fill', 0, 0, tempradius, tempradius+1)
  end)
    -- Texture
    love.graphics.push()
      love.graphics.rotate(self.texR)
      love.graphics.draw(self.tex, -tempradius,-tempradius,0, tempradius*2/self.tex:getWidth(), tempradius*2/self.tex:getHeight())
    love.graphics.pop()
    
    --Shadows
    local offsetImage = Vector(-tempradius*2, -tempradius*2)
    -- (tempradius*pos:dist(sun))/(pos:dist(sun)+300) is a formula that has a asymptote at tempradius
    -- and falls off at a rate of 300
    local offsetDir = dir*(tempradius*pos:dist(sun))/(pos:dist(sun)+300)
    local offset = offsetDir+offsetImage
    if self.appearance.type ~= 'sun' then
      love.graphics.draw(shadow, offset.x,offset.y,0, tempradius*4/shadow:getWidth(), tempradius*4/shadow:getHeight())
    end
    local offsetDirSoft = offsetDir*1.75
    local offsetSoft = offsetDirSoft+offsetImage
    love.graphics.draw(softShadow, offsetSoft.x,offsetSoft.y,0, tempradius*4/softShadow:getWidth(), tempradius*4/softShadow:getHeight())
  love.graphics.setStencil()
    
  if self.appearance.rings then
    self:drawRings(tempradius, dir, false)
  end
    
  love.graphics.pop()
end

function Planet:drawRings(tempradius, dir, upsideDown)
  local persp = 4
  local ringWidth = tempradius / (0.25-(self.appearance.rings.number/self.rings:getWidth()))
  local ringHeight = tempradius*2/persp
  local ringStencil = love.graphics.newStencil(function()
    love.graphics.circle('fill', 0,0, tempradius, tempradius+1)
  end)
  local ringShadowStencil = love.graphics.newStencil(function()
    love.graphics.setLineWidth(tempradius*2)
    love.graphics.line(0,0, -dir.x*ringWidth, -dir.y*ringWidth)
  end)
  if upsideDown then upsideDown=-1 else upsideDown=1 end
  
  love.graphics.setBlendMode('premultiplied')
    love.graphics.setInvertedStencil(ringShadowStencil)
      love.graphics.push()
      love.graphics.rotate(self.texR)
      love.graphics.draw(self.rings, -ringWidth/2,-ringHeight*upsideDown,0, ringWidth/self.rings:getWidth(), ringHeight/self.rings:getHeight()*upsideDown)
      love.graphics.pop()
    love.graphics.setStencil(ringShadowStencil)
      love.graphics.setPixelEffect(silhouetteEffect)
        love.graphics.push()
        love.graphics.rotate(self.texR)
        love.graphics.draw(self.rings, -ringWidth/2,-ringHeight*upsideDown,0, ringWidth/self.rings:getWidth(), ringHeight/self.rings:getHeight()*upsideDown)
        love.graphics.pop()
      love.graphics.setPixelEffect()
    love.graphics.setStencil()
  love.graphics.setBlendMode('alpha')
end

function Planet:drawGhost(cam)
  if self.orbitRadius ~= 0 then
    love.graphics.setColor(255, 255, 255, 50)
    local pos = Vector(cam:cameraCoords(self.x, self.y))
    love.graphics.push()
    love.graphics.translate(pos.x, pos.y)
    local tempradius = math.max(5, self.radius*cam.scale)
    love.graphics.circle('fill', 0, 0, tempradius, tempradius+1)
    love.graphics.pop()
  end
end

function Planet:updatePosition(dt)
  self.r = self.r+(self.orbitSpeed/(2*math.pi)*dt)
  self.x = (math.cos(self.r)*self.orbitRadius)+self.orbitX
  self.y = (math.sin(self.r)*self.orbitRadius)+self.orbitY
end

function Planet:makeBox2D(world)
  local box2D = {}
  box2D.body = love.physics.newBody(world, self.x, self.y, "kinematic")
  box2D.shape = love.physics.newCircleShape(self.radius)
  
  box2D.fixture = love.physics.newFixture(box2D.body, box2D.shape, 1)
  
  box2D.fixture:setUserData({sprite = self})
  
  box2D.body:setMass(self.mass)
  box2D.body:setLinearVelocity(self.dx, self.dy)
  box2D.body:setFixedRotation(true)
  
  self.box2D = box2D
end

function Planet:updateFromBox2D() -- self.r for planet modified in Future:simulateTo loop
  self.x, self.y = self.box2D.body:getPosition()      
  --self.dx, self.dy = self.box2D.body:getLinearVelocity()
end

return Planet